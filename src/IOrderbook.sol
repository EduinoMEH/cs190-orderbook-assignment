// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title IOrderbook
/// @notice Interface for a simple on-chain limit-orderbook trading a base
///         token against a quote token.
///
/// Unit conventions (the same throughout the interface):
///
/// * `amount` is always expressed in **base-token wei** (i.e. raw `uint256`
///   units of the base token, taking its decimals into account).
/// * `price` is the amount of **quote-token wei** paid per **one whole base
///   token** (i.e. per `10**18` base-token wei, assuming an 18-decimal base).
///   The quote required to fill `amount` at `price` is therefore
///   `amount * price / 1e18`.
///
/// Side semantics:
///
/// * `BUY`  = bid  — the maker wants to acquire base, pays in quote.
/// * `SELL` = ask  — the maker wants to dispose of base, receives quote.
interface IOrderbook {
    /// @notice Whether an order is buying or selling the base token.
    enum Side {
        BUY,
        SELL
    }

    /// @notice Place a limit order that rests on the book until matched or
    ///         cleared.
    /// @param side    BUY (bid) or SELL (ask).
    /// @param price   Quote wei per one whole (1e18) base-token unit.
    /// @param amount  Amount of base-token wei the maker wants to trade.
    /// @return orderId Monotonically-increasing id for the placed order
    ///                 (starts at 1; 0 is reserved as a sentinel).
    function placeLimitOrder(Side side, uint256 price, uint256 amount)
        external
        returns (uint256 orderId);

    /// @notice Place a market order that immediately walks the opposite side
    ///         of the book until `amount` base is filled (or the book runs
    ///         out of liquidity).
    /// @param side   BUY → walk the asks; SELL → walk the bids.
    /// @param amount Amount of base-token wei to fill.
    function placeMarketOrder(Side side, uint256 amount) external;

    /// @notice Unconditionally remove every open limit order on both sides
    ///         of the book.
    /// @dev    Test-only helper used by the grading harness to reset state
    ///         between cases. **Do not deploy this contract to production
    ///         as-is** — this function intentionally has no access control.
    function clear() external;

    /// @notice Number of resting bids (open BUY limit orders).
    function getBidsCount() external view returns (uint256);

    /// @notice Number of resting asks (open SELL limit orders).
    function getAsksCount() external view returns (uint256);

    /// @notice Address of the base-token ERC20 the orderbook trades.
    function getBaseToken() external view returns (address);

    /// @notice Address of the quote-token ERC20 the orderbook prices in.
    function getQuoteToken() external view returns (address);

    /// @notice Midprice of the book: `(bestBid + bestAsk) / 2`.
    ///         Same unit as `price` (quote wei per one whole base token).
    /// @dev    Reverts if either side of the book is empty — midprice is
    ///         undefined without both a best bid and a best ask.
    function getMidPrice() external view returns (uint256);
}
