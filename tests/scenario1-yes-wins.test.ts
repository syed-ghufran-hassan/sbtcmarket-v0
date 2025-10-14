import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const traderA = accounts.get("wallet_1")!;
const traderB = accounts.get("wallet_2")!;
const traderC = accounts.get("wallet_3")!;

const MARKET_ID = 1;
const FUND_AMOUNT = 1_000_000_000n;
const FEE_BPS = 30;
const VIRTUAL_LIQUIDITY = 10_000_000n;
const RESOLUTION_BLOCK = 1_000_000n;
const THRESHOLD_PRICE = 10_000_000_000_000n;
const FEED_ID = new Uint8Array(32).fill(0);

function transferSbtc(to: string, amount: bigint) {
  const result = simnet.callPublicFn(
    "sbtc-token",
    "transfer",
    [Cl.uint(amount), Cl.principal(deployer), Cl.principal(to), Cl.none()],
    deployer
  );
  expect(result.result.type).toBe("ok");
}

function createMarket() {
  const result = simnet.callPublicFn(
    "sbtcmarket-v0",
    "create-market",
    [
      Cl.stringUtf8("Will BTC be above 100k?"),
      Cl.uint(RESOLUTION_BLOCK),
      Cl.buffer(FEED_ID),
      Cl.int(THRESHOLD_PRICE),
      Cl.uint(VIRTUAL_LIQUIDITY),
      Cl.uint(FEE_BPS),
      Cl.stringUtf8("GE")
    ],
    deployer
  );

  expect(result.result.type).toBe("ok");
  const ok = result.result as {
    value: { type: string; value: Record<string, { value: string | number | bigint }> };
  };
  expect(ok.value.type).toBe("tuple");
  const fields = ok.value.value;
  expect(fields["market-id"]).toBeDefined();
  expect(BigInt(fields["market-id"].value)).toBe(BigInt(MARKET_ID));
}

function getSbtcBalance(address: string): bigint {
  const response = simnet.callReadOnlyFn(
    "sbtc-token",
    "get-balance",
    [Cl.principal(address)],
    address
  );
  const ok = response.result as { value: { value: string | number | bigint } };
  return BigInt(ok.value.value);
}

function getYesBalance(address: string): bigint {
  const response = simnet.callReadOnlyFn(
    "sbtcmarket-v0",
    "get-balance",
    [Cl.uint(MARKET_ID), Cl.principal(address), Cl.bool(true)],
    address
  );
  const ok = response.result as { value: { value: string | number | bigint } };
  return BigInt(ok.value.value);
}

function getMarketState() {
  const response = simnet.callReadOnlyFn(
    "sbtcmarket-v0",
    "get-market",
    [Cl.uint(MARKET_ID)],
    deployer
  );

  const ok = response.result as {
    type: string;
    value: { type: string; value: Record<string, any> };
  };
  expect(ok.type).toBe("ok");
  expect(ok.value.type).toBe("tuple");
  return ok.value.value;
}

function assertRedeem(result: any, sharesBurned: bigint, payout: bigint) {
  const ratio = sharesBurned === 0n ? 0n : (payout * 10_000n) / sharesBurned;

  expect(result).toBeOk(
    Cl.tuple({
      "shares-burned": Cl.uint(sharesBurned),
      payout: Cl.uint(payout),
      "redemption-ratio-bps": Cl.uint(ratio)
    })
  );
}

describe("Scenario 1 – YES wins", () => {
  it("mirrors the console walkthrough with a deterministic unit test", () => {
    // Arrange: fund participants and create the market
    transferSbtc(traderA, FUND_AMOUNT);
    transferSbtc(traderB, FUND_AMOUNT);
    transferSbtc(traderC, FUND_AMOUNT);

    createMarket();

    const initialMarket = getMarketState();
    expect(initialMarket.resolved.type).toBe("false");

    // Act: three traders buy YES shares with different stake sizes
    const spendA = 100_000n;
    const spendB = 150_000n;
    const spendC = 200_000n;

    expect(
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(MARKET_ID), Cl.bool(true), Cl.uint(spendA)],
        traderA
      ).result.type
    ).toBe("ok");

    expect(
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(MARKET_ID), Cl.bool(true), Cl.uint(spendB)],
        traderB
      ).result.type
    ).toBe("ok");

    expect(
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(MARKET_ID), Cl.bool(true), Cl.uint(spendC)],
        traderC
      ).result.type
    ).toBe("ok");

    const yesA = getYesBalance(traderA);
    const yesB = getYesBalance(traderB);
    const yesC = getYesBalance(traderC);

    expect(yesA > 0n).toBe(true);
    expect(yesB > 0n).toBe(true);
    expect(yesC > 0n).toBe(true);

    const marketAfterTrades = getMarketState();
    const circulatingYes = BigInt(marketAfterTrades["yes-circulating"].value);
    expect(circulatingYes).toBe(yesA + yesB + yesC);

    // Resolve the market in favour of YES
    const resolution = simnet.callPublicFn(
      "sbtcmarket-v0",
      "mock-resolve-market",
      [Cl.uint(MARKET_ID), Cl.bool(true)],
      deployer
    );
    expect(resolution.result.type).toBe("ok");

    // Redemption: each trader receives a proportional payout
    const preRedeemA = getSbtcBalance(traderA);
    const redeemA = simnet.callPublicFn(
      "sbtcmarket-v0",
      "redeem-shares",
      [Cl.uint(MARKET_ID)],
      traderA
    );
    const postRedeemA = getSbtcBalance(traderA);
    const payoutA = postRedeemA - preRedeemA;
    assertRedeem(redeemA.result, yesA, payoutA);

    const preRedeemB = getSbtcBalance(traderB);
    const redeemB = simnet.callPublicFn(
      "sbtcmarket-v0",
      "redeem-shares",
      [Cl.uint(MARKET_ID)],
      traderB
    );
    const postRedeemB = getSbtcBalance(traderB);
    const payoutB = postRedeemB - preRedeemB;
    assertRedeem(redeemB.result, yesB, payoutB);

    const preRedeemC = getSbtcBalance(traderC);
    const redeemC = simnet.callPublicFn(
      "sbtcmarket-v0",
      "redeem-shares",
      [Cl.uint(MARKET_ID)],
      traderC
    );
    const postRedeemC = getSbtcBalance(traderC);
    const payoutC = postRedeemC - preRedeemC;
    assertRedeem(redeemC.result, yesC, payoutC);

    expect(getYesBalance(traderA)).toBe(0n);
    expect(getYesBalance(traderB)).toBe(0n);
    expect(getYesBalance(traderC)).toBe(0n);

    const finalMarket = getMarketState();
    expect(finalMarket["vault-sbtc"].value).toBe(0n);
  });
});
