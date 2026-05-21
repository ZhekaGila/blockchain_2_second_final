// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameToken} from "../src/GameToken.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";

contract ResourceAMMTest is Test {
    GameToken game;
    GoldToken gold;
    ResourceAMM amm;

    address user = address(1);
    address user2 = address(2);

    function setUp() public {
        game = new GameToken(address(this));
        gold = new GoldToken(address(this));

        amm = new ResourceAMM(address(game), address(gold));

        game.mint(user, 1000 ether);
        gold.mint(user, 1000 ether);

        game.mint(user2, 1000 ether);
        gold.mint(user2, 1000 ether);
    }

    function addInitialLiquidity() internal {
        vm.startPrank(user);

        game.approve(address(amm), 100 ether);
        gold.approve(address(amm), 100 ether);

        amm.addLiquidity(100 ether, 100 ether);

        vm.stopPrank();
    }

    // -------------------------------------------------
    // ADD LIQUIDITY TESTS
    // -------------------------------------------------

    function testAddLiquidity() public {
        addInitialLiquidity();

        assertEq(amm.reserve0(), 100 ether);
        assertEq(amm.reserve1(), 100 ether);
    }

    function testMintLPToken() public {
        addInitialLiquidity();

        assertGt(amm.balanceOf(user), 0);
    }

    function testTotalSupplyAfterLiquidity() public {
        addInitialLiquidity();

        assertGt(amm.totalSupply(), 0);
    }

    function testSecondLiquidityProvider() public {
        addInitialLiquidity();

        vm.startPrank(user2);

        game.approve(address(amm), 50 ether);
        gold.approve(address(amm), 50 ether);

        amm.addLiquidity(50 ether, 50 ether);

        vm.stopPrank();

        assertEq(amm.reserve0(), 150 ether);
        assertEq(amm.reserve1(), 150 ether);
    }

    function testRevertZeroLiquidity() public {
        vm.startPrank(user);

        vm.expectRevert("Zero Amount");
        amm.addLiquidity(0, 0);

        vm.stopPrank();
    }

    // -------------------------------------------------
    // SWAP TESTS
    // -------------------------------------------------

    function testSwapGameToGold() public {
        addInitialLiquidity();

        vm.startPrank(user);

        game.approve(address(amm), 10 ether);

        uint256 goldBefore = gold.balanceOf(user);

        amm.swap(address(game), 10 ether, 0);

        uint256 goldAfter = gold.balanceOf(user);

        vm.stopPrank();

        assertGt(goldAfter, goldBefore);
    }

    function testSwapGoldToGame() public {
        addInitialLiquidity();

        vm.startPrank(user);

        gold.approve(address(amm), 10 ether);

        uint256 gameBefore = game.balanceOf(user);

        amm.swap(address(gold), 10 ether, 0);

        uint256 gameAfter = game.balanceOf(user);

        vm.stopPrank();

        assertGt(gameAfter, gameBefore);
    }

    function testSwapChangesReserves() public {
        addInitialLiquidity();

        vm.startPrank(user);

        game.approve(address(amm), 10 ether);

        amm.swap(address(game), 10 ether, 0);

        vm.stopPrank();

        assertGt(amm.reserve0(), 100 ether);
        assertLt(amm.reserve1(), 100 ether);
    }

    function testSwapChargesFee() public {
        addInitialLiquidity();

        uint256 output = amm.getAmountOut(address(game), 10 ether);

        assertLt(output, 10 ether);
    }

    function testGetAmountOut() public {
        addInitialLiquidity();

        uint256 output = amm.getAmountOut(address(game), 10 ether);

        assertGt(output, 0);
    }

    function testRevertInvalidToken() public {
        addInitialLiquidity();

        vm.startPrank(user);

        vm.expectRevert("Invalid Token");
        amm.swap(address(123), 10 ether, 0);

        vm.stopPrank();
    }

    function testRevertZeroSwapInput() public {
        addInitialLiquidity();

        vm.startPrank(user);

        vm.expectRevert("Zero input");
        amm.swap(address(game), 0, 0);

        vm.stopPrank();
    }

    function testRevertSlippage() public {
        addInitialLiquidity();

        vm.startPrank(user);

        game.approve(address(amm), 10 ether);

        vm.expectRevert("Slippage");
        amm.swap(address(game), 10 ether, 100 ether);

        vm.stopPrank();
    }

    // -------------------------------------------------
    // REMOVE LIQUIDITY TESTS
    // -------------------------------------------------

    function testRemoveLiquidity() public {
        addInitialLiquidity();

        vm.startPrank(user);

        uint256 lpBalance = amm.balanceOf(user);

        amm.removeLiquidity(lpBalance, 0, 0);

        vm.stopPrank();

        assertEq(amm.reserve0(), 0);
        assertEq(amm.reserve1(), 0);
    }

    function testBurnLPOnRemoveLiquidity() public {
        addInitialLiquidity();

        vm.startPrank(user);

        uint256 lpBalance = amm.balanceOf(user);

        amm.removeLiquidity(lpBalance, 0, 0);

        vm.stopPrank();

        assertEq(amm.balanceOf(user), 0);
    }

    function testUserGetsTokensBack() public {
        addInitialLiquidity();

        vm.startPrank(user);

        uint256 gameBefore = game.balanceOf(user);

        uint256 lpBalance = amm.balanceOf(user);

        amm.removeLiquidity(lpBalance, 0, 0);

        uint256 gameAfter = game.balanceOf(user);

        vm.stopPrank();

        assertGt(gameAfter, gameBefore);
    }

    function testRevertZeroLPBurn() public {
        addInitialLiquidity();

        vm.startPrank(user);

        vm.expectRevert("Zero LP");
        amm.removeLiquidity(0, 0, 0);

        vm.stopPrank();
    }

    // -------------------------------------------------
    // RESERVE TESTS
    // -------------------------------------------------

    function testInitialReservesZero() public {
        assertEq(amm.reserve0(), 0);
        assertEq(amm.reserve1(), 0);
    }

    function testReservesIncreaseAfterLiquidity() public {
        addInitialLiquidity();

        assertEq(amm.reserve0(), 100 ether);
        assertEq(amm.reserve1(), 100 ether);
    }

    function testReservesUpdateAfterSwap() public {
        addInitialLiquidity();

        vm.startPrank(user);

        game.approve(address(amm), 5 ether);

        amm.swap(address(game), 5 ether, 0);

        vm.stopPrank();

        assertEq(amm.reserve0(), 105 ether);
    }
}
