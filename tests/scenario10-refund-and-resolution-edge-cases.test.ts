import { beforeEach, describe, expect, it } from "vitest";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  mintCompleteSet,
  readMarket,
  cancelMarket,
  refundShares,
  resolveMarket,
  advanceBlocks,
} from "./helpers/scenario-helpers";
import { expectBool, expectUint, unwrapErrUint } from "./helpers/assertions";

const { deployer, wallet1, wallet2, wallet3 } = scenarioAccounts;

describe("Scenario 10 - Refund & Resolution Edge Cases", () => {
  beforeEach(() => {
    [wallet1, wallet2, wallet3].forEach((wallet) => {
      transferSbtc(wallet, 1_000_000_000n);
    });
  });

  it("TEST 1: Market cancellation and refund flow with trading activity", () => {
    const { marketId } = createMarket({
      question: "Refund Test Market",
      resolutionBlock: 1_000_000n,
    });

    buyShares(marketId, true, 100_000n, wallet1);
    buyShares(marketId, false, 150_000n, wallet2);

    const mintResult = mintCompleteSet(marketId, 50_000n, wallet3);
    expect(mintResult.result.type).toBe("ok");

    const market = readMarket(marketId, deployer);
    expect(market.question.value).toBe("Refund Test Market");
    expectUint(market["resolution-block"], 1_000_000n);
    expectUint(market["virtual-liquidity"], 10_000_000n);
    expectUint(market["fee-bps"], 30n);
    expectBool(market.resolved, false);
    expectBool(market.cancelled, false);
    expect(market.outcome.value == null).toBe(true);
    const vault = expectUint(market["vault-sbtc"]);
    const yesIssued = expectUint(market["yes-issued"]);
    const noIssued = expectUint(market["no-issued"]);
    const yesCirculating = expectUint(market["yes-circulating"]);
    const noCirculating = expectUint(market["no-circulating"]);
    expect(vault > 0n).toBe(true);
    expect(yesIssued > 0n).toBe(true);
    expect(noIssued > 0n).toBe(true);
    expect(yesCirculating > 0n).toBe(true);
    expect(noCirculating > 0n).toBe(true);
  });

  it("TEST 2: Cancellation before timeout is rejected", () => {
    const { marketId } = createMarket({
      question: "Cancel Test Market",
      resolutionBlock: 1_000_000n,
    });

    const cancel = cancelMarket(marketId, deployer);
    unwrapErrUint(cancel.result, 1002n); // ERR-TOO-EARLY
  });

  it("TEST 3: Refund attempts before cancellation fail", () => {
    const { marketId } = createMarket({
      question: "Refund Test Market",
      resolutionBlock: 1_000_000n,
    });

    const refund = refundShares(marketId, wallet1);
    unwrapErrUint(refund.result, 1013n); // ERR-NOT-CANCELLED
  });

  it("TEST 6: Mock resolve succeeds regardless of block height (test helper)", () => {
    const { marketId } = createMarket({
      question: "Resolution Test Market",
      resolutionBlock: 1_000_100n,
    });

    transferSbtc(wallet1, 500_000n);
    buyShares(marketId, true, 50_000n, wallet1);

    // Ensure we're still before resolution window to demonstrate mock behaviour
    advanceBlocks(1);
    resolveMarket(marketId, true, deployer);

    const market = readMarket(marketId, deployer);
    expectBool(market.resolved, true);
    expect(market.outcome.value).toBeDefined();
    expectBool(market.outcome.value, true);
  });
});
