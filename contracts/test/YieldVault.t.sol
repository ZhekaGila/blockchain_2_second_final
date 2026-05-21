// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GoldToken} from "../src/GoldToken.sol";
import {YieldVault} from "../src/YieldVault.sol";

contract YieldVaultTest is Test {
    GoldToken gold;
    YieldVault vault;

    address user = address(1);
    address user2 = address(2);

    function setUp() public {
        gold = new GoldToken(address(this));
        vault = new YieldVault(gold, address(this));

        gold.mint(user, 1000 ether);
        gold.mint(user2, 1000 ether);
    }

    function testDeposit() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        assertEq(vault.balanceOf(user), 100 ether);
    }

    function testWithdraw() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vault.withdraw(50 ether, user, user);

        vm.stopPrank();

        assertEq(vault.balanceOf(user), 50 ether);
    }

    function testRedeem() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vault.redeem(100 ether, user, user);

        vm.stopPrank();

        assertEq(vault.balanceOf(user), 0);
    }

    function testVaultReceivesAssets() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        assertEq(gold.balanceOf(address(vault)), 100 ether);
    }

    function testMintShares() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        assertEq(vault.totalSupply(), 100 ether);
    }

    function testAddRewards() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        gold.approve(address(vault), 100 ether);
        vault.addRewards(100 ether);

        assertEq(gold.balanceOf(address(vault)), 200 ether);
    }

    function testShareValueIncreasesAfterRewards() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        gold.approve(address(vault), 100 ether);
        vault.addRewards(100 ether);

        uint256 assets = vault.convertToAssets(100 ether);

        assertApproxEqAbs(assets, 200 ether, 1);
    }

    function testSecondUserDeposit() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        vm.startPrank(user2);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user2);

        vm.stopPrank();

        assertEq(vault.totalSupply(), 200 ether);
    }

    function testPreviewDeposit() public {
        uint256 shares = vault.previewDeposit(100 ether);

        assertEq(shares, 100 ether);
    }

    function testPreviewRedeem() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        uint256 assets = vault.previewRedeem(100 ether);

        assertEq(assets, 100 ether);
    }

    function testRevertWithdrawTooMuch() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.expectRevert();
        vault.withdraw(200 ether, user, user);

        vm.stopPrank();
    }

    function testRevertDepositWithoutApproval() public {
        vm.startPrank(user);

        vm.expectRevert();
        vault.deposit(100 ether, user);

        vm.stopPrank();
    }

    function testTotalAssets() public {
        vm.startPrank(user);

        gold.approve(address(vault), 100 ether);
        vault.deposit(100 ether, user);

        vm.stopPrank();

        assertEq(vault.totalAssets(), 100 ether);
    }
}
