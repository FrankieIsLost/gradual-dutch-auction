// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockDiscreteGDA} from "./mocks/MockDiscreteGDA.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

///@notice test discrete GDA behaviour
///@dev run with --ffi flag to enable correctness tests
contract DiscreteGDATest is DSTest {
    using PRBMathSD59x18 for int256;
    using Strings for uint256;

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    MockDiscreteGDA internal gda;

    int256 public initialPrice = PRBMathSD59x18.fromInt(1000);
    int256 public decayConstant =
        PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(2));
    int256 public scaleFactor =
        PRBMathSD59x18.fromInt(11).div(PRBMathSD59x18.fromInt(10));

    //encodings for revert tests
    bytes insufficientPayment =
        abi.encodeWithSignature("InsufficientPayment()");

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        gda = new MockDiscreteGDA(
            "Token",
            "TKN",
            initialPrice,
            scaleFactor,
            decayConstant
        );
    }

    function testInitialPrice() public {
        //initialPrice should be price scale
        uint256 initial = uint256(initialPrice);
        uint256 purchasePrice = gda.purchasePrice(1);
        utils.assertApproxEqual(purchasePrice, initial, 1);
    }

    function testInsuffientPayment() public {
        uint256 purchasePrice = gda.purchasePrice(1);
        vm.deal(address(this), purchasePrice);
        vm.expectRevert(insufficientPayment);
        gda.purchaseTokens{value: purchasePrice - 1}(1, address(this));
    }

    function testMintCorrectly() public {
        assertTrue(gda.ownerOf(1) != address(this));
        uint256 purchasePrice = gda.purchasePrice(1);
        vm.deal(address(this), purchasePrice);
        gda.purchaseTokens{value: purchasePrice}(1, address(this));
        assertTrue(gda.ownerOf(1) == address(this));
    }

    function testRefund() public {
        uint256 purchasePrice = gda.purchasePrice(1);
        vm.deal(address(this), 2 * purchasePrice);
        //pay twice the purchase price
        gda.purchaseTokens{value: 2 * purchasePrice}(1, address(this));
        //purchase price should have been refunded
        assertTrue(address(this).balance == purchasePrice);
    }

    function testFFICorrectnessOne() public {
        uint256 numTotalPurchases = 1;
        uint256 timeSinceStart = 10;
        uint256 quantity = 9;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    function testFFICorrectnessTwo() public {
        uint256 numTotalPurchases = 2;
        uint256 timeSinceStart = 10;
        uint256 quantity = 9;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    function testFFICorrectnessThree() public {
        uint256 numTotalPurchases = 4;
        uint256 timeSinceStart = 10;
        uint256 quantity = 9;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    function testFFICorrectnessFour() public {
        uint256 numTotalPurchases = 20;
        uint256 timeSinceStart = 100;
        uint256 quantity = 1;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    //parametrized test helper
    function checkPriceWithParameters(
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant,
        uint256 _numTotalPurchases,
        uint256 _timeSinceStart,
        uint256 _quantity
    ) private {
        MockDiscreteGDA _gda = new MockDiscreteGDA(
            "Token",
            "TKN",
            _initialPrice,
            _scaleFactor,
            _decayConstant
        );

        //make past pruchases
        uint256 purchasePrice = _gda.purchasePrice(_numTotalPurchases);
        vm.deal(address(this), purchasePrice);
        _gda.purchaseTokens{value: purchasePrice}(
            _numTotalPurchases,
            address(this)
        );

        //move time forward
        vm.warp(block.timestamp + _timeSinceStart);
        //calculate actual price from gda
        uint256 actualPrice = _gda.purchasePrice(_quantity);
        //calculate expected price from python script
        uint256 expectedPrice = calculatePrice(
            _initialPrice,
            _scaleFactor,
            _decayConstant,
            _numTotalPurchases,
            _timeSinceStart,
            _quantity
        );
        //equal within 0.1%
        utils.assertApproxEqual(actualPrice, expectedPrice, 1);
    }

    //call out to python script for price computation
    function calculatePrice(
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant,
        uint256 _numTotalPurchases,
        uint256 _timeSinceStart,
        uint256 _quantity
    ) private returns (uint256) {
        string[] memory inputs = new string[](15);
        inputs[0] = "python3";
        inputs[1] = "analysis/compute_price.py";
        inputs[2] = "exp_discrete";
        inputs[3] = "--initial_price";
        inputs[4] = uint256(_initialPrice).toString();
        inputs[5] = "--scale_factor";
        inputs[6] = uint256(_scaleFactor).toString();
        inputs[7] = "--decay_constant";
        inputs[8] = uint256(_decayConstant).toString();
        inputs[9] = "--num_total_purchases";
        inputs[10] = _numTotalPurchases.toString();
        inputs[11] = "--time_since_start";
        inputs[12] = _timeSinceStart.toString();
        inputs[13] = "--quantity";
        inputs[14] = _quantity.toString();
        bytes memory res = vm.ffi(inputs);
        uint256 price = abi.decode(res, (uint256));
        return price;
    }

    //make payable
    fallback() external payable {}
}
