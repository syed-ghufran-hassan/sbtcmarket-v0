import { beforeEach, describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  mintCompleteSet,
  buyShares,
  readMarket,
  readRedemptionInfo,
  redeemShares,
} from "./helpers/scenario-helpers";
import { expectUint, unwrapErrUint } from "./helpers/assertions";

const { deployer, wallet1 } = scenarioAccounts;

describe("Scenario 15 - Integer Overflow & Underflow Edge Cases", () => {
  beforeEach(() => {
    transferSbtc(wallet1, 5_000_000_000n);
  });

  it("supports extremely large virtual liquidity without overflow", () => {
    const { marketId } = createMarket({
      question: "Large VL Market",
      virtualLiquidity: 100_000_000_000_000n,
    });
    const market = readMarket(marketId, deployer);
    expectUint(market["virtual-liquidity"], 100_000_000_000_000n);
    expectUint(market["price-yes"], 100_000_000_000_000n);
    expectUint(market["price-no"], 100_000_000_000_000n);
  });

  it("prevents double redemption underflow", () => {
    const { marketId } = createMarket({ question: "Redemption Underflow" });
    mintCompleteSet(marketId, 50_000n, wallet1);

    simnet.callPublicFn(
      "sbtcmarket-v0",
      "mock-resolve-market",
      [Cl.uint(marketId), Cl.bool(true)],
      deployer,
    );

    const firstRedeem = redeemShares(marketId, wallet1);
    expect(firstRedeem.result.type).toBe("ok");

    const secondRedeem = redeemShares(marketId, wallet1);
    unwrapErrUint(secondRedeem.result, 1003n); // ERR-NOTHING-TO-REDEEM
  });

  it("handles purchases with very high fees", () => {
    const { marketId } = createMarket({ question: "High Fee Market", feeBps: 9_999n });
    const result = buyShares(marketId, true, 1_000_000n, wallet1);
    expect(result.type).toBe("ok");

    const redemptionInfo = readRedemptionInfo(marketId, deployer);
    expectUint(redemptionInfo, 1008n); // ERR-NOT-RESOLVED
  });
});
