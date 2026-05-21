// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract UpgradeableCrafting is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public woodCost;
    uint256 public stoneCost;
    uint256 public ironCost;

    event RecipeChanged(uint256 woodCost, uint256 stoneCost, uint256 ironCost);

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);

        woodCost = 3;
        stoneCost = 2;
        ironCost = 1;
    }

    function setRecipe(uint256 newWoodCost, uint256 newStoneCost, uint256 newIronCost) external onlyOwner {
        woodCost = newWoodCost;
        stoneCost = newStoneCost;
        ironCost = newIronCost;

        emit RecipeChanged(newWoodCost, newStoneCost, newIronCost);
    }

    function version() external pure virtual returns (string memory) {
        return "V1";
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
