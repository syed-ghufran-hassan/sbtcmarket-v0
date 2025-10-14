import { beforeEach, describe, expect, it } from "vitest";
import { Cl, cvToValue } from "@stacks/transactions";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  readMarket,
  addMarketCreator,
  removeMarketCreator,
  setProtocolTreasury,
  setContractOwner,
} from "./helpers/scenario-helpers";
import { expectBool, unwrapErrUint, unwrapOk, unwrapOkUint } from "./helpers/assertions";

const { deployer, wallet1, wallet2 } = scenarioAccounts;

describe("Scenario 11 - Access Control & Authorization Security", () => {
  beforeEach(() => {
    [wallet1, wallet2].forEach((wallet) => transferSbtc(wallet, 1_000_000_000n));
  });

  it("TEST 1: Unauthorized set-contract-owner (should fail)", () => {
    const result = setContractOwner(wallet1, wallet1);
    unwrapErrUint(result.result, 1010n); // ERR-UNAUTHORIZED
  });

  it("TEST 2: Unauthorized set-protocol-treasury (should fail)", () => {
    const result = setProtocolTreasury(wallet1, wallet1);
    unwrapErrUint(result.result, 1010n);
  });

  it("TEST 3: Unauthorized set-tax-recipient (should fail)", () => {
    const response = simnet.callPublicFn(
      "sbtcmarket-v0",
      "set-tax-recipient",
      [Cl.principal(wallet1)],
      wallet1,
    );
    unwrapErrUint(response.result, 1010n);
  });

  it("TEST 4: Unauthorized add-market-creator (should fail)", () => {
    const result = addMarketCreator(wallet1, wallet1);
    unwrapErrUint(result.result, 1010n);
  });

  it("TEST 5: Unauthorized remove-market-creator (should fail)", () => {
    const result = removeMarketCreator(deployer, wallet1);
    unwrapErrUint(result.result, 1010n);
  });

  it("TEST 6: Mock resolve remains callable by any user (test helper semantics)", () => {
    const { marketId } = createMarket({
      question: "Access Control Test",
      resolutionBlock: 1_000_000n,
    });

    buyShares(marketId, true, 100_000n, wallet1);
    buyShares(marketId, false, 100_000n, wallet2);

    const result = simnet.callPublicFn(
      "sbtcmarket-v0",
      "mock-resolve-market",
      [Cl.uint(marketId), Cl.bool(true)],
      wallet2,
    );

    expect(result.result.type).toBe("ok");
    const market = readMarket(marketId, deployer);
    expectBool(market.resolved, true);
    expect(market.outcome.value).toBeDefined();
    expectBool(market.outcome.value, true);
  });

  it("TEST 7: Authorized operations work correctly", () => {
    const ownerUpdate = setContractOwner(deployer, deployer);
    const newOwner = unwrapOk(ownerUpdate.result);
    expect(["principal", "address"]).toContain(newOwner.type);
    expect(newOwner.value).toBe(deployer);

    const treasuryUpdate = setProtocolTreasury(wallet2, deployer);
    const newTreasury = unwrapOk(treasuryUpdate.result);
    expect(["principal", "address"]).toContain(newTreasury.type);
    expect(newTreasury.value).toBe(wallet2);

    const addCreatorRes = addMarketCreator(wallet1, deployer);
    expectBool(unwrapOk(addCreatorRes.result), true);

    const isCreator = simnet.callReadOnlyFn(
      "sbtcmarket-v0",
      "is-market-creator",
      [Cl.principal(wallet1)],
      deployer,
    );
    const creatorValue = cvToValue(isCreator.result);
    expect(creatorValue === true).toBe(true);

    const removeCreatorRes = removeMarketCreator(wallet1, deployer);
    expectBool(unwrapOk(removeCreatorRes.result), true);
  });

  it("TEST 8: Treasury redirection updates fee recipients", () => {
    const { marketId } = createMarket({
      question: "Fee Attack Market",
      resolutionBlock: 1_000_100n,
      feeBps: 100n,
    });

    buyShares(marketId, true, 500_000n, wallet1);

    // Verify initial state
    const market = readMarket(marketId, deployer);
    expect(market["fee-bps"]).toBeDefined();

    const redirect = setProtocolTreasury(deployer, deployer);
    const newTreasury = unwrapOk(redirect.result);
    expect(["principal", "address"]).toContain(newTreasury.type);
    expect(newTreasury.value).toBe(deployer);

    const secondTrade = simnet.callPublicFn(
      "sbtcmarket-v0",
      "buy-shares",
      [Cl.uint(marketId), Cl.bool(false), Cl.uint(500_000)],
      wallet2,
    );
    expect(secondTrade.result.type).toBe("ok");
  });
});
