# Gnosis Conditional Tokens Framework (CTF) vs sbtcmarket-v0.clar

## Detailed Comparison Table

| **Aspect** | **Gnosis Conditional Tokens Framework (CTF)** | **sbtcmarket-v0.clar** |
|------------|----------------------------------------------|------------------------|
| **Architecture** | Generic conditional token framework; requires separate AMM/orderbook | All-in-one: market creation + AMM + resolution |
| **Token Standard** | ERC-1155 multi-token standard (Ethereum) | Custom share tracking via Clarity maps |
| **Outcome Types** | Multi-outcome support (N outcomes per condition) | Binary only (YES/NO) |
| **Nested Conditions** | ✅ Supports complex conditional dependencies (condition A → condition B) | ❌ Single-level conditions only |
| **Collateral Model** | Any ERC-20 token; locked in CTF contract | sBTC only; locked in market contract |
| **Position Representation** | `positionId = hash(collateralToken, conditionId, partition)` | `balances[(market-id, user, side)]` |
| **Complete Set Mechanics** | **Split**: 1 collateral → N outcome tokens<br>**Merge**: N outcome tokens → 1 collateral | **Mint**: 1 sBTC → 1 YES + 1 NO<br>**Burn**: 1 YES + 1 NO → 1 sBTC |
| **Invariant Guarantee** | ✅ **Strict**: Total outcome tokens always = collateral (no over-issuance) | ❌ **Weak**: Swaps can create shares > collateral (over-issuance possible) |
| **Trading Mechanism** | No built-in trading; integrates with:<br>- Gnosis Protocol (orderbook)<br>- Balancer (AMM)<br>- Uniswap V3 (concentrated liquidity) | Built-in constant-product AMM (x*y=k) with virtual reserves |
| **Liquidity Model** | Requires external LPs to provide liquidity | Zero-capital creation with virtual liquidity parameter |
| **Price Discovery** | External market determines prices | AMM reserves determine prices (50/50 start) |
| **Market Creation Cost** | Free (just sets condition parameters) | Free (virtual reserves, no upfront collateral) |
| **Resolution Oracle** | Arbitrary oracle (requires `reportPayouts()` call) | Pyth oracle only (Bitcoin block height + price feeds) |
| **Resolution Flexibility** | ✅ Any oracle or governance mechanism | ❌ Fixed to Pyth + block height |
| **Resolution Window** | No time limit; can resolve anytime after condition | 2-block window at `resolution-block` (lines 936-937) |
| **Payout Distribution** | `payoutNumerators[outcomeIndex]` per 1 collateral (e.g., [1,0] for binary) | Winner gets proportional share of vault |
| **Partial Payouts** | ✅ Supports (e.g., [0.5, 0.5] for draw) | ❌ Binary winner-take-all only |
| **Redemption Formula** | `payout = Σ(positionTokens[i] * payoutNumerators[i]) / sum(payoutNumerators)` | `payout = (user_shares / total_circulating) * vault` (line 1035) |
| **Over-Issuance Risk** | ❌ Impossible (split/merge enforces 1:1) | ✅ Possible via AMM swaps (lines 28-46 warning) |
| **Redemption Fairness** | ✅ Always 1:1 for complete sets | ⚠️ Proportional if over-issued (<1 sat/share) |
| **Composability** | ✅ Highly composable:<br>- Use positions as collateral for other conditions<br>- Combine with any DEX | ❌ Limited:<br>- Shares can't be used as collateral<br>- No external trading support |
| **Conditional Markets** | ✅ "If A happens, then market B resolves" | ❌ No conditional dependencies |
| **Example Use Case** | "If ETH>$5k by Dec, will ETH>$10k by Jan?" | "Will BTC>=110k by block 890000?" |
| **Fee Model** | No protocol fees (external AMMs have their own) | 0.3% swap fee (line 834) + 1% buy/sell tax (line 57) |
| **Fee Recipient** | N/A (CTF itself doesn't charge) | `protocol-treasury` (swap fees) + `tax-recipient` (1% tax) |
| **Cancellation** | No built-in cancellation (oracle-dependent) | ✅ After resolution window + 2 blocks (lines 1092-1120) |
| **Refund Mechanism** | Depends on oracle implementation | Proportional refund based on total shares (lines 1137-1228) |
| **Gas/Complexity** | Lower gas for simple split/merge; external AMM = separate txs | Higher (all-in-one), but single-tx buy/sell |
| **Market Maker Requirements** | Requires sophisticated LPs | Anyone can trade (AMM provides liquidity) |
| **Capital Efficiency** | High (LPs can provide concentrated liquidity) | Lower (virtual reserves fixed at creation) |
| **Slippage** | Depends on external AMM liquidity depth | Depends on virtual-liquidity parameter |
| **Frontrunning Protection** | Depends on external AMM/orderbook | None (standard AMM frontrunning possible) |
| **Access Control** | Permissionless (anyone can create conditions) | Permissioned (only authorized creators, lines 624-625) |
| **Resolution Timing** | Flexible (when oracle reports) | Strict 2-block window (lines 936-937) |
| **Chain** | Ethereum + L2s (Polygon, Gnosis Chain, etc.) | Stacks blockchain only |
| **Collateral Bridge** | Any ERC-20 | sBTC (Bitcoin pegged via threshold signatures) |
| **State Complexity** | Higher (supports complex trees of conditions) | Lower (flat binary markets) |

## Key Architectural Differences

### 1. Separation of Concerns

**Gnosis CTF:**
```
CTF Contract (token logic) → External AMM (pricing) → External Oracle (resolution)
```
- Modular, composable, but requires 3+ separate contracts
- Example: CTF + Balancer weighted pools + Chainlink oracle

**sbtcmarket-v0.clar:**
```
Single contract: tokens + AMM + oracle integration
```
- Monolithic, simpler UX, but less flexible
- All operations happen in one contract

### 2. Collateral Invariant

**Gnosis CTF (strict):**
```solidity
// ALWAYS true:
sum(outcomeTokens) == collateralLocked

// Split: collateral → outcomes (decreases collateral, increases outcomes)
// Merge: outcomes → collateral (increases collateral, decreases outcomes)
```

**sbtcmarket-v0.clar (loose):**
```clarity
;; TRUE for complete sets:
vault-sbtc == yes-issued == no-issued

;; FALSE for circulating shares (swaps break it):
vault-sbtc != yes-circulating + no-circulating
;; Over-issuance possible! (lines 32-34)
```

**Impact:**
- Gnosis CTF: No risk of under-collateralization
- sbtcmarket-v0.clar: AMM swaps can create more shares than collateral, requiring proportional redemption

### 3. Position Identification

**Gnosis CTF:**
```solidity
positionId = keccak256(
  collateralToken,
  conditionId,
  indexSet  // e.g., 0b01 for outcome 1
)
```
- Each position is a unique ERC-1155 token
- Can hold "YES on A AND NO on B" as a single position token
- Enables complex strategies and derivatives

**sbtcmarket-v0.clar:**
```clarity
balances: {market-id, user, side} → uint
```
- Flat structure, can't express complex conditionals
- Simple map-based accounting

## Trading Experience Comparison

### Gnosis CTF Trading Flow

1. User deposits collateral (e.g., USDC) to CTF contract
2. CTF mints outcome tokens (e.g., YES_ETH5K, NO_ETH5K)
3. User takes outcome tokens to external DEX (Balancer/Uniswap)
4. Swaps outcome token for different outcome or base collateral
5. Returns to CTF to redeem after resolution

**Pros:**
- Access to deep DEX liquidity
- Multiple trading venues
- Can use advanced DEX features (limit orders, concentrated liquidity)

**Cons:**
- Multi-step process (mint → trade → redeem)
- Multiple transactions and gas fees
- Need to understand multiple protocols

### sbtcmarket-v0.clar Trading Flow

1. User calls `buy-shares(side, amount)` with sBTC
2. Contract mints complete set + swaps automatically
3. User receives position immediately
4. Call `sell-shares(side, amount)` to exit
5. Contract swaps + burns complete sets automatically

**Pros:**
- Single transaction for entry/exit
- Built-in liquidity (AMM)
- Simpler UX

**Cons:**
- Limited to built-in AMM pricing
- No advanced trading features
- Fixed virtual liquidity at creation

## Resolution Mechanisms

### Gnosis CTF Resolution

```solidity
function reportPayouts(bytes32 questionId, uint256[] payouts) external {
  // Oracle reports payout vector
  // Example: [1, 0] for binary YES win
  // Example: [0.5, 0.5] for tie/draw
}
```

**Features:**
- Supports partial payouts (not just winner-take-all)
- Can use any oracle (Chainlink, UMA, Reality.eth, manual governance)
- Flexible timing (resolve whenever oracle reports)
- Can invalidate markets with [1,1,1...] payout

### sbtcmarket-v0.clar Resolution

```clarity
(define-public (resolve-market
    (market-id uint)
    (vaa (buff 8192))  ;; Pyth VAA bytes
    (execution-plan {...})
  )
  ;; Must be called within 2-block window
  ;; Fetches price from Pyth oracle
  ;; Compares against threshold (GE/GT/LE/LT/EQ)
  ;; Sets winner (true=YES, false=NO)
)
```

**Features:**
- Only supports Pyth oracle
- Winner-take-all (no partial payouts)
- Strict 2-block resolution window
- Automatic cancellation if window missed

## Over-Issuance Deep Dive

### Why Gnosis CTF Can't Over-Issue

```solidity
function splitPosition(
  IERC20 collateralToken,
  bytes32 conditionId,
  uint256 amount
) external {
  // Transfer collateral FROM user
  collateralToken.transferFrom(msg.sender, address(this), amount);

  // Mint outcome tokens TO user (sum = amount)
  for (uint i = 0; i < outcomeCount; i++) {
    _mint(msg.sender, positionId[i], amount);
  }
  // Invariant: collateralLocked += amount, outcomeTokens += (amount * outcomeCount)
}
```

**Every mint requires corresponding collateral lock.**

### Why sbtcmarket-v0.clar Can Over-Issue

From contract lines 821-895:
```clarity
(define-public (swap-shares
    (market-id uint)
    (from-side bool)
    (amount-in uint)
  )
  ;; Burns amount-in from from-side
  (try! (burn-shares market-id tx-sender from-side amount-in))

  ;; Mints amount-out to to-side (amount-out can be > amount-in!)
  (let ((amount-out (try! (calculate-amount-out ...))))
    (mint-shares market-id tx-sender (not from-side) amount-out)
  )
  ;; Net effect: If amount-out > amount-in, total shares increased!
  ;; But vault-sbtc unchanged!
)
```

**Example:**
- Vault: 10,000 sats
- User swaps 1,000 YES → receives 1,215 NO
- Net: +215 shares created with no new collateral
- New total circulating: 10,215 shares backed by 10,000 sats
- Redemption ratio: 10,000 / 10,215 = 97.9% (not 100%)

## When to Use Each Model

| **Use Gnosis CTF When:** | **Use sbtcmarket-v0.clar When:** |
|--------------------------|----------------------------------|
| Multi-outcome markets (elections, sports) | Binary predictions only |
| Need conditional/nested markets | Simple yes/no questions |
| Want to integrate with multiple DEXs | Want built-in AMM trading |
| Need flexible oracle integration | Pyth oracle is sufficient |
| Building composable DeFi primitives | Want permissioned market creation |
| Capital-efficient LP strategies | Zero-capital market launch |
| Ethereum/EVM ecosystem | Stacks/Bitcoin ecosystem |
| Require strict 1:1 collateral backing | Accept proportional redemption risk |
| Need partial payout support (ties/draws) | Winner-take-all is acceptable |

## Recommendations for Improvement

If you want to make sbtcmarket-v0.clar more like CTF while keeping the AMM:

### 1. Enforce Strict Collateral Invariant
**Problem:** Swaps can create over-issuance

**Solutions:**
- **Option A:** Disable direct swaps; require users to burn→mint manually
- **Option B:** Track "virtual shares" (for pricing) separately from "redeemable shares" (backed 1:1)
- **Option C:** Add "settlement reserve" that captures swap profits to back over-issued shares

### 2. Support Multi-Outcome Markets
**Current:** Binary YES/NO only

**Improvement:**
```clarity
(define-map balances
  {market-id: uint, user: principal, outcome-index: uint}
  uint
)
```
- Allow N outcomes per market
- Adjust AMM to multi-asset constant-function (harder)
- Or: Keep binary, allow multiple independent markets

### 3. Modularize Oracle Integration
**Current:** Hardcoded to Pyth oracle

**Improvement:**
```clarity
(define-trait oracle-trait
  (
    (resolve (uint) (response {outcome: bool, price: int} uint))
  )
)

(define-public (resolve-market-with-oracle
    (market-id uint)
    (oracle <oracle-trait>)
  )
  ;; Accept any oracle implementation
)
```

### 4. Add Conditional Markets
**Current:** Independent markets only

**Improvement:**
```clarity
(define-map markets
  {id: uint}
  {
    ...
    parent-market: (optional uint),      ;; Link to parent condition
    required-outcome: (optional bool),   ;; Only resolves if parent = this outcome
  }
)
```

### 5. Enable Position Composability
**Current:** Shares locked in contract, not transferable

**Improvement:**
- Implement SIP-013 (semi-fungible token) for shares
- Allow shares to be used as collateral in other contracts
- Enable share transfers between users

## References

- [Gnosis Conditional Tokens Whitepaper](https://docs.gnosis.io/conditionaltokens/)
- [ERC-1155 Multi-Token Standard](https://eips.ethereum.org/EIPS/eip-1155)
- [Pyth Oracle Documentation](https://docs.pyth.network/)
- [Stacks Documentation](https://docs.stacks.co/)

## Conclusion

**Gnosis CTF** is a flexible, composable primitive for building prediction markets with strong collateral guarantees but requires external infrastructure.

**sbtcmarket-v0.clar** is an opinionated, all-in-one solution optimized for simple binary markets on Bitcoin with built-in trading, but sacrifices some guarantees and flexibility for UX simplicity.

The choice depends on your priorities:
- **Flexibility & composability** → Gnosis CTF
- **Simplicity & Bitcoin-native** → sbtcmarket-v0.clar
