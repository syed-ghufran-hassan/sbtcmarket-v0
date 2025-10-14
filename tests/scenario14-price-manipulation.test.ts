import { beforeEach, describe, expect, it } from "vitest";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  sellShares,
  readMarket,
  getShareBalance,
} from "./helpers/scenario-helpers";
import { expectUint } from "./helpers/assertions";

const { deployer, wallet1: victim, wallet2: attacker, wallet3: whale } = scenarioAccounts;

describe("Scenario 14 - Price Manipulation & Sandwich Attacks", () => {
  beforeEach(() => {
    [victim, attacker, whale].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("starts markets at balanced 50/50 pricing", () => {
    const { marketId } = createMarket({ question: "Fair Market", virtualLiquidity: 10_000_000n });
    const market = readMarket(marketId, deployer);
    expectUint(market["price-yes"], 10_000_000n);
    expectUint(market["price-no"], 10_000_000n);
  });

  it("illustrates sandwich attack mechanics with front-run and back-run", () => {
    const { marketId } = createMarket({ question: "Sandwich Market" });

    buyShares(marketId, true, 500_000n, attacker);
    buyShares(marketId, true, 100_000n, victim);

    const attackerYes = getShareBalance(marketId, attacker, true);
    expect(attackerYes > 0n).toBe(true);

    const sell = sellShares(marketId, true, attackerYes / 2n, attacker);
    expect(sell.result.type).toBe("ok");

    const market = readMarket(marketId, deployer);
    const yesPrice = expectUint(market["price-yes"]);
    const noPrice = expectUint(market["price-no"]);
    expect(yesPrice !== noPrice).toBe(true);
  });

  it("shows whales can swing prices across extremes", () => {
    const { marketId } = createMarket({ question: "Whale Market", virtualLiquidity: 5_000_000n });

    buyShares(marketId, true, 2_000_000n, whale);
    buyShares(marketId, false, 1_500_000n, whale);

    const market = readMarket(marketId, deployer);
    const yesReserve = expectUint(market["price-yes"]);
    const noReserve = expectUint(market["price-no"]);
    expect(yesReserve !== noReserve).toBe(true);
    const diff = yesReserve > noReserve ? yesReserve - noReserve : noReserve - yesReserve;
    expect(diff > 0n).toBe(true);
  });
});

