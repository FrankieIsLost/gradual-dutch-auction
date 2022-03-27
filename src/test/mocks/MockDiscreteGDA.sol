// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DiscreteGDA} from "../../DiscreteGDA.sol";

contract MockDiscreteGDA is DiscreteGDA {
    constructor(
        string memory _name,
        string memory _symbol,
        int256 _priceScale,
        int256 _decayConstant
    ) DiscreteGDA(_name, _symbol, _priceScale, _decayConstant) {}

    function tokenURI(uint256)
        public
        pure
        virtual
        override
        returns (string memory)
    {}
}
