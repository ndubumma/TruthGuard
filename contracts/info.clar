;; TruthGuard - Conditional information disclosure system based on threshold monitoring
;; Smart Contract for Stacks Blockchain

;; Contract constants
(define-constant contract-administrator tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-unauthorized-access (err u101))
(define-constant err-disclosure-not-found (err u102))
(define-constant err-threshold-not-met (err u103))
(define-constant err-information-disclosed (err u104))
(define-constant err-insufficient-trigger-events (err u105))

;; Data variables
(define-data-var disclosure-registry-counter uint u0)
(define-data-var global-trigger-threshold uint u3)

;; Data maps
(define-map disclosure-registry
  { disclosure-id: uint }
  {
    custodian: principal,
    encrypted-payload: (string-ascii 500),
    disclosed-content: (optional (string-ascii 500)),
    monitoring-parameters: (list 5 (string-ascii 100)),
    trigger-event-count: uint,
    event-reporters: (list 10 principal),
    disclosure-status: bool,
    registration-block: uint,
    disclosure-block: (optional uint)
  }
)

(define-map trigger-event-logs
  { disclosure-id: uint, event-reporter: principal }
  {
    parameter-violated: (string-ascii 100),
    supporting-evidence: (string-ascii 300),
    event-timestamp: uint,
    validation-status: bool
  }
)

(define-map authorized-validators
  { validator: principal }
  { validation-authority: bool }
)

;; Private functions
(define-private (has-validation-authority (validator principal))
  (default-to false (get validation-authority (map-get? authorized-validators { validator: validator })))
)

(define-private (increment-disclosure-counter)
  (let ((current-counter (var-get disclosure-registry-counter)))
    (var-set disclosure-registry-counter (+ current-counter u1))
    (+ current-counter u1)
  )
)

;; Public functions

;; Register a new disclosure with encrypted content and monitoring parameters
(define-public (register-disclosure 
  (encrypted-payload (string-ascii 500))
  (monitoring-parameters (list 5 (string-ascii 100))))
  (let ((disclosure-id (increment-disclosure-counter)))
    (map-set disclosure-registry
      { disclosure-id: disclosure-id }
      {
        custodian: tx-sender,
        encrypted-payload: encrypted-payload,
        disclosed-content: none,
        monitoring-parameters: monitoring-parameters,
        trigger-event-count: u0,
        event-reporters: (list),
        disclosure-status: false,
        registration-block: block-height,
        disclosure-block: none
      }
    )
    (ok disclosure-id)
  )
)

;; Log a trigger event for a specific disclosure
(define-public (log-trigger-event 
  (disclosure-id uint)
  (parameter-violated (string-ascii 100))
  (supporting-evidence (string-ascii 300)))
  (let ((disclosure-data (unwrap! (map-get? disclosure-registry { disclosure-id: disclosure-id }) err-disclosure-not-found)))
    (if (get disclosure-status disclosure-data)
      err-information-disclosed
      (begin
        ;; Record the trigger event
        (map-set trigger-event-logs
          { disclosure-id: disclosure-id, event-reporter: tx-sender }
          {
            parameter-violated: parameter-violated,
            supporting-evidence: supporting-evidence,
            event-timestamp: block-height,
            validation-status: false
          }
        )
        ;; Update disclosure with new trigger event
        (map-set disclosure-registry
          { disclosure-id: disclosure-id }
          (merge disclosure-data {
            trigger-event-count: (+ (get trigger-event-count disclosure-data) u1),
            event-reporters: (unwrap-panic (as-max-len? 
              (append (get event-reporters disclosure-data) tx-sender) u10))
          })
        )
        (ok true)
      )
    )
  )
)

;; Validate a trigger event (only authorized validators)
(define-public (validate-trigger-event 
  (disclosure-id uint)
  (event-reporter principal))
  (if (has-validation-authority tx-sender)
    (let ((event-data (unwrap! (map-get? trigger-event-logs { disclosure-id: disclosure-id, event-reporter: event-reporter }) err-disclosure-not-found)))
      (map-set trigger-event-logs
        { disclosure-id: disclosure-id, event-reporter: event-reporter }
        (merge event-data { validation-status: true })
      )
      (ok true)
    )
    err-unauthorized-access
  )
)

;; Execute disclosure when trigger threshold is met
(define-public (execute-disclosure 
  (disclosure-id uint)
  (decrypted-content (string-ascii 500)))
  (let ((disclosure-data (unwrap! (map-get? disclosure-registry { disclosure-id: disclosure-id }) err-disclosure-not-found)))
    (if (get disclosure-status disclosure-data)
      err-information-disclosed
      (if (>= (get trigger-event-count disclosure-data) (var-get global-trigger-threshold))
        (if (is-eq tx-sender (get custodian disclosure-data))
          (begin
            (map-set disclosure-registry
              { disclosure-id: disclosure-id }
              (merge disclosure-data {
                disclosed-content: (some decrypted-content),
                disclosure-status: true,
                disclosure-block: (some block-height)
              })
            )
            (ok true)
          )
          err-unauthorized-access
        )
        err-insufficient-trigger-events
      )
    )
  )
)

;; Administrative disclosure by contract administrator
(define-public (administrative-disclosure 
  (disclosure-id uint)
  (decrypted-content (string-ascii 500)))
  (if (is-eq tx-sender contract-administrator)
    (let ((disclosure-data (unwrap! (map-get? disclosure-registry { disclosure-id: disclosure-id }) err-disclosure-not-found)))
      (map-set disclosure-registry
        { disclosure-id: disclosure-id }
        (merge disclosure-data {
          disclosed-content: (some decrypted-content),
          disclosure-status: true,
          disclosure-block: (some block-height)
        })
      )
      (ok true)
    )
    err-admin-only
  )
)

;; Grant validation authority
(define-public (grant-validation-authority (validator principal))
  (if (is-eq tx-sender contract-administrator)
    (begin
      (map-set authorized-validators
        { validator: validator }
        { validation-authority: true }
      )
      (ok true)
    )
    err-admin-only
  )
)

;; Update global trigger threshold
(define-public (update-trigger-threshold (new-threshold uint))
  (if (is-eq tx-sender contract-administrator)
    (begin
      (var-set global-trigger-threshold new-threshold)
      (ok true)
    )
    err-admin-only
  )
)

;; Read-only functions

;; Get disclosure information (protects undisclosed content from unauthorized access)
(define-read-only (get-disclosure-info (disclosure-id uint))
  (let ((disclosure-data (map-get? disclosure-registry { disclosure-id: disclosure-id })))
    (match disclosure-data
      disclosure-record
      (if (get disclosure-status disclosure-record)
        (some {
          custodian: (get custodian disclosure-record),
          monitoring-parameters: (get monitoring-parameters disclosure-record),
          trigger-event-count: (get trigger-event-count disclosure-record),
          disclosure-status: (get disclosure-status disclosure-record),
          registration-block: (get registration-block disclosure-record),
          disclosure-block: (get disclosure-block disclosure-record),
          disclosed-content: (get disclosed-content disclosure-record)
        })
        (some {
          custodian: (get custodian disclosure-record),
          monitoring-parameters: (get monitoring-parameters disclosure-record),
          trigger-event-count: (get trigger-event-count disclosure-record),
          disclosure-status: (get disclosure-status disclosure-record),
          registration-block: (get registration-block disclosure-record),
          disclosure-block: none,
          disclosed-content: none
        })
      )
      none
    )
  )
)

;; Get trigger event details
(define-read-only (get-trigger-event (disclosure-id uint) (event-reporter principal))
  (map-get? trigger-event-logs { disclosure-id: disclosure-id, event-reporter: event-reporter })
)

;; Get current trigger threshold
(define-read-only (get-trigger-threshold)
  (var-get global-trigger-threshold)
)

;; Get total number of disclosures
(define-read-only (get-disclosure-count)
  (var-get disclosure-registry-counter)
)

;; Check if a validator has authority
(define-read-only (has-validator-authority (validator principal))
  (has-validation-authority validator)
)