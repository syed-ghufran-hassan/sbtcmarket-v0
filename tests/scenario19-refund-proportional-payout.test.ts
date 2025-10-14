import { beforeEach, describe, expect, it } from "vitest";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  cancelMarket,
  refundShares,
  readMarket,
  advanceBlocks,
} from "./helpers/scenario-helpers";
import { expectBool, expectUint } from "./helpers/assertions";

const { deployer, wallet1, wallet2 } = scenarioAccounts;

describe("Scenario 19 - Refund Proportional Payout", () => {
  beforeEach(() => {
    [wallet1, wallet2].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("refunds participants proportionally after cancellation", () => {
    const { marketId } = createMarket({
      question: "Refund Test - BTC >= $100k?",
      resolutionBlock: 8n,
    });

    buyShares(marketId, true, 100_000n, wallet1);
    buyShares(marketId, false, 50_000n, wallet2);

    advanceBlocks(12);
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
