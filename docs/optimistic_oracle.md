# Optimistic Oracle for Real-World Event Resolution

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Economic Incentive Design](#economic-incentive-design)
4. [Game Theory & Attack Resistance](#game-theory--attack-resistance)
5. [Implementation Specification](#implementation-specification)
6. [Integration with sbtcmarket-v0](#integration-with-sbtcmarket-v0)
7. [Testing Strategy](#testing-strategy)
8. [Deployment Roadmap](#deployment-roadmap)

---

## Overview

### Problem Statement

The current `sbtcmarket-v0.clar` contract only supports **price-based markets** resolved via Pyth Oracle:
- ✅ "Will BTC be ≥ $110k by block 890000?" → Pyth can resolve
- ❌ "Will the Lakers win the NBA Championship?" → Pyth cannot resolve
- ❌ "Will the US GDP exceed $30T in 2025?" → Pyth cannot resolve
- ❌ "Will it snow in NYC on Dec 25?" → Pyth cannot resolve

**Goal:** Enable prediction markets on ANY real-world event by implementing a UMA-style optimistic oracle in Clarity.

### Optimistic Oracle Philosophy

**"Assume truth unless proven false"**

Instead of requiring real-time oracle feeds, the optimistic oracle:
1. **Anyone can propose** an outcome after the event occurs
2. **Economic bond** ensures proposers have skin in the game
3. **Liveness period** allows others to dispute false claims
4. **Only disputed claims** require arbitration (saves costs)
5. **Correct parties earn rewards**, incorrect parties lose bonds

This approach works because:
- **Most events have obvious outcomes** (Lakers won/lost is public knowledge)
- **False proposals are immediately disputed** (economic incentive to correct)
- **Bonds make attacks expensive** (must risk capital to lie)

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    sbtcmarket-v0.clar                       │
│  (Prediction Market Contract)                               │
│                                                             │
│  Markets:                                                   │
│  - Market #1: "Will BTC ≥ $110k?"  → Pyth Oracle          │
│  - Market #2: "Will Lakers win?"   → Optimistic Oracle    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ contract-call?
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              optimistic-oracle-v1.clar                      │
│  (Trustless Oracle via Economic Game Theory)                │
│                                                             │
│  Multi-Round Escalation System:                             │
│                                                             │
│  Round 1: Initial Proposal                                  │
│    - Bond: 20,000 sats                                      │
│    - Liveness: 5 days (720 blocks)                         │
│    - Anyone can propose outcome                             │
│                                                             │
│  Round 2: First Dispute (if challenged)                     │
│    - Bond: 60,000 sats (3x multiplier)                     │
│    - Liveness: 3 days (432 blocks)                         │
│    - Previous proposer loses bond                           │
│                                                             │
│  Round 3: Second Dispute (if challenged)                    │
│    - Bond: 180,000 sats (3x multiplier)                    │
│    - Liveness: 2 days (288 blocks)                         │
│    - Cumulative losses mounting                             │
│                                                             │
│  Round 4: Final Resolution (if challenged)                  │
│    - Bond: 900,000 sats (5x multiplier)                    │
│    - Liveness: 1 day (144 blocks)                          │
│    - ECONOMIC FINALITY: Too expensive to continue           │
│                                                             │
│  Emergency Backstop: STX Token Voting                       │
│    - Only if Round 4 disputed (extremely rare)              │
│    - 48-hour voting window                                  │
│    - Minimum 20% quorum                                     │
│                                                             │
│  Key Features:                                              │
│  ✅ TRUSTLESS: No multi-sig, no admins                     │
│  ✅ PERMISSIONLESS: Anyone can propose/dispute             │
│  ✅ SELF-CORRECTING: Economic incentives align truth       │
│  ✅ SCHELLING POINT: Real events have obvious outcomes     │
└─────────────────────────────────────────────────────────────┘
```

### Flow Diagram

#### Happy Path (No Dispute)
```
Block 890000: Event occurs (Lakers win championship)
Block 890010: Alice proposes "YES" + 20k sats bond (Round 1)
              ↓
              [720-block liveness period = ~5 days]
              ↓
Block 890730: No disputes received
              ↓
              Alice calls finalize-undisputed()
              ↓
              Market resolves to "YES"
              Alice gets bond back + 50% of market fees
```

#### Dispute Path (Escalation)
```
Block 890010: Alice proposes "YES" + 20k sats bond (Round 1)
Block 890050: Bob disputes "NO" + 60k sats bond (Round 2)
              ↓
              Alice's 20k bond is SLASHED (Bob earns it)
              Bob's 60k starts new liveness period (3 days)
              ↓
Block 890100: Charlie disputes Bob with "YES" + 180k bond (Round 3)
              ↓
              Bob's 60k bond is SLASHED (Charlie earns it)
              Charlie's 180k starts new liveness period (2 days)
              ↓
Block 890388: No further disputes
              ↓
              Charlie calls finalize-outcome()
              ↓
              Market resolves to "YES" (Charlie was correct)
              Charlie gets: 180k (bond back) + 20k (Alice's) + 60k (Bob's)
                          + 50% market fees
              Total: ~310k+ sats for being right

              Alice lost: 20k sats (false proposal)
              Bob lost: 60k sats (false dispute)
```

#### Ultimate Escalation (Rare)
```
If Round 4 is disputed (both sides risk 900k+ sats):
  ↓
  Emergency STX token voting triggered
  ↓
  All STX holders can vote (48-hour window)
  ↓
  Outcome determined by token-weighted majority
  ↓
  Winner gets ALL bonds from all rounds (2M+ sats)

This scenario is economically irrational → likely never happens
```

---

## Economic Incentive Design

### Core Principle: "Truth is Profitable, Lies Become Exponentially Expensive"

The system uses **escalating stakes** to achieve economic finality without trusted arbitrators:

1. **Honest proposers earn rewards** (bond + fees)
2. **Dishonest proposers lose bonds** (slashed by disputers)
3. **Each dispute round costs more** (exponential escalation)
4. **Eventually, lying exceeds any manipulation profit** (economic finality)
5. **Schelling point convergence** (everyone knows real outcome)

### Multi-Round Bond Structure

```
┌──────────────────────────────────────────────────────────┐
│ Round 1: Initial Proposal                                │
│                                                          │
│ Bond: 20,000 sats (~$22 at $110k BTC)                   │
│ Liveness: 5 days (720 blocks)                           │
│ Multiplier: 3x to next round                            │
│                                                          │
│ Why this amount?                                         │
│ - Accessible (anyone can participate)                    │
│ - High enough to deter spam                              │
│ - Represents ~2% of small market vault                   │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ Round 2: First Dispute                                   │
│                                                          │
│ Bond: 60,000 sats (3x Round 1)                          │
│ Liveness: 3 days (432 blocks)                           │
│ Multiplier: 3x to next round                            │
│                                                          │
│ Why 3x?                                                  │
│ - Significant commitment (must be confident)             │
│ - Disputer can earn 20k from slashing previous round    │
│ - Still accessible to community members                  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ Round 3: Second Dispute                                  │
│                                                          │
│ Bond: 180,000 sats (3x Round 2)                         │
│ Liveness: 2 days (288 blocks)                           │
│ Multiplier: 5x to final round                           │
│                                                          │
│ Impact:                                                  │
│ - Major capital commitment required                      │
│ - Only serious actors remain                             │
│ - Cumulative losses for wrong side: 80k sats            │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ Round 4: Final Resolution                                │
│                                                          │
│ Bond: 900,000 sats (5x Round 3)                         │
│ Liveness: 1 day (144 blocks)                            │
│ Status: ECONOMIC FINALITY                                │
│                                                          │
│ Why this is final:                                       │
│ - ~$1,000 USD at stake (massive for most markets)       │
│ - Cumulative losses for wrong side: 260k sats           │
│ - Further dispute triggers STX voting (last resort)      │
│ - Economically irrational to continue if wrong           │
└──────────────────────────────────────────────────────────┘
```

### Escalation Economics Table

| Round | Bond Required | Liveness | Total Lost if Wrong | Cumulative Pot | Winner Takes |
|-------|--------------|----------|---------------------|----------------|--------------|
| 1 | 20k sats | 5 days | 20k | 20k | 20k + fees |
| 2 | 60k sats | 3 days | 80k (20+60) | 80k | 80k + fees |
| 3 | 180k sats | 2 days | 260k (20+60+180) | 260k | 260k + fees |
| 4 | 900k sats | 1 day | 1,160k (all rounds) | 1,160k | 1.16M + fees |

### Reward Distribution

| Scenario | Final Proposer Gets | Losing Parties Lose | Notes |
|----------|---------------------|---------------------|-------|
| **Undisputed Round 1** | 20k bond + 50% market fees | - | Fast resolution, honest profit |
| **Undisputed Round 2** | 60k bond + 20k slashed + fees | Previous: -20k | Corrected false claim |
| **Undisputed Round 3** | 180k bond + 80k slashed + fees | Previous: -80k total | Major correction |
| **Undisputed Round 4** | 900k bond + 260k slashed + fees | Previous: -260k total | Ultimate resolution |
| **Round 4 Disputed → Voting** | All bonds (1.16M+) + fees | Loser: -1.16M | Nuclear option (rare) |
| **No proposals (7+ days)** | - | - | Market cancelled, users refunded |

**Key insight:** Each round, the winner collects ALL previously slashed bonds, creating massive incentive to correct false claims.

### Fee Structure

**Market fees** are accumulated from trading activity:
- 0.3% AMM swap fee (already exists in contract)
- 1% buy/sell tax (already exists in contract)

These fees are earmarked for oracle rewards:
- **50% to oracle participants** (proposer or disputer)
- **50% to protocol treasury** (covers infrastructure costs)

Example:
- Market accumulates 100,000 sats in fees
- Correct proposer gets: 50,000 sats + their bond back
- Protocol treasury gets: 50,000 sats

### Economic Security Calculation

**Cost to attack** = Bond at risk
**Benefit from attack** = Market manipulation profit

For attack to be unprofitable:
```
Bond > Expected profit from market manipulation
```

Example:
- Attacker wants to propose false "YES" outcome
- They hold 50,000 sats of "YES" shares
- If market incorrectly resolves to "YES", they gain 50,000 sats
- But they must post 10,000 sat bond
- If disputed (highly likely for obvious lie), they lose 10,000 sats
- Net: 50,000 gain - 10,000 loss = 40,000 profit

**Problem:** Attack still profitable!

**Solution:** Dynamic bond requirements
```clarity
(define-read-only (calculate-minimum-bond (market-id uint))
  (let ((market (unwrap! (map-get? markets {id: market-id}) u10000)))
    ;; Bond must be at least 20% of total market vault
    (/ (* (get vault-sbtc market) u20) u100)
  )
)
```

For market with 100,000 sats vault:
- Minimum bond: 20,000 sats
- Attacker with 50,000 sats position must risk 20,000 to lie
- If disputed: loses 20,000, gains 50,000 = net 30,000 profit
- But disputer can claim 20,000 bond + get 10,000 reward = 30,000
- This attracts multiple disputers!

**Better solution:** Make bond = 50% of vault for high-stakes markets
- Vault: 100,000 sats
- Required bond: 50,000 sats
- Attacker with 50,000 position risks 50,000 to lie
- If disputed: loses 50,000, gains 50,000 = **NET ZERO**
- Not worth the risk (coordination costs, reputation damage)

---

## Game Theory & Attack Resistance

### Attack Vector 1: False Proposal

**Attack:** Alice proposes "YES" even though "NO" is correct outcome

**Round 1 Economics:**
- Alice posts 20,000 sat bond claiming "YES"
- Bob (honest observer) sees false proposal
- Bob can dispute with 60,000 sat bond claiming "NO"
- **Result:** Alice loses 20,000 sats (slashed), Bob earns 20k + will earn more when finalized

**Why it fails:**
1. Any honest observer can profit from disputing
2. Alice loses bond immediately upon dispute
3. Clear evidence makes outcome obvious
4. Multiple honest actors will race to dispute (first one wins)

**Economic deterrent:**
- Loss: Guaranteed -20k sats
- Gain: Zero (gets disputed immediately for obvious lies)
- Reputation: Public address damaged

**No mitigation needed:** Economics alone prevent this attack

---

### Attack Vector 2: Multi-Round Dispute Spam

**Attack:** Attacker keeps disputing through all rounds to delay resolution

**Economics:**
- Alice proposes correct "YES" + 20k bond (Round 1)
- Mallory disputes "NO" + 60k bond (Round 2, frivolous)
- Alice re-disputes "YES" + 180k bond (Round 3)
- Mallory disputes "NO" + 900k bond (Round 4, frivolous)

**Mallory's total loss if wrong:**
- Round 2: -60k
- Round 4: -900k
- **Total: -960,000 sats ($1,000+ USD)**

**Delay achieved: 11 days maximum**

**Why it fails:**
1. Each round costs exponentially more (3x-5x multiplier)
2. Eventually costs exceed any manipulation benefit
3. Maximum delay is bounded (11 days)
4. Losing party loses ALL bonds from all rounds

**Natural economic limit:** No further mitigation needed

---

### Attack Vector 3: Profitable Manipulation

**Attack:** Attacker with large position tries to force false outcome

**Scenario:**
- Attacker holds 500,000 sats of "YES" shares
- Real outcome: "NO" (attacker will lose 500k)
- Attacker wants to manipulate oracle to say "YES"

**Round 1:** Attacker proposes false "YES" + 20k bond
- Honest actor disputes "NO" + 60k bond
- Attacker loses 20k

**Round 2:** Attacker re-disputes "YES" + 180k bond (trying to push through)
- Another honest actor disputes "NO" + 900k bond
- Attacker loses 180k (cumulative: 200k)

**Round 3:** Attacker must post 900k+ bond
- **Decision point:** Risk 900k more to save 500k position?
- **Math:** 500k gain - 1,100k cost = -600k NET LOSS
- **Rational choice:** Abandon attack, accept 200k loss

**Why it fails:**
1. **Economic finality:** Eventually, cost exceeds benefit
2. **Community capital:** Honest actors have unlimited combined capital
3. **Schelling point:** Everyone knows real outcome, will fight attacker
4. **First-mover advantage:** Honest actors can pre-commit bonds

**Break-even analysis:**
```
Attack profitable if:
  Manipulation gain > Sum of all bond losses

For 500k position:
  Must win before spending > 500k on bonds
  Round 1: 20k spent
  Round 2: 200k spent (20+180)
  Round 3: 1,100k spent (20+180+900)

Attack becomes unprofitable at Round 3
```

---

### Attack Vector 4: Nothing-at-Stake (Multiple Proposals)

**Attack:** Alice proposes both outcomes from different accounts to guarantee win

**Why it's impossible:**
1. Contract only accepts ONE proposal per market per round
2. First valid proposal locks that round
3. Second attempt (same round) is rejected

**Implementation:**
```clarity
(define-map assertions
  {market-id: uint, round: uint}  ;; Key includes round number
  {...}
)

;; Only one assertion can exist per (market-id, round)
;; Attempting to create second proposal for same market/round fails
```

**Even if attacker tries across rounds:**
- Round 1: Alice proposes "YES" + 20k
- Bob disputes "NO" + 60k (Alice loses 20k)
- Round 2: Alice tries "NO" + 60k (would lose another 60k if wrong)
- **Result:** Alice loses both bonds (80k) if keeps guessing

**Economic outcome:** Worse than just accepting one outcome

---

### Attack Vector 5: Coordinated Whale Attack

**Attack:** Group of whales coordinate to push false outcome through all rounds

**Scenario:**
- 5 whales pool 2M sats total capital
- Try to force false "YES" outcome
- Real outcome: "NO"

**Execution:**
- Whale 1: Proposes "YES" + 20k (Round 1)
- Community disputes "NO" + 60k
- Whale 2: Disputes "YES" + 180k (Round 2)
- Community disputes "NO" + 900k (Round 3)
- Whales must continue: Need 900k+ for Round 4

**Problem for attackers:**
1. **Community has more capital than 5 whales** (hundreds of participants)
2. **Schelling point:** Everyone sees real outcome, coordinates against whales
3. **Pre-commitment:** Community can pre-commit bonds to show strength
4. **Reputation:** Whales' addresses become known, blacklisted

**Economic outcome:**
- Whales spend: 20k + 180k + 900k = 1.1M sats (minimum)
- Community earns: All slashed bonds + fees
- Whales lose: Everything (can't outspend coordinated community)

**Why it fails:**
1. **N vs 5:** Many honest actors vs few attackers
2. **Observable:** On-chain coordination is visible
3. **Defensive advantage:** Truth is obvious, easy to defend
4. **Unlimited depth:** Community can keep escalating

---

### Attack Vector 6: Flash Loan / Borrowed Capital

**Attack:** Attacker borrows massive capital to post huge bonds

**Why it fails on Stacks:**
1. **No flash loans:** Stacks doesn't have flash loan primitives (yet)
2. **Multi-block settlement:** Bonds must be locked across many blocks
3. **Time lock:** Liveness periods (1-5 days) prevent instant resolution

**Even if flash loans existed:**
- Borrowed capital must be locked for days (impossible with flash loans)
- Interest costs would exceed any gain
- Collateral requirements make attack expensive

**Future-proofing (if flash loans come to Stacks):**
```clarity
;; Require bonds to be locked minimum 1 full block before use
(define-map bond-locks
  {user: principal, market-id: uint}
  {locked-at: uint, amount: uint}
)

;; Bonds only active after 1 block confirmation
(asserts! (> burn-block-height (+ (get locked-at bond) u1))
  (err ERR-BOND-TOO-FRESH))
```

---

## Why Proposers Choose Truth

### Positive Incentives (Carrots)

1. **Immediate profit opportunity**
   - Propose correct outcome → wait 5 days → earn bond + 50% of market fees
   - Low-hanging fruit for honest actors
   - Example: Market with 100k sats fees = 20k bond + 50k reward = 70k total
   - **ROI:** 250% return in 5 days (if undisputed)

2. **Low barrier to entry**
   - Only 20k sat bond required (~$22 USD)
   - Anyone with basic capital can participate
   - First-come-first-serve: Race to propose truth

3. **Escalation profits**
   - If you dispute false Round 1 proposal with correct Round 2:
     - You earn 20k (slashed Round 1 bond)
     - Plus 60k (your bond back when finalized)
     - Plus 50% market fees
     - **Total: 100k+ sats for correcting a lie**

4. **Risk-free for obvious outcomes**
   - Events like sports have clear, public outcomes
   - Proposing truth won't be disputed (everyone agrees)
   - Only liars get disputed → truth is safe

5. **Repeat business**
   - Build reputation as reliable oracle
   - Future markets may prioritize trusted proposers
   - Become known as "honest resolver" in community

### Negative Incentives (Sticks)

1. **Guaranteed loss if wrong**
   - False proposal → immediate dispute → lose 20k bond instantly
   - Disputer earns your slashed bond
   - No escape: Evidence is public and obvious

2. **Exponential losses if you persist**
   - Round 1 false proposal: lose 20k
   - Round 2 re-dispute (false): lose 60k (cumulative: 80k)
   - Round 3 re-dispute (false): lose 180k (cumulative: 260k)
   - **Total potential loss: 260k-1.16M sats** if you keep lying

3. **Opportunity cost**
   - Capital locked in bond for 5+ days
   - If disputed, locked even longer (escalates to weeks)
   - Could have earned more by proposing truth elsewhere

4. **Reputation damage**
   - Proposer addresses are public on-chain
   - Pattern of false proposals → community blacklist
   - Future proposals may be auto-disputed by bots
   - Can't reuse address without stigma

5. **Time cost + stress**
   - Dispute extends resolution (adds 11 days max)
   - Must monitor chain and respond to disputes
   - Coordination overhead, mental load
   - Honest proposers get paid faster (5 days vs 16+ days)

### The Schelling Point Effect

**Schelling Point:** In coordination games, players gravitate toward the most obvious "focal point"

For real-world events:
- "Did the Lakers win?" has ONE obvious, verifiable answer
- All rational actors converge on this answer
- No coordination needed—truth is self-evident

**Example:**
- Event: 2024 US Presidential Election
- 100 people can propose the outcome
- All 100 have access to same information (news, official results)
- 99 will propose correct outcome
- 1 false proposer gets immediately disputed by 99 others

**Economic outcome:**
- 99 proposers race to be FIRST (only first gets reward)
- Fastest honest proposer wins
- False proposer loses bond to first disputer
- System self-corrects instantly

---

## Why Disputers Correct False Claims

### Economic Motivation

**Profit from disputing false Round 1 claims:**
- Proposer posts false "YES" + 20k bond (Round 1)
- You post "NO" + 60k bond (Round 2, correct)
- Liveness expires without further dispute
- **Your payout:** 60k (your bond back) + 20k (their slashed bond) + 50% market fees
- **Your cost:** 60k bond (returned)
- **Your profit:** 20k+ sats (pure profit from slashing + fees)

**Even better at higher rounds:**
- If you dispute false Round 2 with correct Round 3:
  - You earn: 180k (bond back) + 80k (cumulative slashed bonds) + fees
  - Profit: 80k+ sats
- If you dispute false Round 3 with correct Round 4:
  - You earn: 900k (bond back) + 260k (cumulative slashed) + fees
  - Profit: 260k+ sats

**Risk-free profit** when:
1. False claim is obvious (clear evidence: sports results, election outcomes, etc.)
2. You're confident community will agree with truth
3. Low coordination cost (one transaction to dispute)
4. Outcome is verifiable (Schelling point)

### Dispute Economics Table

| Round | False Proposal Bond | Your Dispute Bond | Cumulative Slashed | Your Profit if Correct | Your Loss if Wrong |
|-------|---------------------|-------------------|-------------------|------------------------|-------------------|
| 1→2 | 20k sats | 60k sats | 20k | 20k + fees | -60k |
| 2→3 | 60k sats | 180k sats | 80k | 80k + fees | -180k |
| 3→4 | 180k sats | 900k sats | 260k | 260k + fees | -900k |
| 4→vote | 900k sats | Voting (no bond) | 1,160k | 1.16M + fees | -0 (just vote) |

**Key insights:**
1. **Higher rounds = higher profit:** Disputing later rounds is MORE lucrative
2. **First-mover advantage:** First disputer at each round earns slashing bonus
3. **Scales with attack severity:** The bigger the lie (higher round), the bigger the profit
4. **Community depth:** If whale tries to push false claim, community can collectively outspend them

---

## Defense Against "No-Dispute" Tragedy of Commons

### The Critical Problem

**Scenario:** Lakers win NBA Championship (truth = YES)
- Attacker proposes "NO" (false) + 20k bond
- 50 shareholders hold YES shares (would lose if NO wins)
- Each thinks: "Someone else will dispute, I'll save my 60k bond"
- 5 days pass, no one disputes
- **Attacker wins by default**, market resolves incorrectly

**Root cause:** Individual cost to act > individual benefit, even though collective benefit > collective cost (tragedy of commons)

### Why Simple Solutions Don't Work

❌ **Priority window for shareholders:** Still optional, they can choose not to act
❌ **Insurance auto-disputes:** Can't distinguish honest vs dishonest proposals
❌ **Slashing non-disputers:** Can't prove outcome was wrong without human verification
❌ **Pre-commitments:** Still requires humans to follow through

**The hard truth:** Only humans can verify real-world events. We must make humans WANT to act.

### 4-Layer Defense System

Each layer is an independent safeguard. Failure requires ALL 4 to fail simultaneously.

---

## Layer 1: First-Mover Advantage (Creates Race to Dispute)

**Mechanism:** Winner-take-all reward for first disputer

**Problem it solves:** Transforms cooperation problem into competition problem

```clarity
;; Only FIRST disputer gets full reward
;; No sharing, no second place

(define-map dispute-claims
  {market-id: uint, round: uint}
  {
    first-disputer: (optional principal),
    claimed-at: uint,
    reward-amount: uint,
  }
)

(define-public (assert-outcome
    (market-id uint)
    (outcome bool)
  )
  (begin
    ;; Standard dispute logic...
    (let ((current-round (get-current-round market-id))
          (next-round (+ current-round u1)))

      ;; Check: Is this the FIRST dispute for next round?
      (let ((existing (map-get? dispute-claims
                        {market-id: market-id, round: next-round})))

        (if (is-none existing)
          ;; YES! First disputer - claim the reward
          (begin
            (map-set dispute-claims
              {market-id: market-id, round: next-round}
              {
                first-disputer: (some tx-sender),
                claimed-at: burn-block-height,
                reward-amount: (calculate-total-reward market-id current-round),
              })

            (print {
              event: "FIRST-DISPUTER-BONUS",
              disputer: tx-sender,
              market-id: market-id,
              reward: (calculate-total-reward market-id current-round),
              message: "Winner takes all - 100% of rewards",
            })

            ;; Continue with dispute...
            (try! (execute-escalation market-id outcome))
            (ok true)
          )
          ;; NO! Someone already disputed - too late
          (err ERR-ALREADY-DISPUTED)
        )
      )
    )
  )
)

;; Calculate winner-take-all reward
(define-read-only (calculate-total-reward
    (market-id uint)
    (current-round uint)
  )
  (let ((round-info (unwrap! (map-get? market-rounds {market-id: market-id})
                             u0)))
    ;; Reward = All slashed bonds from previous rounds + 50% market fees
    (+ (get total-slashed round-info)
       (/ (get-market-fees market-id) u2))
  )
)
```

**Economic Game Theory:**

```
50 shareholders, each holds 2k YES shares

Without first-mover advantage (shared reward):
  "If I wait, others will dispute and I save 60k bond"
  "Reward will be shared anyway, so I get 1/50th whether I act or not"
  Result: Everyone waits → No one acts

With first-mover advantage (winner-take-all):
  "If I act NOW, I get 105k reward ALONE!"
  "If I wait, someone else claims all 105k and I get NOTHING"
  "Even if I lose, at least I tried for huge reward"
  Result: RACE to be first → Someone WILL act

Probability all 50 delay: ~5% (all offline/asleep simultaneously)
```

**Why it works:**
- ✅ Creates urgency (first wins, everyone else loses opportunity)
- ✅ No coordination needed (individual incentive)
- ✅ High redundancy (only 1 of 50 needs to act)
- ✅ Automatic (no setup required)

---

## Layer 2: Professional Watchtower Services

**Mechanism:** Bonded service providers with SLA guarantees

**Problem it solves:** Market participants may all be offline/lazy

```clarity
;; Watchtowers post bonds and promise 24-hour response times
;; They're PAID to watch and SLASHED if they fail

(define-map watchtower-registry
  {watchtower: principal}
  {
    bond-posted: uint,              ;; 100k+ sats staked
    response-sla: uint,             ;; Max blocks to respond
    success-rate: uint,             ;; Historical performance (bps)
    total-markets: uint,
    successful-disputes: uint,
    failed-responses: uint,
    slashed-amount: uint,
  }
)

(define-public (register-as-watchtower
    (bond-amount uint)
    (response-time-blocks uint)
  )
  (begin
    ;; Minimum 100k bond, max 24 hour response time
    (asserts! (>= bond-amount u100000) (err ERR-INSUFFICIENT-BOND))
    (asserts! (<= response-time-blocks u144) (err ERR-SLA-TOO-LONG))

    ;; Lock bond
    (try! (contract-call? .sbtc-token transfer bond-amount
                         tx-sender (as-contract tx-sender) none))

    ;; Register with initial 100% success rate
    (map-set watchtower-registry {watchtower: tx-sender} {
      bond-posted: bond-amount,
      response-sla: response-time-blocks,
      success-rate: u10000,
      total-markets: u0,
      successful-disputes: u0,
      failed-responses: u0,
      slashed-amount: u0,
    })

    (ok true)
  )
)

;; Market creators hire watchtowers at creation
(define-public (hire-watchtower-for-market
    (market-id uint)
    (watchtower principal)
    (payment uint)
  )
  (begin
    ;; Verify watchtower is registered
    (let ((wt-info (unwrap! (map-get? watchtower-registry {watchtower: watchtower})
                            (err ERR-NOT-REGISTERED))))

      ;; Pay watchtower upfront
      (try! (contract-call? .sbtc-token transfer payment
                           tx-sender watchtower none))

      ;; Record assignment
      (map-set watchtower-assignments
        {market-id: market-id, watchtower: watchtower}
        {
          hired-at: burn-block-height,
          payment: payment,
          response-deadline: u0,  ;; Set when proposal made
          responded: false,
          slashable: true,
        })

      (print {
        event: "watchtower-hired",
        market-id: market-id,
        watchtower: watchtower,
        payment: payment,
        sla: (get response-sla wt-info),
      })

      (ok true)
    )
  )
)

;; When proposal made, activate watchtower countdown
(define-private (trigger-watchtower-duties (market-id uint))
  (let ((assignments (get-market-watchtowers market-id)))
    ;; Update each watchtower's deadline
    (map (lambda (wt)
      (let ((sla (get-watchtower-sla (get watchtower wt))))
        (map-set watchtower-assignments
          {market-id: market-id, watchtower: (get watchtower wt)}
          (merge wt {
            response-deadline: (+ burn-block-height sla)
          }))
      )
    ) assignments)
  )
)

;; SLASHING: Anyone can slash non-responsive watchtower
(define-public (slash-non-responsive-watchtower
    (market-id uint)
    (watchtower principal)
  )
  (begin
    (let ((assignment (unwrap! (map-get? watchtower-assignments
                                 {market-id: market-id, watchtower: watchtower})
                               (err ERR-NO-ASSIGNMENT)))
          (wt-info (unwrap! (map-get? watchtower-registry {watchtower: watchtower})
                           (err ERR-NOT-REGISTERED))))

      ;; Verify conditions:
      ;; 1. Deadline passed
      (asserts! (> burn-block-height (get response-deadline assignment))
        (err ERR-DEADLINE-NOT-PASSED))

      ;; 2. Watchtower didn't respond
      (asserts! (not (get responded assignment))
        (err ERR-ALREADY-RESPONDED))

      ;; 3. Market resolved incorrectly (requires off-chain verification)
      ;; For now, allow slashing if deadline passed + no response

      ;; SLASH 10% of bond
      (let ((slash-amount (/ (get bond-posted wt-info) u10)))

        ;; Transfer to whistleblower (caller)
        (try! (as-contract (contract-call? .sbtc-token transfer
                                         (/ slash-amount u2)  ;; 50% to caller
                                         (as-contract tx-sender)
                                         tx-sender
                                         none)))

        ;; Transfer to insurance fund
        (try! (as-contract (contract-call? .sbtc-token transfer
                                         (/ slash-amount u2)  ;; 50% to insurance
                                         (as-contract tx-sender)
                                         (var-get insurance-fund)
                                         none)))

        ;; Update watchtower reputation
        (map-set watchtower-registry {watchtower: watchtower}
          (merge wt-info {
            failed-responses: (+ (get failed-responses wt-info) u1),
            slashed-amount: (+ (get slashed-amount wt-info) slash-amount),
            success-rate: (recalculate-success-rate watchtower),
          }))

        (print {
          event: "watchtower-slashed",
          watchtower: watchtower,
          market-id: market-id,
          slash-amount: slash-amount,
          reason: "failed-to-respond-within-sla",
        })

        (ok slash-amount)
      )
    )
  )
)
```

**Business Model:**

```
Watchtower Economics:

Setup:
- Post 100k sat bond
- Promise 24-hour response
- Run automated monitoring + human review

Revenue per market:
- Paid 5k-10k sats upfront per market
- Watch 50 markets = 250k-500k sats/month

Costs:
- Server infrastructure: ~5k sats/month
- Human oversight (part-time): ~20k sats/month
- Total costs: ~25k sats/month

Profit: 225k-475k sats/month

Risk:
- Miss 1 false claim: -10k slash
- Miss 10 false claims: -100k (lose entire bond)
- Lose reputation: Future income destroyed

Incentive structure: VERY STRONG to perform correctly
```

**Watchtower Operations:**

```javascript
// Example watchtower monitoring bot

class Watchtower {
  async monitorMarket(marketId) {
    // 1. Listen for new proposals
    const proposal = await contract.getProposal(marketId);

    // 2. Verify against external sources
    const truth = await this.verifyEvent(proposal);

    // 3. If false claim detected
    if (proposal.outcome !== truth) {
      // Alert human operator
      await this.alertOperator(marketId);

      // If confirmed false, dispute immediately
      await contract.assertOutcome(marketId, truth);

      // Log for accountability
      await this.log(`Disputed market ${marketId}`);
    }
  }

  async verifyEvent(proposal) {
    // Cross-reference multiple sources
    const sources = [
      await fetch('https://api.espn.com/...'),
      await fetch('https://www.nba.com/...'),
      await fetch('https://www.thescore.com/...'),
    ];

    // Return consensus
    return this.getConsensus(sources);
  }
}
```

**Why it works:**
- ✅ Professional service (like Chainlink nodes)
- ✅ Economic incentive (earn fees + build reputation)
- ✅ Economic penalty (lose bond if fail)
- ✅ Redundancy (multiple watchtowers per market)
- ✅ Automated + human oversight

**Failure probability: ~1%** (all hired watchtowers offline/compromised)

---

## Layer 3: Public Bounty Amplification

**Mechanism:** Time-based reward multiplier attracts wider audience

**Problem it solves:** Even professionals might miss something

```clarity
;; Reward grows exponentially as deadline approaches
;; Attracts progressively wider circles of attention

(define-map amplified-rewards
  {market-id: uint, round: uint}
  {
    base-reward: uint,
    current-multiplier: uint,
    insurance-bonus: uint,
    last-update: uint,
  }
)

(define-read-only (get-current-dispute-reward (market-id uint))
  (let ((assertion (get-current-assertion market-id))
        (round-info (get-current-round-info market-id)))

    (let ((base-reward (+ (get total-slashed round-info)
                         (/ (get-market-fees market-id) u2))))

      ;; Calculate time-based multiplier
      (let ((time-elapsed (- burn-block-height (get assertion-block assertion)))
            (liveness-period (get-liveness-for-round
                              (get current-round round-info))))

        (let ((progress (/ (* time-elapsed u100) liveness-period)))

          ;; Amplification schedule:
          ;; 0-25% progress:   1.0x (base reward)
          ;; 25-50% progress:  1.5x
          ;; 50-75% progress:  2.5x
          ;; 75-100% progress: 5.0x (URGENT!)

          (let ((multiplier (if (< progress u25)
                              u100   ;; 1.0x
                              (if (< progress u50)
                                u150   ;; 1.5x
                                (if (< progress u75)
                                  u250   ;; 2.5x
                                  u500)))))  ;; 5.0x

            ;; After 60% progress, insurance adds bonus
            (let ((bonus (if (>= progress u60)
                           u50000  ;; 50k bonus
                           u0)))

              (ok {
                base: base-reward,
                multiplier: multiplier,
                bonus: bonus,
                total: (+ (/ (* base-reward multiplier) u100) bonus),
              })
            )
          )
        )
      )
    )
  )
)

;; Insurance adds bonus after 60% of liveness
(define-public (insurance-amplify-bounty (market-id uint))
  (begin
    (let ((progress (get-time-progress market-id)))

      ;; Check 60% threshold
      (asserts! (>= progress u60) (err ERR-TOO-EARLY))

      ;; Add 50k from insurance fund
      (let ((current-reward (unwrap! (get-current-dispute-reward market-id)
                                     (err ERR-NO-REWARD))))

        (var-set insurance-fund-balance
          (- (var-get insurance-fund-balance) u50000))

        (map-set amplified-rewards
          {market-id: market-id, round: (get-current-round market-id)}
          {
            base-reward: (get base current-reward),
            current-multiplier: (get multiplier current-reward),
            insurance-bonus: u50000,
            last-update: burn-block-height,
          })

        ;; BROADCAST URGENT ALERT
        (print {
          event: "URGENT-BOUNTY-AMPLIFIED",
          market-id: market-id,
          base-reward: (get base current-reward),
          multiplier: "5x",
          insurance-bonus: u50000,
          total-reward: (get total current-reward),
          message: "⚠️ MASSIVE REWARD - DISPUTE NOW ⚠️",
          progress: progress,
        })

        (ok (get total current-reward))
      )
    )
  )
)
```

**Reward Escalation Example:**

```
Round 1 false "NO" proposal:
Base reward: 20k (slashed bond) + 25k (market fees) = 45k

Hour 0-30 (0-25% liveness):
  Reward: 45k × 1.0 = 45k
  Audience: Market participants (50 people)

Hour 30-60 (25-50%):
  Reward: 45k × 1.5 = 67.5k
  Audience: + Professional watchtowers (3 services)

Hour 60-90 (50-75%):
  Reward: 45k × 2.5 = 112.5k
  + Insurance bonus: 50k
  = 162.5k total
  Audience: + Crypto Twitter bounty hunters (1000s)

Hour 90-120 (75-100%):
  Reward: 45k × 5.0 = 225k
  + Insurance bonus: 50k
  = 275k total!
  Audience: + Reddit, Discord, wider crypto community (10,000s)

Compare to attacker's bond: 20k
Compare to manipulation profit: ~50k
Bounty is 5.5x the attacker's potential gain!
```

**Social Amplification:**

```
Tweet example (auto-posted by monitoring bot):

🚨 URGENT BOUNTY ALERT 🚨

Market: "Will Lakers win NBA Finals?"
False claim detected: NO (Lakers DID win)

REWARD: 275,000 sats ($275 at $100k BTC)
Risk: 60,000 sats bond
Profit: 215,000 sats PURE PROFIT

Requirements:
✅ Can verify Lakers won (watch game/check news)
✅ Post 60k sat bond
✅ Be FIRST to dispute

Easy money! 🚀

Contract: [link]
Evidence: [NBA.com official results]

RT for visibility! ⚡
```

**Why it works:**
- ✅ Growing reward attracts progressively more attention
- ✅ Social media virality (huge bounty = clicks)
- ✅ Extremely wide net (thousands of potential actors)
- ✅ Eventually reward >> any plausible manipulation profit

**Failure probability: ~0.5%** (no one on entire internet claims 275k bounty)

---

## Layer 4: Insurance-Funded Emergency Watchtowers

**Mechanism:** Last-resort professional verification with heavy penalties

**Problem it solves:** All organic + paid actors somehow failed

```clarity
;; After 80% of liveness with no dispute,
;; Insurance automatically hires emergency response team

(define-map emergency-watchtowers
  {market-id: uint, round: uint}
  (list 3 {
    watchtower: principal,
    hired-at: uint,
    payment: uint,
    deadline: uint,
    responded: bool,
  })
)

(define-public (insurance-emergency-protocol (market-id uint))
  (begin
    (let ((progress (get-time-progress market-id)))

      ;; EMERGENCY THRESHOLD: 80% of liveness
      (asserts! (>= progress u80) (err ERR-TOO-EARLY))

      ;; Check no dispute yet
      (asserts! (is-none (get-next-round-assertion market-id))
        (err ERR-ALREADY-DISPUTED))

      ;; Check market is significant (>50k vault)
      (let ((market (unwrap! (get-market market-id) (err ERR-NO-MARKET))))
        (asserts! (> (get vault-sbtc market) u50000)
          (err ERR-MARKET-TOO-SMALL))

        ;; Get top 3 rated watchtowers
        (let ((top-watchtowers (get-top-rated-watchtowers u3)))

          ;; Hire all 3 with EMERGENCY PAYMENT
          (let ((assignments
                  (map (lambda (wt)
                    {
                      watchtower: wt,
                      hired-at: burn-block-height,
                      payment: u20000,  ;; 20k each!
                      deadline: (+ burn-block-height u24),  ;; 4 hours!
                      responded: false,
                    }
                  ) top-watchtowers)))

            ;; Pay each watchtower from insurance fund
            (map (lambda (assignment)
              (try! (as-contract (contract-call? .sbtc-token transfer
                                               u20000
                                               (as-contract tx-sender)
                                               (get watchtower assignment)
                                               none)))
            ) assignments)

            ;; Record assignments
            (map-set emergency-watchtowers
              {market-id: market-id, round: (get-current-round market-id)}
              assignments)

            ;; CRITICAL ALERT
            (print {
              event: "🚨 EMERGENCY WATCHTOWERS ACTIVATED 🚨",
              market-id: market-id,
              watchtowers: top-watchtowers,
              payment-each: u20000,
              total-paid: u60000,
              deadline: "4 HOURS",
              penalty-if-fail: u50000,
              severity: "CRITICAL - FINAL SAFEGUARD",
              message: "Professional verification required IMMEDIATELY",
            })

            (ok top-watchtowers)
          )
        )
      )
    )
  )
)

;; Emergency watchtowers submit verification
(define-public (emergency-verification-response
    (market-id uint)
    (claim-is-correct bool)
    (evidence-url (string-utf8 256))
  )
  (begin
    ;; Check caller is assigned emergency watchtower
    (let ((assignments (unwrap! (map-get? emergency-watchtowers
                                  {market-id: market-id,
                                   round: (get-current-round market-id)})
                                (err ERR-NOT-ASSIGNED))))

      ;; Find this watchtower in assignments
      (let ((my-assignment (unwrap! (find-watchtower-assignment
                                      tx-sender assignments)
                                    (err ERR-NOT-ASSIGNED))))

        ;; Check within deadline
        (asserts! (< burn-block-height (get deadline my-assignment))
          (err ERR-DEADLINE-PASSED))

        ;; Record response
        (map-set emergency-responses
          {market-id: market-id, watchtower: tx-sender}
          {
            claim-is-correct: claim-is-correct,
            evidence: evidence-url,
            responded-at: burn-block-height,
            watchtower-reputation: (get-watchtower-success-rate tx-sender),
          })

        ;; Update assignment
        (update-assignment-responded market-id tx-sender)

        ;; Check if we have consensus (2 of 3 responses)
        (let ((all-responses (get-all-emergency-responses market-id)))

          (if (>= (len all-responses) u2)
            ;; We have enough responses - check consensus
            (let ((false-votes (count-votes all-responses false))
                  (true-votes (count-votes all-responses true)))

              ;; If 2+ say "claim is FALSE", execute dispute
              (if (>= false-votes u2)
                (begin
                  ;; Consensus: Claim is FALSE
                  ;; Insurance fund posts dispute bond
                  (let ((required-bond (get-required-bond-for-next-round market-id)))

                    (try! (insurance-fund-dispute
                            market-id
                            (not (get outcome (get-current-assertion market-id)))))

                    (print {
                      event: "emergency-consensus-dispute",
                      market-id: market-id,
                      decision: "CLAIM IS FALSE - DISPUTING",
                      votes-false: false-votes,
                      votes-true: true-votes,
                      evidence: (map get evidence all-responses),
                    })

                    (ok true)
                  )
                )
                ;; If 2+ say "claim is TRUE", do nothing
                (if (>= true-votes u2)
                  (begin
                    (print {
                      event: "emergency-consensus-accept",
                      market-id: market-id,
                      decision: "CLAIM IS CORRECT - NO DISPUTE",
                      votes-true: true-votes,
                      votes-false: false-votes,
                    })
                    (ok false)
                  )
                  ;; Split vote (1-1 with 1 pending)
                  (ok false)
                )
              )
            )
            ;; Not enough responses yet
            (ok false)
          )
        )
      )
    )
  )
)

;; HEAVY SLASHING for emergency non-response
(define-public (slash-emergency-watchtower
    (market-id uint)
    (watchtower principal)
  )
  (begin
    (let ((assignments (unwrap! (map-get? emergency-watchtowers
                                  {market-id: market-id,
                                   round: (get-current-round market-id)})
                                (err ERR-NO-ASSIGNMENT))))

      (let ((assignment (unwrap! (find-watchtower-assignment watchtower assignments)
                                (err ERR-NOT-ASSIGNED))))

        ;; Check deadline passed
        (asserts! (> burn-block-height (get deadline assignment))
          (err ERR-DEADLINE-NOT-PASSED))

        ;; Check didn't respond
        (asserts! (not (get responded assignment))
          (err ERR-ALREADY-RESPONDED))

        ;; HEAVY SLASH: 50% of bond (50k if 100k bond)
        ;; This is 5x normal slashing because emergency duty
        ;; was the LAST LINE OF DEFENSE

        (let ((wt-info (unwrap! (map-get? watchtower-registry {watchtower: watchtower})
                               (err ERR-NOT-REGISTERED))))

          (let ((slash-amount (/ (get bond-posted wt-info) u2)))  ;; 50%!

            ;; Transfer to insurance fund (replenish what was spent)
            (try! (as-contract (contract-call? .sbtc-token transfer
                                             slash-amount
                                             (as-contract tx-sender)
                                             (var-get insurance-fund)
                                             none)))

            ;; Destroy reputation
            (map-set watchtower-registry {watchtower: watchtower}
              (merge wt-info {
                failed-responses: (+ (get failed-responses wt-info) u1),
                slashed-amount: (+ (get slashed-amount wt-info) slash-amount),
                success-rate: u0,  ;; Set to ZERO - unreliable
              }))

            (print {
              event: "EMERGENCY-WATCHTOWER-SLASHED",
              watchtower: watchtower,
              market-id: market-id,
              slash-amount: slash-amount,
              severity: "CRITICAL FAILURE",
              reason: "failed-emergency-duty-last-defense",
              reputation-destroyed: true,
            })

            (ok slash-amount)
          )
        )
      )
    )
  )
)
```

**Emergency Protocol Timeline:**

```
Day 1-4: Normal operations (Layer 1-3 active)
  ↓
Day 4, Hour 19 (80% of 5-day liveness):
  🚨 EMERGENCY PROTOCOL ACTIVATED 🚨
  ↓
Insurance hires 3 emergency watchtowers:
  - @StacksGuardian (rep: 99%, 200 successful disputes)
  - @OracleDefender (rep: 98%, 150 successful disputes)
  - @CryptoVeritas (rep: 97%, 180 successful disputes)
  ↓
Payment: 20k sats each (60k total from insurance)
Deadline: 4 hours
Penalty: 50k slash if no response
  ↓
Watchtowers investigate:

  @StacksGuardian checks:
    ✓ NBA.com official results
    ✓ ESPN game summary
    ✓ YouTube game footage
    → Verdict: "Claim is FALSE" (evidence: [URLs])

  @OracleDefender checks:
    ✓ TheScore.com
    ✓ Twitter #NBAFinals trending
    ✓ Multiple news sources
    → Verdict: "Claim is FALSE" (evidence: [URLs])

  @CryptoVeritas checks:
    ✓ Official NBA API
    ✓ Sports betting outcomes
    ✓ Player post-game interviews
    → Verdict: "Claim is FALSE" (evidence: [URLs])
  ↓
Consensus: 3 of 3 vote "FALSE"
  ↓
Insurance fund posts 60k dispute bond for Round 2
  ↓
Round 2 begins with massive attention
  ↓
Community sees emergency dispute → Trust maintained
  ↓
Market resolves correctly in Round 2
```

**Why this MUST work:**
- ✅ Professional watchtowers with proven track records
- ✅ HUGE payment for minimal work (20k for 2 hours)
- ✅ MASSIVE penalty if they fail (50k slash)
- ✅ Reputation destruction = loss of future income
- ✅ 3-of-3 redundancy (all must fail for system to fail)
- ✅ 4-hour deadline (urgent, can't ignore)
- ✅ They're HUMANS who CAN verify real-world events

**Failure scenarios:**
1. **All 3 bribed:** Requires >150k bribe (more than manipulation profit) + reputation suicide
2. **All 3 offline:** Requires simultaneous infrastructure failure of 3 independent services
3. **All 3 compromised:** Requires coordinated attack on known, doxxed professionals

**Failure probability: ~0.01%** (essentially impossible for obvious events)

---

## Cumulative Defense Analysis

### Failure Probability Calculation

```
Layer 1 (First-Mover Race):
  P(fail) = P(all 50 shareholders offline/lazy)
  = 0.05 (5%)

Layer 2 (Professional Watchtowers):
  P(fail | Layer 1 failed) = P(all 2-3 hired watchtowers fail)
  = 0.01 (1%)

Layer 3 (Bounty Amplification):
  P(fail | Layers 1-2 failed) = P(no one claims 275k reward)
  = 0.005 (0.5%)

Layer 4 (Emergency Watchtowers):
  P(fail | Layers 1-3 failed) = P(all 3 emergency pros fail/bribed)
  = 0.0001 (0.01%)

Total failure probability:
P(all 4 fail) = 0.05 × 0.01 × 0.005 × 0.0001
              = 0.0000000025
              = 0.00000025%
              = 1 in 400,000,000
```

**For obvious, verifiable events (sports, elections), system failure is mathematically improbable.**

### Attack Cost Analysis

```
To successfully attack (make all 4 layers fail):

Layer 1: Coordinate with 50 shareholders
  Cost: Bribe all 50 to not dispute
  Minimum: 50 × 105k = 5.25M sats
  (Each shareholder giving up 105k reward)

Layer 2: Compromise 2-3 watchtowers
  Cost: Bribe + compensate for slashing + reputation loss
  Minimum: 3 × (100k bond + 50k future income) = 450k sats

Layer 3: Suppress social media bounty hunters
  Cost: Impossible (can't bribe thousands of anonymous actors)
  Minimum: Infinite

Layer 4: Compromise 3 emergency watchtowers
  Cost: Bribe + compensate for 50k slash + reputation suicide
  Minimum: 3 × (50k + 500k lifetime income) = 1.65M sats

Total minimum attack cost: >7M sats ($7,000+ USD)
Typical manipulation profit: ~50k sats ($50 USD)

Attack profitability: NEVER
```

### Layer Independence

```
                    ┌──────────────┐
                    │  Event       │
                    │  Occurs      │
                    └───────┬──────┘
                            │
                    ┌───────▼───────────┐
                    │  False Proposal   │
                    │  Posted           │
                    └───────┬───────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    ┌───▼───┐         ┌─────▼─────┐      ┌────▼────┐
    │Layer 1│         │  Layer 2  │      │ Layer 3 │
    │ Race  │         │Watchtowers│      │ Bounty  │
    │to Win │         │  (SLA)    │      │Growing  │
    └───┬───┘         └─────┬─────┘      └────┬────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                  (if all 3 fail)
                            │
                    ┌───────▼─────────┐
                    │   Layer 4       │
                    │   Emergency     │
                    │   Protocol      │
                    └───────┬─────────┘
                            │
                  ┌─────────▼──────────┐
                  │ Dispute Executed   │
                  │ Market Saved       │
                  └────────────────────┘

Each layer operates independently.
Failure requires SIMULTANEOUS failure of all 4.
```

---

## Implementation Priority

**Phase 1 (Launch):** Must-have
- ✅ Layer 1: First-mover advantage
- ✅ Layer 4: Emergency watchtowers (insurance backstop)

**Phase 2 (Month 2-3):** Recommended
- ✅ Layer 2: Watchtower marketplace
- ✅ Layer 3: Bounty amplification

**Rationale:** Layers 1 + 4 provide 99.9%+ security. Layers 2 + 3 add defense-in-depth and reduce insurance costs.

---

## Implementation Specification

### Contract: `optimistic-oracle-v1.clar`

#### Data Structures

```clarity
;; Map of assertions (one per market-round pair)
;; Each dispute creates a new assertion in the next round
(define-map assertions
  {market-id: uint, round: uint}
  {
    asserter: principal,              ;; who made this assertion
    outcome: bool,                    ;; true=YES, false=NO
    bond-amount: uint,                ;; sBTC staked for this round
    assertion-block: uint,            ;; when asserted
    liveness-expiry: uint,            ;; assertion-block + liveness period
    status: (string-ascii 10),        ;; "active", "disputed", "finalized"
  }
)

;; Track current round for each market
(define-map market-rounds
  {market-id: uint}
  {
    current-round: uint,              ;; Which round we're on (1-4)
    total-slashed: uint,              ;; Cumulative bonds slashed (pot for winner)
    final-outcome: (optional bool),   ;; Set when finalized
  }
)

;; Escalation configuration per round
(define-map round-config
  {round: uint}
  {
    required-bond: uint,              ;; Minimum bond for this round
    liveness-blocks: uint,            ;; How long to wait
    next-multiplier: uint,            ;; Multiplier to next round bond
  }
)

;; Initialize round configuration (done in contract deployment)
;; Round 1: 20k bond, 720 blocks (~5 days), 3x to next
;; Round 2: 60k bond, 432 blocks (~3 days), 3x to next
;; Round 3: 180k bond, 288 blocks (~2 days), 5x to next
;; Round 4: 900k bond, 144 blocks (~1 day), FINAL

(map-set round-config {round: u1} {
  required-bond: u20000,
  liveness-blocks: u720,
  next-multiplier: u3,
})

(map-set round-config {round: u2} {
  required-bond: u60000,
  liveness-blocks: u432,
  next-multiplier: u3,
})

(map-set round-config {round: u3} {
  required-bond: u180000,
  liveness-blocks: u288,
  next-multiplier: u5,
})

(map-set round-config {round: u4} {
  required-bond: u900000,
  liveness-blocks: u144,
  next-multiplier: u0,  ;; No next round (final)
})

;; Constants
(define-constant MAX-ROUNDS u4)         ;; Maximum 4 rounds before voting
(define-constant FEE-SHARE-BPS u5000)   ;; Proposer gets 50% of market fees
```

#### Function: `assert-outcome` (replaces `propose-outcome`)

```clarity
;; Can be called for Round 1 (initial proposal) or any round (escalation)
(define-public (assert-outcome
    (market-id uint)
    (outcome bool)
  )
  (begin
    ;; 1. Determine current round (1 if first assertion, else next round)
    (let ((round-info (default-to
                        {current-round: u0, total-slashed: u0, final-outcome: none}
                        (map-get? market-rounds {market-id: market-id}))))

      (let ((current-round (get current-round round-info))
            (next-round (if (is-eq current-round u0) u1 (+ current-round u1))))

        ;; 2. Validate we haven't exceeded max rounds
        (asserts! (<= next-round MAX-ROUNDS) (err ERR-MAX-ROUNDS-EXCEEDED))

        ;; 3. Get round configuration
        (let ((config (unwrap! (map-get? round-config {round: next-round})
                               (err ERR-INVALID-ROUND))))

          (let ((required-bond (get required-bond config))
                (liveness (get liveness-blocks config)))

            ;; 4. Validate market exists and is awaiting resolution
            (let ((market (unwrap! (contract-call? .sbtcmarket-v0 get-market market-id)
                                   (err ERR-NO-MARKET))))
              ;; Market must be past resolution block
              (asserts! (>= burn-block-height (get resolution-block market))
                (err ERR-TOO-EARLY))
              ;; Market must not be already resolved
              (asserts! (not (get resolved market))
                (err ERR-ALREADY-RESOLVED))

              ;; 5. If this is escalation (round > 1), validate previous round was disputed
              (if (> next-round u1)
                (let ((prev-assertion (unwrap! (map-get? assertions
                                                 {market-id: market-id, round: current-round})
                                               (err ERR-NO-PREVIOUS-ASSERTION))))
                  ;; Previous must still be within liveness period
                  (asserts! (< burn-block-height (get liveness-expiry prev-assertion))
                    (err ERR-PREVIOUS-LIVENESS-EXPIRED))

                  ;; Mark previous assertion as disputed
                  (map-set assertions {market-id: market-id, round: current-round}
                    (merge prev-assertion {status: "disputed"}))

                  ;; Slash previous asserter's bond (add to pot)
                  (let ((new-total-slashed (+ (get total-slashed round-info)
                                             (get bond-amount prev-assertion))))
                    (map-set market-rounds {market-id: market-id}
                      (merge round-info {
                        current-round: next-round,
                        total-slashed: new-total-slashed,
                      }))
                  )
                )
                ;; First round: Initialize market-rounds
                (map-set market-rounds {market-id: market-id} {
                  current-round: u1,
                  total-slashed: u0,
                  final-outcome: none,
                })
              )

              ;; 6. Lock bond (transfer sBTC to oracle contract)
              (try! (contract-call? .sbtc-token transfer required-bond tx-sender
                                   (as-contract tx-sender) none))

              ;; 7. Create new assertion
              (map-set assertions {market-id: market-id, round: next-round}
                {
                  asserter: tx-sender,
                  outcome: outcome,
                  bond-amount: required-bond,
                  assertion-block: burn-block-height,
                  liveness-expiry: (+ burn-block-height liveness),
                  status: "active",
                }
              )

              (print {
                event: "outcome-asserted",
                market-id: market-id,
                round: next-round,
                outcome: outcome,
                asserter: tx-sender,
                bond: required-bond,
                liveness-expiry: (+ burn-block-height liveness),
              })
              (ok next-round)
            )
          )
        )
      )
    )
  )
)
```

#### Function: `finalize-outcome`

```clarity
;; Finalize outcome after liveness period expires without dispute
;; Can be called by anyone after liveness expiry
(define-public (finalize-outcome (market-id uint))
  (begin
    ;; 1. Load current round info
    (let ((round-info (unwrap! (map-get? market-rounds {market-id: market-id})
                               (err ERR-NO-ASSERTION))))

      (let ((current-round (get current-round round-info))
            (total-slashed (get total-slashed round-info)))

        ;; 2. Load current round's assertion
        (let ((assertion (unwrap! (map-get? assertions
                                   {market-id: market-id, round: current-round})
                                  (err ERR-NO-ASSERTION))))

          ;; 3. Validate liveness has expired
          (asserts! (>= burn-block-height (get liveness-expiry assertion))
            (err ERR-LIVENESS-NOT-EXPIRED))

          ;; 4. Validate assertion is still active (not disputed)
          (asserts! (is-eq (get status assertion) "active")
            (err ERR-WAS-DISPUTED))

          ;; 5. Mark as finalized
          (map-set assertions {market-id: market-id, round: current-round}
            (merge assertion {status: "finalized"}))

          (map-set market-rounds {market-id: market-id}
            (merge round-info {final-outcome: (some (get outcome assertion))}))

          ;; 6. Resolve market with finalized outcome
          (try! (contract-call? .sbtcmarket-v0 set-oracle-resolution
                                market-id (get outcome assertion)))

          ;; 7. Calculate payout (bond + all slashed bonds + market fees)
          (let ((market-fees (try! (calculate-market-fees market-id)))
                (total-payout (+ (get bond-amount assertion)
                                total-slashed
                                market-fees)))

            ;; 8. Pay out winner
            (try! (as-contract (contract-call? .sbtc-token transfer total-payout
                                              (as-contract tx-sender)
                                              (get asserter assertion)
                                              none)))

            (print {
              event: "outcome-finalized",
              market-id: market-id,
              final-round: current-round,
              outcome: (get outcome assertion),
              winner: (get asserter assertion),
              payout: total-payout,
              slashed-bonds: total-slashed,
              market-fees: market-fees,
            })
            (ok total-payout)
          )
        )
      )
    )
  )
)

;; Helper function to calculate market fees allocated to oracle
(define-private (calculate-market-fees (market-id uint))
  (match (contract-call? .sbtcmarket-v0 get-market-fees market-id)
    fees (ok (/ (* (+ (get fees-yes fees) (get fees-no fees)) FEE-SHARE-BPS)
                   u10000))
    err-code (err err-code)
  )
)
```

---

## Integration with sbtcmarket-v0

### Changes to `sbtcmarket-v0.clar`

#### 1. Add oracle type field to markets

```clarity
(define-map markets
  {id: uint}
  {
    ;; ... existing fields ...
    oracle-type: (string-ascii 10),  ;; "pyth" or "optimistic"
    ;; ... rest of fields ...
  }
)
```

#### 2. Add new resolution function

```clarity
;; Called by optimistic-oracle-v1 to set final outcome
(define-public (set-oracle-resolution
    (market-id uint)
    (outcome bool)
  )
  (begin
    ;; Only optimistic oracle can call this
    (asserts! (is-eq tx-sender (contract-of .optimistic-oracle-v1))
      (err ERR-UNAUTHORIZED))

    (let ((market (unwrap! (map-get? markets {id: market-id})
                           (err ERR-NO-MARKET))))

      ;; Ensure market uses optimistic oracle
      (asserts! (is-eq (get oracle-type market) "optimistic")
        (err ERR-WRONG-ORACLE-TYPE))

      ;; Ensure not already resolved
      (asserts! (not (get resolved market))
        (err ERR-ALREADY-RESOLVED))

      ;; Set resolution
      (map-set markets {id: market-id}
        (merge market {
          resolved: true,
          outcome: (some outcome),
        })
      )

      (print {
        event: "market-resolved-by-oracle",
        market-id: market-id,
        outcome: outcome,
        oracle: "optimistic",
      })
      (ok true)
    )
  )
)
```

#### 3. Update create-market to support both oracle types

```clarity
(define-public (create-market
    (question (string-utf8 256))
    (resolution-block uint)
    (oracle-type (string-ascii 10))   ;; NEW: "pyth" or "optimistic"
    (feed-id (optional (buff 32)))    ;; Optional: only for pyth markets
    (threshold-price (optional int))  ;; Optional: only for pyth markets
    (comparison-type (optional (string-utf8 2))) ;; Optional: only for pyth
    (virtual-liquidity uint)
    (fee-bps uint)
  )
  (begin
    ;; Validation
    (asserts! (or (is-eq oracle-type "pyth") (is-eq oracle-type "optimistic"))
      (err ERR-INVALID-ORACLE-TYPE))

    ;; If pyth, require feed-id/threshold/comparison
    ;; If optimistic, these should be none

    (let ((id (claim-market-id)))
      (map-set markets {id: id} {
        question: question,
        resolution-block: resolution-block,
        oracle-type: oracle-type,
        threshold-feed-id: (default-to 0x00... feed-id),
        threshold-price: (default-to 0 threshold-price),
        comparison-type: (default-to u"" comparison-type),
        ;; ... rest of fields ...
      })
      (ok id)
    )
  )
)
```

---

## Testing Strategy

### Test Categories

#### 1. Happy Path Tests
```typescript
describe("Optimistic Oracle - Happy Path", () => {
  it("should accept undisputed proposal after liveness", async () => {
    // 1. Create optimistic market
    // 2. Event occurs (simulated)
    // 3. Alice proposes outcome + bond
    // 4. Wait 432 blocks
    // 5. Finalize (no disputes)
    // 6. Assert: Market resolved, Alice gets bond + reward
  });
});
```

#### 2. Dispute Tests
```typescript
describe("Optimistic Oracle - Disputes", () => {
  it("should allow dispute during liveness period", async () => {
    // 1. Alice proposes "YES" (false)
    // 2. Bob disputes "NO" (correct)
    // 3. Multi-sig resolves to "NO"
    // 4. Assert: Bob gets both bonds, Alice loses bond
  });

  it("should reject disputes after liveness expires", async () => {
    // 1. Alice proposes "YES"
    // 2. Wait 433 blocks (past expiry)
    // 3. Bob tries to dispute
    // 4. Assert: Transaction fails with ERR-LIVENESS-EXPIRED
  });

  it("should handle multiple dispute attempts", async () => {
    // 1. Alice proposes "YES"
    // 2. Bob disputes "NO"
    // 3. Charlie tries to dispute "NO"
    // 4. Assert: Charlie's dispute rejected (already disputed)
  });
});
```

#### 3. Economic Security Tests
```typescript
describe("Optimistic Oracle - Economic Security", () => {
  it("should require minimum bond", async () => {
    // 1. Alice tries to propose with 1000 sats (< 10k min)
    // 2. Assert: Transaction fails with ERR-INSUFFICIENT-BOND
  });

  it("should require 2x bond for disputes", async () => {
    // 1. Alice proposes with 10k bond
    // 2. Bob tries to dispute with 10k bond (should be 20k)
    // 3. Assert: Transaction fails
  });

  it("should scale bond requirements for large markets", async () => {
    // 1. Create market with 1M sats vault
    // 2. Try to propose with 10k bond
    // 3. Assert: Fails (requires 200k = 20% of vault)
  });
});
```

#### 4. Integration Tests
```typescript
describe("Optimistic Oracle - Integration with Market", () => {
  it("should resolve market when proposal finalized", async () => {
    // 1. Create optimistic market
    // 2. Propose + finalize outcome
    // 3. Assert: Market status = resolved
    // 4. User redeems winning shares
    // 5. Assert: User receives correct payout
  });

  it("should distribute fees to oracle participants", async () => {
    // 1. Market accumulates 100k sats in fees
    // 2. Alice proposes (correct)
    // 3. Finalize
    // 4. Assert: Alice receives 50k sats (50% of fees) + bond
    // 5. Assert: Treasury receives 50k sats
  });
});
```

#### 5. Attack Resistance Tests
```typescript
describe("Optimistic Oracle - Attack Resistance", () => {
  it("should punish false proposals", async () => {
    // 1. Alice proposes false outcome
    // 2. Bob disputes (correct)
    // 3. Arbitrate
    // 4. Assert: Alice loses bond, Bob profits
  });

  it("should punish frivolous disputes", async () => {
    // 1. Alice proposes correct outcome
    // 2. Mallory disputes (incorrect)
    // 3. Arbitrate
    // 4. Assert: Mallory loses 2x bond
  });

  it("should prevent duplicate proposals", async () => {
    // 1. Alice proposes "YES"
    // 2. Bob tries to propose "NO"
    // 3. Assert: Bob's proposal rejected
  });
});
```

---

## Deployment Roadmap

### Phase 1: Testnet Launch (Month 1-2)
**Objective:** Test the multi-round escalation system in live conditions

**Actions:**
- Deploy `optimistic-oracle-v1.clar` to testnet (Stacks testnet)
- Deploy updated `sbtcmarket-v0.clar` with dual oracle support
- Create test markets for real events:
  - Sports games (NBA, NFL)
  - Cryptocurrency price milestones
  - Public company earnings reports (verifiable)
- Run simulated attacks:
  - False proposals
  - Multi-round disputes
  - Griefing attempts
- Bug bounty program: 10k-100k testnet tokens for finding bugs

**Conservative testnet parameters:**
```
Round 1: 50k sats bond, 7 days liveness (1008 blocks)
Round 2: 150k sats, 5 days
Round 3: 450k sats, 3 days
Round 4: 2M sats, 1 day
```

**Success criteria:**
- 10+ markets successfully resolved
- At least 2 disputed markets (to test escalation)
- Zero critical bugs found
- Gas costs < 500k units per transaction

---

### Phase 2: Mainnet Launch (Month 3-4)
**Objective:** Launch with real incentives and monitor behavior

**Actions:**
- Deploy to Stacks mainnet with production parameters:
  ```
  Round 1: 20k sats bond, 5 days liveness (720 blocks)
  Round 2: 60k sats, 3 days (432 blocks)
  Round 3: 180k sats, 2 days (288 blocks)
  Round 4: 900k sats, 1 day (144 blocks)
  ```
- Start with low-stakes markets:
  - Market vault caps: 100k sats maximum
  - Simple binary outcomes only
  - Short resolution windows (same-day events)
- Restrict market creation to allowlisted creators initially
- Community monitoring:
  - Public dashboard showing all proposals/disputes
  - Alert system for suspicious activity
  - Weekly community calls to review outcomes

**Risk mitigation:**
- Emergency pause mechanism (only for critical bugs)
- 7-day timelock on parameter changes
- Insurance fund (10% of early fees) for potential exploits

---

### Phase 3: Scale & Optimize (Month 5-8)
**Objective:** Increase market sizes and optimize parameters

**Actions:**
- Increase market vault caps to 1M sats
- Open market creation to all authorized creators
- Introduce dynamic bonding based on market size:
  ```clarity
  required-bond = max(
    round-base-bond,
    market-vault * risk-multiplier
  )
  ```
- Add pre-commitment feature:
  - Users can pre-commit bonds to signal they'll dispute
  - Creates credible threat against false claims
- Reputation system:
  - Track proposer/disputer win rates
  - Display reputation scores on-chain
  - Allow filtering by reputation

**Parameter tuning based on data:**
- If disputes are rare (< 5%): Reduce liveness periods
- If spam proposals occur: Increase Round 1 bond
- If escalation never reaches Round 4: Reduce higher round bonds

---

### Phase 4: Advanced Features (Month 9-12)
**Objective:** Add sophisticated features for edge cases

**Actions:**
1. **Conditional bond commitments:**
   ```clarity
   ;; "I'll post 100k bond in Round 3 if outcome X is claimed"
   (define-public (commit-conditional-bond ...))
   ```
   - Allows community to show strength before attack happens
   - Deters false proposals (can see wall of capital ready to fight)

2. **Resolution markets for ambiguous outcomes:**
   - If market reaches Round 4 dispute, trigger meta-market
   - "Will market #123 resolve to YES?" becomes tradable
   - Meta-market price = probability of outcome
   - Use meta-market result to finalize original market

3. **STX voting as final backstop:**
   - Only if Round 4 is disputed (extremely rare)
   - All STX holders can vote (token-weighted)
   - 48-hour voting window
   - Minimum 20% quorum required
   - Implementation:
     ```clarity
     (define-public (emergency-vote market-id outcome)
       ;; Only callable if round 4 disputed
       ;; Uses STX balance as voting weight
     )
     ```

4. **Cross-chain oracle federation:**
   - Accept proposals from other chains (Ethereum UMA, etc.)
   - If Ethereum UMA resolves, can be proposed here
   - Reduces duplicate work across ecosystems

---

### Phase 5: Full Maturity (Year 2+)
**Objective:** Self-sustaining, battle-tested oracle system

**Characteristics:**
- Hundreds of markets resolved monthly
- Zero governance intervention needed
- Parameters tuned based on years of data
- Integration with multiple prediction market protocols
- Oracle-as-a-service for other Stacks contracts
- Potential expansion to other blockchains (via bridges)

---

## Risk Assessment & Mitigations

### Risk 1: Insufficient Economic Deterrent (Bonds Too Low)
**Risk:** Attacker profits from manipulation despite losing bonds
**Impact:** Markets resolve incorrectly, users lose trust
**Probability:** Medium if bonds not calibrated to market size
**Mitigation:**
- Dynamic bonding: Scale with market vault size
  ```clarity
  required-bond = max(base-bond, vault-size * 0.20)
  ```
- Monitor early markets for profitability of attacks
- Adjust multipliers based on real data
- Cap market sizes during early phases (< 100k sats)

**Example:**
- Market vault: 500k sats
- Required Round 1 bond: max(20k, 500k * 0.20) = 100k sats
- Manipulation only profitable if attacker's position > 100k
- Most users won't have > 20% of market → attack unprofitable

### Risk 2: Low Participation (No Proposals)
**Risk:** No one proposes outcomes (lack of incentive)
**Impact:** Markets don't resolve, users can't redeem
**Probability:** Medium for low-fee markets
**Mitigation:**
- Auto-cancellation after 7 days of no proposals
- Users can trigger refund if no resolution
- Increase fee share to oracle (from 50% to 75%)
- Protocol can run "market resolver bot" as backstop

### Risk 3: Oracle Spam (Too Many False Proposals)
**Risk:** Attackers spam false proposals to grief system
**Impact:** Honest disputers must lock capital repeatedly
**Probability:** Low (bonds make spam expensive)
**Mitigation:**
- Blacklist addresses with pattern of false proposals
- Progressive bonding: Require higher bonds for repeat offenders
- Dispute cooldown: Failed disputers wait 1000 blocks
- Community can vote to ban malicious actors

### Risk 4: Evidence Ambiguity
**Risk:** Event outcome is genuinely unclear (e.g., "Will AI be sentient?")
**Impact:** Arbitrators can't reach consensus, disputes drag on
**Probability:** Medium for poorly-worded markets
**Mitigation:**
- Market creation guidelines (require objective criteria)
- Pre-approve market questions before creation
- Implement "invalid" outcome option (refunds everyone)
- Require markets to specify evidence source (e.g., "per ESPN")

### Risk 5: Flash Loan Attack on Bonds
**Risk:** Attacker uses flash loan to post massive bond, manipulate market
**Impact:** Can propose/dispute without real capital risk
**Probability:** Very Low (flash loans don't exist on Stacks yet)
**Mitigation:**
- Require bonds to be locked for minimum 1 block
- Flash loans can't work (need multi-block settlement)
- If flash loans come to Stacks: Add time-lock on bond withdrawal

### Risk 6: Smart Contract Bugs
**Risk:** Vulnerability in contract code (reentrancy, arithmetic overflow, etc.)
**Impact:** Funds lost, system exploited
**Probability:** Medium (Clarity is safer than Solidity, but bugs possible)
**Mitigation:**
- Comprehensive test suite (100+ test cases)
- Professional security audit before mainnet
- Bug bounty program (50k-500k sats rewards)
- Gradual rollout (testnet → small mainnet → full scale)
- Emergency pause for first 6 months
- Clarity's built-in safety (no reentrancy, checked arithmetic)

---

## Comparison: Trustless vs Multi-sig Approaches

### Pure Game Theory (Our Design) vs Multi-sig Arbitration

| Aspect | Multi-sig Arbitration | Pure Game Theory (Ours) |
|--------|----------------------|-------------------------|
| **Trust model** | Requires trusting 3-5 specific people | Trustless (pure economics) |
| **Censorship resistance** | Low (signers can collude) | High (anyone can participate) |
| **Scalability** | Limited (signers bottleneck) | Unlimited (permissionless) |
| **Resolution speed** | Fast (hours to days) | Slower (5-11 days) |
| **Attack cost** | Bribe 3 signers (~150k) | Out-bond community (260k-1.16M) |
| **Governance** | Requires finding/managing signers | Self-governing (no admins) |
| **Failure mode** | Signer compromise | Economic parameters wrong |
| **Long-term viability** | Requires ongoing signer management | Self-sustaining forever |
| **Transparency** | Signer votes (potential bias) | Pure on-chain math (objective) |
| **Complexity** | Simple (just signatures) | Complex (multi-round logic) |

**Our choice:** Trustless from day 1, accepting slower resolution as trade-off for decentralization.

---

## Comparison to Existing Solutions

| Feature | UMA Protocol | Polymarket (UMA) | Our Optimistic Oracle | Gnosis CTF |
|---------|--------------|------------------|----------------------|-----------|
| **Blockchain** | Ethereum/L2s | Polygon | Stacks | Ethereum/L2s |
| **Dispute Resolution** | Token voting (UMA holders) | UMA + human review | Multi-sig → token voting | External oracle |
| **Liveness Period** | 2 hours (default) | Variable | 3 days (longer, safer) | N/A (oracle-dependent) |
| **Bonding** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No built-in |
| **Collateral** | Any ERC-20 | USDC | sBTC only | Any ERC-20 |
| **Integration** | Standalone oracle | Conditional tokens + oracle | Built into market | Token framework only |
| **Governance** | UMA DAO | UMA DAO + Polymarket team | Multi-sig → community | External |
| **Oracle Type** | Generalized | Prediction markets | Prediction markets only | Agnostic (any oracle) |

**Our advantages:**
- ✅ Bitcoin-native (via Stacks + sBTC)
- ✅ Integrated with market contract (simpler UX)
- ✅ Longer liveness period (more security)

**Our disadvantages:**
- ❌ Smaller community (vs Ethereum ecosystem)
- ❌ Less liquidity (sBTC market cap < USDC)
- ❌ New system (UMA has 4+ years of battle-testing)

---

## Conclusion

This optimistic oracle design achieves **true decentralization** through pure economic game theory, requiring NO trusted intermediaries.

### Key Innovations

1. **Trustless from Day 1**
   - No multi-sig, no admin keys, no governance
   - Pure economic incentives align behavior
   - Self-sustaining forever (no maintenance needed)

2. **Multi-Round Escalation**
   - Each dispute costs 3-5x more than previous
   - Eventually becomes unprofitable to lie
   - Economic finality without human arbitration

3. **Schelling Point Convergence**
   - Real-world events have obvious outcomes
   - Community naturally coordinates on truth
   - Lying is provably unprofitable

4. **Scalable Security**
   - Bonds scale with market size
   - Larger markets automatically require larger bonds
   - Attack cost grows with incentive to attack

5. **Bitcoin-Native**
   - Built on Stacks (Bitcoin's L2)
   - Settles in sBTC (Bitcoin-backed asset)
   - Brings prediction markets to Bitcoin ecosystem

### Advantages Over Existing Solutions

**vs UMA Protocol:**
- ✅ No token governance (UMA requires UMA tokens)
- ✅ Multi-round escalation (UMA has single dispute)
- ✅ Bitcoin-native (UMA is Ethereum-only)
- ❌ Slower (5-11 days vs 2 hours)

**vs Polymarket:**
- ✅ Fully decentralized (Polymarket uses UMA + centralized resolution)
- ✅ Open-source, permissionless
- ✅ Bitcoin-settled
- ❌ Smaller user base initially

**vs Multi-sig Oracles:**
- ✅ Trustless (no reliance on specific people)
- ✅ Censorship-resistant (can't be captured)
- ✅ Self-sustaining (no governance overhead)
- ❌ More complex implementation

### Trade-offs Accepted

1. **Slower resolution:** 5-11 days vs instant (multi-sig)
   - **Why acceptable:** Prediction markets don't need instant resolution
   - Users can wait days/weeks to redeem anyway
   - Security > speed for financial applications

2. **Higher capital requirements:** Up to 900k sats for Round 4
   - **Why acceptable:** Most markets resolve in Round 1 (20k bond)
   - Only malicious actors reach higher rounds
   - High cost is the POINT (deters attacks)

3. **More complex implementation:** Multi-round logic vs simple signatures
   - **Why acceptable:** Complexity is manageable in Clarity
   - One-time implementation cost for permanent trustlessness
   - Tests + audits ensure correctness

### Success Metrics

**Year 1:**
- 100+ markets resolved
- < 10% dispute rate
- Zero successful manipulations
- 50+ active proposers/disputers
- $100k+ in total market volume

**Year 2:**
- 1000+ markets resolved
- Integration with 3+ other Stacks protocols
- Oracle-as-a-service for external contracts
- Self-sustaining (no team intervention)

### Next Steps

**Month 1-2: Implementation**
1. Write `optimistic-oracle-v1.clar` (~600 lines of Clarity)
2. Comprehensive test suite (150+ test cases)
3. Cover all attack vectors and edge cases
4. Gas optimization

**Month 3-4: Testing & Audit**
5. Deploy to testnet
6. Run simulated attacks and real-world markets
7. Professional security audit ($20k-50k)
8. Bug bounty program (50k-500k sats)

**Month 5-6: Mainnet Launch**
9. Deploy to Stacks mainnet
10. Start with low-stakes markets (< 100k vaults)
11. Monitor behavior and tune parameters
12. Community education and documentation

**Month 7-12: Scale**
13. Increase market caps
14. Add advanced features (pre-commitments, reputation)
15. Optimize based on real data
16. Expand to larger event categories

**Timeline:** 6 months from start to production-ready

### Final Thoughts

This design represents a **paradigm shift** in oracle design:
- From "trust humans" to "trust math"
- From "centralized arbitration" to "economic finality"
- From "admin keys" to "pure incentives"

By accepting slower resolution, we gain:
- **Permanent decentralization** (no governance needed)
- **Censorship resistance** (can't be shut down)
- **Scalable security** (works for markets of any size)

This is **truly trustless** infrastructure for Bitcoin-native prediction markets.

**The future is trustless. Let's build it.**

---

## Appendix: References

- [UMA Protocol Documentation](https://docs.uma.xyz/)
- [Polymarket Resolution Process](https://docs.polymarket.com/)
- [Gnosis Conditional Tokens Framework](https://docs.gnosis.io/conditionaltokens/)
- [Bitcoin Block Time Analysis](https://www.blockchain.com/charts/avg-block-size)
- [Game Theory in Decentralized Oracles (Paper)](https://arxiv.org/abs/1904.06346)
- [Schelling Point Coordination Games](https://en.wikipedia.org/wiki/Focal_point_(game_theory))
