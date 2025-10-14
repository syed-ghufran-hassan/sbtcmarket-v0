;; ============================================================================
;; SCENARIO 7: MASS REDEMPTION STRESS TEST
;; Tests redemption mechanics with 10 users claiming in various orders
;; Validates proportional fairness across all redeemers
;; ============================================================================

;; Setup: 10 users with sBTC
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM none)

;; Create market with moderate virtual liquidity
;; 20M sats virtual liquidity
(contract-call? .sbtcmarket-v0 create-market
  "Mass Redemption Test"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u20000000
  u30
  u"GE"
)

;; ============================================================================
;; PHASE 1: DIFFERENT SIZE POSITIONS
;; 10 users buy varying amounts of YES shares
;; ============================================================================

;; User 1: Whale (500k sats)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u500000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; User 2: Large (400k sats)
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u400000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; User 3: Large (350k sats)
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u350000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; User 4: Medium (250k sats)
::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u250000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)

;; User 5: Medium (200k sats)
::set_tx_sender ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)

;; User 6: Small (150k sats)
::set_tx_sender ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u150000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0)

;; User 7: Small (100k sats)
::set_tx_sender ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ)

;; User 8: Tiny (50k sats)
::set_tx_sender ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u50000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP)

;; User 9: Tiny (25k sats)
::set_tx_sender STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u25000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6)

;; User 10: Micro (10k sats, deployer wallet)
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u10000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; ============================================================================
;; PHASE 2: RECORD POSITIONS BEFORE RESOLUTION
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Check all user share balances
(contract-call? .sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0 true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP true)
(contract-call? .sbtcmarket-v0 get-balance u1 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6 true)
(contract-call? .sbtcmarket-v0 get-balance u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true)

;; Check market state
(contract-call? .sbtcmarket-v0 get-market u1)
;; Note: Total invested = 500+400+350+250+200+150+100+50+25+10 = 2,035,000 sats

;; ============================================================================
;; PHASE 3: RESOLVE MARKET (YES WINS)
;; ============================================================================

(contract-call? .sbtcmarket-v0 mock-resolve-market u1 true)

;; Check redemption info (shows baseline ratio)
(contract-call? .sbtcmarket-v0 get-redemption-info u1)
;; Key metric: redemption-ratio-bps (THIS SHOULD BE CONSTANT FOR ALL REDEEMERS)

;; ============================================================================
;; PHASE 4: REDEMPTION ORDER TEST - SMALLEST FIRST
;; Test: Small holders redeem first to ensure they're not disadvantaged
;; ============================================================================

;; Redemption #1: User 10 (Micro holder - 10k)
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Check redemption info after first claim
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-redemption-info u1)
;; CRITICAL: redemption-ratio-bps should be UNCHANGED

;; Redemption #2: User 9 (Tiny holder - 25k)
::set_tx_sender STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6)

;; Redemption #3: User 8 (Tiny holder - 50k)
::set_tx_sender ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP)

;; ============================================================================
;; PHASE 5: REDEMPTION ORDER TEST - MID-SIZE HOLDERS
;; ============================================================================

;; Redemption #4: User 7 (Small - 100k)
::set_tx_sender ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ)

;; Redemption #5: User 5 (Medium - 200k)
::set_tx_sender ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)

;; Check vault is decreasing proportionally
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-redemption-info u1)

;; Redemption #6: User 6 (Small - 150k)
::set_tx_sender ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0)

;; ============================================================================
;; PHASE 6: REDEMPTION ORDER TEST - LARGEST HOLDERS LAST
;; Test: Whales redeem last to ensure system remains fair even for late claims
;; ============================================================================

;; Redemption #7: User 4 (Medium - 250k)
::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)

;; Redemption #8: User 3 (Large - 350k)
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; Redemption #9: User 2 (Large - 400k)
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Redemption #10: User 1 (Whale - 500k) - FINAL REDEEMER
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; ============================================================================
;; PHASE 7: FINAL STATE VERIFICATION
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Check market state after all redemptions
(contract-call? .sbtcmarket-v0 get-market u1)
;; Expected: vault-sbtc ~ 0 (all distributed)
;; Expected: yes-circulating = 0 (all shares burned)

;; Try to check redemption info (should show vault depleted)
(contract-call? .sbtcmarket-v0 get-redemption-info u1)

;; Verify no one can redeem again
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
;; Expected: (err u1008) - ERR-NOTHING-TO-REDEEM

;; ============================================================================
;; EXPECTED RESULTS & VALIDATION
;; ============================================================================

;; CRITICAL ASSERTIONS:
;;
;; 1. CONSTANT RATIO: redemption-ratio-bps should be THE SAME for all 10 users
;;    - First redeemer (User 10, 10k investment)
;;    - Last redeemer (User 1, 500k investment)
;;    - Everyone in between
;;    - All should receive the same percentage of their shares' value
;;
;; 2. PROPORTIONAL PAYOUTS:
;;    - If User 1 has 10x the shares of User 10, they get 10x the payout
;;    - But the RATIO (payout / shares) is identical
;;
;; 3. FAIR DISTRIBUTION:
;;    - Small holders (redeemed first) are not disadvantaged
;;    - Large holders (redeemed last) are not advantaged
;;    - Position size doesn't affect redemption ratio
;;    - Redemption order doesn't matter
;;
;; 4. COMPLETE DISTRIBUTION:
;;    - Vault should be nearly empty (within rounding errors)
;;    - All YES shares should be burned
;;    - Total payouts ~ initial vault balance
;;
;; 5. NO RACE CONDITION:
;;    - Unlike traditional "first come first served" systems
;;    - Late redeemers don't get screwed
;;    - No incentive to rush to redeem
;;
;; EXAMPLE CALCULATION:
;; If redemption-ratio-bps = 9800 (98% payout due to slight over-issuance)
;;
;; User 10: 10k investment -> ~10,200 shares -> 9,996 sats payout (98% of shares)
;; User 1:  500k investment -> ~510,000 shares -> 499,800 sats payout (98% of shares)
;;
;; Loss percentage is IDENTICAL: 2% for both
;; This is FAIR!
;;
;; Compare to naive "race to redeem" system:
;; - First 9 users might get 100% payout
;; - Last user (User 1, the whale) gets screwed with 0% payout
;; - This is UNFAIR and creates perverse incentives
