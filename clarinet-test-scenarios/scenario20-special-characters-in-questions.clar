;; ============================================================================
;; SCENARIO 20: SPECIAL CHARACTERS IN MARKET QUESTIONS
;; Test creating markets with special characters like >=, <=, <, >, etc.
;; ============================================================================

;; ============================================================================
;; MARKET CREATION WITH SPECIAL CHARACTERS
;; ============================================================================

;; Test 1: Market with >= symbol
(contract-call? .sbtcmarket-v0 create-market
  "Will BTC >= $100,000 by Dec 31?"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Verify market 1 created successfully
(contract-call? .sbtcmarket-v0 get-market u1)

;; Test 2: Market with <= symbol
(contract-call? .sbtcmarket-v0 create-market
  "Will ETH <= $3,000 by EOY?"
  u1000001
  0x0000000000000000000000000000000000000000000000000000000000000001
  300000000000
  u5000000
  u30
  u"LE"
)

;; Verify market 2 created successfully
(contract-call? .sbtcmarket-v0 get-market u2)

;; Test 3: Market with > symbol
(contract-call? .sbtcmarket-v0 create-market
  "Will SOL > $200 by Q1 2025?"
  u1000002
  0x0000000000000000000000000000000000000000000000000000000000000002
  20000000000
  u8000000
  u30
  u"GT"
)

;; Verify market 3 created successfully
(contract-call? .sbtcmarket-v0 get-market u3)

;; Test 4: Market with < symbol
(contract-call? .sbtcmarket-v0 create-market
  "Will inflation rate < 2% by end of year?"
  u1000003
  0x0000000000000000000000000000000000000000000000000000000000000003
  200000000
  u6000000
  u30
  u"LT"
)

;; Verify market 4 created successfully
(contract-call? .sbtcmarket-v0 get-market u4)

;; Test 5: Market with = symbol (using EQ comparison)
(contract-call? .sbtcmarket-v0 create-market
  "Will S&P 500 = exactly 5000 on New Year?"
  u1000004
  0x0000000000000000000000000000000000000000000000000000000000000004
  500000000000
  u7000000
  u30
  u"EQ"
)

;; Verify market 5 created successfully
(contract-call? .sbtcmarket-v0 get-market u5)

;; Test 6: Market with multiple special characters
(contract-call? .sbtcmarket-v0 create-market
  "BTC/USD >= $110k && ETH >= $4k?"
  u1000005
  0x0000000000000000000000000000000000000000000000000000000000000005
  11000000000000
  u12000000
  u30
  u"GE"
)

;; Verify market 6 created successfully
(contract-call? .sbtcmarket-v0 get-market u6)

;; Test 7: Market with parentheses and operators
(contract-call? .sbtcmarket-v0 create-market
  "Will (BTC price / ETH price) >= 30?"
  u1000006
  0x0000000000000000000000000000000000000000000000000000000000000006
  3000000000
  u9000000
  u30
  u"GE"
)

;; Verify market 7 created successfully
(contract-call? .sbtcmarket-v0 get-market u7)

;; Test 8: Market with percentage signs
(contract-call? .sbtcmarket-v0 create-market
  "Will BTC dominance >= 55%?"
  u1000007
  0x0000000000000000000000000000000000000000000000000000000000000007
  5500000000
  u10000000
  u30
  u"GE"
)

;; Verify market 8 created successfully
(contract-call? .sbtcmarket-v0 get-market u8)

;; Test 9: Market with dollar signs and commas
(contract-call? .sbtcmarket-v0 create-market
  "Will total crypto market cap >= $3,500,000,000,000?"
  u1000008
  0x0000000000000000000000000000000000000000000000000000000000000008
  350000000000000
  u15000000
  u30
  u"GE"
)

;; Verify market 9 created successfully
(contract-call? .sbtcmarket-v0 get-market u9)

;; Test 10: Market with quotes and apostrophes
(contract-call? .sbtcmarket-v0 create-market
  "Will 'king' BTC stay >= $100k?"
  u1000009
  0x0000000000000000000000000000000000000000000000000000000000000009
  10000000000000
  u11000000
  u30
  u"GE"
)

;; Verify market 10 created successfully
(contract-call? .sbtcmarket-v0 get-market u10)

;; ============================================================================
;; TEST TRADING ON MARKET WITH SPECIAL CHARACTERS
;; ============================================================================

;; Setup: Transfer sBTC to test wallet
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)

;; User buys shares on market with >= in question (market u1)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)

;; Check user balance on market 1
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; User buys shares on market with <= in question (market u2)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 false u50000)

;; Check user balance on market 2
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 false)

;; ============================================================================
;; RESOLUTION TEST
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Resolve market 1 (with >= in question) - YES wins
(contract-call? .sbtcmarket-v0 mock-resolve-market u1 true)

;; Verify resolution worked correctly
(contract-call? .sbtcmarket-v0 get-market u1)
(contract-call? .sbtcmarket-v0 get-redemption-info u1)

;; Resolve market 2 (with <= in question) - NO wins
(contract-call? .sbtcmarket-v0 mock-resolve-market u2 false)

;; Verify resolution worked correctly
(contract-call? .sbtcmarket-v0 get-market u2)
(contract-call? .sbtcmarket-v0 get-redemption-info u2)

;; ============================================================================
;; REDEMPTION TEST
;; ============================================================================

;; User redeems from market 1 (won on YES side)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u1)

;; User redeems from market 2 (won on NO side)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u2)

;; Check final sBTC balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; ============================================================================
;; EXPECTED OUTCOMES:
;; ============================================================================
;; 1. All 10 markets should be created successfully with special characters
;; 2. Market questions containing >=, <=, <, >, =, %, $, commas, quotes work
;; 3. Trading on markets with special characters works normally
;; 4. Resolution and redemption work correctly regardless of question text
;; 5. Special characters in questions are purely descriptive (don't affect logic)
;; 6. The comparison-type parameter (GE, LE, GT, LT, EQ) controls actual logic
;;
