# How Prediction Markets Like Polymarket Work

## Overview

Prediction markets are platforms where people buy and sell **shares** representing the outcomes of future events—like elections or sports games. Each event creates two types of tokens:

- **YES token**: Pays out $1 if the event happens.
- **NO token**: Pays out $1 if the event does *not* happen.

You always get one YES and one NO token for each $1 you deposit. That means the combined value of one YES + one NO is always $1. Traders buy and sell these tokens based on what they believe will happen. If you think an outcome is likely, you buy its token; if you’re wrong, it becomes worthless, but if you’re right, it pays $1.

## Architecture

Polymarket’s system has two main on-chain components:

1. **Conditional Tokens Framework (CTF)**
   - A smart contract that handles **minting** (creating) and **redeeming** shares backed by collateral (USDC).
   - Enforces the $1 peg by requiring $1 collateral to mint a YES+NO pair, and only returning $1 when both tokens are burned together.

2. **ERC-1155 Multi-Token Standard**
   - A flexible token interface that tracks balances of multiple token types (YES and NO shares) within a single contract.
   - Enables efficient batch transfers and a unified ledger for all markets.

Behind the scenes, Polymarket’s front end interacts with these contracts to:  
- Allow users to deposit USDC and mint shares  
- Trade shares on an off-chain order book  
- Redeem back USDC by burning complete share sets

## Technical Details

### Conditional Tokens Framework (CTF)

