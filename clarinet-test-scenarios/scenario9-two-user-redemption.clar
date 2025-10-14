;; ============================================================================
;; SCENARIO 9: TWO USER REDEMPTION BUGFIX
;; Recreates the reported YES-win market with 2 traders to ensure
;; sequential redemptions stay proportional after the bugfix.
;;
;; Expected shares & payouts:
;;   User 1: spends 17,047 sats -> 31,574 YES shares -> payout 21,139 sats
;;   User 2: spends 85,237 sats -> 121,200 YES shares -> payout 81,144 sats
;; Redemption ratio should remain ~6,695 bps for both users.
;; ============================================================================

;; Fund the two user wallets with ample sBTC
(contract-call? .sbtc-token transfer u100000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u100000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)

;; Create the market matching the reported parameters
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 create-market
  "test"
  u96966
  0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43
  120000
  u100000
  u30
  u"GE"
)

;; Confirm initial market state
(contract-call? .sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TRADING PHASE - replicate the original deposits and share allocations
;; ============================================================================

;; User 1 buys YES with 17,047 sats -> should receive 31,574 YES shares
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u16980)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; User 2 buys YES later with 85,237 sats -> should receive ~121,200 YES shares
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u16983)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)

;; Market state should show ~152,774 YES circulating and 102,284 sats in vault
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 get-market u1)

;; ============================================================================
;; RESOLUTION - YES outcome wins
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 mock-resolve-market u1 true)
(contract-call? .sbtcmarket-v0 get-redemption-info u1)

;; ============================================================================
;; REDEMPTION - ensure sequential calls stay proportional
;; ============================================================================

;; User 1 redeems first, expecting 21,139 sats payout and 31,574 shares burned
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; Redemption info should maintain the same ratio after User 1 redeems
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 get-redemption-info u1)

;; User 2 redeems second, expecting the remaining ~81,144 sats payout
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Final market state - vault should be near zero and no YES shares circulating
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 get-market u1)

;; End of scenario
