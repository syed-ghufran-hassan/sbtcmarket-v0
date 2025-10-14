;; ============================================================================
;; SCENARIO 5: PROPORTIONAL REDEMPTION TEST
;; Tests over-issuance handling and fair distribution
;; ============================================================================

;; Setup: 5 users
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB none)

;; Create market with small virtual liquidity to demonstrate over-issuance
;; 10M sats virtual liquidity
(contract-call? .sbtcmarket-v0 create-market
  "Small Liquidity Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; ============================================================================
;; PHASE 1: Create Over-Issuance via Trading
;; ============================================================================

;; User 1: Buy 500k sats worth of YES
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u500000)

;; Check shares received (will be MORE than 500k due to AMM mechanics)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; User 2: Buy 400k sats worth of YES
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u400000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)

;; User 3: Buy 300k sats worth of YES
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u300000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC true)

;; User 4: Buy 200k sats worth of YES
::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND true)

;; User 5: Buy 100k sats worth of YES
::set_tx_sender ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB true)

;; ============================================================================
;; PHASE 2: Check Over-Issuance State
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Check market state
(contract-call? .sbtcmarket-v0 get-market u1)
;; Key metrics:
;; - vault-sbtc: Total sBTC deposited (500k + 400k + 300k + 200k + 100k = 1.5M)
;; - yes-circulating: Total YES shares (likely > 1.5M due to virtual liquidity AMM)
;; - no-circulating: Total NO shares (likely < vault due to selling)

;; ============================================================================
;; PHASE 3: Resolve Market (YES Wins)
;; ============================================================================

(contract-call? .sbtcmarket-v0 mock-resolve-market u1 true)

;; Check redemption info
(contract-call? .sbtcmarket-v0 get-redemption-info u1)
;; Shows:
;; - winner: true (YES)
;; - vault-balance: ~1.5M sats
;; - total-circulating: Total YES shares (may be > vault)
;; - redemption-ratio-bps: Payout ratio per share (<10000 if over-issued)

;; ============================================================================
;; PHASE 4: Early Redeemers
;; ============================================================================

;; User 5 redeems first (smallest holder)
::set_tx_sender ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB

;; Check balance before redemption
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)

;; Redeem
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; Check balance after redemption
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)
;; Calculate: gain = (after - before) - 100000 (original investment)

;; Check redemption info again
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-redemption-info u1)
;; redemption-ratio-bps should be UNCHANGED (key test!)

;; ============================================================================
;; PHASE 5: Middle Redeemers
;; ============================================================================

;; User 3 redeems
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; User 2 redeems
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; ============================================================================
;; PHASE 6: Late Redeemers
;; ============================================================================

;; User 4 redeems late
::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)

;; User 1 redeems last (largest holder)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; ============================================================================
;; PHASE 7: Verify Fairness
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Check final market state
(contract-call? .sbtcmarket-v0 get-market u1)
;; vault-sbtc should be near 0 (all distributed)

;; ============================================================================
;; EXPECTED RESULTS & FAIRNESS VERIFICATION
;; ============================================================================

;; KEY ASSERTION: All redeemers should get the SAME ratio
;; Formula: payout_ratio = redemption_amount / (shares_held * original_investment_per_share)
;;
;; Example calculation:
;; If User 5 has 105,000 shares from 100k investment:
;;   - Original: 100k sats
;;   - Shares: 105k
;;   - If redemption-ratio-bps = 9500 (95%)
;;   - Payout = 105k * 0.95 = 99,750 sats
;;   - Loss = 250 sats (0.25%)
;;
;; If User 1 has 525,000 shares from 500k investment:
;;   - Original: 500k sats
;;   - Shares: 525k
;;   - If redemption-ratio-bps = 9500 (95%)
;;   - Payout = 525k * 0.95 = 498,750 sats
;;   - Loss = 1,250 sats (also 0.25%)
;;
;; Both users lose the same percentage - FAIR!
;; Without proportional redemption, late redeemers could lose everything.
