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
  readRedemptionInfo,
  getShareBalance,
  readMarket,
} from "./helpers/scenario-helpers";

describe("Scenario 5 – Proportional redemption", () => {
  it("keeps redemption ratio identical for all YES holders", () => {
    const { wallet1, wallet2, wallet3, wallet4, wallet5 } = scenarioAccounts;
    const participants = [
      { account: wallet1, amount: 500_000n },
      { account: wallet2, amount: 400_000n },
      { account: wallet3, amount: 300_000n },
      { account: wallet4, amount: 200_000n },
      { account: wallet5, amount: 100_000n },
    ];

    participants.forEach(({ account }) => {
      transferSbtc(account, 1_000_000_000n);
    });

    const { marketId } = createMarket({ question: "Small Liquidity Market" });

    participants.forEach(({ account, amount }) => {
      buyShares(marketId, true, amount, account);
      expect(getShareBalance(marketId, account, true) > amount).toBe(true);
    });

    resolveMarket(marketId, true);

    const redemptionInfo = readRedemptionInfo(marketId);
    const initialRatio = BigInt(redemptionInfo.value["redemption-ratio-bps"].value);
    expect(initialRatio < 10_000n).toBe(true);

    const redemptionOrder = [wallet5, wallet3, wallet2, wallet4, wallet1];

    redemptionOrder.forEach((account, index) => {
      const before = getSbtcBalance(account);
      const result = redeemShares(marketId, account);
      expect(result.result.type).toBe("ok");
      const tuple = cvToValue(result.result) as {
        value: {
          payout: { value: string | number | bigint };
          "shares-burned": { value: string | number | bigint };
          "redemption-ratio-bps": { value: string | number | bigint };
        };
      };
      const payout = BigInt(tuple.value.payout.value);
      const sharesBurned = BigInt(tuple.value["shares-burned"].value);
      const ratio = BigInt(tuple.value["redemption-ratio-bps"].value);
      expect(ratio).toBe(initialRatio);

      const after = getSbtcBalance(account);
      expect(after - before).toBe(payout);
      expect(getShareBalance(marketId, account, true)).toBe(0n);

      const infoAfter = readRedemptionInfo(marketId);
      const ongoingRatio = BigInt(infoAfter.value["redemption-ratio-bps"].value);
      if (index < redemptionOrder.length - 1) {
        expect(ongoingRatio).toBe(initialRatio);
      }
      expect(sharesBurned > 0n).toBe(true);
    });

    const finalMarket = readMarket(marketId);
    const vaultRemaining = BigInt(finalMarket["vault-sbtc"].value);
    expect(vaultRemaining < 5_000n).toBe(true);
  });
});
