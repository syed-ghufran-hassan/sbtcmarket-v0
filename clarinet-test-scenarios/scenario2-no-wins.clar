;; ============================================================================
;; SCENARIO 2: NO WINS
;; 3 users buy YES, 4 users buy NO, then NO wins resolution
;; ============================================================================

;; Setup: Transfer sBTC to wallets (7 users total)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ none)

;; Create Market
(contract-call? .sbtcmarket-v0 create-market
  "Will BTC be above 100k?"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Check market created
(contract-call? .sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TRADING PHASE: 3 users buy YES, 4 users buy NO
;; ============================================================================

;; YES BUYERS
;; -----------

;; User 1 (YES): Buy with 100,000 sats
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; User 2 (YES): Buy with 150,000 sats
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u150000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)

;; User 3 (YES): Buy with 200,000 sats
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC true)

;; NO BUYERS
;; ---------

;; User 4 (NO): Buy with 120,000 sats
::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 false u120000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND false)

;; User 5 (NO): Buy with 180,000 sats
::set_tx_sender ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 false u180000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB false)

;; User 6 (NO): Buy with 90,000 sats
::set_tx_sender ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 false u90000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0 false)

;; User 7 (NO): Buy with 250,000 sats
::set_tx_sender ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 false u250000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ false)

;; ============================================================================
;; CHECK MARKET STATE AFTER TRADING
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 get-market u1)

;; ============================================================================
;; RESOLUTION PHASE: NO WINS
;; ============================================================================

;; Mock resolve market with NO as winner (false)
(contract-call? .sbtcmarket-v0 mock-resolve-market u1 false)

;; Check market is resolved
(contract-call? .sbtcmarket-v0 get-market u1)

;; Check redemption info
(contract-call? .sbtcmarket-v0 get-redemption-info u1)

;; ============================================================================
;; REDEMPTION PHASE: NO holders redeem (YES holders get nothing)
;; ============================================================================

;; User 4 (NO) redeems
::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)

;; User 5 (NO) redeems
::set_tx_sender ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)

;; User 6 (NO) redeems
::set_tx_sender ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0)

;; User 7 (NO) redeems
::set_tx_sender ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ)

;; ============================================================================
;; VERIFY YES HOLDERS CANNOT REDEEM (should fail)
;; ============================================================================

;; User 1 (YES loser) tries to redeem - should fail
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; ============================================================================
;; FINAL STATE CHECK
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Check final market state
(contract-call? .sbtcmarket-v0 get-market u1)

;; Expected outcome:
;; - All 4 NO holders receive proportional payouts
;; - 3 YES holders get nothing (losers)
;; - Total vault distributed among NO holders proportionally
;; - YES holders attempting redemption should fail with ERR-NOTHING-TO-REDEEM
