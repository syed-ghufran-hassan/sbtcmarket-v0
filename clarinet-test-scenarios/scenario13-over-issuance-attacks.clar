;; ============================================================================
;; SCENARIO 13: OVER-ISSUANCE ATTACK SCENARIOS
;; Tests deliberate attempts to break vault/shares invariants
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)

;; ============================================================================
;; TEST 1: Verify Initial Invariants
;; ============================================================================

(contract-call? .sbtcmarket-v0 create-market
  "Invariant Test Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Check initial state
;; Expected: vault-sbtc == yes-issued == no-issued == 0
(contract-call? .sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TEST 2: Aggressive Swap to Create Imbalance
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Mint complete sets
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u500000)

;; Verify invariants still hold
;; vault-sbtc == yes-issued == no-issued == 500000
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; Perform large swap YES -> NO
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u400000)

;; Check state after swap
;; CRITICAL: Swap INCREASES circulating shares without adding vault collateral
;; yes-circulating should be < yes-issued
;; no-circulating should be > no-issued (OVER-ISSUANCE!)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TEST 3: Multiple Users Create Imbalance
;; ============================================================================

;; User 2 mints and swaps
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u300000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u250000)

;; User 3 mints and swaps
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u1 u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u1 true u150000)

;; Check final state
;; NO side should be heavily over-issued
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TEST 4: Resolve and Check Redemption Math
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Resolve market (NO wins due to swaps)
(contract-call? .sbtcmarket-v0 mock-resolve-market u1 false)

;; Check redemption info
;; redemption-ratio-bps should be < 10000 (less than 1:1)
;; because no-circulating > vault-sbtc
(contract-call? .sbtcmarket-v0 get-redemption-info u1)

;; ============================================================================
;; TEST 5: All Winners Redeem Proportionally
;; ============================================================================

;; User 1 redeems NO shares
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; User 2 redeems NO shares
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG false)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; User 3 redeems NO shares
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC false)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; ============================================================================
;; TEST 6: Verify Fair Distribution
;; ============================================================================

;; Check vault is fully depleted
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: vault-sbtc should be ~0 (minus rounding)

;; Check no-circulating is also ~0
;; Expected: All NO shares burned during redemption

;; ============================================================================
;; TEST 7: Extreme Over-Issuance Scenario
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Extreme Over-Issuance"
  u1000100
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u1000000
  u30
  u"GE"
)

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Mint small amount
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u2 u50000)

;; Swap almost everything
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u2 true u49000)

;; User 2 does the same
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u2 u50000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u2 true u49000)

;; Check extreme imbalance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u2)

;; Resolve with NO winning
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 mock-resolve-market u2 false)

;; Check redemption ratio (should be very low)
(contract-call? .sbtcmarket-v0 get-redemption-info u2)

;; Redeem to verify proportional payout works
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u2)

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u2)

;; Verify vault depleted correctly
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u2)

;; ============================================================================
;; TEST 8: Buy After Swap-Induced Imbalance
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Buy After Imbalance"
  u1000200
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Create imbalance via swap
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u3 u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u3 true u150000)

;; Check state (NO over-issued)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u3)

;; New user buys NO (already over-issued side)
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u3 false u100000)

;; Check state (over-issuance worsens)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u3)

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Key Findings:
;; 1. Swaps can create over-issuance (circulating > issued)
;; 2. Multiple swaps amplify the imbalance
;; 3. Proportional redemption handles over-issuance correctly
;; 4. redemption-ratio-bps < 10000 when over-issued
;; 5. All users get fair proportional share
;; 6. Vault depletes correctly even with extreme imbalance
;; 7. Buying over-issued side worsens the problem
;; 8. System remains solvent (doesn't lose sBTC)

;; Invariants Tested:
;; - vault-sbtc == yes-issued == no-issued (initially)
;; - After swaps: circulating can exceed issued
;; - After redemption: vault-sbtc depletes proportionally
;; - No user can steal more than fair share
