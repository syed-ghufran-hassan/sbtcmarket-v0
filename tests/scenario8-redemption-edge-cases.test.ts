import { describe, it, expect } from "vitest";
import { Cl, cvToValue } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  resolveMarket,
  redeemShares,
  getSbtcBalance,
  getShareBalance,
  mintCompleteSet,
  readMarket,
  readRedemptionInfo,
} from "./helpers/scenario-helpers";

describe("Scenario 8 – Redemption edge cases", () => {
  it("redeems dust amounts proportionally", () => {
    const { wallet1, wallet2 } = scenarioAccounts;
    transferSbtc(wallet1, 1_000_000_000n);
    transferSbtc(wallet2, 1_000_000_000n);

    const { marketId } = createMarket({ question: "Dust Test Market" });

    buyShares(marketId, true, 500_000n, wallet1);
    buyShares(marketId, true, 100n, wallet2);
    expect(getShareBalance(marketId, wallet2, true) > 0n).toBe(true);

    resolveMarket(marketId, true);

    const balanceBefore = getSbtcBalance(wallet2);
    const redemption = redeemShares(marketId, wallet2);
    expect(redemption.result.type).toBe("ok");
    const tuple = cvToValue(redemption.result) as {
      value: { payout: { value: string | number | bigint }; "shares-burned": { value: string | number | bigint } };
    };
    const payout = BigInt(tuple.value.payout.value);
    expect(payout > 0n).toBe(true);
    const balanceAfter = getSbtcBalance(wallet2);
    expect(balanceAfter - balanceBefore).toBe(payout);
  });

  it("prevents losing side from redeeming", () => {
    const { wallet1, wallet2 } = scenarioAccounts;
    transferSbtc(wallet1, 1_000_000_000n);
    transferSbtc(wallet2, 1_000_000_000n);

    const { marketId } = createMarket({ question: "Loser Test Market" });

    buyShares(marketId, true, 300_000n, wallet1);
    buyShares(marketId, false, 200_000n, wallet2);

    resolveMarket(marketId, false);

    const loserAttempt = redeemShares(marketId, wallet1);
    expect(loserAttempt.result).toBeErr(Cl.uint(1003));

    const winnerRedeem = redeemShares(marketId, wallet2);
    expect(winnerRedeem.result.type).toBe("ok");
  });

  it("allows mixed position holders to redeem only winning side", () => {
    const { wallet1 } = scenarioAccounts;
    transferSbtc(wallet1, 1_000_000_000n);

    const { marketId } = createMarket({ question: "Mixed Position Market" });

    expect(mintCompleteSet(marketId, 100_000n, wallet1).result.type).toBe("ok");
    expect(getShareBalance(marketId, wallet1, true)).toBe(100_000n);
    expect(getShareBalance(marketId, wallet1, false)).toBe(100_000n);

    resolveMarket(marketId, true);

    const before = getSbtcBalance(wallet1);
    const redemption = redeemShares(marketId, wallet1);
    expect(redemption.result.type).toBe("ok");
    const tuple = cvToValue(redemption.result) as {
      value: { payout: { value: string | number | bigint } };
    };
    const payout = BigInt(tuple.value.payout.value);
    expect(getSbtcBalance(wallet1) - before).toBe(payout);
    expect(getShareBalance(marketId, wallet1, true)).toBe(0n);
    expect(getShareBalance(marketId, wallet1, false)).toBe(100_000n);
  });

  it("drains the vault proportionally across multiple redeemers", () => {
    const { wallet1, wallet2, wallet3 } = scenarioAccounts;
    [wallet1, wallet2, wallet3].forEach((account) => transferSbtc(account, 1_000_000_000n));

    const { marketId } = createMarket({ question: "Partial Depletion Market", virtualLiquidity: 5_000_000n });

    [wallet1, wallet2, wallet3].forEach((account) => buyShares(marketId, true, 100_000n, account));

    resolveMarket(marketId, true);

    const initialVault = BigInt(readMarket(marketId)["vault-sbtc"].value);
    expect(initialVault > 0n).toBe(true);

    const redeemAndCheck = (account: string) => {
      const vaultBefore = BigInt(readMarket(marketId)["vault-sbtc"].value);
      const result = redeemShares(marketId, account);
      expect(result.result.type).toBe("ok");
      const vaultAfter = BigInt(readMarket(marketId)["vault-sbtc"].value);
      expect(vaultAfter < vaultBefore).toBe(true);
    };

    redeemAndCheck(wallet1);
    redeemAndCheck(wallet2);
    redeemAndCheck(wallet3);

    const finalVault = BigInt(readMarket(marketId)["vault-sbtc"].value);
    expect(finalVault < 5_000n).toBe(true);
  });

  it("handles issuance imbalances without overpaying", () => {
    const { wallet1, wallet2 } = scenarioAccounts;
    transferSbtc(wallet1, 1_000_000_000n);
    transferSbtc(wallet2, 1_000_000_000n);

    const { marketId } = createMarket({ question: "Over-Issuance Market", virtualLiquidity: 10_000_000n });

    buyShares(marketId, true, 500_000n, wallet1);
    buyShares(marketId, true, 300_000n, wallet2);

    resolveMarket(marketId, true);

    const info = readRedemptionInfo(marketId);
    const ratio = BigInt(info.value["redemption-ratio-bps"].value);
    expect(ratio > 5_000n).toBe(true);
    expect(ratio <= 10_000n).toBe(true);

    const before = getSbtcBalance(wallet2);
    const redemption = redeemShares(marketId, wallet2);
    expect(redemption.result.type).toBe("ok");
    const redemptionTuple = cvToValue(redemption.result) as {
      value: { payout: { value: string | number | bigint } };
    };
    const payout = BigInt(redemptionTuple.value.payout.value);
    expect(getSbtcBalance(wallet2) - before).toBe(payout);
    expect(getShareBalance(marketId, wallet2, true)).toBe(0n);

    const doubleRedeem = redeemShares(marketId, wallet2);
    expect(doubleRedeem.result).toBeErr(Cl.uint(1003));
  });
});
