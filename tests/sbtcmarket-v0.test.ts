import { describe, expect, it, beforeEach } from "vitest";
import { Cl } from "@stacks/transactions";
import {
  unwrapOk,
  unwrapErr,
  expectUint,
  expectBool,
  unwrapOkUint,
  unwrapErrUint,
  unwrapSome,
} from "./helpers/assertions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get("wallet_2")!;
const wallet3 = accounts.get("wallet_3")!;

// Helper to create a test market
function createTestMarket(
  question: string = "Will BTC be above 100k?",
  resolutionBlock: number = 1000000,
  virtualLiquidity: number = 10000000,
  feeBps: number = 30
) {
  const feedId = new Uint8Array(32).fill(0); // Mock feed ID
  const thresholdPrice = 100000000000; // 100k in cents with 6 decimals

  return simnet.callPublicFn(
    "sbtcmarket-v0",
    "create-market",
    [
      Cl.stringUtf8(question),
      Cl.uint(resolutionBlock),
      Cl.buffer(feedId),
      Cl.int(thresholdPrice),
      Cl.uint(virtualLiquidity),
      Cl.uint(feeBps),
      Cl.stringUtf8("GE")
    ],
    deployer
  );
}

function mintSbtc(recipient: string, amount: number | bigint) {
  const result = simnet.callPublicFn(
    "sbtc-token",
    "transfer",
    [
      Cl.uint(typeof amount === "bigint" ? amount : BigInt(amount)),
      Cl.principal(deployer),
      Cl.principal(recipient),
      Cl.none()
    ],
    deployer
  );

  expect(result.result.type).toBe("ok");
}

function unwrapOkTuple(response: any) {
  const value = unwrapOk(response);
  expect(value.type).toBe("tuple");
  return value.value;
}

function advanceBlocks(blocks: number) {
  for (let i = 0; i < blocks; i++) {
    simnet.mineEmptyBlock();
  }
}

describe("sBTC Market v0 - Contract Tests", () => {
  // ======= EXISTING TESTS =======

  describe("create-market", () => {
    it("successfully creates a new market", () => {
      const result = createTestMarket();

      const created = unwrapOkTuple(result.result);
      expectUint(created["market-id"], 1n);

      // Verify market was created with correct initial state
      const market = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-market",
        [Cl.uint(1)],
        wallet1
      );
      const marketTuple = unwrapOkTuple(market.result);
      expectUint(marketTuple["resolution-block"], 1000000n);
      expectUint(marketTuple["vault-sbtc"], 0n);
      expectUint(marketTuple["yes-issued"], 0n);
      expectUint(marketTuple["no-issued"], 0n);
      expectUint(marketTuple["yes-circulating"], 0n);
      expectUint(marketTuple["no-circulating"], 0n);
      expectUint(marketTuple["price-yes"], 10000000n);
      expectUint(marketTuple["price-no"], 10000000n);
      expectUint(marketTuple["virtual-liquidity"], 10000000n);
      expectUint(marketTuple["fee-bps"], 30n);
      expectBool(marketTuple.resolved, false);
      expect(marketTuple.outcome.type).toBe("none");
    });

    it("creates multiple markets with incrementing IDs", () => {
      const market1 = createTestMarket("Market 1");
      const market2 = createTestMarket("Market 2");
      const market3 = createTestMarket("Market 3");

      expectUint(unwrapOkTuple(market1.result)["market-id"], 1n);
      expectUint(unwrapOkTuple(market2.result)["market-id"], 2n);
      expectUint(unwrapOkTuple(market3.result)["market-id"], 3n);
    });

    it("rejects invalid comparison type", () => {
      const feedId = new Uint8Array(32).fill(0);

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "create-market",
        [
          Cl.stringUtf8("Test"),
          Cl.uint(1000000),
          Cl.buffer(feedId),
          Cl.int(100000),
          Cl.uint(10000000),
          Cl.uint(30),
          Cl.stringUtf8("XX") // Invalid comparison type
        ],
        deployer
      );

      expect(unwrapErrUint(result.result)).toBe(1009n); // ERR-INVALID-COMPARISON
    });
  });

  describe("mint-complete-set", () => {
    beforeEach(() => {
      createTestMarket();
      mintSbtc(wallet1, 100000000); // 1 sBTC
    });

    it("successfully mints complete set of shares", () => {
      const amount = 10000; // 10,000 sats

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(amount)],
        wallet1
      );
      const minted = unwrapOk(result.result);
      expect(minted.type).toBe("tuple");
      expectUint(minted.value.yes, amount);
      expectUint(minted.value.no, amount);

      // Verify balances
      const yesBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(true)],
        wallet1
      );
      expect(unwrapOkUint(yesBalance.result)).toBe(BigInt(amount));

      const noBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(false)],
        wallet1
      );
      expect(unwrapOkUint(noBalance.result)).toBe(BigInt(amount));
    });

    it("fails when user has insufficient sBTC", () => {
      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(200000000)], // More than wallet has
        wallet1
      );
      expect(unwrapErrUint(result.result)).toBe(1n); // ft-transfer error
    });

    it("fails with zero amount", () => {
      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(0)],
        wallet1
      );
      expect(unwrapErrUint(result.result)).toBe(1004n); // ERR-ZERO-AMOUNT
    });

    it("fails for non-existent market", () => {
      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(999), Cl.uint(10000)],
        wallet1
      );
      expect(unwrapErrUint(result.result)).toBe(1000n); // ERR-NO-MARKET
    });
  });

  describe("burn-complete-set", () => {
    beforeEach(() => {
      createTestMarket();
      mintSbtc(wallet1, 100000000);

      // Mint a complete set first
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(10000)],
        wallet1
      );
    });

    it("successfully burns complete set and returns sBTC", () => {
      const burnAmount = 5000;

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "burn-complete-set",
        [Cl.uint(1), Cl.uint(burnAmount)],
        wallet1
      );
      expect(unwrapOkUint(result.result)).toBe(BigInt(burnAmount));

      // Verify balances decreased
      const yesBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(true)],
        wallet1
      );
      expect(unwrapOkUint(yesBalance.result)).toBe(5000n); // 10000 - 5000
    });

    it("fails when user doesn't have complete set", () => {
      // User has 10k YES and 10k NO, try to burn 15k
      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "burn-complete-set",
        [Cl.uint(1), Cl.uint(15000)],
        wallet1
      );

      expect(unwrapErrUint(result.result)).toBe(1005n); // ERR-INSUFFICIENT-BALANCE
    });
  });

  describe("swap-shares", () => {
    beforeEach(() => {
      createTestMarket();
      mintSbtc(wallet1, 100000000);

      // Mint complete set to have shares to swap
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(10000)],
        wallet1
      );
    });

    it("successfully swaps NO shares for YES shares", () => {
      const swapAmount = 5000;

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "swap-shares",
        [Cl.uint(1), Cl.bool(false), Cl.uint(swapAmount)], // Swap from NO side
        wallet1
      );
      const amountOut = unwrapOkUint(result.result);
      expect(amountOut > 0n).toBe(true);

      // NO balance should decrease
      const noBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(false)],
        wallet1
      );
      expect(unwrapOkUint(noBalance.result) < 10000n).toBe(true);

      // YES balance should increase
      const yesBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(true)],
        wallet1
      );
      expect(unwrapOkUint(yesBalance.result) > 10000n).toBe(true);
    });

    it("fails when swapping more shares than owned", () => {
      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "swap-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(20000)], // More than owned
        wallet1
      );
      expect(unwrapErrUint(result.result)).toBe(1005n); // ERR-INSUFFICIENT-BALANCE
    });
  });

  describe("buy-shares", () => {
    beforeEach(() => {
      createTestMarket();
      mintSbtc(wallet1, 100000000); // 1 sBTC
    });

    it("successfully buys YES shares", () => {
      const sbtcAmount = 10000; // 10,000 sats

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(sbtcAmount)], // Buy YES
        wallet1
      );
      const finalBalance = unwrapOkUint(result.result);
      expect(finalBalance > 0n).toBe(true);

      // User should have YES shares
      const yesBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(true)],
        wallet1
      );
      expect(unwrapOkUint(yesBalance.result) > 0n).toBe(true);

      // User should have minimal or no NO shares (swapped away)
      const noBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(false)],
        wallet1
      );
      expect(unwrapOkUint(noBalance.result) <= 100n).toBe(true); // Allow for rounding
    });

    it("successfully buys NO shares", () => {
      const sbtcAmount = 10000;

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(false), Cl.uint(sbtcAmount)], // Buy NO
        wallet1
      );

      expect(unwrapOkUint(result.result) > 0n).toBe(true);

      const noBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(false)],
        wallet1
      );
      expect(unwrapOkUint(noBalance.result) > 0n).toBe(true);
    });

    it("fails with insufficient sBTC", () => {
      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(200000000)], // More than wallet has
        wallet1
      );
      expect(result.result.type).toBe("err");
    });
  });

  describe("sell-shares", () => {
    beforeEach(() => {
      createTestMarket();
      mintSbtc(wallet1, 100000000);

      // Buy some YES shares first
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(10000)],
        wallet1
      );
    });

    it("successfully sells YES shares for sBTC", () => {
      const sharesToSell = 5000;

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "sell-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(sharesToSell)],
        wallet1
      );
      const received = unwrapOkUint(result.result);
      expect(received > 0n).toBe(true);

      // YES balance should decrease
      const yesBalance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(true)],
        wallet1
      );
      expect(unwrapOkUint(yesBalance.result) < 10000n).toBe(true);
    });

    it("fails when selling more shares than owned", () => {
      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "sell-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(1000000)], // Way more than owned
        wallet1
      );
      expect(unwrapErrUint(result.result)).toBe(1005n); // ERR-INSUFFICIENT-BALANCE
    });
  });

  describe("read-only functions", () => {
    beforeEach(() => {
      createTestMarket();
      mintSbtc(wallet1, 100000000);

      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(10000)],
        wallet1
      );
    });

    it("get-balance returns correct balance", () => {
      const result = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(true)],
        wallet1
      );
      expect(unwrapOkUint(result.result) > 0n).toBe(true);
    });

    it("get-market returns market info", () => {
      const result = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-market",
        [Cl.uint(1)],
        wallet1
      );
      const tuple = unwrapOkTuple(result.result);
      expectUint(tuple["resolution-block"], 1000000n);
    });

    it("get-balance returns 0 for non-existent balance", () => {
      const result = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet2), Cl.bool(true)],
        wallet2
      );
      expect(unwrapOkUint(result.result)).toBe(0n);
    });
  });

  describe("circulating share tracking", () => {
    beforeEach(() => {
      createTestMarket();
      mintSbtc(wallet1, 100000000);
    });

    it("tracks circulating shares through mint-complete-set", () => {
      const amount = 10000;

      simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(amount)],
        wallet1
      );

      const market = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-market",
        [Cl.uint(1)],
        wallet1
      );
      const marketData = unwrapOkTuple(market.result);
      expectUint(marketData["yes-circulating"], amount);
      expectUint(marketData["no-circulating"], amount);
    });

    it("tracks circulating shares through swaps", () => {
      const mintAmount = 10000;

      // Mint complete set
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(mintAmount)],
        wallet1
      );

      // Swap NO shares for YES
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "swap-shares",
        [Cl.uint(1), Cl.bool(false), Cl.uint(5000)],
        wallet1
      );

      const market = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-market",
        [Cl.uint(1)],
        wallet1
      );
      const marketData = unwrapOkTuple(market.result);
      const yesCirculating = expectUint(marketData["yes-circulating"]);
      const noCirculating = expectUint(marketData["no-circulating"]);
      expect(yesCirculating > BigInt(mintAmount)).toBe(true);
      expect(noCirculating < BigInt(mintAmount)).toBe(true);
    });
  });

  describe("fee calculation", () => {
    beforeEach(() => {
      createTestMarket("Test Market", 1000000, 10000000, 100); // 1% fee
      mintSbtc(wallet1, 100000000);
    });

    it("charges fees on swaps", () => {
      const mintAmount = 10000;

      // Mint complete set
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "mint-complete-set",
        [Cl.uint(1), Cl.uint(mintAmount)],
        wallet1
      );

      // Get initial treasury balance
      const treasuryBefore = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(deployer), Cl.bool(false)],
        deployer
      );

      // Perform swap (should charge 1% fee)
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "swap-shares",
        [Cl.uint(1), Cl.bool(false), Cl.uint(5000)],
        wallet1
      );

      // Treasury should have received fees
      const treasuryAfter = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(deployer), Cl.bool(false)],
        deployer
      );
      const before = unwrapOkUint(treasuryBefore.result);
      const after = unwrapOkUint(treasuryAfter.result);
      expect(after > before).toBe(true);
    });
  });

  describe("edge cases", () => {
    it("handles multiple users trading in same market", () => {
      createTestMarket();
      mintSbtc(wallet1, 100000000);
      mintSbtc(wallet2, 100000000);
      mintSbtc(wallet3, 100000000);

      // All three users buy shares
      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(10000)],
        wallet1
      );

      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(false), Cl.uint(15000)],
        wallet2
      );

      simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(20000)],
        wallet3
      );

      // All should have their respective shares
      const wallet1Balance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet1), Cl.bool(true)],
        wallet1
      );
      expect(unwrapOkUint(wallet1Balance.result) > 0n).toBe(true);

      const wallet2Balance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet2), Cl.bool(false)],
        wallet2
      );
      expect(unwrapOkUint(wallet2Balance.result) > 0n).toBe(true);

      const wallet3Balance = simnet.callReadOnlyFn(
        "sbtcmarket-v0",
        "get-balance",
        [Cl.uint(1), Cl.principal(wallet3), Cl.bool(true)],
        wallet3
      );
      expect(unwrapOkUint(wallet3Balance.result) > 0n).toBe(true);
    });

    it("handles very small amounts", () => {
      createTestMarket();
      mintSbtc(wallet1, 100000000);

      const result = simnet.callPublicFn(
        "sbtcmarket-v0",
        "buy-shares",
        [Cl.uint(1), Cl.bool(true), Cl.uint(100)], // Very small amount
        wallet1
      );
      expect(unwrapOkUint(result.result) > 0n).toBe(true);
    });
  });

  // ======= NEW TWAP ENHANCEMENT TESTS =======

  describe("TWAP - Time-Weighted Average Price", () => {
    const OBSERVATION_FREQUENCY = 100;
    const TWAP_WINDOW = 500;

    beforeEach(() => {
      // Create market with deployer (who will enable TWAP)
      createTestMarket();
      mintSbtc(wallet1, 1000000000); // 10 sBTC for trading
      mintSbtc(wallet2, 1000000000);
    });

    describe("enable-twap", () => {
      it("enables TWAP for a market before any trading", () => {
        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(OBSERVATION_FREQUENCY), Cl.uint(TWAP_WINDOW)],
          deployer
        );
        expect(result.result.type).toBe("ok");

        // Verify config was set
        const config = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-twap-config",
          [Cl.uint(1)],
          deployer
        );
        const configTuple = unwrapSome(config.result);
        expectBool(configTuple.enabled, true);
        expectUint(configTuple["observation-frequency"], OBSERVATION_FREQUENCY);
        expectUint(configTuple["observation-count"], 1n); // Initial observation taken
      });

      it("fails if not called by market creator", () => {
        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(OBSERVATION_FREQUENCY), Cl.uint(TWAP_WINDOW)],
          wallet1 // Not creator
        );
        expect(unwrapErrUint(result.result)).toBe(1010n); // ERR-UNAUTHORIZED
      });

      it("fails if TWAP window is too small", () => {
        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(OBSERVATION_FREQUENCY), Cl.uint(50)], // Window < frequency
          deployer
        );
        expect(unwrapErrUint(result.result)).toBe(1102n); // ERR-TWAP-WINDOW-TOO-SMALL
      });

      it("fails if market already has trades", () => {
        // Make a trade first
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "buy-shares",
          [Cl.uint(1), Cl.bool(true), Cl.uint(10000)],
          wallet1
        );

        // Try to enable TWAP
        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(OBSERVATION_FREQUENCY), Cl.uint(TWAP_WINDOW)],
          deployer
        );
        expect(unwrapErrUint(result.result)).toBe(1014n); // ERR-TOO-LATE
      });
    });

    describe("take-twap-observation", () => {
      beforeEach(() => {
        // Enable TWAP first
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(OBSERVATION_FREQUENCY), Cl.uint(TWAP_WINDOW)],
          deployer
        );

        // Add some trades to create price movement
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "buy-shares",
          [Cl.uint(1), Cl.bool(true), Cl.uint(50000)],
          wallet1
        );
      });

      it("anyone can take observations after enough blocks", () => {
        // Advance blocks to pass observation frequency
        advanceBlocks(OBSERVATION_FREQUENCY + 10);

        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation",
          [Cl.uint(1)],
          wallet2 // Different user
        );
        expect(result.result.type).toBe("ok");

        // Verify observation was recorded
        const config = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-twap-config",
          [Cl.uint(1)],
          deployer
        );
        const configTuple = unwrapSome(config.result);
        expectUint(configTuple["observation-count"], 2n); // Should have 2 observations now
      });

      it("returns false if not enough blocks passed", () => {
        // Try to observe immediately
        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation",
          [Cl.uint(1)],
          wallet1
        );
        expect(result.result.type).toBe("ok");
        expect(result.result.value).toBe(false); // Should return false (no observation taken)
      });

      it("fails if TWAP not enabled", () => {
        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation",
          [Cl.uint(2)], // Market without TWAP
          wallet1
        );
        expect(unwrapErrUint(result.result)).toBe(1100n); // ERR-TWAP-NOT-ENABLED
      });
    });

    describe("calculate-twap", () => {
      beforeEach(() => {
        // Enable TWAP
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(50), Cl.uint(200)], // Smaller values for test
          deployer
        );

        // Create price movement through trades
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "buy-shares",
          [Cl.uint(1), Cl.bool(true), Cl.uint(100000)],
          wallet1
        );

        // Take first observation
        advanceBlocks(60);
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation",
          [Cl.uint(1)],
          wallet1
        );

        // More trades to move price
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "buy-shares",
          [Cl.uint(1), Cl.bool(false), Cl.uint(80000)],
          wallet2
        );

        // Take second observation
        advanceBlocks(60);
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation",
          [Cl.uint(1)],
          wallet1
        );
      });

      it("calculates TWAP over specified window", () => {
        const startBlock = 100; // Mock start block
        const endBlock = 200;   // Mock end block

        const result = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "calculate-twap",
          [Cl.uint(1), Cl.uint(startBlock), Cl.uint(endBlock)],
          deployer
        );
        const twap = unwrapOkTuple(result.result);
        expectUint(twap["twap-yes"]);
        expectUint(twap["twap-no"]);
        expectUint(twap["window-blocks"], endBlock - startBlock);
      });

      it("fails if insufficient observations", () => {
        const result = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "calculate-twap",
          [Cl.uint(1), Cl.uint(1), Cl.uint(1000)], // Window with no observations
          deployer
        );
        expect(unwrapErrUint(result.result)).toBe(1101n); // ERR-TWAP-INSUFFICIENT-OBS
      });
    });

    describe("get-current-twap", () => {
      beforeEach(() => {
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(50), Cl.uint(200)],
          deployer
        );
      });

      it("returns current TWAP for specified window", () => {
        const result = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-current-twap",
          [Cl.uint(1), Cl.uint(100)],
          deployer
        );
        expect(result.result.type).toBe("ok");
      });

      it("fails if window too large (before market start)", () => {
        const result = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-current-twap",
          [Cl.uint(1), Cl.uint(1000000)], // Huge window
          deployer
        );
        expect(unwrapErrUint(result.result)).toBe(1103n); // ERR-TWAP-WINDOW-TOO-LARGE
      });
    });

    describe("keeper incentives", () => {
      beforeEach(() => {
        // Enable TWAP
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(50), Cl.uint(200)],
          deployer
        );

        // Fund keeper pool
        mintSbtc(deployer, 1000000);
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "fund-keeper-pool",
          [Cl.uint(1000000)],
          deployer
        );
      });

      it("pays reward to keeper for taking observation", () => {
        advanceBlocks(60);

        const keeperBalanceBefore = simnet.callReadOnlyFn(
          "sbtc-token",
          "get-balance",
          [Cl.principal(wallet1)],
          wallet1
        );

        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation-with-reward",
          [Cl.uint(1)],
          wallet1
        );
        expect(result.result.type).toBe("ok");

        const keeperBalanceAfter = simnet.callReadOnlyFn(
          "sbtc-token",
          "get-balance",
          [Cl.principal(wallet1)],
          wallet1
        );
        expect(unwrapOkUint(keeperBalanceAfter.result) > unwrapOkUint(keeperBalanceBefore.result)).toBe(true);
      });

      it("doesn't pay reward if pool is empty", () => {
        advanceBlocks(60);

        const keeperBalanceBefore = simnet.callReadOnlyFn(
          "sbtc-token",
          "get-balance",
          [Cl.principal(wallet2)],
          wallet2
        );

        const result = simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation-with-reward",
          [Cl.uint(1)],
          wallet2
        );
        expect(result.result.type).toBe("ok");

        const keeperBalanceAfter = simnet.callReadOnlyFn(
          "sbtc-token",
          "get-balance",
          [Cl.principal(wallet2)],
          wallet2
        );
        expect(unwrapOkUint(keeperBalanceAfter.result)).toBe(unwrapOkUint(keeperBalanceBefore.result));
      });
    });

    describe("get-twap-observation", () => {
      beforeEach(() => {
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(50), Cl.uint(200)],
          deployer
        );
      });

      it("returns observation at specific index", () => {
        // Take first observation
        advanceBlocks(60);
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation",
          [Cl.uint(1)],
          wallet1
        );

        const result = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-twap-observation",
          [Cl.uint(1), Cl.uint(0)],
          deployer
        );
        const observation = unwrapSome(result.result);
        expectUint(observation["price-yes"]);
        expectUint(observation["price-no"]);
        expectUint(observation["accumulator-yes"]);
      });

      it("returns none for non-existent index", () => {
        const result = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-twap-observation",
          [Cl.uint(1), Cl.uint(999)],
          deployer
        );
        expect(result.result.type).toBe("none");
      });
    });

    describe("get-twap-observation-count", () => {
      it("returns correct observation count", () => {
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "enable-twap",
          [Cl.uint(1), Cl.uint(50), Cl.uint(200)],
          deployer
        );

        const count1 = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-twap-observation-count",
          [Cl.uint(1)],
          deployer
        );
        expectUint(unwrapOk(count1.result), 1n); // Initial observation

        advanceBlocks(60);
        simnet.callPublicFn(
          "sbtcmarket-v0",
          "take-twap-observation",
          [Cl.uint(1)],
          wallet1
        );

        const count2 = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-twap-observation-count",
          [Cl.uint(1)],
          deployer
        );
        expectUint(unwrapOk(count2.result), 2n);
      });

      it("fails if TWAP not enabled", () => {
        const result = simnet.callReadOnlyFn(
          "sbtcmarket-v0",
          "get-twap-observation-count",
          [Cl.uint(2)],
          deployer
        );
        expect(unwrapErrUint(result.result)).toBe(1100n); // ERR-TWAP-NOT-ENABLED
      });
    });
  });
});
