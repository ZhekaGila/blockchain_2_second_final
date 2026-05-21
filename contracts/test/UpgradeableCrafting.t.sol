// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {UpgradeableCrafting} from "../src/UpgradeableCrafting.sol";
import {UpgradeableCraftingV2} from "../src/UpgradeableCraftingV2.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeableCraftingTest is Test {
    UpgradeableCrafting proxyAsV1;

    address owner = address(this);
    address user = address(1);

    function setUp() public {
        UpgradeableCrafting impl = new UpgradeableCrafting();

        bytes memory initData = abi.encodeWithSelector(
            UpgradeableCrafting.initialize.selector,
            owner
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            initData
        );

        proxyAsV1 = UpgradeableCrafting(address(proxy));
    }

    function testInitialValues() public view {
        assertEq(proxyAsV1.woodCost(), 3);
        assertEq(proxyAsV1.stoneCost(), 2);
        assertEq(proxyAsV1.ironCost(), 1);
    }

    function testVersionV1() public view {
        assertEq(proxyAsV1.version(), "V1");
    }

    function testOwnerCanSetRecipe() public {
        proxyAsV1.setRecipe(5, 4, 3);

        assertEq(proxyAsV1.woodCost(), 5);
        assertEq(proxyAsV1.stoneCost(), 4);
        assertEq(proxyAsV1.ironCost(), 3);
    }

    function testNonOwnerCannotSetRecipe() public {
        vm.startPrank(user);

        vm.expectRevert();
        proxyAsV1.setRecipe(1, 1, 1);

        vm.stopPrank();
    }

    function testUpgradeToV2KeepsStorage() public {
        proxyAsV1.setRecipe(7, 8, 9);

        UpgradeableCraftingV2 implV2 = new UpgradeableCraftingV2();

        proxyAsV1.upgradeToAndCall(address(implV2), "");

        UpgradeableCraftingV2 proxyAsV2 =
            UpgradeableCraftingV2(address(proxyAsV1));

        assertEq(proxyAsV2.woodCost(), 7);
        assertEq(proxyAsV2.stoneCost(), 8);
        assertEq(proxyAsV2.ironCost(), 9);
    }

    function testVersionV2AfterUpgrade() public {
        UpgradeableCraftingV2 implV2 = new UpgradeableCraftingV2();

        proxyAsV1.upgradeToAndCall(address(implV2), "");

        UpgradeableCraftingV2 proxyAsV2 =
            UpgradeableCraftingV2(address(proxyAsV1));

        assertEq(proxyAsV2.version(), "V2");
    }

    function testV2CanSetGoldCost() public {
        UpgradeableCraftingV2 implV2 = new UpgradeableCraftingV2();

        proxyAsV1.upgradeToAndCall(address(implV2), "");

        UpgradeableCraftingV2 proxyAsV2 =
            UpgradeableCraftingV2(address(proxyAsV1));

        proxyAsV2.setGoldCost(10);

        assertEq(proxyAsV2.goldCost(), 10);
    }

    function testNonOwnerCannotUpgrade() public {
        UpgradeableCraftingV2 implV2 = new UpgradeableCraftingV2();

        vm.startPrank(user);

        vm.expectRevert();
        proxyAsV1.upgradeToAndCall(address(implV2), "");

        vm.stopPrank();
    }
}