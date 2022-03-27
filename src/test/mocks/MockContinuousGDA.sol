// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ContinuousGDA} from "../../ContinuousGDA.sol";

contract MockContinuousGDA is ContinuousGDA {
    constructor(
        string memory _name,
        string memory _symbol,
        int256 _priceScale,
        int256 _decayConstant,
        int256 _emissionRate
    )
        ContinuousGDA(
            _name,
            _symbol,
            _priceScale,
            _decayConstant,
            _emissionRate
        )
    {}
}
