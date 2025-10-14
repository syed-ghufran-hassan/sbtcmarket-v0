import { beforeEach, describe, expect, it } from "vitest";
import {
  scenarioAccounts,
  transferSbtc,
  createMarket,
  buyShares,
  resolveMarket,
  redeemShares,
  readMarket,
} from "./helpers/scenario-helpers";
import { expectBool } from "./helpers/assertions";

const { deployer, wallet1 } = scenarioAccounts;

describe("Scenario 20 - Special Characters in Market Questions", () => {
  beforeEach(() => {
    transferSbtc(wallet1, 1_000_000_000n);
  });

  it("handles unicode and punctuation in questions through lifecycle", () => {
    const question = "Will BTC hit $150k? 🚀";
    const { marketId } = createMarket({ question });

    const market = readMarket(marketId, deployer);
    expect(market.question.value).toBe(question);

    buyShares(marketId, true, 100_000n, wallet1);
    resolveMarket(marketId, true, deployer);

    const resolveState = readMarket(marketId, deployer);
    expectBool(resolveState.resolved, true);

    const redeem = redeemShares(marketId, wallet1);
    expect(redeem.result.type).toBe("ok");
  });
});

