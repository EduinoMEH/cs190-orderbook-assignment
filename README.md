# Orderbook Assignment

Implement an on-chain limit/market orderbook in Solidity that trades a base
ERC20 against a quote ERC20.

## What you write

Fill in `src/Orderbook.sol`. The constructor, immutable token wiring, and
`getBaseToken` / `getQuoteToken` are already done. Every other function ships
as a stub that reverts with `"NotImplemented"`. Your job is to make them
behave per the spec in `src/IOrderbook.sol`.

The interface (in full):

| method | behavior |
|---|---|
| `placeLimitOrder(Side, price, amount)` | rest a bid (BUY) or ask (SELL); return the new order id (≥1) |
| `placeMarketOrder(Side, amount)` | walk the opposite side of the book until `amount` base is filled |
| `clear()` | drop **every** open limit order on both sides (test-only) |
| `getBidsCount()` | number of resting bids |
| `getAsksCount()` | number of resting asks |
| `getBaseToken()` | base ERC20 address |
| `getQuoteToken()` | quote ERC20 address |

Read the unit conventions and side semantics at the top of `IOrderbook.sol`
carefully — `price` is **quote wei per one whole base token**, and `amount`
is always in **base wei**.

## Tokens

Both base and quote are `MockERC20` (see `src/MockERC20.sol`). It exposes a
permissionless `mint(address, uint256)` so you don't need a faucet — mint
yourself test balances, then call `approve` on the orderbook.

## Setup

```sh
forge install
forge build
```

## Test locally

```sh
forge test -vv
```

`test/OrderbookTestBasic.t.sol` is a one-case sanity check: it places a bid
and an ask, then runs a market order against each side. It **fails** against
the shipped stub — making it pass is your minimum bar.

## Deploy to Sepolia

The bundled deploy script ships two `MockERC20`s (`Mock1`, `Mock2`) and an
`Orderbook` wired to them, in a single broadcast:

```sh
forge script script/Orderbook.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

Logged at the end: the three deployed addresses. Copy the **Orderbook**
address into your submission.

If you want to redeploy a single mock token standalone:

```sh
TOKEN_NAME=Mock1 TOKEN_SYMBOL=M1 \
forge script script/MockERC20.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

## Submission

Submit the deployed Sepolia address of your `Orderbook`. We run a grading
script against it that exercises the `IOrderbook` ABI — keep the interface
exact.
