import { describe, it, expect } from "vitest";
import { cvToValue } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  getShareBalance,
  resolveMarket,
  readRedemptionInfo,
  redeemShares,
  getSbtcBalance,
  readMarket,
} from "./helpers/scenario-helpers";

function basisPointCheck(payout: bigint, shares: bigint, ratio: bigint) {
  return payout * 10_000n >= shares * ratio
    ? payout * 10_000n - shares * ratio
    : shares * ratio - payout * 10_000n;
}

describe("Scenario 7 – Mass redemption fairness", () => {
  it("keeps proportional payouts consistent across 10 redeemers", () => {
    const {
      deployer,
      wallet1,
      wallet2,
      wallet3,
      wallet4,
      wallet5,
      wallet6,
      wallet7,
      wallet8,
      faucet,
    } = scenarioAccounts;

    const buyers = [
      { account: wallet1, spend: 500_000n },
      { account: wallet2, spend: 400_000n },
      { account: wallet3, spend: 350_000n },
      { account: wallet4, spend: 250_000n },
      { account: wallet5, spend: 200_000n },
      { account: wallet6, spend: 150_000n },
      { account: wallet7, spend: 100_000n },
      { account: wallet8, spend: 50_000n },
      { account: faucet, spend: 25_000n },
      { account: deployer, spend: 10_000n },
    ];

    buyers.forEach(({ account }) => {
      if (account !== deployer) {
        transferSbtc(account, 1_000_000_000n);
      }
    });

    const { marketId } = createMarket({ question: "Mass Redemption Test", virtualLiquidity: 20_000_000n });

    const shareMap = new Map<string, bigint>();
    buyers.forEach(({ account, spend }) => {
      buyShares(marketId, true, spend, account);
      const shares = getShareBalance(marketId, account, true);
      expect(shares > spend).toBe(true);
      shareMap.set(account, shares);
    });

    resolveMarket(marketId, true);

    const redemptionInfo = readRedemptionInfo(marketId);
    const baseRatio = BigInt(redemptionInfo.value["redemption-ratio-bps"].value);

    const redemptionOrder = [
      deployer,
      faucet,
      wallet8,
      wallet7,
      wallet5,
      wallet6,
      wallet4,
      wallet3,
      wallet2,
      wallet1,
    ];

    redemptionOrder.forEach((account, index) => {
      const sharesBefore = getShareBalance(marketId, account, true);
      expect(sharesBefore > 0n).toBe(true);

      const balanceBefore = getSbtcBalance(account);
      const redemption = redeemShares(marketId, account);
      expect(redemption.result.type).toBe("ok");
      const tuple = cvToValue(redemption.result) as {
        value: {
          payout: { value: string | number | bigint };
          "shares-burned": { value: string | number | bigint };
          "redemption-ratio-bps": { value: string | number | bigint };
        };
      };
      const payout = BigInt(tuple.value.payout.value);
      const burned = BigInt(tuple.value["shares-burned"].value);
      const ratio = BigInt(tuple.value["redemption-ratio-bps"].value);
      expect(ratio).toBe(baseRatio);

      const balanceAfter = getSbtcBalance(account);
      expect(balanceAfter - balanceBefore).toBe(payout);
      expect(getShareBalance(marketId, account, true)).toBe(0n);

      const infoAfter = readRedemptionInfo(marketId);
      const nextRatio = BigInt(infoAfter.value["redemption-ratio-bps"].value);
      if (index < redemptionOrder.length - 1) {
        expect(nextRatio).toBe(baseRatio);
      }
    });

    const finalMarket = readMarket(marketId);
    expect(BigInt(finalMarket["vault-sbtc"].value) < 5_000n).toBe(true);
  });
});
