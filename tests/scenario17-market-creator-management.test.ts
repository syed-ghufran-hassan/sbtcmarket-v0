import { beforeEach, describe, expect, it } from "vitest";
import { Cl, cvToValue } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  addMarketCreator,
  removeMarketCreator,
} from "./helpers/scenario-helpers";
import { expectBool, unwrapErrUint, unwrapOk } from "./helpers/assertions";

const { deployer, wallet1, wallet2 } = scenarioAccounts;

describe("Scenario 17 - Market Creator Management", () => {
  beforeEach(() => {
    [wallet1, wallet2].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("restricts market creation to authorized creators", () => {
    const unauthorized = simnet.callPublicFn(
      "sbtcmarket-v0",
      "create-market",
      [
        Cl.stringUtf8("Unauthorized Market"),
        Cl.uint(1_000_000n),
        Cl.buffer(new Uint8Array(32).fill(0)),
        Cl.int(10_000_000_000_000n),
        Cl.uint(10_000_000n),
        Cl.uint(30n),
        Cl.stringUtf8("GE"),
      ],
      wallet1,
    );
    unwrapErrUint(unauthorized.result, 1011n); // ERR-NOT-MARKET-CREATOR

    const add = addMarketCreator(wallet1, deployer);
    expectBool(unwrapOk(add.result), true);

    const authorized = createMarket({ question: "Authorized Market", caller: wallet1 });
    expect(authorized.marketId > 0n).toBe(true);

    const remove = removeMarketCreator(wallet1, deployer);
    expectBool(unwrapOk(remove.result), true);

    const postRemoval = simnet.callReadOnlyFn(
      "sbtcmarket-v0",
      "is-market-creator",
      [Cl.principal(wallet1)],
      deployer,
    );
    const value = cvToValue(postRemoval.result);
    expectBool(value, false);
  });

  it("keeps trading permissions unaffected by creator status", () => {
    const { marketId } = createMarket({ question: "Trading Market" });
    const before = addMarketCreator(wallet2, deployer);
    expectBool(unwrapOk(before.result), true);

    transferSbtc(wallet2, 500_000n);
    const buy = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(true), Cl.uint(100_000n)],
      wallet2,
    );
    expect(buy.result.type).toBe("ok");

    const remove = removeMarketCreator(wallet2, deployer);
    expectBool(unwrapOk(remove.result), true);
  });
});
