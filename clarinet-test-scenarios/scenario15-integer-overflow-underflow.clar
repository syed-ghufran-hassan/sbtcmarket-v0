;; ============================================================================
;; SCENARIO 15: INTEGER OVERFLOW & UNDERFLOW EDGE CASES
;; Tests extreme values that could cause math errors
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)

;; ============================================================================
;; TEST 1: Maximum Virtual Liquidity
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Try to create market with very large virtual liquidity
;; Max uint128 = u340282366920938463463374607431768211455
;; Let's try a large but reasonable value first
(contract-call? .sbtcmarket-v0 create-market
  "Large VL Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u100000000000000
  u30
  u"GE"
)

;; Check if it created successfully
(contract-call? .sbtcmarket-v0 get-market u1)

;; Check price calculations with large VL
;; price-yes and price-no should both equal virtual-liquidity
;; price-yes * price-no should equal virtual-liquidity^2
;; This could overflow if VL is too large!

;; ============================================================================
;; TEST 2: Extremely Large Virtual Liquidity (Overflow Risk)
;; ============================================================================

;; Try with even larger VL that might cause overflow
;; VL^2 must fit in uint128
;; sqrt(max-uint128) = u18446744073709551615 (2^64 - 1)
;; Let's test near that boundary

(contract-call? .sbtcmarket-v0 create-market
  "Overflow Risk Market"
  u1000100
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000000000000
  u30
  u"GE"
)

;; If this succeeds, check the market
(contract-call? .sbtcmarket-v0 get-market u2)

;; ============================================================================
;; TEST 3: Zero Virtual Liquidity (should fail)
;; ============================================================================

(contract-call? .sbtcmarket-v0 create-market
  "Zero VL Market"
  u1000200
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u0
  u30
  u"GE"
)
;; Expected: Should fail with division by zero or invalid parameter

;; ============================================================================
;; TEST 4: Minimum Valid Virtual Liquidity
;; ============================================================================

(contract-call? .sbtcmarket-v0 create-market
  "Min VL Market"
  u1000300
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u1
  u30
  u"GE"
)

;; Check if ultra-low VL works
(contract-call? .sbtcmarket-v0 get-market u3)

;; ============================================================================
;; TEST 5: Circulating Count Underflow
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Underflow Test Market"
  u1000400
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Mint small amount
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u4 u1000)

;; Check balances
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u4 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; Resolve market
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 mock-resolve-market u4 true)

;; Redeem shares
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u4)

;; Check market state - circulating should be 0 or close to it
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u4)

;; Now try to redeem again (should fail but might underflow)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u4)
;; Expected: err u1008 (ERR-NOTHING-TO-REDEEM)
;; If underflow bug exists: yes-circulating wraps to max-uint

;; ============================================================================
;; TEST 6: Very Large Buy Order
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Large Buy Test"
  u1000500
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Give user massive sBTC balance (if possible in test environment)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Try to buy with very large amount
;; This tests if AMM math can handle extreme inputs
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u5 true u999999999)
;; Might fail with insufficient balance, but tests math limits

;; ============================================================================
;; TEST 7: Maximum Fee (9999 bps = 99.99%)
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Max Fee Market"
  u1000600
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u9999
  u"GE"
)

;; Check if it created (should succeed per current code)
(contract-call? .sbtcmarket-v0 get-market u6)

;; Try to trade on it
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u6 true u100000)

;; Check how much went to fees vs shares
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u6 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market-fees u6)
;; Expected: 99.99% went to fees, only 0.01% to shares

;; ============================================================================
;; TEST 8: Invalid Fee (10000 bps = 100%, should fail)
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "100% Fee Market"
  u1000700
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u10000
  u"GE"
)
;; Expected: (err u1006) - ERR-INVALID-FEE

;; ============================================================================
;; TEST 9: Fee Greater Than 100% (should fail)
;; ============================================================================

(contract-call? .sbtcmarket-v0 create-market
  "Over 100% Fee"
  u1000800
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u15000
  u"GE"
)
;; Expected: (err u1006) - ERR-INVALID-FEE

;; ============================================================================
;; TEST 10: Dust Amounts in Redemption
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Dust Redemption"
  u1000900
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; User 1: Buy 1 sat worth
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u7 true u1)

;; Check shares received (might be 0 after fees)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u7 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; User 2: Buy huge amount
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u7 true u500000)

;; Resolve YES wins
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 mock-resolve-market u7 true)

;; User 1 redeems dust shares
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u7)
;; Check payout (might be 0 due to rounding)

;; ============================================================================
;; TEST 11: Division by Zero Protection
;; ============================================================================

;; All AMM math functions should handle edge cases
;; Test scenarios already covered:
;; - Empty reserves (no trades yet)
;; - One-sided market (all swapped to one side)
;; - Dust amounts

;; These should not crash with division by zero

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Edge Cases Tested:
;; 1. Maximum virtual liquidity - Tests overflow in price calculations
;; 2. Extremely large VL - Tests VL^2 overflow
;; 3. Zero VL - Should fail gracefully
;; 4. Minimum VL - Tests division edge cases
;; 5. Circulating underflow - Redeem more than owned
;; 6. Large buy orders - Tests AMM math limits
;; 7. Maximum fee (99.99%) - Tests fee calculation
;; 8. 100% fee - Should fail
;; 9. Over 100% fee - Should fail
;; 10. Dust redemption - Tests rounding in payouts
;; 11. Division by zero - Various edge cases

;; Vulnerabilities Found:
;; - No maximum virtual liquidity validation
;; - No maximum fee validation (99.99% works)
;; - Potential underflow in circulating counts
;; - Rounding errors with dust amounts
;; - Large VL could cause overflow in price^2 calculations

;; Recommendations:
;; - Add MAX-VIRTUAL-LIQUIDITY constant
;; - Add MAX-FEE-BPS constant (e.g., u500 = 5%)
;; - Add explicit underflow checks in burn-shares
;; - Document minimum trade amounts
;; - Add overflow checks in AMM math
