;; Define constants
(define-constant curator-principal tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-artwork (err u101))
(define-constant err-artwork-exists (err u102))

;; Define data maps
(define-map artworks {id: uint} {cataloged: bool})
(define-map conservation-records 
  {artwork-id: uint, entry-id: uint} 
  {
    date: uint,
    procedure: (string-ascii 20),
    notes: (string-ascii 100),
    materials-used: (optional (string-ascii 100)),
    conservator: principal
  }
)

;; Define variables
(define-data-var entry-id-counter uint u0)

;; Private function to get and increment the entry ID
(define-private (generate-entry-id)
  (let ((current-id (var-get entry-id-counter)))
    (var-set entry-id-counter (+ current-id u1))
    current-id
  )
)

;; Private function to check if an artwork is cataloged
(define-private (is-artwork-cataloged (artwork-id uint))
  (default-to false (get cataloged (map-get? artworks {id: artwork-id})))
)

;; Public function to catalog an artwork
(define-public (catalog-artwork (artwork-id uint))
  (begin
    (asserts! (is-eq tx-sender curator-principal) err-not-authorized)
    (asserts! (not (is-artwork-cataloged artwork-id)) err-artwork-exists)
    (ok (map-set artworks {id: artwork-id} {cataloged: true}))
  )
)

;; Public function to add a conservation record
(define-public (add-conservation-record
    (artwork-id uint)
    (procedure (string-ascii 20))
    (notes (string-ascii 100))
    (materials-used (optional (string-ascii 100)))
  )
  (let
    (
      (entry-id (generate-entry-id))
    )
    (asserts! (is-artwork-cataloged artwork-id) err-invalid-artwork)
    (ok (map-set conservation-records
      {artwork-id: artwork-id, entry-id: entry-id}
      {
        date: stacks-block-height,
        procedure: procedure,
        notes: notes,
        materials-used: materials-used,
        conservator: tx-sender
      }
    ))
  )
)

;; Read-only function to get a conservation record
(define-read-only (get-conservation-record (artwork-id uint) (entry-id uint))
  (map-get? conservation-records {artwork-id: artwork-id, entry-id: entry-id})
)

;; Read-only function to get the total number of records
(define-read-only (get-total-records)
  (var-get entry-id-counter)
)

;; Read-only function to check if an artwork is cataloged
(define-read-only (check-artwork-cataloged (artwork-id uint))
  (is-artwork-cataloged artwork-id)
)