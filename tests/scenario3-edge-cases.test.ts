import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  resolveMarket,
  redeemShares,
  getShareBalance,
} from "./helpers/scenario-helpers";

describe("Scenario 3 – Edge cases and error handling", () => {
  it("guards against invalid operations", () => {
    const { deployer, wallet1, wallet2 } = scenarioAccounts;

    transferSbtc(wallet1, 1_000_000_000n);
    transferSbtc(wallet2, 1_000_000_000n);

    const { marketId } = createMarket({ question: "Test Market" });

    const zeroBuy = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(0)],
      wallet1,
    );
    expect(zeroBuy.result).toBeErr(Cl.uint(3));

    const zeroMint = simnet.callPublicFn(
      "sbtcmarket-v0",
      "mint-complete-set",
      [Cl.uint(marketId), Cl.uint(0)],
      wallet1,
    );
    expect(zeroMint.result).toBeErr(Cl.uint(1004));

    const tooMuchBuy = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(2_000_000_000n)],
      wallet1,
    );
    expect(tooMuchBuy.result).toBeErr(Cl.uint(1));

    const missingMarket = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(999), Cl.bool(true), Cl.uint(10_000)],
      wallet1,
    );
    expect(missingMarket.result).toBeErr(Cl.uint(1000));

    const missingBalance = simnet.callReadOnlyFn(
      "sbtcmarket-v0",
      "get-balance",
      [Cl.uint(999), Cl.principal(wallet1), Cl.bool(true)],
      wallet1,
    );
    expect(missingBalance.result).toBeOk(Cl.uint(0));

    const tinyBuy1 = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(1)],
      wallet1,
    );
    expect(tinyBuy1.result).toBeErr(Cl.uint(3));

    const tinyBuy10 = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(10)],
      wallet1,
    );
    expect(tinyBuy10.result).toBeErr(Cl.uint(3));

    const normalBuy = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(100_000)],
      wallet1,
    );
    expect(normalBuy.result.type).toBe("ok");

    const burnWithoutNo = simnet.callPublicFn(
      "sbtcmarket-v0",
      "burn-complete-set",
      [Cl.uint(marketId), Cl.uint(10)],
      wallet1,
    );
    expect(burnWithoutNo.result).toBeErr(Cl.uint(1005));

    const swapTooMuch = simnet.callPublicFn(
      "sbtcmarket-v0",
      "swap-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(1_000_000)],
      wallet1,
    );
    expect(swapTooMuch.result).toBeErr(Cl.uint(1005));

    const redeemEarly = redeemShares(marketId, wallet1);
    expect(redeemEarly.result).toBeErr(Cl.uint(1008));

    resolveMarket(marketId, true);

    const postResolveBuy = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(10_000)],
      wallet1,
    );
    expect(postResolveBuy.result).toBeErr(Cl.uint(1001));

    const postResolveSwap = simnet.callPublicFn(
      "sbtcmarket-v0",
      "swap-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(10)],
      wallet1,
    );
    expect(postResolveSwap.result).toBeErr(Cl.uint(1001));

    const wallet2Redeem = redeemShares(marketId, wallet2);
    expect(wallet2Redeem.result).toBeErr(Cl.uint(1003));

    const firstRedeem = redeemShares(marketId, wallet1);
    expect(firstRedeem.result.type).toBe("ok");

    const secondRedeem = redeemShares(marketId, wallet1);
    expect(secondRedeem.result).toBeErr(Cl.uint(1003));

    const invalidComparison = simnet.callPublicFn(
      "sbtcmarket-v0",
      "create-market",
      [
        Cl.stringUtf8("Invalid Market"),
        Cl.uint(1_000_000),
        Cl.buffer(new Uint8Array(32).fill(0)),
        Cl.int(10_000_000_000_000n),
        Cl.uint(10_000_000),
        Cl.uint(30),
        Cl.stringUtf8("XX"),
      ],
      deployer,
    );
    expect(invalidComparison.result).toBeErr(Cl.uint(1009));

    const invalidFee = simnet.callPublicFn(
      "sbtcmarket-v0",
      "create-market",
      [
        Cl.stringUtf8("High Fee Market"),
        Cl.uint(1_000_000),
        Cl.buffer(new Uint8Array(32).fill(0)),
        Cl.int(10_000_000_000_000n),
        Cl.uint(10_000_000),
        Cl.uint(15_000),
        Cl.stringUtf8("GE"),
      ],
      deployer,
    );
    expect(invalidFee.result).toBeErr(Cl.uint(1006));

    expect(getShareBalance(marketId, wallet1, true)).toBe(0n);
  });
});
