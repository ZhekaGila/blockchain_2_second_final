// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20Like {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

interface IChainlinkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

    function decimals() external view returns (uint8);
}

contract ForkTests is Test {
    uint256 arbitrumFork;

    address constant USDC_ARBITRUM = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    address constant WETH_ARBITRUM = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address constant ETH_USD_FEED_ARBITRUM = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

    function setUp() public {
        string memory rpcUrl = vm.envString("ARBITRUM_RPC_URL");
        arbitrumFork = vm.createFork(rpcUrl);
        vm.selectFork(arbitrumFork);
    }

    function testForkReadUSDCMetadata() public view {
        IERC20Like usdc = IERC20Like(USDC_ARBITRUM);

        assertEq(usdc.symbol(), "USDC");
        assertEq(usdc.decimals(), 6);
    }

    function testForkReadWETHMetadata() public view {
        IERC20Like weth = IERC20Like(WETH_ARBITRUM);

        assertEq(weth.symbol(), "WETH");
        assertEq(weth.decimals(), 18);
    }

    function testForkReadChainlinkETHPrice() public view {
        IChainlinkFeed feed = IChainlinkFeed(ETH_USD_FEED_ARBITRUM);

        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();

        assertGt(answer, 0);
        assertGt(updatedAt, 0);
        assertEq(feed.decimals(), 8);
    }
}
