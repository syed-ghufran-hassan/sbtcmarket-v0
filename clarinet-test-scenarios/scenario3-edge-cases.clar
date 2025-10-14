;; ============================================================================
;; SCENARIO 3: EDGE CASES & ERROR CONDITIONS
;; Tests boundary conditions, error handling, and potential mistakes
;; ============================================================================

;; Setup: Transfer sBTC to wallets
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)

;; ============================================================================
;; TEST 1: Zero Amount Transactions (should fail)
;; ============================================================================

;; Create market first
(contract-call? .sbtcmarket-v0 create-market
  "Test Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Try to buy with 0 amount (should fail with ERR-ZERO-AMOUNT)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u0)
;; Expected: (err u1004) - ERR-ZERO-AMOUNT

;; Try to mint complete set with 0 (should fail)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u0)
;; Expected: (err u1004) - ERR-ZERO-AMOUNT

;; ============================================================================
;; TEST 2: Insufficient Balance (should fail)
;; ============================================================================

;; Try to buy more than wallet balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u2000000000)
;; Expected: (err u1) - ft-transfer error (insufficient balance)

;; ============================================================================
;; TEST 3: Non-existent Market (should fail)
;; ============================================================================

;; Try to buy from market that doesn't exist
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u999 true u10000)
;; Expected: (err u1000) - ERR-NO-MARKET

;; Try to get balance from non-existent market
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u999 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
;; Expected: u0 (default value)

;; ============================================================================
;; TEST 4: Very Small Amounts (boundary test)
;; ============================================================================

;; Buy with 1 sat (minimum possible)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u1)
;; Should succeed but might get 0 shares after fees

;; Check balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; Buy with 10 sats
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u10)

;; ============================================================================
;; TEST 5: Burn Without Matching Shares (should fail)
;; ============================================================================

;; User has only YES shares, try to burn complete set (needs YES + NO)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 burn-complete-set u1 u10)
;; Expected: (err u1005) - ERR-INSUFFICIENT-BALANCE (missing NO shares)

;; ============================================================================
;; TEST 6: Swap More Than Balance (should fail)
;; ============================================================================

;; Check current YES balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; Try to swap more YES shares than owned
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u1000000)
;; Expected: (err u1005) - ERR-INSUFFICIENT-BALANCE

;; ============================================================================
;; TEST 7: Redeem Before Resolution (should fail)
;; ============================================================================

;; Try to redeem before market is resolved
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
;; Expected: (err u1003) - ERR-NOT-RESOLVED

;; ============================================================================
;; TEST 8: Trading After Resolution (should fail)
;; ============================================================================

;; Resolve the market
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 mock-resolve-market u1 true)

;; Try to buy after resolution (should fail)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u10000)
;; Expected: (err u1001) - ERR-RESOLVED

;; Try to swap after resolution (should fail)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u10)
;; Expected: (err u1001) - ERR-RESOLVED

;; ============================================================================
;; TEST 9: Redeem With No Winning Shares (should fail)
;; ============================================================================

;; Switch to user who doesn't have shares
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

;; Try to redeem (should fail - no shares)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
;; Expected: (err u1008) - ERR-NOTHING-TO-REDEEM

;; ============================================================================
;; TEST 10: Double Redemption (should fail on second attempt)
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; First redemption (should succeed)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; Try to redeem again (should fail - already redeemed)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
;; Expected: (err u1008) - ERR-NOTHING-TO-REDEEM

;; ============================================================================
;; TEST 11: Invalid Market Parameters (should fail on creation)
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Try to create market with invalid comparison type
;; Invalid comparison type XX
(contract-call? .sbtcmarket-v0 create-market
  "Invalid Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"XX"
)
;; Expected: (err u1009) - ERR-INVALID-COMPARISON

;; Try to create market with excessive fee (>100%)
;; 150% fee (u15000 = 150%)
(contract-call? .sbtcmarket-v0 create-market
  "High Fee Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u15000
  u"GE"
)
;; Expected: (err u1010) - ERR-INVALID-FEE

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Expected test results:
;; 1. Zero amounts -> ERR-ZERO-AMOUNT
;; 2. Insufficient balance -> Transfer error
;; 3. Non-existent market -> ERR-NO-MARKET
;; 4. Very small amounts -> Should work but may result in 0 shares after fees
;; 5. Burn without matching shares -> ERR-INSUFFICIENT-BALANCE
;; 6. Swap more than balance -> ERR-INSUFFICIENT-BALANCE
;; 7. Redeem before resolution -> ERR-NOT-RESOLVED
;; 8. Trading after resolution -> ERR-RESOLVED
;; 9. Redeem with no shares -> ERR-NOTHING-TO-REDEEM
;; 10. Double redemption -> ERR-NOTHING-TO-REDEEM
;; 11. Invalid parameters -> ERR-INVALID-COMPARISON or ERR-INVALID-FEE
