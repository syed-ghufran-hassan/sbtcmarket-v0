import { describe, it, expect } from "vitest";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  readMarket,
  getShareBalance,
  mintCompleteSet,
  swapShares,
  burnCompleteSet,
} from "./helpers/scenario-helpers";

const LIQUIDITY = 10_000_000n;

function extractPrices(market: ReturnType<typeof readMarket>) {
  return {
    yes: BigInt(market["price-yes"].value),
    no: BigInt(market["price-no"].value),
  };
}

describe("Scenario 4 – AMM pricing mechanics", () => {
  it("tracks price impact, neutral operations, and constant product", () => {
    const { wallet1, wallet2, wallet3 } = scenarioAccounts;

    [wallet1, wallet2, wallet3].forEach((wallet) => {
      transferSbtc(wallet, 1_000_000_000n);
    });

    const { marketId } = createMarket({ question: "AMM Test Market" });
    const initialMarket = readMarket(marketId);
    const initialPrices = extractPrices(initialMarket);

    expect(initialPrices.yes).toBe(LIQUIDITY);
    expect(initialPrices.no).toBe(LIQUIDITY);

    buyShares(marketId, true, 10_000n, wallet1);
    const afterSmallBuy = readMarket(marketId);
    const smallPrices = extractPrices(afterSmallBuy);
    expect(smallPrices.yes < smallPrices.no).toBe(true);

    const wallet1Yes = getShareBalance(marketId, wallet1, true);
    expect(wallet1Yes > 0n).toBe(true);

    buyShares(marketId, true, 1_000_000n, wallet2);
    const afterLargeBuy = readMarket(marketId);
    const largePrices = extractPrices(afterLargeBuy);
    expect(largePrices.yes < largePrices.no).toBe(true);
    const wallet2Yes = getShareBalance(marketId, wallet2, true);
    expect(wallet2Yes > 0n).toBe(true);

    expect(wallet1Yes * 1_000_000n > wallet2Yes * 10_000n).toBe(true);

    const imbalance = largePrices.no > largePrices.yes
      ? largePrices.no - largePrices.yes
      : largePrices.yes - largePrices.no;

    buyShares(marketId, false, 1_000_000n, wallet3);
    const afterOpposite = readMarket(marketId);
    const oppositePrices = extractPrices(afterOpposite);
    const newImbalance = oppositePrices.yes > oppositePrices.no
      ? oppositePrices.yes - oppositePrices.no
      : oppositePrices.no - oppositePrices.yes;
    expect(newImbalance < imbalance).toBe(true);

    const yesBeforeMint = getShareBalance(marketId, wallet1, true);
    const noBeforeMint = getShareBalance(marketId, wallet1, false);

    const mintResult = mintCompleteSet(marketId, 50_000n, wallet1);
    expect(mintResult.result.type).toBe("ok");

    const afterMint = readMarket(marketId);
    const mintPrices = extractPrices(afterMint);
    expect(mintPrices.yes).toBe(oppositePrices.yes);
    expect(mintPrices.no).toBe(oppositePrices.no);

    const yesAfterMint = getShareBalance(marketId, wallet1, true);
    const noAfterMint = getShareBalance(marketId, wallet1, false);
    expect(yesAfterMint - yesBeforeMint).toBe(50_000n);
    expect(noAfterMint - noBeforeMint).toBe(50_000n);

    const swapResult = swapShares(marketId, false, 25_000n, wallet1);
    expect(swapResult.result.type).toBe("ok");

    const afterSwap = readMarket(marketId);
    const swapPrices = extractPrices(afterSwap);
    expect(swapPrices.yes < mintPrices.yes).toBe(true);
    expect(swapPrices.no > mintPrices.no).toBe(true);

    const yesAfterSwap = getShareBalance(marketId, wallet1, true);
    const noAfterSwap = getShareBalance(marketId, wallet1, false);
    expect(yesAfterSwap > yesAfterMint).toBe(true);
    expect(noAfterSwap < noAfterMint).toBe(true);

    const burnResult = burnCompleteSet(marketId, 20_000n, wallet1);
    expect(burnResult.result.type).toBe("ok");

    const afterBurn = readMarket(marketId);
    const burnPrices = extractPrices(afterBurn);
    expect(burnPrices.yes).toBe(swapPrices.yes);
    expect(burnPrices.no).toBe(swapPrices.no);

    const product = burnPrices.yes * burnPrices.no;
    const baseline = LIQUIDITY * LIQUIDITY;
    const deviation = product > baseline ? product - baseline : baseline - product;
    expect(deviation * 100n < baseline * 5n).toBe(true);
  });
});
