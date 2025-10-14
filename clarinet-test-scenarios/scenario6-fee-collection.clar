;; ============================================================================
;; SCENARIO 6: FEE COLLECTION & TREASURY
;; Tests protocol fee mechanics and treasury accumulation
;; ============================================================================

;; Setup
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 none)
(contract-call? .sbtc-token transfer u1000000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG none)

;; ============================================================================
;; TEST 1: Create Market with Different Fee Levels
;; ============================================================================

;; Market 1: Low fee (0.1% = 10 bps)
(contract-call? .sbtcmarket-v0 create-market
  "Low Fee Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u10
  u"GE"
)

;; Market 2: Medium fee (0.3% = 30 bps)
(contract-call? .sbtcmarket-v0 create-market
  "Medium Fee Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u30
  u"GE"
)

;; Market 3: High fee (1% = 100 bps)
(contract-call? .sbtcmarket-v0 create-market
  "High Fee Market"
  u1000000
  0x0000000000000000000000000000000000000000000000000000000000000000
  10000000000000
  u10000000
  u100
  u"GE"
)

;; ============================================================================
;; TEST 2: Trade on Low Fee Market
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; Check deployer's initial balance (treasury)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)
;; Expected: u0

;; Buy 100k sats worth on low fee market
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u1 true u100000)

;; Check treasury balance (deployer receives fees)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)
;; Expected: ~100 shares (0.1% of 100k)

;; Check market's fee tracking
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u1)
;; fees-no should show accumulated fees

;; ============================================================================
;; TEST 3: Trade on Medium Fee Market
;; ============================================================================

;; Check treasury initial NO balance for market 2
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)

;; Buy 100k sats worth on medium fee market
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 true u100000)

;; Check treasury NO balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)
;; Expected: ~300 shares (0.3% of 100k)

;; ============================================================================
;; TEST 4: Trade on High Fee Market
;; ============================================================================

;; Check treasury initial NO balance for market 3
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)

;; Buy 100k sats worth on high fee market
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u3 true u100000)

;; Check treasury NO balance
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u3 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)
;; Expected: ~1000 shares (1% of 100k)

;; ============================================================================
;; TEST 5: Multiple Trades = Cumulative Fees
;; ============================================================================

::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG

;; Another user trades on market 2
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 buy-shares u2 true u200000)

;; Check treasury balance increased
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)
;; Expected: ~300 + ~600 = ~900 shares total

;; Check market fees tracking
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u2)
;; fees-no should show cumulative fees

;; ============================================================================
;; TEST 6: Swap Generates Fees
;; ============================================================================

::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5

;; First mint complete set to have shares to swap
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u2 u50000)

;; Check treasury YES balance before swap
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true)

;; Swap YES for NO (fees charged)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 swap-shares u2 true u25000)

;; Check treasury YES balance after swap (should have fees)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true)
;; Expected: ~75 shares (0.3% of 25k)

;; Check market fees
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-market u2)
;; fees-yes should now show accumulated fees

;; ============================================================================
;; TEST 7: Mint/Burn Don't Generate Fees
;; ============================================================================

;; Check treasury balances before
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)

;; Mint complete set (no fees)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 mint-complete-set u2 u30000)

;; Burn complete set (no fees)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 burn-complete-set u2 u20000)

;; Check treasury balances after (should be unchanged)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true)
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false)
;; Expected: No change (mint/burn are fee-free)

;; ============================================================================
;; TEST 8: Treasury Can Redeem Fees After Resolution
;; ============================================================================

::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM

;; Resolve market 2 with YES winning
(contract-call? .sbtcmarket-v0 mock-resolve-market u2 true)

;; Check treasury YES balance
(contract-call? .sbtcmarket-v0 get-balance u2 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true)

;; Treasury redeems its YES shares (collected as fees)
(contract-call? .sbtcmarket-v0 redeem-shares u2)

;; Check sBTC received by treasury
(contract-call? .sbtc-token get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; Should show protocol revenue from fees

;; ============================================================================
;; TEST 9: Change Treasury Address
;; ============================================================================

;; Get current treasury
(contract-call? .sbtcmarket-v0 get-protocol-treasury)

;; Try to change treasury from non-treasury address (should fail)
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtcmarket-v0 set-protocol-treasury 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
;; Expected: (err u1011) - ERR-UNAUTHORIZED

;; Change treasury from current treasury address (should succeed)
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
(contract-call? .sbtcmarket-v0 set-protocol-treasury 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
;; Expected: (ok 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Verify treasury changed
(contract-call? .sbtcmarket-v0 get-protocol-treasury)
;; Should show new address

;; ============================================================================
;; FEE COMPARISON SUMMARY
;; ============================================================================

;; Market 1 (0.1% fee): Lowest fees, most competitive for traders
;; Market 2 (0.3% fee): Medium fees, standard for most markets
;; Market 3 (1% fee): High fees, generates most protocol revenue
;;
;; Fee accumulation:
;; - Charged on buy-shares (via internal swap)
;; - Charged on swap-shares (direct swap)
;; - Charged on sell-shares (via internal swap)
;; - NOT charged on mint-complete-set or burn-complete-set
;;
;; Treasury receives:
;; - Fees as shares (not sBTC)
;; - Can redeem shares after resolution
;; - Receives proportional payout like other winners
