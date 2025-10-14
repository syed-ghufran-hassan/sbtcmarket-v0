;; ============================================================================
;; SCENARIO 4: AMM PRICING & VIRTUAL LIQUIDITY
;; Tests constant-product formula, price impact, and liquidity mechanics
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)

;; ============================================================================
;; TEST 1: Initial Market State (50/50 pricing)
;; ============================================================================

;; Create market with 10M sats virtual liquidity
;; 10 million sats virtual liquidity, 0.3% fee
(contract-call? .sbtcmarket-v0 create-market
  "AMM Test Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Check initial state
(contract-call? .sbtcmarket-v0 get-market u1)
;; Expected: price-yes = u10000000, price-no = u10000000 (equal reserves = 50/50 odds)

;; ============================================================================
;; TEST 2: Small Buy - Minimal Price Impact
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Buy YES with small amount (0.1% of liquidity)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u10000)

;; Check market state after small buy
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: price-yes slightly > u10000000, price-no slightly < u10000000

;; Check shares received
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
;; Should be close to u10000 (minus small slippage and fees)

;; ============================================================================
;; TEST 3: Large Buy - Significant Price Impact
;; ============================================================================

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

;; Buy YES with large amount (10% of liquidity)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u1000000)

;; Check market state after large buy
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: price-yes >> price-no (YES more expensive now)

;; Check shares received (should show slippage)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)
;; Should be less than u1000000 due to slippage

;; ============================================================================
;; TEST 4: Opposite Side Buy (Price Rebalancing)
;; ============================================================================

::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC

;; Now buy NO to push price back
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 false u1000000)

;; Check market state (should be more balanced now)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: price-yes and price-no closer together

;; ============================================================================
;; TEST 5: Mint Complete Set (No Price Impact)
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Mint complete set (creates equal YES/NO, no AMM interaction)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u50000)

;; Check market state (reserves should be unchanged)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: price-yes and price-no unchanged (no AMM impact)

;; Check balances
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)
;; Expected: Both increased by exactly u50000

;; ============================================================================
;; TEST 6: Direct Swap (Price Impact)
;; ============================================================================

;; Now swap some NO for YES (this DOES impact price)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 false u25000)

;; Check market state (reserves should have changed)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: price-yes increased, price-no decreased

;; Check balances after swap
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)
;; Expected: YES up, NO down (with slippage)

;; ============================================================================
;; TEST 7: Burn Complete Set (No Price Impact)
;; ============================================================================

;; Burn remaining complete set
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 burn-complete-set u1 u20000)

;; Check market state (reserves should be unchanged)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: price-yes and price-no unchanged

;; ============================================================================
;; TEST 8: Verify Constant Product (x * y = k)
;; ============================================================================

;; Get final market state
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Manually verify: price-yes * price-no should approximately equal virtual-liquidity^2
;; Note: Will vary slightly due to trades, but should maintain constant product

;; ============================================================================
;; OBSERVATIONS
;; ============================================================================

;; 1. Small trades (~0.1% of liquidity): Minimal price impact
;; 2. Large trades (~10% of liquidity): Significant price impact (slippage)
;; 3. Opposite side trades: Rebalance pricing
;; 4. Complete set operations: No price impact (bypass AMM)
;; 5. Direct swaps: Direct price impact via AMM
;; 6. Constant product formula: x * y ~ k (virtual-liquidity^2)
