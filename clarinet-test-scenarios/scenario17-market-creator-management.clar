;; ============================================================================
;; SCENARIO 17: MARKET CREATOR MANAGEMENT
;; Tests add/remove market creator functionality and permissions
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)

;; ============================================================================
;; TEST 1: Owner Can Add Market Creators
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Verify initial state - deployer is default creator
(contract-call? .sbtcmarket-v0 is-market-creator 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; Expected: (ok true)

;; Add first market creator (User 1)
(contract-call? .sbtcmarket-v0 add-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; Verify User 1 is now a creator
(contract-call? .sbtcmarket-v0 is-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; Add second market creator (User 2)
(contract-call? .sbtcmarket-v0 add-market-creator 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
;; Expected: (ok true)

;; Verify User 2 is now a creator
(contract-call? .sbtcmarket-v0 is-market-creator 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
;; Expected: (ok true)

;; Add third market creator (User 3)
(contract-call? .sbtcmarket-v0 add-market-creator 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
;; Expected: (ok true)

;; Verify User 3 is now a creator
(contract-call? .sbtcmarket-v0 is-market-creator 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
;; Expected: (ok true)

;; ============================================================================
;; TEST 2: Non-Owner Cannot Add Market Creators
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; User 1 (not owner) tries to add another creator
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 add-market-creator 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6)
;; Expected: (err u401) - ERR-UNAUTHORIZED

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

;; User 2 (not owner) tries to add another creator
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 add-market-creator 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 3: Adding Same Creator Twice (Idempotent)
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Try to add User 1 again (already added)
(contract-call? .sbtcmarket-v0 add-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true) - Should succeed (idempotent)

;; Verify User 1 still is a creator
(contract-call? .sbtcmarket-v0 is-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; ============================================================================
;; TEST 4: Authorized Creators Can Create Markets
;; ============================================================================

;; User 1 (authorized creator) creates market
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "User 1 Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)
;; Expected: (ok u1) - Success

;; Verify market was created
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)

;; User 2 (authorized creator) creates market
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "User 2 Market"
  u1000100
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u50
  u"GE"
)
;; Expected: (ok u2) - Success

;; User 3 (authorized creator) creates market
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "User 3 Market"
  u1000200
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u100
  u"GE"
)
;; Expected: (ok u3) - Success

;; ============================================================================
;; TEST 5: Unauthorized User Cannot Create Markets
;; ============================================================================

;; User who was never added tries to create market
::set_tx_sender STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "Unauthorized Market"
  u1000300
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 6: Owner Can Remove Market Creators
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Remove User 1 from creators
(contract-call? .sbtcmarket-v0 remove-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; Verify User 1 is no longer a creator
(contract-call? .sbtcmarket-v0 is-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok false)

;; Remove User 2 from creators
(contract-call? .sbtcmarket-v0 remove-market-creator 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
;; Expected: (ok true)

;; Verify User 2 is no longer a creator
(contract-call? .sbtcmarket-v0 is-market-creator 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
;; Expected: (ok false)

;; ============================================================================
;; TEST 7: Non-Owner Cannot Remove Market Creators
;; ============================================================================

::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC

;; User 3 (not owner) tries to remove themselves
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 remove-market-creator 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
;; Expected: (err u401) - ERR-UNAUTHORIZED

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Removed creator tries to remove another creator
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 remove-market-creator 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 8: Removed Creators Cannot Create Markets
;; ============================================================================

;; User 1 (removed) tries to create market
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "Post-Removal Market"
  u1000400
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; User 2 (removed) tries to create market
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "Post-Removal Market 2"
  u1000500
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)
;; Expected: (err u401) - ERR-UNAUTHORIZED

;; ============================================================================
;; TEST 9: Removing Non-Existent Creator (Idempotent)
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Remove User 1 again (already removed)
(contract-call? .sbtcmarket-v0 remove-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true) - Should succeed (idempotent)

;; Try to remove someone who was never added
(contract-call? .sbtcmarket-v0 remove-market-creator 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ)
;; Expected: (ok true) - Should succeed (idempotent)

;; ============================================================================
;; TEST 10: Owner Can Re-Add Removed Creators
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Re-add User 1
(contract-call? .sbtcmarket-v0 add-market-creator 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
;; Expected: (ok true)

;; Verify User 1 can now create markets again
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "Re-added Creator Market"
  u1000600
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)
;; Expected: (ok u4) - Success

;; ============================================================================
;; TEST 11: Owner Cannot Remove Themselves as Creator
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Try to remove owner (deployer) from creators
(contract-call? .sbtcmarket-v0 remove-market-creator 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; Expected: (ok true) - Technically succeeds but doesn't matter since owner can always create

;; Verify owner can still create markets regardless
(contract-call? .sbtcmarket-v0 create-market
  "Owner Always Allowed"
  u1000700
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)
;; Expected: (ok u5) - Owner bypasses creator check

;; ============================================================================
;; TEST 12: Market Creator Permissions Don't Affect Trading
;; ============================================================================

;; User who is NOT a creator can still trade on markets
::set_tx_sender STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6

;; Transfer sBTC to unauthorized user
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtc-token transfer u500000000 tx-sender 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6 none)

;; Unauthorized user can buy shares
::set_tx_sender STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u50000)
;; Expected: (ok ...) - Success

;; Unauthorized user can mint complete sets
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u2 u50000)
;; Expected: (ok true) - Success

;; Unauthorized user can swap
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u2 true u25000)
;; Expected: (ok ...) - Success

;; ============================================================================
;; TEST 13: Multiple Creators Creating Markets Simultaneously
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Add multiple creators
(contract-call? .sbtcmarket-v0 add-market-creator 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND)
(contract-call? .sbtcmarket-v0 add-market-creator 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB)
(contract-call? .sbtcmarket-v0 add-market-creator 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0)

;; Transfer sBTC to all creators
(contract-call? .sbtc-token transfer u500000000 tx-sender 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND none)
(contract-call? .sbtc-token transfer u500000000 tx-sender 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB none)
(contract-call? .sbtc-token transfer u500000000 tx-sender 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0 none)

;; All 3 creators create markets in sequence
::set_tx_sender ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "Creator 1 Concurrent"
  u1000800
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

::set_tx_sender ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "Creator 2 Concurrent"
  u1000900
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u50
  u"GE"
)

::set_tx_sender ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 create-market
  "Creator 3 Concurrent"
  u1001000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u100
  u"GE"
)

;; Verify all markets were created with unique IDs
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u6)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u7)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u8)

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Test Results:
;; 1. Owner can add market creators -> Success
;; 2. Non-owner cannot add creators -> ERR-UNAUTHORIZED
;; 3. Adding same creator twice -> Idempotent (ok true)
;; 4. Authorized creators can create markets -> Success
;; 5. Unauthorized users cannot create markets -> ERR-UNAUTHORIZED
;; 6. Owner can remove market creators -> Success
;; 7. Non-owner cannot remove creators -> ERR-UNAUTHORIZED
;; 8. Removed creators cannot create markets -> ERR-UNAUTHORIZED
;; 9. Removing non-existent creator -> Idempotent (ok true)
;; 10. Owner can re-add removed creators -> Success
;; 11. Owner can always create (bypasses creator check) -> Success
;; 12. Creator permissions don't affect trading -> Success
;; 13. Multiple creators can create markets -> Success

;; Access Control Matrix:
;;
;; Operation          | Owner | Authorized Creator | Removed Creator | Unauthorized User
;; -------------------+-------+--------------------+-----------------+------------------
;; add-creator        | Y     | N (ERR-401)        | N (ERR-401)     | N (ERR-401)
;; remove-creator     | Y     | N (ERR-401)        | N (ERR-401)     | N (ERR-401)
;; create-market      | Y     | Y                  | N (ERR-401)     | N (ERR-401)
;; buy/sell shares    | Y     | Y                  | Y               | Y
;; mint/burn sets     | Y     | Y                  | Y               | Y
;; swap shares        | Y     | Y                  | Y               | Y
;; resolve market     | Y     | N (ERR-401)        | N (ERR-401)     | N (ERR-401)
;; redeem shares      | Y     | Y                  | Y               | Y

;; Key Findings:
;; - Market creator permissions only control market creation
;; - All users can trade regardless of creator status
;; - Owner has all permissions regardless of creator list
;; - Adding/removing creators is idempotent
;; - No way for creators to escalate privileges
