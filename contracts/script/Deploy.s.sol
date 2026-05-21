// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {GameToken} from "../src/GameToken.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {GameItems} from "../src/GameItems.sol";
import {Crafting} from "../src/Crafting.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";
import {YieldVault} from "../src/YieldVault.sol";
import {GameGovernor} from "../src/GameGovernor.sol";
import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {YulMath} from "../src/YulMath.sol";
import {UpgradeableCrafting} from "../src/UpgradeableCrafting.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ItemShop} from "../src/ItemShop.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        address[10] memory testUsers = [
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
            0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
            0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
            0x976EA74026E726554dB657fA54763abd0C3a0aa9,
            0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
            0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f,
            0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
        ];

        GameToken gameToken = new GameToken(deployer);
        GoldToken goldToken = new GoldToken(deployer);
        YieldVault vault = new YieldVault(goldToken, deployer);

        GameItems items = new GameItems(deployer);
        Crafting crafting = new Crafting(deployer, address(items));
        items.setCraftingContract(address(crafting));
        UpgradeableCrafting craftingImpl = new UpgradeableCrafting();

        bytes memory initData = abi.encodeWithSelector(UpgradeableCrafting.initialize.selector, deployer);

        ERC1967Proxy craftingProxy = new ERC1967Proxy(address(craftingImpl), initData);

        UpgradeableCrafting upgradeableCrafting = UpgradeableCrafting(address(craftingProxy));

        GameFactory factory = new GameFactory();

        ResourceAMM amm = new ResourceAMM(address(gameToken), address(goldToken));

        for (uint256 i = 0; i < testUsers.length; i++) {
            gameToken.mint(testUsers[i], 1000 ether);
            goldToken.mint(testUsers[i], 1000 ether);
        }

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        TimelockController timelock = new TimelockController(2 minutes, proposers, executors, deployer);

        GameGovernor governor = new GameGovernor(gameToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, deployer);

        crafting.transferOwnership(address(timelock));

        YulMath yulMath = new YulMath();

        ItemShop itemShop = new ItemShop(deployer, address(goldToken), address(items));

        items.setItemShop(address(itemShop));

        vm.stopBroadcast();

        console2.log("Deployer:", deployer);
        console2.log("GameToken:", address(gameToken));
        console2.log("GoldToken:", address(goldToken));
        console2.log("GameItems:", address(items));
        console2.log("Crafting:", address(crafting));
        console2.log("ResourceAMM:", address(amm));
        console2.log("YieldVault:", address(vault));
        console2.log("Timelock:", address(timelock));
        console2.log("GameGovernor:", address(governor));
        console2.log("GameFactory:", address(factory));
        console2.log("YulMath:", address(yulMath));
        console2.log("UpgradeableCrafting implementation:", address(craftingImpl));
        console2.log("UpgradeableCrafting proxy:", address(upgradeableCrafting));
        console2.log("UpgradeableCrafting version:", upgradeableCrafting.version());
        console2.log("ItemShop:", address(itemShop));
    }
}
