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

function hexToBytes(hex: string) {
  return Uint8Array.from(hex.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16)));
}

describe("Scenario 9 – Two user redemption bugfix", () => {
  it("keeps redemption ratio consistent between sequential redeemers", () => {
    const { wallet1, wallet2 } = scenarioAccounts;
    const feedId = hexToBytes("e62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43");

    transferSbtc(wallet1, 100_000_000n);
    transferSbtc(wallet2, 100_000_000n);

    const { marketId } = createMarket({
      question: "test",
      resolutionBlock: 96_966n,
      feedId,
      thresholdPrice: 120_000n,
      virtualLiquidity: 100_000n,
      feeBps: 30n,
    });

    buyShares(marketId, true, 16_980n, wallet1);
    buyShares(marketId, true, 16_983n, wallet2);

    const shares1 = getShareBalance(marketId, wallet1, true);
    const shares2 = getShareBalance(marketId, wallet2, true);
    expect(shares1).toBe(31_166n);
    expect(shares2).toBe(27_567n);

    resolveMarket(marketId, true);
    const info = readRedemptionInfo(marketId);
    const baseRatio = BigInt(info.value["redemption-ratio-bps"].value);

    const before1 = getSbtcBalance(wallet1);
    const redemption1 = redeemShares(marketId, wallet1);
    expect(redemption1.result.type).toBe("ok");
    const tuple1 = cvToValue(redemption1.result) as {
      value: {
        payout: { value: string | number | bigint };
        "shares-burned": { value: string | number | bigint };
        "redemption-ratio-bps": { value: string | number | bigint };
      };
    };
    const payout1 = BigInt(tuple1.value.payout.value);
    const ratio1 = BigInt(tuple1.value["redemption-ratio-bps"].value);
    const diff1 = ratio1 > baseRatio ? ratio1 - baseRatio : baseRatio - ratio1;
    expect(diff1 <= 1n).toBe(true);
    expect(payout1).toBe(17_842n);
    expect(payout1 > 0n).toBe(true);
    expect(getSbtcBalance(wallet1) - before1).toBe(payout1);

    const postInfo = readRedemptionInfo(marketId);
    const postRatio = BigInt(postInfo.value["redemption-ratio-bps"].value);
    const diffPost = postRatio > baseRatio ? postRatio - baseRatio : baseRatio - postRatio;
    expect(diffPost <= 1n).toBe(true);

    const before2 = getSbtcBalance(wallet2);
    const redemption2 = redeemShares(marketId, wallet2);
    expect(redemption2.result.type).toBe("ok");
    const tuple2 = cvToValue(redemption2.result) as {
      value: {
        payout: { value: string | number | bigint };
        "shares-burned": { value: string | number | bigint };
        "redemption-ratio-bps": { value: string | number | bigint };
      };
    };
    const payout2 = BigInt(tuple2.value.payout.value);
    expect(payout2).toBe(15_783n);
    expect(getSbtcBalance(wallet2) - before2).toBe(payout2);
    const ratio2 = BigInt(tuple2.value["redemption-ratio-bps"].value);
    const diff2 = ratio2 > baseRatio ? ratio2 - baseRatio : baseRatio - ratio2;
    expect(diff2 <= 1n).toBe(true);

    const finalMarket = readMarket(marketId);
    expect(BigInt(finalMarket["vault-sbtc"].value) < 5_000n).toBe(true);
    expect(getShareBalance(marketId, wallet1, true)).toBe(0n);
    expect(getShareBalance(marketId, wallet2, true)).toBe(0n);
  });
});
