// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameItems} from "../src/GameItems.sol";
import {Crafting} from "../src/Crafting.sol";

contract CraftingTest is Test {
    GameItems items;
    Crafting crafting;

    address owner = address(this);
    address user = address(1);

    function setUp() public {
        items = new GameItems(owner);
        crafting = new Crafting(owner, address(items));

        items.setCraftingContract(address(crafting));

        items.mint(user, items.WOOD(), 10);
        items.mint(user, items.STONE(), 10);
        items.mint(user, items.IRON(), 10);
    }

    function testInitialRecipe() public {
        assertEq(crafting.woodCost(), 3);
        assertEq(crafting.stoneCost(), 2);
        assertEq(crafting.ironCost(), 1);
    }

    function testCraftSword() public {
        vm.startPrank(user);

        items.setApprovalForAll(address(crafting), true);
        crafting.craftSword();

        vm.stopPrank();

        assertEq(items.balanceOf(user, items.WOOD()), 7);
        assertEq(items.balanceOf(user, items.STONE()), 8);
        assertEq(items.balanceOf(user, items.IRON()), 9);
        assertEq(items.balanceOf(user, items.SWORD()), 1);
    }

    function testCraftMultipleSwords() public {
        vm.startPrank(user);

        items.setApprovalForAll(address(crafting), true);
        crafting.craftSword();
        crafting.craftSword();

        vm.stopPrank();

        assertEq(items.balanceOf(user, items.WOOD()), 4);
        assertEq(items.balanceOf(user, items.STONE()), 6);
        assertEq(items.balanceOf(user, items.IRON()), 8);
        assertEq(items.balanceOf(user, items.SWORD()), 2);
    }

    function testRevertCraftWithoutApproval() public {
        vm.startPrank(user);

        vm.expectRevert("Not Approved");
        crafting.craftSword();

        vm.stopPrank();
    }

    function testRevertCraftWithoutEnoughWood() public {
        address poorUser = address(2);

        items.mint(poorUser, items.WOOD(), 1);
        items.mint(poorUser, items.STONE(), 10);
        items.mint(poorUser, items.IRON(), 10);

        vm.startPrank(poorUser);

        items.setApprovalForAll(address(crafting), true);
        vm.expectRevert();
        crafting.craftSword();

        vm.stopPrank();
    }

    function testOwnerCanChangeRecipe() public {
        crafting.setSwordRecipe(1, 1, 1);

        assertEq(crafting.woodCost(), 1);
        assertEq(crafting.stoneCost(), 1);
        assertEq(crafting.ironCost(), 1);
    }

    function testNonOwnerCannotChangeRecipe() public {
        vm.startPrank(user);

        vm.expectRevert();
        crafting.setSwordRecipe(1, 1, 1);

        vm.stopPrank();
    }

    function testCraftAfterRecipeChange() public {
        crafting.setSwordRecipe(1, 1, 1);

        vm.startPrank(user);

        items.setApprovalForAll(address(crafting), true);
        crafting.craftSword();

        vm.stopPrank();

        assertEq(items.balanceOf(user, items.WOOD()), 9);
        assertEq(items.balanceOf(user, items.STONE()), 9);
        assertEq(items.balanceOf(user, items.IRON()), 9);
        assertEq(items.balanceOf(user, items.SWORD()), 1);
    }

    function testGetRecipe() public {
        (uint256 wood, uint256 stone, uint256 iron) = crafting.getRecipe();

        assertEq(wood, 3);
        assertEq(stone, 2);
        assertEq(iron, 1);
    }

    function testCraftingContractAddressIsSet() public {
        assertEq(items.craftingContract(), address(crafting));
    }
    
    function testOwnerCanMintResources() public {
        items.mint(user, items.WOOD(), 5);

        assertEq(items.balanceOf(user, items.WOOD()), 15);
    }

    function testBurnResource() public {
        vm.startPrank(user);

        items.burn(user, items.WOOD(), 2);

        vm.stopPrank();

        assertEq(items.balanceOf(user, items.WOOD()), 8);
    }
}