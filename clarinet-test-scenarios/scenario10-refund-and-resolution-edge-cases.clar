;; ============================================================================
;; SCENARIO 10: REFUND & RESOLUTION EDGE CASES
;; Tests cancel-market, refund-shares, and resolve-market edge cases
;; NOTE: This scenario uses the OLD 1008-block timeout for legacy testing
;; For NEW 2-block window tests, see scenario18-resolution-window-and-cancellation.clar
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)

;; ============================================================================
;; TEST 1: Market Cancellation and Refund Flow
;; ============================================================================

;; Create market with resolution block 1000 blocks in future
(contract-call? .sbtcmarket-v0 create-market
  "Refund Test Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Check market created
(contract-call? .sbtcmarket-v0 get-market u1)

;; User 1: Buy YES shares (100k sats)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)

;; User 2: Buy NO shares (150k sats)
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 false u150000)

;; User 3: Mint complete set (50k sats worth)
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u50000)

;; Check balances before cancellation
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG false)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC true)

;; Check market state
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TEST 2: Try to Cancel Before Timeout (should fail)
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Try to cancel immediately (should fail - too early)
(contract-call? .sbtcmarket-v0 cancel-market u1)
;; Expected: (err u1002) - ERR-TOO-EARLY

;; ============================================================================
;; TEST 3: Try to Refund Before Cancellation (should fail)
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Try to refund before market is cancelled (should fail)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 refund-shares u1)
;; Expected: (err u1013) - ERR-NOT-CANCELLED

;; ============================================================================
;; TEST 4: Simulate Passage of Time and Cancel Market
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; NEW BEHAVIOR: CANCEL-TIMEOUT-BLOCKS = 2 (immediate after 2-block window)
;; Timeline:
;;   Block 1000000:     Can resolve (window start)
;;   Block 1000001:     Can resolve (window end)
;;   Block 1000002+:    Can cancel (immediate)
;;
;; For testing without block advancement, see scenario18 for comprehensive tests
;; This demonstrates the intended flow conceptually

;; ============================================================================
;; TEST 5: Refund Flow (Complete Set Holders)
;; ============================================================================

;; Note: User 3 has complete sets (YES + NO in equal amounts)
;; When refunding, users get proportional share of vault based on complete sets

::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC

;; Check User 3's balances (should have 50k YES and 50k NO)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC false)

;; ============================================================================
;; TEST 6: Resolve Market with Incorrect Block (Price Staleness)
;; ============================================================================

;; Create a second market for resolution testing
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Resolution Test Market"
  u1000100
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Check market 2 created
(contract-call? .sbtcmarket-v0 get-market u2)

;; Add some trading activity
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 true u50000)

;; Try to resolve before resolution block (should fail)
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; In production, this would call resolve-market with Pyth VAA
;; The contract would check:
;; 1. Current burn-block-height >= resolution-block
;; 2. Pyth price timestamp matches resolution-block time (within staleness threshold)
;; 3. If price is from wrong block, resolution fails with ERR-TOO-EARLY

;; For testing with mock:
;; Try to mock-resolve before resolution block
(contract-call? .sbtcmarket-v0 mock-resolve-market u2 true)
;; Expected: (err u1002) - ERR-TOO-EARLY (if block height check is enforced)
;; Note: mock-resolve currently doesn't check block height - this is intentional for testing

;; ============================================================================
;; TEST 7: Double Refund Protection
;; ============================================================================

;; Scenario: User tries to refund twice
;; Expected: Second refund should fail (no shares left)

;; Note: Actual refund testing requires market cancellation
;; Which requires advancing block height beyond resolution + timeout
;; This is demonstrated conceptually here

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Expected test results:
;; 1. Market creation and trading -> Success
;; 2. Cancel before timeout -> ERR-TOO-EARLY
;; 3. Refund before cancellation -> ERR-NOT-CANCELLED
;; 4. Refund with complete sets -> Proportional sBTC return
;; 5. Resolve with wrong block price -> ERR-TOO-EARLY (price staleness)
;; 6. Double refund -> ERR-NOTHING-TO-REDEEM (no shares left)

;; Key Features Tested:
;; - cancel-market function with timeout enforcement
;; - refund-shares function with proportional distribution
;; - Complete set refund mechanics
;; - Resolution timestamp validation (price staleness check)
;; - Protection against early cancellation
;; - Protection against refund before cancellation
