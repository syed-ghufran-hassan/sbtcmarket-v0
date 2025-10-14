import { beforeEach, describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  mintCompleteSet,
  swapShares,
  readMarket,
  getShareBalance,
} from "./helpers/scenario-helpers";
import { expectUint, unwrapErrUint } from "./helpers/assertions";

const { wallet1, wallet2 } = scenarioAccounts;

describe("Scenario 12 - Swap Mechanics & Edge Cases", () => {
  beforeEach(() => {
    [wallet1, wallet2].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("TEST 1: Basic swap after mint", () => {
    const { marketId } = createMarket({ question: "Swap Test Market" });

    const mint = mintCompleteSet(marketId, 100_000n, wallet1);
    expect(mint.result.type).toBe("ok");

    const yesBefore = getShareBalance(marketId, wallet1, true);
    expect(yesBefore).toBe(100_000n);

    const swap = swapShares(marketId, true, 50_000n, wallet1);
    expect(swap.result.type).toBe("ok");

    const yesAfter = getShareBalance(marketId, wallet1, true);
    const noAfter = getShareBalance(marketId, wallet1, false);
    expect(yesAfter < yesBefore).toBe(true);
    expect(noAfter > 0n).toBe(true);
  });

  it("TEST 3: Swap more than balance fails", () => {
    const { marketId } = createMarket({ question: "Swap Overdraw" });
    mintCompleteSet(marketId, 10_000n, wallet1);

    const swap = swapShares(marketId, true, 999_999_999n, wallet1);
    unwrapErrUint(swap.result, 1005n); // ERR-INSUFFICIENT-BALANCE
  });

  it("TEST 4: Swap after resolution fails", () => {
    const { marketId } = createMarket({ question: "Resolved Market" });
    mintCompleteSet(marketId, 50_000n, wallet1);

    simnet.callPublicFn(
      "sbtcmarket-v0",
      "mock-resolve-market",
      [Cl.uint(marketId), Cl.bool(true)],
      scenarioAccounts.deployer,
    );

    const swap = swapShares(marketId, true, 10_000n, wallet1);
    unwrapErrUint(swap.result, 1001n); // ERR-RESOLVED
  });

  it("TEST 5: Swap zero amount fails", () => {
    const { marketId } = createMarket({ question: "Zero Swap" });
    mintCompleteSet(marketId, 1_000n, wallet1);

    const swap = swapShares(marketId, true, 0n, wallet1);
    unwrapErrUint(swap.result, 1004n); // ERR-ZERO-AMOUNT
  });

  it("TEST 6: Large swap impacts pricing", () => {
    const { marketId } = createMarket({ question: "Price Impact Test" });
    mintCompleteSet(marketId, 1_000_000n, wallet1);

    const before = readMarket(marketId);
    const priceYesBefore = expectUint(before["price-yes"]);
    const priceNoBefore = expectUint(before["price-no"]);

    const swap = swapShares(marketId, true, 500_000n, wallet1);
    expect(swap.result.type).toBe("ok");

    const after = readMarket(marketId);
    const priceYesAfter = expectUint(after["price-yes"]);
    const priceNoAfter = expectUint(after["price-no"]);
    expect(priceYesAfter > priceYesBefore).toBe(true);
    expect(priceNoAfter < priceNoBefore).toBe(true);
  });

  it("TEST 7: Swap back and forth (round trip)", () => {
    const { marketId } = createMarket({ question: "Round Trip" });
    mintCompleteSet(marketId, 200_000n, wallet1);

    const first = swapShares(marketId, true, 100_000n, wallet1);
    expect(first.result.type).toBe("ok");

    const second = swapShares(marketId, false, 50_000n, wallet1);
    expect(second.result.type).toBe("ok");

    const yes = getShareBalance(marketId, wallet1, true);
    const no = getShareBalance(marketId, wallet1, false);
    expect(yes > 0n).toBe(true);
    expect(no > 0n).toBe(true);
  });

  it("TEST 8: Arbitrage with complete sets keeps balances non-zero", () => {
    const { marketId } = createMarket({ question: "Arb Market" });
    mintCompleteSet(marketId, 200_000n, wallet2);

    const swap = swapShares(marketId, true, 200_000n, wallet2);
    expect(swap.result.type).toBe("ok");

    const yesBalance = getShareBalance(marketId, wallet2, true);
    const noBalance = getShareBalance(marketId, wallet2, false);
    expect(yesBalance + noBalance > 0n).toBe(true);
  });
});
