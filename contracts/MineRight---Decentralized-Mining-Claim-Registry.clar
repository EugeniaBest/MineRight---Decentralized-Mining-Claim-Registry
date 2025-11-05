(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-EXISTS (err u3))
(define-constant ERR-INVALID-COORDINATES (err u4))
(define-constant ERR-INSUFFICIENT-APPROVALS (err u5))
(define-constant ERR-INVALID-COMPLIANCE-SCORE (err u6))
(define-constant ERR-CLAIM-INACTIVE (err u7))
(define-constant ERR-INVALID-ROYALTY-RATE (err u8))
(define-constant ERR-DISPUTE-NOT-FOUND (err u9))
(define-constant ERR-DISPUTE-ALREADY-RESOLVED (err u10))
(define-constant ERR-INVALID-DISPUTE-TYPE (err u11))
(define-constant ERR-VOTING-PERIOD-ENDED (err u12))
(define-constant ERR-INVALID-DURATION (err u15))
(define-constant ERR-INVALID-RENT (err u16))
(define-constant ERR-NO-RENT-DUE (err u17))
(define-constant ERR-INVALID-PRICE (err u18))

(define-data-var claim-counter uint u0)
(define-data-var required-approvals uint u2)
(define-data-var dispute-counter uint u0)
(define-data-var sub-claim-counter uint u0)
(define-data-var marketplace-counter uint u0)

(define-map mining-claims
  { claim-id: uint }
  {
    owner: principal,
    gps-latitude: int,
    gps-longitude: int,
    area-hectares: uint,
    mineral-type: (string-ascii 50),
    status: (string-ascii 20),
    issue-date: uint,
    expiry-date: uint,
    royalty-rate: uint,
    compliance-score: uint
  })

(define-map claim-approvals
  { claim-id: uint }
  {
    government-approved: bool,
    local-body-approved: bool,
    community-approved: bool,
    environmental-approved: bool
  })

(define-map royalty-balances
  { claim-id: uint, recipient: principal }
  { balance: uint })

(define-map compliance-votes
  { claim-id: uint, voter: principal }
  { score: uint, timestamp: uint })

(define-map claim-coordinates
  { latitude: int, longitude: int }
  { claim-id: uint })

(define-map disputes
  { dispute-id: uint }
  {
    claim-id: uint,
    plaintiff: principal,
    defendant: principal,
    dispute-type: (string-ascii 20),
    description: (string-ascii 200),
    evidence-hash: (string-ascii 64),
    filed-at: uint,
    voting-ends: uint,
    status: (string-ascii 20),
    resolution: (string-ascii 20),
    penalty-amount: uint
  })

(define-map dispute-votes
  { dispute-id: uint, voter: principal }
  { vote: (string-ascii 20), timestamp: uint })

(define-map dispute-vote-counts
  { dispute-id: uint }
  { favor-plaintiff: uint, favor-defendant: uint, abstain: uint })

(define-map sub-claims
  { sub-claim-id: uint }
  {
    parent-claim-id: uint,
    owner: principal,
    gps-latitude: int,
    gps-longitude: int,
    area-hectares: uint,
    mineral-type: (string-ascii 50),
    status: (string-ascii 20),
    issue-date: uint,
    expiry-date: uint,
    royalty-rate: uint,
    compliance-score: uint
  })

(define-map sub-claim-coordinates
  { latitude: int, longitude: int }
  { sub-claim-id: uint })

(define-map claim-leases
  { claim-id: uint }
  {
    lessee: principal,
    start-block: uint,
    end-block: uint,
    rent-per-block: uint,
    last-payment-block: uint
  })

(define-map marketplace-listings
  { listing-id: uint }
  {
    claim-id: uint,
    seller: principal,
    price: uint,
    listed-at: uint,
    status: (string-ascii 20)
  })

(define-read-only (get-claim (claim-id uint))
  (map-get? mining-claims { claim-id: claim-id }))

(define-read-only (get-claim-approvals (claim-id uint))
  (map-get? claim-approvals { claim-id: claim-id }))

(define-read-only (get-royalty-balance (claim-id uint) (recipient principal))
  (default-to u0 (get balance (map-get? royalty-balances { claim-id: claim-id, recipient: recipient }))))

(define-read-only (get-compliance-score (claim-id uint))
  (match (get-claim claim-id)
    claim (get compliance-score claim)
    u0))

(define-read-only (check-coordinate-overlap (latitude int) (longitude int))
  (or
    (is-some (map-get? claim-coordinates { latitude: latitude, longitude: longitude }))
    (is-some (map-get? sub-claim-coordinates { latitude: latitude, longitude: longitude }))))

(define-read-only (is-claim-active (claim-id uint))
  (match (get-claim claim-id)
    claim (is-eq (get status claim) "active")
    false))

(define-read-only (count-approvals (claim-id uint))
  (match (get-claim-approvals claim-id)
    approvals
      (+ 
        (if (get government-approved approvals) u1 u0)
        (if (get local-body-approved approvals) u1 u0)
        (if (get community-approved approvals) u1 u0)
        (if (get environmental-approved approvals) u1 u0))
    u0))

(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id }))

(define-read-only (get-dispute-vote-counts (dispute-id uint))
  (default-to 
    { favor-plaintiff: u0, favor-defendant: u0, abstain: u0 }
    (map-get? dispute-vote-counts { dispute-id: dispute-id })))

(define-read-only (is-voting-active (dispute-id uint))
  (match (get-dispute dispute-id)
    dispute (and
      (is-eq (get status dispute) "voting")
      (< stacks-block-height (get voting-ends dispute)))
    false))

(define-read-only (get-sub-claim (sub-claim-id uint))
  (map-get? sub-claims { sub-claim-id: sub-claim-id }))

(define-read-only (is-sub-claim-active (sub-claim-id uint))
  (match (get-sub-claim sub-claim-id)
    sub-claim (is-eq (get status sub-claim) "active")
    false))

(define-read-only (get-lease (claim-id uint))
  (map-get? claim-leases { claim-id: claim-id }))

(define-read-only (get-marketplace-listing (listing-id uint))
  (map-get? marketplace-listings { listing-id: listing-id }))

(define-public (register-claim 
  (gps-latitude int) 
  (gps-longitude int) 
  (area-hectares uint) 
  (mineral-type (string-ascii 50))
  (royalty-rate uint))
  (let ((claim-id (+ (var-get claim-counter) u1)))
    (asserts! (and (>= gps-latitude -90000000) (<= gps-latitude 90000000)) ERR-INVALID-COORDINATES)
    (asserts! (and (>= gps-longitude -180000000) (<= gps-longitude 180000000)) ERR-INVALID-COORDINATES)
    (asserts! (not (check-coordinate-overlap gps-latitude gps-longitude)) ERR-ALREADY-EXISTS)
    (asserts! (<= royalty-rate u1000) ERR-INVALID-ROYALTY-RATE)
    (map-set mining-claims
      { claim-id: claim-id }
      {
        owner: tx-sender,
        gps-latitude: gps-latitude,
        gps-longitude: gps-longitude,
        area-hectares: area-hectares,
        mineral-type: mineral-type,
        status: "pending",
        issue-date: stacks-block-height,
        expiry-date: (+ stacks-block-height u52560),
        royalty-rate: royalty-rate,
        compliance-score: u0
      })
    (map-set claim-approvals
      { claim-id: claim-id }
      {
        government-approved: false,
        local-body-approved: false,
        community-approved: false,
        environmental-approved: false
      })
    (map-set claim-coordinates
      { latitude: gps-latitude, longitude: gps-longitude }
      { claim-id: claim-id })
    (var-set claim-counter claim-id)
    (ok claim-id)))

(define-public (approve-claim-government (claim-id uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND))
        (approvals (unwrap! (get-claim-approvals claim-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (as-contract tx-sender)) ERR-UNAUTHORIZED)
    (map-set claim-approvals
      { claim-id: claim-id }
      (merge approvals { government-approved: true }))
    (if (>= (count-approvals claim-id) (var-get required-approvals))
      (begin
        (map-set mining-claims
          { claim-id: claim-id }
          (merge claim { status: "active" }))
        (ok true))
      (ok false))))

(define-public (approve-claim-local-body (claim-id uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND))
        (approvals (unwrap! (get-claim-approvals claim-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (as-contract tx-sender)) ERR-UNAUTHORIZED)
    (map-set claim-approvals
      { claim-id: claim-id }
      (merge approvals { local-body-approved: true }))
    (if (>= (count-approvals claim-id) (var-get required-approvals))
      (begin
        (map-set mining-claims
          { claim-id: claim-id }
          (merge claim { status: "active" }))
        (ok true))
      (ok false))))

(define-public (vote-compliance (claim-id uint) (score uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (is-claim-active claim-id) ERR-CLAIM-INACTIVE)
    (asserts! (<= score u100) ERR-INVALID-COMPLIANCE-SCORE)
    (map-set compliance-votes
      { claim-id: claim-id, voter: tx-sender }
      { score: score, timestamp: stacks-block-height })
    (ok true)))

(define-public (update-compliance-score (claim-id uint) (new-score uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner claim)) ERR-UNAUTHORIZED)
    (asserts! (<= new-score u100) ERR-INVALID-COMPLIANCE-SCORE)
    (map-set mining-claims
      { claim-id: claim-id }
      (merge claim { compliance-score: new-score }))
    (ok true)))

(define-public (deposit-royalty (claim-id uint) (amount uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (is-claim-active claim-id) ERR-CLAIM-INACTIVE)
    (asserts! (> amount u0) (err u13))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set royalty-balances
      { claim-id: claim-id, recipient: (get owner claim) }
      { balance: (+ (get-royalty-balance claim-id (get owner claim)) amount) })
    (ok true)))

(define-public (withdraw-royalty (claim-id uint) (amount uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND))
        (current-balance (get-royalty-balance claim-id tx-sender)))
    (asserts! (is-eq tx-sender (get owner claim)) ERR-UNAUTHORIZED)
    (asserts! (>= current-balance amount) (err u14))
    (map-set royalty-balances
      { claim-id: claim-id, recipient: tx-sender }
      { balance: (- current-balance amount) })
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (ok true)))

(define-public (transfer-claim (claim-id uint) (new-owner principal))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner claim)) ERR-UNAUTHORIZED)
    (asserts! (is-claim-active claim-id) ERR-CLAIM-INACTIVE)
    (map-set mining-claims
      { claim-id: claim-id }
      (merge claim { owner: new-owner }))
    (ok true)))

(define-public (extend-claim (claim-id uint) (additional-blocks uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner claim)) ERR-UNAUTHORIZED)
    (asserts! (is-claim-active claim-id) ERR-CLAIM-INACTIVE)
    (map-set mining-claims
      { claim-id: claim-id }
      (merge claim { expiry-date: (+ (get expiry-date claim) additional-blocks) }))
    (ok true)))

(define-public (revoke-claim (claim-id uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (or 
      (is-eq tx-sender (get owner claim))
      (is-eq tx-sender (as-contract tx-sender))) ERR-UNAUTHORIZED)
    (map-set mining-claims
      { claim-id: claim-id }
      (merge claim { status: "revoked" }))
    (ok true)))

(define-public (set-required-approvals (new-required uint))
  (begin
    (asserts! (is-eq tx-sender (as-contract tx-sender)) ERR-UNAUTHORIZED)
    (var-set required-approvals new-required)
    (ok true)))

(define-public (file-dispute 
  (claim-id uint) 
  (defendant principal) 
  (dispute-type (string-ascii 20)) 
  (description (string-ascii 200)) 
  (evidence-hash (string-ascii 64)))
  (let ((dispute-id (+ (var-get dispute-counter) u1))
        (claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (is-claim-active claim-id) ERR-CLAIM-INACTIVE)
    (asserts! (or 
      (is-eq dispute-type "boundary")
      (is-eq dispute-type "environmental")
      (is-eq dispute-type "royalty")
      (is-eq dispute-type "ownership")) ERR-INVALID-DISPUTE-TYPE)
    (map-set disputes
      { dispute-id: dispute-id }
      {
        claim-id: claim-id,
        plaintiff: tx-sender,
        defendant: defendant,
        dispute-type: dispute-type,
        description: description,
        evidence-hash: evidence-hash,
        filed-at: stacks-block-height,
        voting-ends: (+ stacks-block-height u1440),
        status: "voting",
        resolution: "pending",
        penalty-amount: u0
      })
    (map-set dispute-vote-counts
      { dispute-id: dispute-id }
      { favor-plaintiff: u0, favor-defendant: u0, abstain: u0 })
    (var-set dispute-counter dispute-id)
    (ok dispute-id)))

(define-public (vote-on-dispute (dispute-id uint) (vote (string-ascii 20)))
  (let ((dispute (unwrap! (get-dispute dispute-id) ERR-DISPUTE-NOT-FOUND))
        (current-counts (get-dispute-vote-counts dispute-id)))
    (asserts! (is-voting-active dispute-id) ERR-VOTING-PERIOD-ENDED)
    (asserts! (or 
      (is-eq vote "plaintiff")
      (is-eq vote "defendant")
      (is-eq vote "abstain")) ERR-INVALID-DISPUTE-TYPE)
    (map-set dispute-votes
      { dispute-id: dispute-id, voter: tx-sender }
      { vote: vote, timestamp: stacks-block-height })
    (map-set dispute-vote-counts
      { dispute-id: dispute-id }
      (if (is-eq vote "plaintiff")
        (merge current-counts { favor-plaintiff: (+ (get favor-plaintiff current-counts) u1) })
        (if (is-eq vote "defendant")
          (merge current-counts { favor-defendant: (+ (get favor-defendant current-counts) u1) })
          (merge current-counts { abstain: (+ (get abstain current-counts) u1) }))))
    (ok true)))

(define-public (resolve-dispute (dispute-id uint))
  (let ((dispute (unwrap! (get-dispute dispute-id) ERR-DISPUTE-NOT-FOUND))
        (vote-counts (get-dispute-vote-counts dispute-id))
        (plaintiff-votes (get favor-plaintiff vote-counts))
        (defendant-votes (get favor-defendant vote-counts)))
    (asserts! (not (is-voting-active dispute-id)) ERR-VOTING-PERIOD-ENDED)
    (asserts! (is-eq (get status dispute) "voting") ERR-DISPUTE-ALREADY-RESOLVED)
    (let ((resolution (if (> plaintiff-votes defendant-votes) "plaintiff-wins" "defendant-wins"))
          (penalty (if (> plaintiff-votes defendant-votes) u10000000 u0)))
      (map-set disputes
        { dispute-id: dispute-id }
        (merge dispute { 
          status: "resolved", 
          resolution: resolution,
          penalty-amount: penalty
        }))
      (if (> plaintiff-votes defendant-votes)
        (begin
          (try! (stx-transfer? penalty (get defendant dispute) (get plaintiff dispute)))
          (ok { resolution: resolution, penalty: penalty }))
        (ok { resolution: resolution, penalty: u0 })))))

(define-public (appeal-dispute (dispute-id uint))
  (let ((dispute (unwrap! (get-dispute dispute-id) ERR-DISPUTE-NOT-FOUND)))
    (asserts! (is-eq (get status dispute) "resolved") ERR-DISPUTE-NOT-FOUND)
    (asserts! (or
      (is-eq tx-sender (get plaintiff dispute))
      (is-eq tx-sender (get defendant dispute))) ERR-UNAUTHORIZED)
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: "appeal",
        voting-ends: (+ stacks-block-height u2880)
      }))
    (map-set dispute-vote-counts
      { dispute-id: dispute-id }
      { favor-plaintiff: u0, favor-defendant: u0, abstain: u0 })
    (ok true)))

(define-public (subdivide-claim
  (parent-claim-id uint)
  (gps-latitude int)
  (gps-longitude int)
  (area-hectares uint)
  (mineral-type (string-ascii 50))
  (royalty-rate uint))
  (let ((parent-claim (unwrap! (get-claim parent-claim-id) ERR-NOT-FOUND))
        (sub-claim-id (+ (var-get sub-claim-counter) u1)))
    (asserts! (is-eq tx-sender (get owner parent-claim)) ERR-UNAUTHORIZED)
    (asserts! (is-claim-active parent-claim-id) ERR-CLAIM-INACTIVE)
    (asserts! (and (>= gps-latitude -90000000) (<= gps-latitude 90000000)) ERR-INVALID-COORDINATES)
    (asserts! (and (>= gps-longitude -180000000) (<= gps-longitude 180000000)) ERR-INVALID-COORDINATES)
    (asserts! (not (check-coordinate-overlap gps-latitude gps-longitude)) ERR-ALREADY-EXISTS)
    (asserts! (<= royalty-rate u1000) ERR-INVALID-ROYALTY-RATE)
    (map-set sub-claims
      { sub-claim-id: sub-claim-id }
      {
        parent-claim-id: parent-claim-id,
        owner: tx-sender,
        gps-latitude: gps-latitude,
        gps-longitude: gps-longitude,
        area-hectares: area-hectares,
        mineral-type: mineral-type,
        status: "active",
        issue-date: stacks-block-height,
        expiry-date: (+ stacks-block-height u52560),
        royalty-rate: royalty-rate,
        compliance-score: u0
      })
    (map-set sub-claim-coordinates
      { latitude: gps-latitude, longitude: gps-longitude }
      { sub-claim-id: sub-claim-id })
    (var-set sub-claim-counter sub-claim-id)
    (ok sub-claim-id)))

(define-public (create-lease (claim-id uint) (lessee principal) (duration-blocks uint) (rent-per-block uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner claim)) ERR-UNAUTHORIZED)
    (asserts! (is-claim-active claim-id) ERR-CLAIM-INACTIVE)
    (asserts! (> duration-blocks u0) ERR-INVALID-DURATION)
    (asserts! (> rent-per-block u0) ERR-INVALID-RENT)
    (asserts! (is-none (get-lease claim-id)) ERR-ALREADY-EXISTS)
    (map-set claim-leases
      { claim-id: claim-id }
      {
        lessee: lessee,
        start-block: stacks-block-height,
        end-block: (+ stacks-block-height duration-blocks),
        rent-per-block: rent-per-block,
        last-payment-block: stacks-block-height
      })
    (ok true)))

(define-public (pay-lease-rent (claim-id uint))
  (let ((lease (unwrap! (get-lease claim-id) ERR-NOT-FOUND))
        (claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND))
        (blocks-due (- stacks-block-height (get last-payment-block lease)))
        (rent-due (* blocks-due (get rent-per-block lease))))
    (asserts! (is-eq tx-sender (get lessee lease)) ERR-UNAUTHORIZED)
    (asserts! (<= stacks-block-height (get end-block lease)) ERR-CLAIM-INACTIVE)
    (asserts! (> rent-due u0) ERR-NO-RENT-DUE)
    (try! (stx-transfer? rent-due tx-sender (get owner claim)))
    (map-set claim-leases
      { claim-id: claim-id }
      (merge lease { last-payment-block: stacks-block-height }))
    (ok rent-due)))

(define-public (terminate-lease (claim-id uint))
  (let ((lease (unwrap! (get-lease claim-id) ERR-NOT-FOUND))
        (claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get owner claim)) (is-eq tx-sender (get lessee lease))) ERR-UNAUTHORIZED)
    (map-delete claim-leases { claim-id: claim-id })
    (ok true)))

(define-public (list-claim-for-sale (claim-id uint) (price uint))
  (let ((claim (unwrap! (get-claim claim-id) ERR-NOT-FOUND))
        (listing-id (+ (var-get marketplace-counter) u1)))
    (asserts! (is-eq tx-sender (get owner claim)) ERR-UNAUTHORIZED)
    (asserts! (is-claim-active claim-id) ERR-CLAIM-INACTIVE)
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (map-set marketplace-listings
      { listing-id: listing-id }
      {
        claim-id: claim-id,
        seller: tx-sender,
        price: price,
        listed-at: stacks-block-height,
        status: "active"
      })
    (var-set marketplace-counter listing-id)
    (ok listing-id)))

(define-public (buy-claim (listing-id uint))
  (let ((listing (unwrap! (get-marketplace-listing listing-id) ERR-NOT-FOUND))
        (claim (unwrap! (get-claim (get claim-id listing)) ERR-NOT-FOUND)))
    (asserts! (is-eq (get status listing) "active") ERR-NOT-FOUND)
    (asserts! (is-claim-active (get claim-id listing)) ERR-CLAIM-INACTIVE)
    (asserts! (not (is-eq tx-sender (get seller listing))) ERR-UNAUTHORIZED)
    (try! (stx-transfer? (get price listing) tx-sender (get seller listing)))
    (map-set mining-claims
      { claim-id: (get claim-id listing) }
      (merge claim { owner: tx-sender }))
    (map-set marketplace-listings
      { listing-id: listing-id }
      (merge listing { status: "sold" }))
    (ok true)))

(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (get-marketplace-listing listing-id) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get seller listing)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status listing) "active") ERR-NOT-FOUND)
    (map-set marketplace-listings
      { listing-id: listing-id }
      (merge listing { status: "cancelled" }))
    (ok true)))
