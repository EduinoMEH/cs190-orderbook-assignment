// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderbook} from "./IOrderbook.sol";

/// @dev Minimal ERC20 surface the orderbook needs. The provided `MockERC20`
///      implements all of these methods (plus `mint`).
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

/// @title Orderbook (template)
/// @notice Skeleton to complete. The constructor, immutable
///         token wiring, and the two trivial getters are already done —
///         everything else reverts with `"NotImplemented"`.
///
///         You are free to add additional state, structs, errors, and
///         helper functions. The only hard constraints are:
///         (1) keep the `IOrderbook` ABI exactly as declared in the
///             interface (the grading harness depends on it), and
///         (2) keep `baseToken`/`quoteToken` as immutables set in the
///             constructor.
contract Orderbook is IOrderbook {
    IERC20 public immutable baseToken;
    IERC20 public immutable quoteToken;

    /// @dev Suggested events. These are a starting point — your
    ///      implementation may emit a different set, rename them, or omit
    ///      events entirely. Nothing in the grading harness depends on
    ///      these signatures.
    event OrderPlaced(
        uint256 indexed orderId,
        address indexed maker,
        Side side,
        uint256 price,
        uint256 amount
    );
    event OrderFilled(
        uint256 indexed orderId,
        address indexed taker,
        uint256 fillAmount,
        uint256 fillPrice
    );
    event OrderCleared();

    struct Order {
        uint256 id;
        address maker;
        uint256 price;
        uint256 amount;
        Side    side;
    }

    uint256 private _nextId = 1;

    Order[] private _bids;
    Order[] private _asks;

    constructor(address _baseToken, address _quoteToken) {
        require(_baseToken != address(0), "baseToken=0");
        require(_quoteToken != address(0), "quoteToken=0");
        require(_baseToken != _quoteToken, "base==quote");
        baseToken = IERC20(_baseToken);
        quoteToken = IERC20(_quoteToken);
    }

    function getBaseToken() external view returns (address) {
        return address(baseToken);
    }

    function getQuoteToken() external view returns (address) {
        return address(quoteToken);
    }

    function placeLimitOrder(Side side, uint256 price, uint256 amount) external returns (uint256) {
        require(price > 0,  "ZeroPrice");
        require(amount > 0, "ZeroAmount");

        uint256 id = _nextId++;

        if (side == Side.BUY) {
            uint256 quoteLocked = _quoteOwed(amount, price);
            require(quoteLocked > 0, "QuoteZero");
            quoteToken.transferFrom(msg.sender, address(this), quoteLocked);

            _insertBid(Order({
                id:     id,
                maker:  msg.sender,
                price:  price,
                amount: amount,
                side:   Side.BUY
            }));
        } else {
            baseToken.transferFrom(msg.sender, address(this), amount);

            _insertAsk(Order({
                id:     id,
                maker:  msg.sender,
                price:  price,
                amount: amount,
                side:   Side.SELL
            }));
        }

        emit OrderPlaced(id, msg.sender, side, price, amount);
        return id;
    }

    function placeMarketOrder(Side side, uint256 amount) external {
        require(amount > 0, "ZeroAmount");

        if (side == Side.BUY) {
            _marketBuy(amount);
        } else {
            _marketSell(amount);
        }
    }

    function clear() external {
        for (uint256 i = 0; i < _bids.length; i++) {
            Order storage b = _bids[i];
            uint256 refund  = _quoteOwed(b.amount, b.price);
            if (refund > 0) {
                quoteToken.transfer(b.maker, refund);
            }
        }
        delete _bids;

        for (uint256 i = 0; i < _asks.length; i++) {
            Order storage a = _asks[i];
            if (a.amount > 0) {
                baseToken.transfer(a.maker, a.amount);
            }
        }
        delete _asks;

        emit OrderCleared();
    }

    function getBidsCount() external view returns (uint256) {
        return _bids.length;
    }

    function getAsksCount() external view returns (uint256) {
        return _asks.length;
    }

    function getMidPrice() external view returns (uint256) {
        require(_bids.length > 0 && _asks.length > 0, "EmptySide");
        return (_bids[0].price + _asks[0].price) / 2;
    }

    // internal functions!
    function _marketBuy(uint256 amount) internal {
        require(_asks.length > 0, "NoAsks");

        uint256 maxQuote   = _worstCaseQuote(amount);
        quoteToken.transferFrom(msg.sender, address(this), maxQuote);

        uint256 remaining  = amount;
        uint256 quoteSpent = 0;
        while (remaining > 0 && _asks.length > 0) {
            Order storage ask = _asks[0];

            uint256 fillBase  = ask.amount <= remaining ? ask.amount : remaining;
            uint256 fillQuote = _quoteOwed(fillBase, ask.price);

            quoteToken.transfer(ask.maker, fillQuote);
            baseToken.transfer(msg.sender, fillBase);

            quoteSpent += fillQuote;
            remaining  -= fillBase;
            ask.amount -= fillBase;

            emit OrderFilled(ask.id, msg.sender, fillBase, ask.price);

            if (ask.amount == 0) {
                _removeAsk(0);
            }
        }

        uint256 refund = maxQuote - quoteSpent;
        if (refund > 0) {
            quoteToken.transfer(msg.sender, refund);
        }
    }

    function _marketSell(uint256 amount) internal {
        require(_bids.length > 0, "NoBids");

        baseToken.transferFrom(msg.sender, address(this), amount);

        uint256 remaining = amount;
        while (remaining > 0 && _bids.length > 0) {
            Order storage bid = _bids[0];

            uint256 fillBase  = bid.amount <= remaining ? bid.amount : remaining;
            uint256 fillQuote = _quoteOwed(fillBase, bid.price);

            baseToken.transfer(bid.maker, fillBase);
            quoteToken.transfer(msg.sender, fillQuote);

            remaining  -= fillBase;
            bid.amount -= fillBase;

            emit OrderFilled(bid.id, msg.sender, fillBase, bid.price);

            if (bid.amount == 0) {
                _removeBid(0);
            }
        }

        if (remaining > 0) {
            baseToken.transfer(msg.sender, remaining);
        }
    }

    function _insertBid(Order memory ord) internal {
        _bids.push(ord);
        uint256 i = _bids.length - 1;
        while (i > 0 && _bids[i].price > _bids[i - 1].price) {
            Order memory tmp = _bids[i];
            _bids[i]         = _bids[i - 1];
            _bids[i - 1]     = tmp;
            i--;
        }
    }

    function _insertAsk(Order memory ord) internal {
        _asks.push(ord);
        uint256 i = _asks.length - 1;
        while (i > 0 && _asks[i].price < _asks[i - 1].price) {
            Order memory tmp = _asks[i];
            _asks[i]         = _asks[i - 1];
            _asks[i - 1]     = tmp;
            i--;
        }
    }

    function _removeBid(uint256 idx) internal {
        uint256 last = _bids.length - 1;
        for (uint256 i = idx; i < last; i++) {
            _bids[i] = _bids[i + 1];
        }
        _bids.pop();
    }

    function _removeAsk(uint256 idx) internal {
        uint256 last = _asks.length - 1;
        for (uint256 i = idx; i < last; i++) {
            _asks[i] = _asks[i + 1];
        }
        _asks.pop();
    }

    // math-related
    function _quoteOwed(uint256 baseAmt, uint256 price) internal pure returns (uint256) {
        return (baseAmt * price) / 1e18;
    }

    function _worstCaseQuote(uint256 amount) internal view returns (uint256) {
        uint256 remaining = amount;
        uint256 total     = 0;
        for (uint256 i = 0; i < _asks.length && remaining > 0; i++) {
            uint256 fill  = _asks[i].amount <= remaining ? _asks[i].amount : remaining;
            total        += _quoteOwed(fill, _asks[i].price);
            remaining    -= fill;
        }
        return total;
    }
}
