// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameToken} from "../src/GameToken.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";
import {YieldVault} from "../src/YieldVault.sol";

contract FuzzTests is Test {
    GameToken game;
    GoldToken gold;
    ResourceAMM amm;
    YieldVault vault;

    address user = address(1);

    function setUp() public {
        game = new GameToken(address(this));
        gold = new GoldToken(address(this));

        amm = new ResourceAMM(address(game), address(gold));
        vault = new YieldVault(gold, address(this));

        game.mint(user, 1_000_000 ether);
        gold.mint(user, 1_000_000 ether);

        vm.startPrank(user);

        game.approve(address(amm), type(uint256).max);
        gold.approve(address(amm), type(uint256).max);

        gold.approve(address(vault), type(uint256).max);

        vm.stopPrank();
    }

    // -------------------------------------------------
    // AMM FUZZ TESTS
    // -------------------------------------------------

    function testFuzzAddLiquidity(uint256 amount0, uint256 amount1) public {
        amount0 = bound(amount0, 1 ether, 1000 ether);
        amount1 = bound(amount1, 1 ether, 1000 ether);

        vm.startPrank(user);

        amm.addLiquidity(amount0, amount1);

        vm.stopPrank();

        assertEq(amm.reserve0(), amount0);
        assertEq(amm.reserve1(), amount1);
    }

    function testFuzzSwapGameToGold(uint256 liquidity, uint256 swapAmount) public {
        liquidity = bound(liquidity, 100 ether, 1000 ether);
        swapAmount = bound(swapAmount, 1 ether, liquidity / 10);

        vm.startPrank(user);

        amm.addLiquidity(liquidity, liquidity);

        uint256 beforeBalance = gold.balanceOf(user);

        amm.swap(address(game), swapAmount, 0);

        uint256 afterBalance = gold.balanceOf(user);

        vm.stopPrank();

        assertGt(afterBalance, beforeBalance);
    }

    function testFuzzSwapGoldToGame(uint256 liquidity, uint256 swapAmount) public {
        liquidity = bound(liquidity, 100 ether, 1000 ether);
        swapAmount = bound(swapAmount, 1 ether, liquidity / 10);

        vm.startPrank(user);

        amm.addLiquidity(liquidity, liquidity);

        uint256 beforeBalance = game.balanceOf(user);

        amm.swap(address(gold), swapAmount, 0);

        uint256 afterBalance = game.balanceOf(user);

        vm.stopPrank();

        assertGt(afterBalance, beforeBalance);
    }

    function testFuzzGetAmountOut(uint256 liquidity, uint256 amountIn) public {
        liquidity = bound(liquidity, 100 ether, 1000 ether);
        amountIn = bound(amountIn, 1 ether, 100 ether);

        vm.startPrank(user);

        amm.addLiquidity(liquidity, liquidity);

        uint256 output = amm.getAmountOut(address(game), amountIn);

        vm.stopPrank();

        assertGt(output, 0);
    }

    function testFuzzRemoveLiquidity(uint256 liquidity) public {
        liquidity = bound(liquidity, 100 ether, 1000 ether);

        vm.startPrank(user);

        amm.addLiquidity(liquidity, liquidity);

        uint256 lpBalance = amm.balanceOf(user);

        amm.removeLiquidity(lpBalance, 0, 0);

        vm.stopPrank();

        assertEq(amm.reserve0(), 0);
        assertEq(amm.reserve1(), 0);
    }

    // -------------------------------------------------
    // VAULT FUZZ TESTS
    // -------------------------------------------------

    function testFuzzVaultDeposit(uint256 amount) public {
        amount = bound(amount, 1 ether, 1000 ether);

        vm.startPrank(user);

        vault.deposit(amount, user);

        vm.stopPrank();

        assertEq(vault.balanceOf(user), amount);
    }

    function testFuzzVaultWithdraw(uint256 amount) public {
        amount = bound(amount, 1 ether, 1000 ether);

        vm.startPrank(user);

        vault.deposit(amount, user);

        vault.withdraw(amount / 2, user, user);

        vm.stopPrank();

        assertApproxEqAbs(vault.balanceOf(user), amount / 2, 1);
    }

    function testFuzzVaultRedeem(uint256 amount) public {
        amount = bound(amount, 1 ether, 1000 ether);

        vm.startPrank(user);

        vault.deposit(amount, user);

        vault.redeem(amount, user, user);

        vm.stopPrank();

        assertEq(vault.balanceOf(user), 0);
    }

    function testFuzzVaultPreviewDeposit(uint256 amount) public {
        amount = bound(amount, 1 ether, 1000 ether);

        uint256 shares = vault.previewDeposit(amount);

        assertEq(shares, amount);
    }

    // -------------------------------------------------
    // GOVERNANCE TOKEN FUZZ TEST
    // -------------------------------------------------

    function testFuzzDelegateVotes(uint256 amount) public {
        amount = bound(amount, 1 ether, 1000 ether);

        game.mint(user, amount);

        vm.startPrank(user);

        game.delegate(user);

        uint256 votes = game.getVotes(user);

        vm.stopPrank();

        assertEq(votes, amount + 1_000_000 ether);
    }
}
