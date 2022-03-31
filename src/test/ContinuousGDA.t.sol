// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockContinuousGDA} from "./mocks/MockContinuousGDA.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

///@notice test discrete GDA behaviour
///@dev run with --ffi flag to enable correctness tests
contract ContinuousGDATest is DSTest {
    using PRBMathSD59x18 for int256;
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    MockContinuousGDA internal gda;

    int256 public initialPrice = PRBMathSD59x18.fromInt(1000);
    int256 public decayConstant =
        PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(2));
    int256 public emissionRate = PRBMathSD59x18.fromInt(1);

    //encodings for revert tests
    bytes insufficientPayment =
        abi.encodeWithSignature("InsufficientPayment()");
    bytes insufficientTokens =
        abi.encodeWithSignature("InsufficientAvailableTokens()");

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        gda = new MockContinuousGDA(
            "Token",
            "TKN",
            initialPrice,
            decayConstant,
            emissionRate
        );
    }

    function testInsuffientPayment() public {
        vm.warp(block.timestamp + 10);
        uint256 purchaseAmount = 5;
        uint256 purchasePrice = gda.purchasePrice(purchaseAmount);
        vm.deal(address(this), purchasePrice);
        vm.expectRevert(insufficientPayment);
        gda.purchaseTokens{value: purchasePrice - 1}(
            purchaseAmount,
            address(this)
        );
    }

    function testInsufficientEmissions() public {
        //10 tokens available for sale
        vm.warp(block.timestamp + 10);
        //attempt to purchase 11
        vm.expectRevert(insufficientTokens);
        gda.purchaseTokens(11, address(this));
    }

    function testMintCorrectly() public {
        vm.warp(block.timestamp + 10);
        assertEq(gda.balanceOf(address(this)), 0);
        uint256 purchaseAmount = 5;
        uint256 purchasePrice = gda.purchasePrice(purchaseAmount);
        assertTrue(purchasePrice > 0);
        vm.deal(address(this), purchasePrice);
        gda.purchaseTokens{value: purchasePrice}(purchaseAmount, address(this));
        assertEq(gda.balanceOf(address(this)), purchaseAmount);
    }

    function testRefund() public {
        vm.warp(block.timestamp + 10);
        uint256 purchasePrice = gda.purchasePrice(1);
        vm.deal(address(this), 2 * purchasePrice);
        //pay twice the purchase price
        gda.purchaseTokens{value: 2 * purchasePrice}(1, address(this));
        //purchase price should have been refunded
        assertTrue(address(this).balance == purchasePrice);
    }

    function testFFICorrectnessOne() public {
        uint256 ageOfLastAuction = 10;
        uint256 quantity = 9;
        checkPriceWithParameters(
            initialPrice,
            decayConstant,
            emissionRate,
            ageOfLastAuction,
            quantity
        );
    }

    function testFFICorrectnessTwo() public {
        uint256 ageOfLastAuction = 20;
        uint256 quantity = 8;
        checkPriceWithParameters(
            initialPrice,
            decayConstant,
            emissionRate,
            ageOfLastAuction,
            quantity
        );
    }

    function testFFICorrectnessThree() public {
        uint256 ageOfLastAuction = 30;
        uint256 quantity = 15;
        checkPriceWithParameters(
            initialPrice,
            decayConstant,
            emissionRate,
            ageOfLastAuction,
            quantity
        );
    }

    function testFFICorrectnessFour() public {
        uint256 ageOfLastAuction = 40;
        uint256 quantity = 35;
        checkPriceWithParameters(
            initialPrice,
            decayConstant,
            emissionRate,
            ageOfLastAuction,
            quantity
        );
    }

    //parametrized test helper
    function checkPriceWithParameters(
        int256 _initialPrice,
        int256 _decayConstant,
        int256 _emissionRate,
        uint256 _ageOfLastAuction,
        uint256 _quantity
    ) private {
        MockContinuousGDA _gda = new MockContinuousGDA(
            "Token",
            "TKN",
            initialPrice,
            decayConstant,
            emissionRate
        );

        //move time forward
        vm.warp(block.timestamp + _ageOfLastAuction);
        //calculate actual price from gda
        uint256 actualPrice = _gda.purchasePrice(_quantity);
        //calculate expected price from python script
        uint256 expectedPrice = calculatePrice(
            _initialPrice,
            _decayConstant,
            _emissionRate,
            _ageOfLastAuction,
            _quantity
        );
        //equal within 0.1 percent
        utils.assertApproxEqual(actualPrice, expectedPrice, 1);
    }

    //call out to python script for price computation
    function calculatePrice(
        int256 _initialPrice,
        int256 _decayConstant,
        int256 _emissionRate,
        uint256 _ageOfLastAuction,
        uint256 _quantity
    ) private returns (uint256) {
        string[] memory inputs = new string[](13);
        inputs[0] = "python3";
        inputs[1] = "analysis/compute_price.py";
        inputs[2] = "exp_continuous";
        inputs[3] = "--initial_price";
        inputs[4] = uint256(_initialPrice).toString();
        inputs[5] = "--decay_constant";
        inputs[6] = uint256(_decayConstant).toString();
        inputs[7] = "--emission_rate";
        inputs[8] = uint256(_emissionRate).toString();
        inputs[9] = "--age_last_auction";
        inputs[10] = _ageOfLastAuction.toString();
        inputs[11] = "--quantity";
        inputs[12] = _quantity.toString();
        bytes memory res = vm.ffi(inputs);
        uint256 price = abi.decode(res, (uint256));
        return price;
    }

    //make payable
    fallback() external payable {}
}
