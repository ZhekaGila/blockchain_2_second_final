// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {GameItems} from "./GameItems.sol";

contract Crafting is Ownable {
    GameItems public immutable items;

    uint256 public woodCost = 3;
    uint256 public stoneCost = 2;
    uint256 public ironCost = 1;

    event SwordCrafted(address indexed player);

    constructor(address initialOwner, address itemsAddress) Ownable(initialOwner) {
        items = GameItems(itemsAddress);
    }

    function craftSword() external {
        items.burn(msg.sender, items.WOOD(), woodCost);
        items.burn(msg.sender, items.STONE(), stoneCost);
        items.burn(msg.sender, items.IRON(), ironCost);

        items.mint(msg.sender, items.SWORD(), 1);

        emit SwordCrafted(msg.sender);
    }

    function setSwordRecipe(uint256 newWoodCost, uint256 newStoneCost, uint256 newIronCost) external onlyOwner {
        woodCost = newWoodCost;
        stoneCost = newStoneCost;
        ironCost = newIronCost;
    }

    function getRecipe() external view returns (uint256, uint256, uint256) {
        return (woodCost, stoneCost, ironCost);
    }
}
