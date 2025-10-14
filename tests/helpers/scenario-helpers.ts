import { Cl, cvToValue } from "@stacks/transactions";
import { expect } from "vitest";

type Account = string;

type MarketTuple = Record<string, any>;

type RedemptionTuple = {
  winner: { type: string; value: boolean };
  "vault-balance": { type: string; value: bigint | number | string };
  "total-circulating": { type: string; value: bigint | number | string };
  "redemption-ratio-bps": { type: string; value: bigint | number | string };
};

const accountMap = simnet.getAccounts();

export const scenarioAccounts = {
  deployer: accountMap.get("deployer")! as Account,
  wallet1: accountMap.get("wallet_1")! as Account,
  wallet2: accountMap.get("wallet_2")! as Account,
  wallet3: accountMap.get("wallet_3")! as Account,
  wallet4: accountMap.get("wallet_4")! as Account,
  wallet5: accountMap.get("wallet_5")! as Account,
  wallet6: accountMap.get("wallet_6")! as Account,
  wallet7: accountMap.get("wallet_7")! as Account,
  wallet8: accountMap.get("wallet_8")! as Account,
  faucet: accountMap.get("faucet")! as Account,
};

export function transferSbtc(to: Account, amount: bigint, from: Account = scenarioAccounts.deployer) {
  const result = simnet.callPublicFn(
    "sbtc-token",
    "transfer",
    [Cl.uint(amount), Cl.principal(from), Cl.principal(to), Cl.none()],
    from
  );
  expect(result.result.type).toBe("ok");
}

interface MarketConfig {
  question?: string;
  resolutionBlock?: bigint;
  feedId?: Uint8Array;
  thresholdPrice?: bigint;
  virtualLiquidity?: bigint;
  feeBps?: bigint;
  comparison?: string;
  caller?: Account;
}

const DEFAULT_FEED = new Uint8Array(32).fill(0);

export function createMarket(config: MarketConfig = {}) {
  const {
    question = "Will BTC be above 100k?",
    resolutionBlock = 1_000_000n,
    feedId = DEFAULT_FEED,
    thresholdPrice = 10_000_000_000_000n,
    virtualLiquidity = 10_000_000n,
    feeBps = 30n,
    comparison = "GE",
    caller = scenarioAccounts.deployer,
  } = config;

  const result = simnet.callPublicFn(
    "sbtcmarket-v0",
    "create-market",
    [
      Cl.stringUtf8(question),
      Cl.uint(resolutionBlock),
      Cl.buffer(feedId),
      Cl.int(thresholdPrice),
      Cl.uint(virtualLiquidity),
      Cl.uint(feeBps),
      Cl.stringUtf8(comparison),
    ],
    caller,
  );

  expect(result.result.type).toBe("ok");
  const tuple = cvToValue(result.result) as Record<string, any>;
  const marketId = BigInt(tuple.value["market-id"].value);
  return { marketId, tuple };
}

export function getSbtcBalance(account: Account) {
  const response = simnet.callReadOnlyFn(
    "sbtc-token",
    "get-balance",
    [Cl.principal(account)],
    account,
  );
  const ok = cvToValue(response.result) as { type: string; value: bigint | number | string };
  return BigInt(ok.value);
}

export function getShareBalance(marketId: bigint, account: Account, isYes: boolean) {
  const response = simnet.callReadOnlyFn(
    "sbtcmarket-v0",
    "get-balance",
    [Cl.uint(marketId), Cl.principal(account), Cl.bool(isYes)],
    account,
  );
  const ok = cvToValue(response.result) as { type: string; value: bigint | number | string };
  return BigInt(ok.value);
}

export function readMarket(marketId: bigint, caller: Account = scenarioAccounts.deployer) {
  const response = simnet.callReadOnlyFn(
    "sbtcmarket-v0",
    "get-market",
    [Cl.uint(marketId)],
    caller,
  );
  const ok = cvToValue(response.result) as { type: string; value: MarketTuple };
  return ok.value;
}

export function readRedemptionInfo(marketId: bigint, caller: Account = scenarioAccounts.deployer) {
  const response = simnet.callReadOnlyFn(
    "sbtcmarket-v0",
    "get-redemption-info",
    [Cl.uint(marketId)],
    caller,
  );
  return cvToValue(response.result) as { type: string; value: RedemptionTuple };
}

export function buyShares(marketId: bigint, isYes: boolean, amount: bigint, caller: Account) {
  const result = simnet.callPublicFn(
    "sbtcmarket-v0",
    "buy-shares",
    [Cl.uint(marketId), Cl.bool(isYes), Cl.uint(amount)],
    caller,
  );
  expect(result.result.type).toBe("ok");
  return result.result;
}

export function sellShares(marketId: bigint, isYes: boolean, amount: bigint, caller: Account) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "sell-shares",
    [Cl.uint(marketId), Cl.bool(isYes), Cl.uint(amount)],
    caller,
  );
}

export function mintCompleteSet(marketId: bigint, amount: bigint, caller: Account) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "mint-complete-set",
    [Cl.uint(marketId), Cl.uint(amount)],
    caller,
  );
}

export function burnCompleteSet(marketId: bigint, amount: bigint, caller: Account) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "burn-complete-set",
    [Cl.uint(marketId), Cl.uint(amount)],
    caller,
  );
}

export function swapShares(marketId: bigint, fromYes: boolean, amount: bigint, caller: Account) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "swap-shares",
    [Cl.uint(marketId), Cl.bool(fromYes), Cl.uint(amount)],
    caller,
  );
}

export function resolveMarket(marketId: bigint, winner: boolean, caller: Account = scenarioAccounts.deployer) {
  const result = simnet.callPublicFn(
    "sbtcmarket-v0",
    "mock-resolve-market",
    [Cl.uint(marketId), Cl.bool(winner)],
    caller,
  );
  expect(result.result.type).toBe("ok");
  return result.result;
}

export function redeemShares(marketId: bigint, caller: Account) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "redeem-shares",
    [Cl.uint(marketId)],
    caller,
  );
}

export function refundShares(marketId: bigint, caller: Account) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "refund-shares",
    [Cl.uint(marketId)],
    caller,
  );
}

export function cancelMarket(marketId: bigint, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "cancel-market",
    [Cl.uint(marketId)],
    caller,
  );
}

export function advanceBlocks(count: number) {
  for (let i = 0; i < count; i += 1) {
    simnet.mineEmptyBlock();
  }
}

export function setBurnBlockHeight(height: bigint, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "set-burn-block-height",
    [Cl.uint(height)],
    caller,
  );
}

export function setCancelTimeoutBlocks(blocks: bigint, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "set-cancel-timeout-blocks",
    [Cl.uint(blocks)],
    caller,
  );
}

export function addMarketCreator(account: Account, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "add-market-creator",
    [Cl.principal(account)],
    caller,
  );
}

export function removeMarketCreator(account: Account, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "remove-market-creator",
    [Cl.principal(account)],
    caller,
  );
}

export function setProtocolTreasury(account: Account, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "set-protocol-treasury",
    [Cl.principal(account)],
    caller,
  );
}

export function setContractOwner(account: Account, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "set-contract-owner",
    [Cl.principal(account)],
    caller,
  );
}

export function setMarketMetadata(marketId: bigint, key: string, value: string, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "set-market-metadata",
    [Cl.uint(marketId), Cl.stringUtf8(key), Cl.stringUtf8(value)],
    caller,
  );
}

export function updateFeeBps(marketId: bigint, feeBps: bigint, caller: Account = scenarioAccounts.deployer) {
  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "set-fee-bps",
    [Cl.uint(marketId), Cl.uint(feeBps)],
    caller,
  );
}

export function fetchVaultBalance(marketId: bigint) {
  const market = readMarket(marketId);
  return BigInt(market["vault-sbtc"].value);
}

export function fetchWinningCirculation(marketId: bigint, winner: boolean) {
  const market = readMarket(marketId);
  const key = winner ? "yes-circulating" : "no-circulating";
  return BigInt(market[key].value);
}

