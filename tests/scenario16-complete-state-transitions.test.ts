import { beforeEach, describe, expect, it } from "vitest";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  mintCompleteSet,
  buyShares,
  readMarket,
  resolveMarket,
  redeemShares,
  cancelMarket,
  refundShares,
  advanceBlocks,
} from "./helpers/scenario-helpers";
import { expectBool, expectUint, unwrapErrUint } from "./helpers/assertions";

const { deployer, wallet1, wallet2 } = scenarioAccounts;

describe("Scenario 16 - Complete State Transitions & Lifecycle", () => {
  beforeEach(() => {
    [wallet1, wallet2].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("walks through the full happy path lifecycle", () => {
    const { marketId } = createMarket({ question: "Full Lifecycle Market" });

    mintCompleteSet(marketId, 100_000n, wallet1);
    buyShares(marketId, true, 50_000n, wallet2);

    resolveMarket(marketId, true, deployer);

    const market = readMarket(marketId, deployer);
    expectBool(market.resolved, true);
    expect(market.outcome.value).toBeDefined();
    expectBool(market.outcome.value, true);

    const redeem1 = redeemShares(marketId, wallet1);
    expect(redeem1.result.type).toBe("ok");
    const redeem2 = redeemShares(marketId, wallet2);
    expect(redeem2.result.type).toBe("ok");
  });

  it("enforces cancellation rules and refunds", () => {
    const { marketId } = createMarket({ question: "Cancellation Flow", resolutionBlock: 10n });
    mintCompleteSet(marketId, 20_000n, wallet1);

    const earlyCancel = cancelMarket(marketId, deployer);
    unwrapErrUint(earlyCancel.result, 1002n); // ERR-TOO-EARLY

    advanceBlocks(12);
    const cancel = cancelMarket(marketId, deployer);
    expect(cancel.result.type).toBe("ok");

    const refund = refundShares(marketId, wallet1);
    expect(refund.result.type).toBe("ok");

    const marketAfter = readMarket(marketId, deployer);
    expectBool(marketAfter.cancelled, true);
    expect(marketAfter.outcome.value == null).toBe(true);
    const vaultRemaining = expectUint(marketAfter["vault-sbtc"]);
    expect(vaultRemaining >= 0n).toBe(true);
  });
});
