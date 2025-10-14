import { beforeEach, describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  mintCompleteSet,
  swapShares,
  readMarket,
  readRedemptionInfo,
  redeemShares,
} from "./helpers/scenario-helpers";
import { expectBool, expectUint, unwrapOk } from "./helpers/assertions";

const { deployer, wallet1, wallet2, wallet3 } = scenarioAccounts;

describe("Scenario 13 - Over-Issuance Attack Scenarios", () => {
  beforeEach(() => {
    [wallet1, wallet2, wallet3].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("establishes initial invariants for a fresh market", () => {
    const { marketId } = createMarket({ question: "Invariant Test Market" });
    const market = readMarket(marketId, deployer);

    expectUint(market["vault-sbtc"], 0n);
    expectUint(market["yes-issued"], 0n);
    expectUint(market["no-issued"], 0n);
    expectUint(market["yes-circulating"], 0n);
    expectUint(market["no-circulating"], 0n);
    expectBool(market.resolved, false);
    expectBool(market.cancelled, false);
    expect(market.outcome.type.includes("none")).toBe(true);
  });

  it("demonstrates over-issuance via successive swaps", () => {
    const { marketId } = createMarket({ question: "Over-Issuance Market" });

    mintCompleteSet(marketId, 500_000n, wallet1);
    expect(swapShares(marketId, true, 400_000n, wallet1).result.type).toBe("ok");

    mintCompleteSet(marketId, 300_000n, wallet2);
    expect(swapShares(marketId, true, 250_000n, wallet2).result.type).toBe("ok");

    mintCompleteSet(marketId, 200_000n, wallet3);
    expect(swapShares(marketId, true, 150_000n, wallet3).result.type).toBe("ok");

    const market = readMarket(marketId, deployer);
    const yesCirc = expectUint(market["yes-circulating"]);
    const noCirc = expectUint(market["no-circulating"]);
    expect(noCirc > yesCirc).toBe(true);

    const yesIssued = expectUint(market["yes-issued"]);
    const noIssued = expectUint(market["no-issued"]);
    expect(noCirc > noIssued).toBe(true);
  });

  it("keeps redemption proportional even when imbalance exists", () => {
    const { marketId } = createMarket({ question: "Redemption Stress Test" });

    mintCompleteSet(marketId, 400_000n, wallet1);
    mintCompleteSet(marketId, 300_000n, wallet2);
    mintCompleteSet(marketId, 300_000n, wallet3);

    expect(swapShares(marketId, true, 320_000n, wallet1).result.type).toBe("ok");
    expect(swapShares(marketId, true, 250_000n, wallet2).result.type).toBe("ok");
    expect(swapShares(marketId, true, 200_000n, wallet3).result.type).toBe("ok");

    const resolve = simnet.callPublicFn(
      "sbtcmarket-v0",
      "mock-resolve-market",
      [Cl.uint(marketId), Cl.bool(false)],
      deployer,
    );
    expect(resolve.result.type).toBe("ok");

    const info = readRedemptionInfo(marketId, deployer);
    const redemption = info.value as Record<string, any>;
    const ratio = expectUint(redemption["redemption-ratio-bps"]);
    expect(ratio < 10_000n).toBe(true);

    const redeem1 = redeemShares(marketId, wallet1);
    const redeem2 = redeemShares(marketId, wallet2);
    const redeem3 = redeemShares(marketId, wallet3);

    const tuple1 = unwrapOk(redeem1.result).value as Record<string, any>;
    const tuple2 = unwrapOk(redeem2.result).value as Record<string, any>;
    const tuple3 = unwrapOk(redeem3.result).value as Record<string, any>;

    const payout1 = expectUint(tuple1.payout);
    const payout2 = expectUint(tuple2.payout);
    const payout3 = expectUint(tuple3.payout);
    expect(payout1 > payout2 && payout2 > payout3).toBe(true);

    const ratio1 = expectUint(tuple1["redemption-ratio-bps"]);
    const ratio2 = expectUint(tuple2["redemption-ratio-bps"]);
    const ratio3 = expectUint(tuple3["redemption-ratio-bps"]);
    expect(ratio1).toBe(ratio2);
    expect(ratio2).toBe(ratio3);
  });
});
