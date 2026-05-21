// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UpgradeableCrafting} from "./UpgradeableCrafting.sol";

contract UpgradeableCraftingV2 is UpgradeableCrafting {
    uint256 public goldCost;

    event GoldCostChanged(uint256 goldCost);

    function setGoldCost(uint256 newGoldCost) external onlyOwner {
        goldCost = newGoldCost;
        emit GoldCostChanged(newGoldCost);
    }

    function version() external pure override returns (string memory) {
        return "V2";
    }
}