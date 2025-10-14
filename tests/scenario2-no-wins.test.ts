import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  resolveMarket,
  redeemShares,
  getSbtcBalance,
  getShareBalance,
  readMarket,
} from "./helpers/scenario-helpers";

describe("Scenario 2 – NO wins", () => {
  it("pays NO holders proportionally and blocks YES redemptions", () => {
    const {
      wallet1,
      wallet2,
      wallet3,
      wallet4,
      wallet5,
      wallet6,
      wallet7,
    } = scenarioAccounts;

    const FUND = 1_000_000_000n;
    [wallet1, wallet2, wallet3, wallet4, wallet5, wallet6, wallet7].forEach((wallet) => {
      transferSbtc(wallet, FUND);
    });

    const { marketId } = createMarket();

    buyShares(marketId, true, 100_000n, wallet1);
    buyShares(marketId, true, 150_000n, wallet2);
    buyShares(marketId, true, 200_000n, wallet3);

    buyShares(marketId, false, 120_000n, wallet4);
    buyShares(marketId, false, 180_000n, wallet5);
    buyShares(marketId, false, 90_000n, wallet6);
    buyShares(marketId, false, 250_000n, wallet7);

    expect(getShareBalance(marketId, wallet4, false) > 0n).toBe(true);
    expect(getShareBalance(marketId, wallet7, false) > 0n).toBe(true);

    resolveMarket(marketId, false);

    const winners = [wallet4, wallet5, wallet6, wallet7];
    winners.forEach((wallet) => {
      const before = getSbtcBalance(wallet);
      const redemption = redeemShares(marketId, wallet);
      expect(redemption.result.type).toBe("ok");
      const after = getSbtcBalance(wallet);
      expect(after > before).toBe(true);
    });

    const loserRedeem = redeemShares(marketId, wallet1);
    expect(loserRedeem.result).toBeErr(Cl.uint(1003));

    const finalMarket = readMarket(marketId);
    expect(finalMarket.resolved.value).toBe(true);
    const vaultRemainder = BigInt(finalMarket["vault-sbtc"].value);
    expect(vaultRemainder < 5_000n).toBe(true);
  });
});
