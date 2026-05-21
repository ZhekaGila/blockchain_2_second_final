// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {PriceOracle} from "../src/PriceOracle.sol";
import {MockAggregator} from "../src/MockAggregator.sol";

contract PriceOracleTest is Test {
    PriceOracle oracle;
    MockAggregator mock;

    function setUp() public {
        mock = new MockAggregator(
            2000e8, // 2000 USD
            8
        );

        oracle = new PriceOracle(address(mock), 1 hours);
    }

    function testGetPrice() public {
        (uint256 price, uint8 decimals) = oracle.getPrice();

        assertEq(price, 2000e8);
        assertEq(decimals, 8);
    }

    function testUpdatePrice() public {
        mock.setAnswer(3000e8);

        (uint256 price,) = oracle.getPrice();

        assertEq(price, 3000e8);
    }

    function testDecimals() public {
        (, uint8 decimals) = oracle.getPrice();

        assertEq(decimals, 8);
    }

    function testRevertStalePrice() public {
        vm.warp(block.timestamp + 2 hours);

        vm.expectRevert(PriceOracle.StalePrice.selector);
        oracle.getPrice();
    }

    function testRevertInvalidPrice() public {
        mock.setAnswer(0);

        vm.expectRevert(PriceOracle.InvalidPrice.selector);
        oracle.getPrice();
    }

    function testNegativePriceReverts() public {
        mock.setAnswer(-1);

        vm.expectRevert(PriceOracle.InvalidPrice.selector);
        oracle.getPrice();
    }

    function testFreshPriceDoesNotRevert() public {
        vm.warp(block.timestamp + 30 minutes);

        (uint256 price,) = oracle.getPrice();

        assertEq(price, 2000e8);
    }

    function testUpdatedAtRefreshes() public {
        vm.warp(block.timestamp + 30 minutes);

        mock.setAnswer(2500e8);

        vm.warp(block.timestamp + 30 minutes);

        (uint256 price,) = oracle.getPrice();

        assertEq(price, 2500e8);
    }

    function testMultiplePriceUpdates() public {
        mock.setAnswer(2100e8);

        (uint256 price1,) = oracle.getPrice();

        mock.setAnswer(2200e8);

        (uint256 price2,) = oracle.getPrice();

        assertEq(price1, 2100e8);
        assertEq(price2, 2200e8);
    }

    function testStaleBoundary() public {
        vm.warp(block.timestamp + 1 hours);

        (uint256 price,) = oracle.getPrice();

        assertEq(price, 2000e8);
    }
}
