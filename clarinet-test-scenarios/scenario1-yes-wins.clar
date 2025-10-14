;; ============================================================================
;; SCENARIO 1: YES WINS
;; 3 users buy YES shares, then YES wins resolution
;; ============================================================================

;; Setup: Transfer sBTC to wallets
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)

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
;; TRADING PHASE: All 3 users buy YES shares
;; ============================================================================

;; User 1: Buy YES with 100,000 sats
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)

;; Check User 1 balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; User 2: Buy YES with 150,000 sats
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u150000)

;; Check User 2 balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)

;; User 3: Buy YES with 200,000 sats
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u200000)

;; Check User 3 balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC true)

;; ============================================================================
;; CHECK MARKET STATE AFTER TRADING
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 get-market u1)

;; ============================================================================
;; RESOLUTION PHASE: YES WINS
;; ============================================================================

;; Mock resolve market with YES as winner (true)
(contract-call? .sbtcmarket-v0 mock-resolve-market u1 true)

;; Check market is resolved
(contract-call? .sbtcmarket-v0 get-market u1)

;; Check redemption info
(contract-call? .sbtcmarket-v0 get-redemption-info u1)

;; ============================================================================
;; REDEMPTION PHASE: Winners redeem their shares
;; ============================================================================

;; User 1 redeems YES shares
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; Check User 1 sBTC balance after redemption
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; User 2 redeems YES shares
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; Check User 2 sBTC balance after redemption
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; User 3 redeems YES shares
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; Check User 3 sBTC balance after redemption
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; ============================================================================
;; FINAL STATE CHECK
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Check final market state
(contract-call? .sbtcmarket-v0 get-market u1)

;; Expected outcome:
;; - All 3 users should receive proportional payouts based on their YES shares
;; - Total vault should be distributed among all YES holders
;; - NO shares are worthless
