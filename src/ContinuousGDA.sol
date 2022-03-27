// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

///@notice Implementation of Discrete GDA with exponential price decay for ERC721
abstract contract ContinuousGDA is ERC20 {
    using PRBMathSD59x18 for int256;

    /// -----------------------------
    /// ---- Pricing Parameters -----
    /// -----------------------------

    ///@notice parameter that scales initial price, stored as a 59x18 fixed precision number
    int256 internal priceScale;

    ///@notice parameter that controls price decay, stored as a 59x18 fixed precision number
    int256 internal decayConstant;

    ///@notice emission rate, in tokens per second, stored as a 59x18 fixed precision number
    int256 internal emissionRate;

    ///@notice start time for last available auction, stored as a 59x18 fixed precision number
    int256 internal lastAvailableAuctionStartTime;

    error InsufficientPayment();

    error InsufficientAvailableTokens();

    error UnableToRefund();

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol, 18)
    {
        lastAvailableAuctionStartTime = int256(block.timestamp).fromInt();
    }

    ///@notice purchase a specific number of tokens from the GDA
    function purchaseTokens(uint256 numTokens, address to) public payable {
        //number of seconds of token emissions that are available to be purchased
        int256 secondsOfEmissionsAvaiable = int256(block.timestamp).fromInt() -
            lastAvailableAuctionStartTime;
        //number of seconds of emissions are being purchased
        int256 secondsOfEmissionsToPurchase = int256(numTokens).fromInt().div(
            emissionRate
        );
        //ensure there's been sufficient emissions to allow purchase
        if (secondsOfEmissionsToPurchase > secondsOfEmissionsAvaiable) {
            revert InsufficientAvailableTokens();
        }

        uint256 cost = purchasePrice(numTokens);
        if (msg.value < cost) {
            revert InsufficientPayment();
        }
        //mint tokens
        _mint(to, numTokens);
        //refund extra payment
        uint256 refund = msg.value - cost;
        (bool sent, ) = msg.sender.call{value: refund}("");
        if (!sent) {
            revert UnableToRefund();
        }
        //update last available auction
        lastAvailableAuctionStartTime += secondsOfEmissionsToPurchase;
    }

    ///@notice calculate purchase price using exponential continuous GDA formula
    function purchasePrice(uint256 numTokens) public view returns (uint256) {
        int256 quantity = int256(numTokens).fromInt();
        int256 timeSinceLastAuctionStart = int256(block.timestamp).fromInt() -
            lastAvailableAuctionStartTime;
        int256 num1 = priceScale.div(decayConstant);
        int256 num2 = decayConstant.mul(quantity).div(emissionRate).exp() -
            PRBMathSD59x18.fromInt(1);
        int256 den = decayConstant.mul(timeSinceLastAuctionStart).exp();
        int256 totalCost = num1.mul(num2).div(den);
        return uint256(totalCost.toInt());
    }
}
