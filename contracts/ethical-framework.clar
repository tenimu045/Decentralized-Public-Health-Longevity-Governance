;; Ethical Framework Contract
;; Ensures responsible longevity governance

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_PRINCIPLE_EXISTS (err u401))
(define-constant ERR_PRINCIPLE_NOT_FOUND (err u402))
(define-constant ERR_INVALID_SCORE (err u403))

;; Data structures
(define-map ethical-principles uint
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    category: (string-ascii 50),
    importance-score: uint,
    created-by: principal,
    created-at: uint,
    is-active: bool
  })

(define-map principle-violations { principle-id: uint, violator: principal }
  {
    violation-count: uint,
    last-violation: uint,
    severity-score: uint
  })

(define-map ethical-assessments uint
  {
    assessed-entity: principal,
    overall-score: uint,
    assessment-date: uint,
    assessor: principal,
    notes: (string-ascii 200)
  })

(define-data-var next-principle-id uint u1)
(define-data-var next-assessment-id uint u1)
(define-data-var min-ethical-score uint u70)

;; Public functions
(define-public (add-ethical-principle (title (string-ascii 100)) (description (string-ascii 300)) (category (string-ascii 50)) (importance-score uint))
  (let ((principle-id (var-get next-principle-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= importance-score u100) ERR_INVALID_SCORE)

    (map-set ethical-principles principle-id
      {
        title: title,
        description: description,
        category: category,
        importance-score: importance-score,
        created-by: tx-sender,
        created-at: block-height,
        is-active: true
      })

    (var-set next-principle-id (+ principle-id u1))
    (ok principle-id)))

(define-public (record-violation (principle-id uint) (violator principal) (severity-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? ethical-principles principle-id)) ERR_PRINCIPLE_NOT_FOUND)
    (asserts! (<= severity-score u100) ERR_INVALID_SCORE)

    (let ((current-violations (default-to { violation-count: u0, last-violation: u0, severity-score: u0 }
                                         (map-get? principle-violations { principle-id: principle-id, violator: violator }))))
      (map-set principle-violations { principle-id: principle-id, violator: violator }
        {
          violation-count: (+ (get violation-count current-violations) u1),
          last-violation: block-height,
          severity-score: severity-score
        }))

    (ok true)))

(define-public (conduct-ethical-assessment (assessed-entity principal) (overall-score uint) (notes (string-ascii 200)))
  (let ((assessment-id (var-get next-assessment-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= overall-score u100) ERR_INVALID_SCORE)

    (map-set ethical-assessments assessment-id
      {
        assessed-entity: assessed-entity,
        overall-score: overall-score,
        assessment-date: block-height,
        assessor: tx-sender,
        notes: notes
      })

    (var-set next-assessment-id (+ assessment-id u1))
    (ok assessment-id)))

;; Read-only functions
(define-read-only (get-principle (principle-id uint))
  (map-get? ethical-principles principle-id))

(define-read-only (get-violation-record (principle-id uint) (violator principal))
  (map-get? principle-violations { principle-id: principle-id, violator: violator }))

(define-read-only (get-assessment (assessment-id uint))
  (map-get? ethical-assessments assessment-id))

(define-read-only (meets-ethical-standards (entity principal))
  (>= (get-latest-score entity) (var-get min-ethical-score)))

(define-read-only (get-latest-score (entity principal))
  ;; Simplified scoring - in practice would aggregate multiple assessments
  u75)
