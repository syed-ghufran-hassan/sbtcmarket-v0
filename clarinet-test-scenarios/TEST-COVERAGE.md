# sBTC Market - Complete Test Coverage

This document provides a comprehensive overview of all test scenarios and the contract features they validate.

## Test Coverage Matrix

| Feature | Scenario 1 | Scenario 2 | Scenario 3 | Scenario 4 | Scenario 5 | Scenario 6 |
|---------|:----------:|:----------:|:----------:|:----------:|:----------:|:----------:|
| **Market Creation** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Buy Shares** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Sell Shares** | | | | | | |
| **Mint Complete Set** | | | | ✅ | ✅ | ✅ |
| **Burn Complete Set** | | | ✅ | ✅ | | |
| **Swap Shares** | | | ✅ | ✅ | | ✅ |
| **Market Resolution** | ✅ | ✅ | | | ✅ | ✅ |
| **Redeem Shares** | ✅ | ✅ | ✅ | | ✅ | ✅ |
| **Proportional Redemption** | ✅ | ✅ | | | ✅ | |
| **Fee Collection** | | | | | | ✅ |
| **Treasury Management** | | | | | | ✅ |
| **Error Handling** | | ✅ | ✅ | | | ✅ |
| **AMM Pricing** | | | | ✅ | | |
| **Over-Issuance** | | | | | ✅ | |
| **Edge Cases** | | | ✅ | | | |

## Error Codes Tested

| Error Code | Name | Scenarios Testing |
|------------|------|-------------------|
| `u1000` | ERR-NO-MARKET | Scenario 3 |
| `u1001` | ERR-RESOLVED | Scenario 3 |
| `u1002` | ERR-TOO-EARLY | _(Not tested - requires block advancement)_ |
| `u1003` | ERR-NOT-RESOLVED | Scenario 3 |
| `u1004` | ERR-ZERO-AMOUNT | Scenario 3 |
| `u1005` | ERR-INSUFFICIENT-BALANCE | Scenarios 2, 3 |
| `u1007` | ERR-INVALID-V-LIQUIDITY | _(Internal check)_ |
| `u1008` | ERR-NOTHING-TO-REDEEM | Scenarios 2, 3 |
| `u1009` | ERR-INVALID-COMPARISON | Scenario 3 |
| `u1010` | ERR-INVALID-FEE | Scenario 3 |
| `u1011` | ERR-UNAUTHORIZED | Scenario 6 |

## Function Coverage

### Public Functions

| Function | Test Coverage |
|----------|---------------|
| `create-market` | All scenarios |
| `buy-shares` | Scenarios 1, 2, 3, 4, 5, 6 |
| `sell-shares` | _(Recommended: Add scenario)_ |
| `mint-complete-set` | Scenarios 3, 4, 5, 6 |
| `burn-complete-set` | Scenarios 3, 4 |
| `swap-shares` | Scenarios 3, 4, 6 |
| `resolve-market` | _(Production - uses Pyth oracle)_ |
| `mock-resolve-market` | Scenarios 1, 2, 5, 6 |
| `redeem-shares` | Scenarios 1, 2, 3, 5, 6 |
| `set-protocol-treasury` | Scenario 6 |

### Read-Only Functions

| Function | Test Coverage |
|----------|---------------|
| `get-market` | All scenarios |
| `get-balance` | All scenarios |
| `get-redemption-info` | Scenarios 1, 2, 5 |
| `get-protocol-treasury` | Scenario 6 |

## Critical Path Testing

### Happy Path (Scenario 1)
```
Create Market → Buy Shares → Resolve (YES) → Redeem → Success
```
✅ Tests basic functionality end-to-end

### Mixed Outcome (Scenario 2)
```
Create Market → Multiple Buyers (YES/NO) → Resolve (NO) → Winners Redeem → Losers Fail
```
✅ Tests winner/loser logic and error handling

### Error Paths (Scenario 3)
```
All Error Conditions → Verify Correct Error Codes
```
✅ Tests 11 different error scenarios

### AMM Mechanics (Scenario 4)
```
Create Market → Small Trade → Large Trade → Opposite Trade → Verify Pricing
```
✅ Tests constant-product formula and slippage

### Fairness (Scenario 5)
```
Create Over-Issuance → Multiple Redeemers → Verify Same Ratio
```
✅ Tests proportional redemption fairness

### Revenue (Scenario 6)
```
Create Markets → Trade → Accumulate Fees → Treasury Redeems
```
✅ Tests protocol revenue mechanics

## Missing Test Coverage

### Recommended Additional Scenarios

1. **Scenario 7: Sell-Shares Testing**
   - Test sell-shares function explicitly
   - Verify sBTC returned matches expectation
   - Test selling partial positions

2. **Scenario 8: Complex Trading Patterns**
   - Multiple swaps between same users
   - Arbitrage scenarios (mint → swap → burn → profit)
   - Large position exits

3. **Scenario 9: Time-Based Resolution**
   - Test ERR-TOO-EARLY (requires block advancement)
   - Multiple markets at different resolution blocks
   - Resolution exactly at target block

4. **Scenario 10: Stress Testing**
   - Maximum virtual liquidity values
   - Minimum viable amounts (1 sat)
   - Maximum number of participants (10-20 users)

## Integration Testing Checklist

When moving to testnet, verify:

- [ ] Real Pyth oracle integration (VAA verification)
- [ ] Wormhole signature validation
- [ ] Block height resolution timing
- [ ] Gas costs for all operations
- [ ] Multi-block transaction sequences
- [ ] Real sBTC token integration
- [ ] Treasury address management
- [ ] Production error scenarios

## Security Testing Checklist

- [ ] Re-entrancy protection (none needed - no callbacks)
- [ ] Arithmetic overflow/underflow (fixed with safe math)
- [ ] Access control (treasury management)
- [ ] Input validation (comparison types, fees)
- [ ] State consistency (market resolution finality)
- [ ] Front-running protection (proportional redemption)

## Performance Metrics to Monitor

| Operation | Expected Cost | Actual Cost | Notes |
|-----------|--------------|-------------|-------|
| create-market | ~10k | TBD | One-time per market |
| buy-shares | ~20k | TBD | Includes mint + swap |
| mint-complete-set | ~15k | TBD | No AMM interaction |
| burn-complete-set | ~15k | TBD | No AMM interaction |
| swap-shares | ~18k | TBD | Pure AMM operation |
| sell-shares | ~20k | TBD | Includes swap + burn |
| resolve-market | ~30k | TBD | Oracle verification |
| redeem-shares | ~12k | TBD | Proportional calc |

## Known Limitations

1. **Mock Resolution**: `mock-resolve-market` bypasses oracle - must be removed before production
2. **Block Advancement**: Cannot test time-based resolution in Clarinet console
3. **Real Oracle**: Cannot test Pyth VAA verification without actual oracle data
4. **Large Numbers**: Limited testing of maximum uint values (u340282366920938463463374607431768211455)

## Test Execution Time

Estimated runtime for all scenarios:
- Scenario 1: ~30 seconds
- Scenario 2: ~45 seconds
- Scenario 3: ~60 seconds
- Scenario 4: ~45 seconds
- Scenario 5: ~60 seconds
- Scenario 6: ~60 seconds

**Total**: ~5 minutes for complete test suite

## Continuous Integration

Recommended CI pipeline:
```bash
# 1. Syntax check
clarinet check

# 2. Run all scenarios
./run-test-scenarios.sh

# 3. Check for errors
grep -r "error:" test-results/
grep -r "Runtime error" test-results/

# 4. Generate coverage report
./generate-coverage-report.sh  # (To be implemented)

# 5. Deploy to testnet
clarinet deployments apply -e testnet

# 6. Run integration tests
npm run test:integration
```

## Success Criteria

All tests pass when:
- ✅ No "error:" in test results (except expected error tests)
- ✅ No "Runtime error" in test results (except expected)
- ✅ All redemptions complete successfully
- ✅ Vault balance reduces to ~0 after all redemptions
- ✅ Proportional redemption ratios are consistent
- ✅ Fee accumulation matches expected values
- ✅ Market state transitions are correct

## Maintenance

Update this document when:
- Adding new scenarios
- Discovering new edge cases
- Fixing bugs
- Adding new features
- Changing contract logic

Last updated: 2025-10-01
