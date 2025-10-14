;; ============================================================================
;; SCENARIO 12: SWAP MECHANICS & EDGE CASES
;; Tests swap-shares function with various scenarios
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)

;; Create market
(contract-call? .sbtcmarket-v0 create-market
  "Swap Test Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; ============================================================================
;; TEST 1: Basic Swap After Mint
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Mint complete set (100k sats worth)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u100000)

;; Check balances before swap
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)

;; Swap 50k YES for NO
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u50000)

;; Check balances after swap
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)

;; Check market state (reserves changed)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TEST 2: Repeated Small Swaps vs One Large Swap
;; ============================================================================

;; Mint more shares
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u100000)

;; Do 10 small swaps of 5k each
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 false u5000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 false u5000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 false u5000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 false u5000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 false u5000)

;; Check current state
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TEST 3: Swap More Than Balance (should fail)
;; ============================================================================

;; Check current YES balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; Try to swap more YES than owned
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u999999999)
;; Expected: (err u1005) - ERR-INSUFFICIENT-BALANCE

;; ============================================================================
;; TEST 4: Swap After Resolution (should fail)
;; ============================================================================

;; Create and immediately resolve a market
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Resolved Market"
  u1000100
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u2 u50000)

;; Resolve market
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 mock-resolve-market u2 true)

;; Try to swap after resolution
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u2 true u10000)
;; Expected: (err u1001) - ERR-RESOLVED

;; ============================================================================
;; TEST 5: Swap Zero Amount (should fail)
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u0)
;; Expected: (err u1004) - ERR-ZERO-AMOUNT

;; ============================================================================
;; TEST 6: Large Swap Impact on Pricing
;; ============================================================================

;; Create fresh market for price impact testing
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Price Impact Test"
  u1000200
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Check initial pricing (50/50)
(contract-call? .sbtcmarket-v0 get-market u3)

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Mint large position
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u3 u1000000)

;; Swap large amount (50% of virtual liquidity)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u3 true u500000)

;; Check new pricing (should be heavily skewed)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u3)

;; ============================================================================
;; TEST 7: Swap Back and Forth (Round Trip)
;; ============================================================================

;; Swap YES -> NO
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u3 true u100000)

;; Check balances
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)

;; Swap NO -> YES (reverse)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u3 false u50000)

;; Check balances (should have lost value due to slippage + fees)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)

;; ============================================================================
;; TEST 8: Arbitrage with Complete Sets
;; ============================================================================

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

;; Check initial sBTC balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Arbitrage attempt: Mint -> Swap -> Burn
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u3 u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u3 true u200000)

;; Now have unbalanced position - try to burn what we can
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG false)

;; Burn complete sets (limited by smaller balance)
;; Note: Can't burn because we swapped all YES for NO

;; Check final sBTC balance (should be less due to fees)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Expected Results:
;; 1. Basic swap -> Updates balances and reserves
;; 2. Repeated swaps -> Cumulative price impact
;; 3. Swap more than balance -> ERR-INSUFFICIENT-BALANCE
;; 4. Swap after resolution -> ERR-RESOLVED
;; 5. Swap zero amount -> ERR-ZERO-AMOUNT
;; 6. Large swap -> Significant price skew
;; 7. Round trip swap -> Net loss from slippage + fees
;; 8. Mint-Swap-Burn -> Not profitable due to fees

;; Key Observations:
;; - Swaps change reserves (unlike mint/burn)
;; - Fees charged on swaps go to treasury
;; - Large swaps have significant slippage
;; - Round trips always lose value
;; - Arbitrage is limited by fees
