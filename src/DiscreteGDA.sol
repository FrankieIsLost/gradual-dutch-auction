// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

///@notice Implementation of Discrete GDA with exponential price decay for ERC721
abstract contract DiscreteGDA is ERC721 {
    using PRBMathSD59x18 for int256;

    ///@notice id of current ERC721 being minted
    uint256 public currentId = 0;

    /// -----------------------------
    /// ---- Pricing Parameters -----
    /// -----------------------------

    ///@notice parameter that scales initial price, stored as a 59x18 fixed precision number
    int256 internal immutable priceScale;

    ///@notice parameter that controls price decay, stored as a 59x18 fixed precision number
    int256 internal immutable decayConstant;

    ///@notice start time for all auctions, stored as a 59x18 fixed precision number
    int256 internal immutable auctionStartTime;

    error InsufficientPayment();

    error UnableToRefund();

    constructor(
        string memory _name,
        string memory _symbol,
        int256 _priceScale,
        int256 _decayConstant
    ) ERC721(_name, _symbol) {
        priceScale = _priceScale;
        decayConstant = _decayConstant;
        auctionStartTime = int256(block.timestamp).fromInt();
    }

    ///@notice purchase a specific number of tokens from the GDA
    function purchaseTokens(uint256 numTokens, address to) public payable {
        uint256 cost = purchasePrice(numTokens);
        if (msg.value < cost) {
            revert InsufficientPayment();
        }
        //mint all tokens
        for (uint256 i = 0; i < numTokens; i++) {
            _mint(to, ++currentId);
        }
        //refund extra payment
        uint256 refund = msg.value - cost;
        (bool sent, ) = msg.sender.call{value: refund}("");
        if (!sent) {
            revert UnableToRefund();
        }
    }

    ///@notice calculate purchase price using exponential discrete GDA formula
    function purchasePrice(uint256 numTokens) public view returns (uint256) {
        int256 quantity = int256(numTokens).fromInt();
        int256 numSold = int256(currentId).fromInt();
        int256 timeSinceStart = int256(block.timestamp).fromInt() -
            auctionStartTime;
        int256 num1 = (numSold - timeSinceStart.mul(decayConstant)).exp().mul(
            priceScale
        );
        int256 num2 = quantity.exp() - PRBMathSD59x18.fromInt(1);
        int256 den = PRBMathSD59x18.e() - PRBMathSD59x18.fromInt(1);
        int256 totalCost = num1.mul(num2).div(den);
        //total cost is already in terms of wei so no need to scale down before
        //conversion to uint. This is due to the fact that the original formula gives
        //price in terms of ether but we scale up by 10^18 during computation
        //in order to do fixed point math.
        return uint256(totalCost);
    }
}
