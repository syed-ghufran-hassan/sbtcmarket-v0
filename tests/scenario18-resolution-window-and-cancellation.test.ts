import { beforeEach, describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  readMarket,
  cancelMarket,
  refundShares,
  advanceBlocks,
} from "./helpers/scenario-helpers";
import { expectBool, expectUint, unwrapErrUint } from "./helpers/assertions";

const { deployer, wallet1, wallet2 } = scenarioAccounts;

describe("Scenario 18 - Resolution Window & Immediate Cancellation", () => {
  beforeEach(() => {
    [wallet1, wallet2].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("creates market with short resolution window", () => {
    const { marketId } = createMarket({
      question: "2-Block Window Test Market",
      resolutionBlock: 100_010n,
    });
    const market = readMarket(marketId, deployer);
    expectUint(market["resolution-block"], 100_010n);
    expectBool(market.resolved, false);
    expectBool(market.cancelled, false);
  });

  it("enforces cancellation timing and allows refunds after", () => {
    const { marketId } = createMarket({
      question: "Cancellation Timing",
      resolutionBlock: 12n,
    });

    buyShares(marketId, true, 150_000n, wallet1);
    buyShares(marketId, false, 150_000n, wallet2);

    const early = cancelMarket(marketId, deployer);
    unwrapErrUint(early.result, 1002n);

    advanceBlocks(15);
    const cancel = cancelMarket(marketId, deployer);
    expect(cancel.result.type).toBe("ok");

    const refund1 = refundShares(marketId, wallet1);
    const refund2 = refundShares(marketId, wallet2);
    expect(refund1.result.type).toBe("ok");
    expect(refund2.result.type).toBe("ok");

    const market = readMarket(marketId, deployer);
    expectBool(market.cancelled, true);
    const remainingVault = expectUint(market["vault-sbtc"]);
    expect(remainingVault <= 1_000n).toBe(true);
  });
});
