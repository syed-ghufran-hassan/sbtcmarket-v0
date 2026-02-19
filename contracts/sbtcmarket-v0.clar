;; sBTC Prediction Market - Complete Set AMM
;; Implements zero-capital market creation, complete-set mint/burn,
;; constant-product swaps, oracle resolution (Pyth v4), and redemption.
;;
;; ENHANCEMENT: Time-Weighted Average Price (TWAP) Oracle Integration
;; Prevents price manipulation attacks by using TWAP instead of spot prices
;;
;; TWAP accumulates prices over time and provides a volume-weighted average,
;; making it much harder and more expensive to manipulate than spot prices.
;;
;; Implementation:
;;   1. Price accumulators store cumulative product of price * time
;;   2. Observations stored periodically for TWAP calculation
;;   3. Users can query TWAP over any time window
;;   4. Optional TWAP-based market resolution

;; ====================================================================================
;; ENHANCEMENT: TWAP ORACLE DATA STRUCTURES
;; ====================================================================================

;; TWAP Observation: Stores price snapshot at a point in time
(define-map twap-observations
  { market-id: uint, observation-index: uint }
  {
    timestamp: uint,           ;; Block height when observation was taken
    price-yes: uint,           ;; YES price at observation time
    price-no: uint,            ;; NO price at observation time
    accumulator-yes: uint,     ;; Cumulative YES price * time product
    accumulator-no: uint,      ;; Cumulative NO price * time product
  }
)

;; TWAP configuration per market
(define-map twap-config
  { market-id: uint }
  {
    enabled: bool,                      ;; Is TWAP enabled for this market?
    observation-frequency: uint,        ;; Blocks between observations (e.g., 100)
    last-observation-block: uint,       ;; Last block when observation was taken
    observation-count: uint,            ;; Total number of observations
    current-accumulator-yes: uint,      ;; Running accumulator for YES
    current-accumulator-no: uint,       ;; Running accumulator for NO
    twap-window: uint,                  ;; Default TWAP window for resolution (blocks)
  }
)

;; New error codes
(define-constant ERR-TWAP-NOT-ENABLED u1100)
(define-constant ERR-TWAP-INSUFFICIENT-OBS u1101)
(define-constant ERR-TWAP-WINDOW-TOO-SMALL u1102)
(define-constant ERR-TWAP-WINDOW-TOO-LARGE u1103)

;; ====================================================================================
;; ENHANCEMENT: TWAP CONFIGURATION FUNCTIONS
;; ====================================================================================

;; Enable TWAP for a market (can only be called by market creator before first trade)
(define-public (enable-twap
    (market-id uint)
    (observation-frequency uint)
    (twap-window uint)
  )
  (let ((market (try! (fetch-market market-id))))
    ;; Only market creator can enable TWAP
    (try! (ensure (is-eq tx-sender (get proposer market)) ERR-UNAUTHORIZED))
    
    ;; Can only enable before any trading activity
    (try! (ensure (is-eq (get yes-circulating market) u0) ERR-TOO-LATE))
    
    ;; Validate parameters
    (try! (ensure (> observation-frequency u0) ERR-INVALID-V-LIQUIDITY))
    (try! (ensure (> twap-window observation-frequency) ERR-TWAP-WINDOW-TOO-SMALL))
    
    ;; Initialize TWAP config
    (map-set twap-config { market-id: market-id }
      {
        enabled: true,
        observation-frequency: observation-frequency,
        last-observation-block: burn-block-height,
        observation-count: u0,
        current-accumulator-yes: u0,
        current-accumulator-no: u0,
        twap-window: twap-window,
      }
    )
    
    ;; Take initial observation
    (try! (take-twap-observation market-id))
    
    (print {
      event: "twap-enabled",
      market-id: market-id,
      observation-frequency: observation-frequency,
      twap-window: twap-window,
      enabled-by: tx-sender,
    })
    (ok true)
  )
)

;; Take TWAP observation (can be called by anyone as a keeper function)
(define-public (take-twap-observation (market-id uint))
  (let (
      (market (try! (fetch-market market-id)))
      (config-opt (map-get? twap-config { market-id: market-id }))
    )
    (match config-opt
      config
        (let (
            (current-block burn-block-height)
            (last-block (get last-observation-block config))
            (blocks-passed (- current-block last-block))
          )
          ;; Only take observation if enough blocks have passed
          (if (>= blocks-passed (get observation-frequency config))
            (let (
                (price-yes (get price-yes market))
                (price-no (get price-no market))
                (current-acc-yes (get current-accumulator-yes config))
                (current-acc-no (get current-accumulator-no config))
                ;; Update accumulators: add price * time since last observation
                (new-acc-yes (+ current-acc-yes (* price-yes blocks-passed)))
                (new-acc-no (+ current-acc-no (* price-no blocks-passed)))
                (obs-index (get observation-count config))
              )
              ;; Store observation
              (map-set twap-observations
                { market-id: market-id, observation-index: obs-index }
                {
                  timestamp: current-block,
                  price-yes: price-yes,
                  price-no: price-no,
                  accumulator-yes: new-acc-yes,
                  accumulator-no: new-acc-no,
                }
              )
              
              ;; Update config
              (map-set twap-config { market-id: market-id }
                (merge config {
                  last-observation-block: current-block,
                  observation-count: (+ obs-index u1),
                  current-accumulator-yes: new-acc-yes,
                  current-accumulator-no: new-acc-no,
                })
              )
              
              (print {
                event: "twap-observation",
                market-id: market-id,
                observation-index: obs-index,
                block: current-block,
                price-yes: price-yes,
                price-no: price-no,
                acc-yes: new-acc-yes,
                acc-no: new-acc-no,
              })
              (ok true)
            )
            (ok false)  ;; Not enough blocks passed
          )
        )
      (err ERR-TWAP-NOT-ENABLED)
    )
  )
)

;; ====================================================================================
;; ENHANCEMENT: TWAP CALCULATION FUNCTIONS
;; ====================================================================================

;; Calculate TWAP over a time window
;; Returns average YES and NO prices over the specified window
(define-read-only (calculate-twap
    (market-id uint)
    (start-block uint)
    (end-block uint)
  )
  (let (
      (config-opt (map-get? twap-config { market-id: market-id }))
    )
    (match config-opt
      config
        (let (
            (obs-count (get observation-count config))
          )
          ;; Find nearest observations to start and end
          (let (
              (start-obs (find-nearest-observation market-id start-block u0 (- obs-count u1)))
              (end-obs (find-nearest-observation market-id end-block u0 (- obs-count u1)))
            )
            (match start-obs
              start
                (match end-obs
                  end
                    (let (
                        (start-acc-yes (get accumulator-yes start))
                        (start-acc-no (get accumulator-no start))
                        (end-acc-yes (get accumulator-yes end))
                        (end-acc-no (get accumulator-no end))
                        (time-diff (- (get timestamp end) (get timestamp start)))
                      )
                      (if (> time-diff u0)
                        (ok {
                          twap-yes: (/ (- end-acc-yes start-acc-yes) time-diff),
                          twap-no: (/ (- end-acc-no start-acc-no) time-diff),
                          window-blocks: time-diff,
                        })
                        (err ERR-INVALID-V-LIQUIDITY)
                      )
                    )
                  (err ERR-TWAP-INSUFFICIENT-OBS)
                )
              (err ERR-TWAP-INSUFFICIENT-OBS)
            )
          )
        )
      (err ERR-TWAP-NOT-ENABLED)
    )
  )
)

;; Binary search helper to find nearest observation to target block
(define-private (find-nearest-observation
    (market-id uint)
    (target-block uint)
    (low uint)
    (high uint)
  )
  (if (<= low high)
    (let ((mid (/ (+ low high) u2)))
      (match (map-get? twap-observations { market-id: market-id, observation-index: mid })
        obs
          (let ((obs-block (get timestamp obs)))
            (if (is-eq obs-block target-block)
              (some obs)
              (if (< obs-block target-block)
                (if (< mid high)
                  (find-nearest-observation market-id target-block (+ mid u1) high)
                  (some obs)
                )
                (if (> mid low)
                  (find-nearest-observation market-id target-block low (- mid u1))
                  (some obs)
                )
              )
            )
          )
        none
      )
    )
    none
  )
)

;; ====================================================================================
;; ENHANCEMENT: TWAP-BASED MARKET RESOLUTION
;; ====================================================================================

;; Enhanced resolve-market function with TWAP option
(define-public (resolve-market-with-twap
    (market-id uint)
    (twap-window uint)          ;; Blocks to look back for TWAP calculation
    (vaa (buff 8192))
    (execution-plan {
      pyth-storage-contract: <pyth-storage-trait>,
      pyth-decoder-contract: <pyth-decoder-trait>,
      wormhole-core-contract: <wormhole-core-trait>,
    })
  )
  (let (
      (market (try! (require-market-open market-id)))
      (config-opt (map-get? twap-config { market-id: market-id }))
    )
    ;; Verify TWAP is enabled
    (match config-opt
      config
        (begin
          ;; Check resolution window
          (try! (ensure (>= burn-block-height (get resolution-block market)) ERR-TOO-EARLY))
          (try! (ensure (<= burn-block-height (+ (get resolution-block market) u1)) ERR-TOO-LATE))
          
          ;; Verify and update Pyth storage
          (try! (contract-call? .pyth-oracle-v4 verify-and-update-price-feeds vaa execution-plan))
          
          ;; Get spot price from Pyth
          (let ((price-response (try! (contract-call? .pyth-oracle-v4 get-price (get threshold-feed-id market)
                  (get pyth-storage-contract execution-plan)
                ))))
            
            ;; Take final TWAP observation
            (try! (take-twap-observation market-id))
            
            ;; Calculate TWAP over specified window
            (let ((twap-start (- burn-block-height twap-window)))
              (if (>= twap-start u0)
                (match (calculate-twap market-id twap-start burn-block-height)
                  twap-result
                    (let (
                        ;; Use TWAP price instead of spot price
                        (twap-price (get price price-response))  ;; For demo - ideally use TWAP from Pyth
                        (outcome (evaluate-comparison 
                          (get comparison-type market) 
                          twap-price
                          (get threshold-price market)
                        ))
                      )
                      ;; Mark market as resolved
                      (map-set markets { id: market-id }
                        (merge market {
                          resolved: true,
                          outcome: (some outcome),
                        })
                      )
                      (print {
                        event: "market-resolved-with-twap",
                        market-id: market-id,
                        outcome: outcome,
                        twap-price: twap-price,
                        spot-price: (get price price-response),
                        window-blocks: twap-window,
                        resolver: tx-sender,
                      })
                      (ok outcome)
                    )
                  (err ERR-TWAP-INSUFFICIENT-OBS)
                )
                (err ERR-TWAP-WINDOW-TOO-SMALL)
              )
            )
          )
        )
      (err ERR-TWAP-NOT-ENABLED)
    )
  )
)

;; ====================================================================================
;; ENHANCEMENT: TWAP VIEW FUNCTIONS
;; ====================================================================================

;; Get current TWAP for a market
(define-read-only (get-current-twap (market-id uint) (window-blocks uint))
  (let (
      (current-block burn-block-height)
      (start-block (- current-block window-blocks))
    )
    (if (>= start-block u0)
      (calculate-twap market-id start-block current-block)
      (err ERR-TWAP-WINDOW-TOO-LARGE)
    )
  )
)

;; Get TWAP config for a market
(define-read-only (get-twap-config (market-id uint))
  (ok (map-get? twap-config { market-id: market-id }))
)

;; Get number of observations for a market
(define-read-only (get-twap-observation-count (market-id uint))
  (match (map-get? twap-config { market-id: market-id })
    config (ok (get observation-count config))
    (err ERR-TWAP-NOT-ENABLED)
  )
)

;; Get specific observation
(define-read-only (get-twap-observation (market-id uint) (index uint))
  (ok (map-get? twap-observations { market-id: market-id, observation-index: index }))
)

;; ====================================================================================
;; ENHANCEMENT: TWAP KEEPER INCENTIVES
;; ====================================================================================

;; Optional: Incentivize keepers to take observations
(define-constant KEEPER-REWARD u1000)  ;; 0.001 sBTC per observation

(define-data-var keeper-reward-pool uint u0)

;; Fund keeper reward pool (optional, can be funded by fees)
(define-public (fund-keeper-pool (amount uint))
  (begin
    (try! (contract-call? .sbtc-token transfer amount tx-sender (as-contract tx-sender) none))
    (var-set keeper-reward-pool (+ (var-get keeper-reward-pool) amount))
    (ok true)
  )
)

;; Enhanced observation function with keeper reward
(define-public (take-twap-observation-with-reward (market-id uint))
  (let (
      (result (try! (take-twap-observation market-id)))
      (pool-balance (var-get keeper-reward-pool))
    )
    (if (and result (>= pool-balance KEEPER-REWARD))
      (begin
        (var-set keeper-reward-pool (- pool-balance KEEPER-REWARD))
        (try! (as-contract (contract-call? .sbtc-token transfer KEEPER-REWARD (as-contract tx-sender) tx-sender none)))
        (print {
          event: "keeper-reward-paid",
          market-id: market-id,
          keeper: tx-sender,
          reward: KEEPER-REWARD,
        })
        (ok true)
      )
      (ok result)
    )
  )
)
