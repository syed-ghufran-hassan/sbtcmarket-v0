import { describe, it, expect } from "vitest";
import { Cl, cvToValue } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  getShareBalance,
  readMarket,
  mintCompleteSet,
  swapShares,
  burnCompleteSet,
  resolveMarket,
  redeemShares,
  getSbtcBalance,
  setProtocolTreasury,
} from "./helpers/scenario-helpers";

const FEE_DENOMINATOR = 10_000n;
const TAX_RATE = 100n; // 1%

function netAmount(amount: bigint) {
  return amount - (amount * TAX_RATE) / FEE_DENOMINATOR;
}

describe("Scenario 6 – Fee collection and treasury", () => {
  it("collects, tracks, and redeems protocol fees", () => {
    const { deployer, wallet1, wallet2 } = scenarioAccounts;

    [wallet1, wallet2].forEach((account) => transferSbtc(account, 1_000_000_000n));

    const marketLow = createMarket({ question: "Low Fee Market", feeBps: 10n }).marketId;
    const marketMedium = createMarket({ question: "Medium Fee Market", feeBps: 30n }).marketId;
    const marketHigh = createMarket({ question: "High Fee Market", feeBps: 100n }).marketId;

    expect(getShareBalance(marketLow, deployer, false)).toBe(0n);

    buyShares(marketLow, true, 100_000n, wallet1);
    const lowFee = (netAmount(100_000n) * 10n) / FEE_DENOMINATOR;
    expect(getShareBalance(marketLow, deployer, false)).toBe(lowFee);
    const lowState = readMarket(marketLow);
    expect(BigInt(lowState["fees-no"].value)).toBe(lowFee);

    expect(getShareBalance(marketMedium, deployer, false)).toBe(0n);
    buyShares(marketMedium, true, 100_000n, wallet1);
    const mediumFirst = (netAmount(100_000n) * 30n) / FEE_DENOMINATOR;
    expect(getShareBalance(marketMedium, deployer, false)).toBe(mediumFirst);

    expect(getShareBalance(marketHigh, deployer, false)).toBe(0n);
    buyShares(marketHigh, true, 100_000n, wallet1);
    const highFee = (netAmount(100_000n) * 100n) / FEE_DENOMINATOR;
    expect(getShareBalance(marketHigh, deployer, false)).toBe(highFee);

    buyShares(marketMedium, true, 200_000n, wallet2);
    const mediumSecond = (netAmount(200_000n) * 30n) / FEE_DENOMINATOR;
    const treasuryNoMedium = getShareBalance(marketMedium, deployer, false);
    expect(treasuryNoMedium).toBe(mediumFirst + mediumSecond);
    const mediumState = readMarket(marketMedium);
    expect(BigInt(mediumState["fees-no"].value)).toBe(mediumFirst + mediumSecond);

    const treasuryYesBeforeSwap = getShareBalance(marketMedium, deployer, true);
    expect(mintCompleteSet(marketMedium, 50_000n, wallet1).result.type).toBe("ok");
    expect(swapShares(marketMedium, true, 25_000n, wallet1).result.type).toBe("ok");
    const swapFee = (25_000n * 30n) / FEE_DENOMINATOR;
    const treasuryYesAfterSwap = getShareBalance(marketMedium, deployer, true);
    expect(treasuryYesAfterSwap - treasuryYesBeforeSwap).toBe(swapFee);
    const mediumAfterSwap = readMarket(marketMedium);
    expect(BigInt(mediumAfterSwap["fees-yes"].value)).toBe(swapFee);

    const treasuryYesBefore = getShareBalance(marketMedium, deployer, true);
    const treasuryNoBefore = getShareBalance(marketMedium, deployer, false);
    expect(mintCompleteSet(marketMedium, 30_000n, wallet1).result.type).toBe("ok");
    expect(burnCompleteSet(marketMedium, 20_000n, wallet1).result.type).toBe("ok");
    expect(getShareBalance(marketMedium, deployer, true)).toBe(treasuryYesBefore);
    expect(getShareBalance(marketMedium, deployer, false)).toBe(treasuryNoBefore);

    resolveMarket(marketMedium, true);
    const treasuryYesForRedeem = getShareBalance(marketMedium, deployer, true);
    expect(treasuryYesForRedeem > 0n).toBe(true);
    const sbtcBefore = getSbtcBalance(deployer);
    const treasuryRedeem = redeemShares(marketMedium, deployer);
    expect(treasuryRedeem.result.type).toBe("ok");
    const redeemTuple = cvToValue(treasuryRedeem.result) as {
      value: { payout: { value: string | number | bigint } };
    };
    const payout = BigInt(redeemTuple.value.payout.value);
    const sbtcAfter = getSbtcBalance(deployer);
    expect(sbtcAfter - sbtcBefore).toBe(payout);
    expect(getShareBalance(marketMedium, deployer, true)).toBe(0n);

    const currentTreasury = simnet.callReadOnlyFn(
      "sbtcmarket-v0",
      "get-protocol-treasury",
      [],
      deployer,
    );
    const treasuryValue = cvToValue(currentTreasury.result) as { value: string };
    expect(treasuryValue.value).toBe(deployer);

    const unauthorizedChange = simnet.callPublicFn(
      "sbtcmarket-v0",
      "set-protocol-treasury",
      [Cl.principal(wallet2)],
      wallet1,
    );
    expect(unauthorizedChange.result).toBeErr(Cl.uint(1010));

    const changeTreasury = setProtocolTreasury(wallet2, deployer);
    expect(changeTreasury.result.type).toBe("ok");

    const updatedTreasury = simnet.callReadOnlyFn(
      "sbtcmarket-v0",
      "get-protocol-treasury",
      [],
      deployer,
    );
    const updatedValue = cvToValue(updatedTreasury.result) as { value: string };
    expect(updatedValue.value).toBe(wallet2);
  });
});
