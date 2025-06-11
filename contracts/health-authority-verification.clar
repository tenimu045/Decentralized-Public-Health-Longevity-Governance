;; Health Authority Verification Contract
;; Validates and manages longevity governance entities

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_AUTHORITY (err u103))

;; Data structures
(define-map verified-authorities principal
  {
    name: (string-ascii 50),
    verification-date: uint,
    authority-type: (string-ascii 20),
    is-active: bool
  })

(define-map authority-credentials principal
  {
    credentials-hash: (buff 32),
    expiry-date: uint,
    issuer: principal
  })

(define-data-var total-authorities uint u0)

;; Public functions
(define-public (verify-authority (authority principal) (name (string-ascii 50)) (authority-type (string-ascii 20)) (credentials-hash (buff 32)) (expiry-date uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-authorities authority)) ERR_ALREADY_VERIFIED)

    (map-set verified-authorities authority
      {
        name: name,
        verification-date: block-height,
        authority-type: authority-type,
        is-active: true
      })

    (map-set authority-credentials authority
      {
        credentials-hash: credentials-hash,
        expiry-date: expiry-date,
        issuer: tx-sender
      })

    (var-set total-authorities (+ (var-get total-authorities) u1))
    (ok true)))

(define-public (revoke-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? verified-authorities authority)) ERR_NOT_FOUND)

    (map-set verified-authorities authority
      (merge (unwrap-panic (map-get? verified-authorities authority))
             { is-active: false }))
    (ok true)))

;; Read-only functions
(define-read-only (is-verified-authority (authority principal))
  (match (map-get? verified-authorities authority)
    authority-data (get is-active authority-data)
    false))

(define-read-only (get-authority-info (authority principal))
  (map-get? verified-authorities authority))

(define-read-only (get-total-authorities)
  (var-get total-authorities))
