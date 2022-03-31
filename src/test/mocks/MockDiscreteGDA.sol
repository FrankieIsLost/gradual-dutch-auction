// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DiscreteGDA} from "../../DiscreteGDA.sol";

contract MockDiscreteGDA is DiscreteGDA {
    constructor(
        string memory _name,
        string memory _symbol,
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant
    )
        DiscreteGDA(_name, _symbol, _initialPrice, _scaleFactor, _decayConstant)
    {}

    function tokenURI(uint256)
        public
        pure
        virtual
        override
        returns (string memory)
    {}
}
