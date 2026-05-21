// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {GameItems} from "./GameItems.sol";

contract ItemShop is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable goldToken;
    GameItems public immutable items;

    uint256 public woodPrice = 1 ether;
    uint256 public stonePrice = 2 ether;
    uint256 public ironPrice = 3 ether;

    constructor(
        address initialOwner,
        address goldTokenAddress,
        address itemsAddress
    ) Ownable(initialOwner) {
        goldToken = IERC20(goldTokenAddress);
        items = GameItems(itemsAddress);
    }

    function buyWood(uint256 amount) external {
        goldToken.safeTransferFrom(msg.sender, address(this), woodPrice * amount);
        items.mint(msg.sender, items.WOOD(), amount);
    }

    function buyStone(uint256 amount) external {
        goldToken.safeTransferFrom(msg.sender, address(this), stonePrice * amount);
        items.mint(msg.sender, items.STONE(), amount);
    }

    function buyIron(uint256 amount) external {
        goldToken.safeTransferFrom(msg.sender, address(this), ironPrice * amount);
        items.mint(msg.sender, items.IRON(), amount);
    }
}