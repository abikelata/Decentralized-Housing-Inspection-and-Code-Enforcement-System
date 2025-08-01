;; Housing Discrimination Prevention Contract
;; Monitors rental practices to prevent illegal discrimination

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-COMPLAINT-NOT-FOUND (err u200))
(define-constant ERR-INVALID-INPUT (err u201))
(define-constant ERR-LANDLORD-NOT-FOUND (err u300))
(define-constant ERR-INVALID-STATUS (err u400))

;; Data Variables
(define-data-var next-complaint-id uint u1)
(define-data-var next-case-id uint u1)

;; Data Maps
(define-map discrimination-complaints
  { complaint-id: uint }
  {
    complainant: principal,
    landlord: principal,
    property-address: (string-ascii 100),
    discrimination-type: (string-ascii 50),
    incident-date: uint,
    filed-date: uint,
    description: (string-ascii 500),
    status: (string-ascii 20),
    evidence-url: (string-ascii 100)
  }
)

(define-map investigation-cases
  { case-id: uint }
  {
    complaint-id: uint,
    investigator: principal,
    opened-date: uint,
    closed-date: (optional uint),
    findings: (string-ascii 300),
    violation-found: (optional bool),
    status: (string-ascii 20)
  }
)

(define-map landlord-records
  { landlord: principal }
  {
    name: (string-ascii 50),
    properties-count: uint,
    complaints-count: uint,
    violations-count: uint,
    compliance-score: uint,
    last-training-date: (optional uint)
  }
)

(define-map fair-housing-violations
  { landlord: principal, violation-id: uint }
  {
    violation-type: (string-ascii 50),
    violation-date: uint,
    penalty-amount: uint,
    paid: bool,
    resolution-required: bool,
    resolution-deadline: uint
  }
)

(define-map authorized-investigators
  { investigator: principal }
  {
    name: (string-ascii 50),
    badge-number: (string-ascii 20),
    authorized: bool,
    authorization-date: uint
  }
)

;; Authorization Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-authorized-investigator (investigator principal))
  (match (map-get? authorized-investigators { investigator: investigator })
    investigator-data (get authorized investigator-data)
    false
  )
)

;; Investigator Management
(define-public (authorize-investigator (investigator principal) (name (string-ascii 50)) (badge-number (string-ascii 20)))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len badge-number) u0) ERR-INVALID-INPUT)

    (map-set authorized-investigators
      { investigator: investigator }
      {
        name: name,
        badge-number: badge-number,
        authorized: true,
        authorization-date: block-height
      }
    )

    (print { event: "investigator-authorized", investigator: investigator, badge: badge-number })
    (ok true)
  )
)

;; Landlord Registration
(define-public (register-landlord (landlord principal) (name (string-ascii 50)) (properties-count uint))
  (begin
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> properties-count u0) ERR-INVALID-INPUT)

    (map-set landlord-records
      { landlord: landlord }
      {
        name: name,
        properties-count: properties-count,
        complaints-count: u0,
        violations-count: u0,
        compliance-score: u100,
        last-training-date: none
      }
    )

    (print { event: "landlord-registered", landlord: landlord, properties: properties-count })
    (ok true)
  )
)

;; Complaint Management
(define-public (file-complaint (landlord principal) (property-address (string-ascii 100)) (discrimination-type (string-ascii 50)) (incident-date uint) (description (string-ascii 500)) (evidence-url (string-ascii 100)))
  (let ((complaint-id (var-get next-complaint-id)))
    (asserts! (is-some (map-get? landlord-records { landlord: landlord })) ERR-LANDLORD-NOT-FOUND)
    (asserts! (> (len property-address) u0) ERR-INVALID-INPUT)
    (asserts! (> (len discrimination-type) u0) ERR-INVALID-INPUT)
    (asserts! (<= incident-date block-height) ERR-INVALID-INPUT)

    (map-set discrimination-complaints
      { complaint-id: complaint-id }
      {
        complainant: tx-sender,
        landlord: landlord,
        property-address: property-address,
        discrimination-type: discrimination-type,
        incident-date: incident-date,
        filed-date: block-height,
        description: description,
        status: "filed",
        evidence-url: evidence-url
      }
    )

    ;; Update landlord complaint count
    (match (map-get? landlord-records { landlord: landlord })
      landlord-data
      (let ((current-score (get compliance-score landlord-data))
            (new-score (if (>= current-score u5) (- current-score u5) u0)))
        (map-set landlord-records
          { landlord: landlord }
          (merge landlord-data {
            complaints-count: (+ (get complaints-count landlord-data) u1),
            compliance-score: new-score
          })
        )
      )
      false
    )

    (var-set next-complaint-id (+ complaint-id u1))
    (print { event: "complaint-filed", complaint-id: complaint-id, landlord: landlord, type: discrimination-type })
    (ok complaint-id)
  )
)

;; Investigation Management
(define-public (open-investigation (complaint-id uint))
  (let ((case-id (var-get next-case-id)))
    (asserts! (is-authorized-investigator tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? discrimination-complaints { complaint-id: complaint-id })) ERR-COMPLAINT-NOT-FOUND)

    (map-set investigation-cases
      { case-id: case-id }
      {
        complaint-id: complaint-id,
        investigator: tx-sender,
        opened-date: block-height,
        closed-date: none,
        findings: "",
        violation-found: none,
        status: "open"
      }
    )

    ;; Update complaint status
    (match (map-get? discrimination-complaints { complaint-id: complaint-id })
      complaint-data
      (map-set discrimination-complaints
        { complaint-id: complaint-id }
        (merge complaint-data { status: "under-investigation" })
      )
      false
    )

    (var-set next-case-id (+ case-id u1))
    (print { event: "investigation-opened", case-id: case-id, complaint-id: complaint-id })
    (ok case-id)
  )
)

(define-public (close-investigation (case-id uint) (findings (string-ascii 300)) (violation-found bool))
  (match (map-get? investigation-cases { case-id: case-id })
    case-data
    (begin
      (asserts! (is-eq tx-sender (get investigator case-data)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status case-data) "open") ERR-INVALID-STATUS)

      (map-set investigation-cases
        { case-id: case-id }
        (merge case-data {
          closed-date: (some block-height),
          findings: findings,
          violation-found: (some violation-found),
          status: "closed"
        })
      )

      ;; Update complaint status
      (match (map-get? discrimination-complaints { complaint-id: (get complaint-id case-data) })
        complaint-data
        (map-set discrimination-complaints
          { complaint-id: (get complaint-id case-data) }
          (merge complaint-data {
            status: (if violation-found "violation-found" "no-violation")
          })
        )
        false
      )

      (print { event: "investigation-closed", case-id: case-id, violation-found: violation-found })
      (ok true)
    )
    ERR-COMPLAINT-NOT-FOUND
  )
)

;; Violation Management
(define-public (issue-violation (landlord principal) (violation-type (string-ascii 50)) (penalty-amount uint) (resolution-deadline uint))
  (begin
    (asserts! (is-authorized-investigator tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? landlord-records { landlord: landlord })) ERR-LANDLORD-NOT-FOUND)
    (asserts! (> penalty-amount u0) ERR-INVALID-INPUT)
    (asserts! (> resolution-deadline block-height) ERR-INVALID-INPUT)

    (let ((violation-id block-height))
      (map-set fair-housing-violations
        { landlord: landlord, violation-id: violation-id }
        {
          violation-type: violation-type,
          violation-date: block-height,
          penalty-amount: penalty-amount,
          paid: false,
          resolution-required: true,
          resolution-deadline: resolution-deadline
        }
      )

      ;; Update landlord violation count and compliance score
      (match (map-get? landlord-records { landlord: landlord })
        landlord-data
        (let ((current-score (get compliance-score landlord-data))
              (new-score (if (>= current-score u20) (- current-score u20) u0)))
          (map-set landlord-records
            { landlord: landlord }
            (merge landlord-data {
              violations-count: (+ (get violations-count landlord-data) u1),
              compliance-score: new-score
            })
          )
        )
        false
      )

      (print { event: "violation-issued", landlord: landlord, violation-id: violation-id, penalty: penalty-amount })
      (ok violation-id)
    )
  )
)

;; Read-only Functions
(define-read-only (get-complaint (complaint-id uint))
  (map-get? discrimination-complaints { complaint-id: complaint-id })
)

(define-read-only (get-investigation-case (case-id uint))
  (map-get? investigation-cases { case-id: case-id })
)

(define-read-only (get-landlord-record (landlord principal))
  (map-get? landlord-records { landlord: landlord })
)

(define-read-only (get-violation (landlord principal) (violation-id uint))
  (map-get? fair-housing-violations { landlord: landlord, violation-id: violation-id })
)

(define-read-only (get-investigator (investigator principal))
  (map-get? authorized-investigators { investigator: investigator })
)

(define-read-only (get-next-complaint-id)
  (var-get next-complaint-id)
)

(define-read-only (get-next-case-id)
  (var-get next-case-id)
)
