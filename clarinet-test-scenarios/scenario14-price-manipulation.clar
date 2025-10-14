;; ============================================================================
;; SCENARIO 14: PRICE MANIPULATION & SANDWICH ATTACKS
;; Tests front-running, price impact, and manipulation attempts
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC none)

;; ============================================================================
;; TEST 1: Baseline - Fair Market Pricing
;; ============================================================================

(contract-call? .sbtcmarket-v0 create-market
  "Fair Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Check initial 50/50 pricing
(contract-call? .sbtcmarket-v0 get-market u1)
;; Expected: price-yes = 10000000, price-no = 10000000

;; ============================================================================
;; TEST 2: Sandwich Attack Simulation
;; ============================================================================

;; Victim: User wants to buy YES with 100k sats
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Record victim's initial sBTC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; ATTACKER SEES TRANSACTION IN MEMPOOL
;; Attacker: Front-run with large buy to move price up
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u500000)

;; Check price after front-run
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; Expected: price-yes >> 10000000 (much higher)

;; Victim's transaction executes at worse price
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)

;; Check shares received by victim (less than expected)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; Attacker: Back-run with sell to profit
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 sell-shares u1 true u300000)

;; Check attacker's final sBTC (should have profited)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc-token get-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; ============================================================================
;; TEST 3: Whale Manipulation - Move Market to Extreme
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Whale Target Market"
  u1000100
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u5000000
  u30
  u"GE"
)

;; Whale buys massive position on one side
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 true u2000000)

;; Check market state (heavily skewed)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u2)
;; Expected: price-yes very high, price-no very low

;; Whale buys opposite side to push back
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 false u1500000)

;; Check final state (should be more balanced)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u2)

;; ============================================================================
;; TEST 4: Coordinated Attack - Multiple Attackers
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Coordinated Attack"
  u1000200
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Attacker 1: Buy YES
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u3 true u400000)

;; Attacker 2: Buy YES immediately after
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u3 true u400000)

;; Attacker 3: Buy YES
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u3 true u400000)

;; Check extreme price skew
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u3)

;; All attackers resolve in their favor (using mock-resolve exploit)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mock-resolve-market u3 true)

;; All attackers redeem
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u3)

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u3)

::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u3)

;; ============================================================================
;; TEST 5: Just-In-Time Liquidity Attack
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "JIT Attack Market"
  u1000300
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Victim announces intent to buy large position
;; Attacker: Mint complete sets just before victim's tx
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u4 u500000)

;; Attacker swaps to create imbalance favoring what victim will buy
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u4 false u450000)

;; Check market state (YES now more expensive)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u4)

;; Victim buys at inflated price
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u4 true u300000)

;; Attacker swaps back
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u4 true u200000)

;; ============================================================================
;; TEST 6: Last-Minute Market Manipulation Before Resolution
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Pre-Resolution Manipulation"
  u1000400
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Normal trading phase
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u5 true u100000)

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u5 false u100000)

;; Just before resolution block, whale pumps one side
::set_tx_sender ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u5 true u800000)

;; Check heavily skewed odds
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u5)

;; Whale resolves in their favor
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mock-resolve-market u5 true)

;; Whale redeems huge payout
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 redeem-shares u5)

;; ============================================================================
;; TEST 7: Price Impact Comparison - Buy vs Swap
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

(contract-call? .sbtcmarket-v0 create-market
  "Buy vs Swap Comparison"
  u1000500
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; User 1: Uses buy-shares
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u6 true u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u6 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 true)

;; User 2: Uses mint + swap
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u6 u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u6 false u200000)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u6 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG true)

;; Compare final balances
;; Both spent 200k sBTC but got different amounts of YES shares

;; ============================================================================
;; SUMMARY
;; ============================================================================

;; Attack Vectors Tested:
;; 1. Sandwich attack - Front-run + back-run victim
;; 2. Whale manipulation - Single large position moves market
;; 3. Coordinated attack - Multiple attackers pump one side
;; 4. JIT liquidity - Mint + swap to manipulate price
;; 5. Pre-resolution pump - Last-minute manipulation
;; 6. Buy vs swap efficiency - Different paths, different costs

;; Vulnerabilities Demonstrated:
;; - No slippage protection allows sandwich attacks
;; - mock-resolve-market allows attackers to guarantee wins
;; - Large trades have extreme price impact
;; - No maximum position size allows whale dominance
;; - Fees don't prevent manipulation at scale

;; Mitigations Needed:
;; - Add slippage parameters (min-shares-out, min-sbtc-out)
;; - Remove/restrict mock-resolve-market
;; - Consider max position size limits
;; - Add trade size limits per block
;; - Implement time-weighted average pricing
