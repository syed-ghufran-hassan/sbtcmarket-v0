;; ============================================================================
;; SCENARIO 11: ACCESS CONTROL & AUTHORIZATION SECURITY
;; Tests unauthorized access to privileged functions
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)

;; Create test market
(contract-call? .sbtcmarket-v0 create-market
  "Access Control Test"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; ============================================================================
;; TEST 1: Unauthorized set-contract-owner (should fail)
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Non-owner tries to change contract owner
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 set-contract-owner 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 2: Unauthorized set-protocol-treasury (should fail)
;; ============================================================================

;; Non-owner tries to change treasury address
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 set-protocol-treasury 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 3: Unauthorized set-tax-recipient (should fail)
;; ============================================================================

;; Non-owner tries to change tax recipient
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 set-tax-recipient 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 4: Unauthorized add-market-creator (should fail)
;; ============================================================================

;; Non-owner tries to add market creator
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 add-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 5: Unauthorized remove-market-creator (should fail)
;; ============================================================================

;; Non-owner tries to remove market creator
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 remove-market-creator 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 6: CRITICAL - Unauthorized mock-resolve-market (VULNERABILITY!)
;; ============================================================================

;; Add some trading first
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 false u100000)

;; ATTACK: Non-owner tries to resolve market
;; This is CRITICAL VULNERABILITY - anyone can resolve with arbitrary outcome
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mock-resolve-market u1 true)
;; Expected: (err u401) - ERR-UNAUTHORIZED
;; ACTUAL: (ok true) - SECURITY BUG! Anyone can resolve!

;; Check if market was resolved by attacker
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; ============================================================================
;; TEST 7: Authorized Operations Work Correctly
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Owner CAN change contract owner
(contract-call? .sbtcmarket-v0 set-contract-owner 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; Expected: (ok true)

;; Owner CAN change treasury
(contract-call? .sbtcmarket-v0 set-protocol-treasury 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
;; Expected: (ok 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Owner CAN change tax recipient
(contract-call? .sbtcmarket-v0 set-tax-recipient 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
;; Expected: (ok 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; Owner CAN add market creator
(contract-call? .sbtcmarket-v0 add-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; Verify market creator was added
(contract-call? .sbtcmarket-v0 is-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; Owner CAN remove market creator
(contract-call? .sbtcmarket-v0 remove-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; ============================================================================
;; TEST 8: Treasury Redirection Attack Scenario
;; ============================================================================

;; Create new market for fee testing
(contract-call? .sbtcmarket-v0 create-market
  "Fee Attack Market"
  u1000100
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u100
  u"GE"
)

;; User trades and generates fees
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 true u500000)

;; Check fees accumulated
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market-fees u2)

;; ATTACK: Owner redirects treasury to steal future fees
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 set-protocol-treasury 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Future trades now send fees to attacker
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 false u500000)

;; Check attacker's fee balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Expected Results:
;; 1. Non-owner set-contract-owner -> ERR-UNAUTHORIZED
;; 2. Non-owner set-protocol-treasury -> ERR-UNAUTHORIZED
;; 3. Non-owner set-tax-recipient -> ERR-UNAUTHORIZED
;; 4. Non-owner add-market-creator -> ERR-UNAUTHORIZED
;; 5. Non-owner remove-market-creator -> ERR-UNAUTHORIZED
;; 6. Non-owner mock-resolve-market -> SECURITY BUG (currently succeeds)
;; 7. Owner operations -> All succeed
;; 8. Treasury redirection -> Demonstrates centralization risk

;; CRITICAL FINDING:
;; mock-resolve-market has NO access control - anyone can resolve any market!
;; This allows complete theft of all funds in any market.
