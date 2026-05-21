// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract GameItems is ERC1155, Ownable {
    uint256 public constant WOOD = 1;
    uint256 public constant STONE = 2;
    uint256 public constant IRON = 3;
    uint256 public constant SWORD = 4;

    address public craftingContract;


    constructor(address initialOwner)
        ERC1155("https://gamefi.example/api/item/{id}.json")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 id, uint256 amount) external {
        require(
            msg.sender == owner() ||
            msg.sender == craftingContract ||
            msg.sender == itemShop,
            "Not allowed to mint"
        );

        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function burn (address from, uint256 id, uint256 amount) external{
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "Not Approved"
        );
        _burn(from,id,amount);
    }

    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts)external{
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "NoApproved"
        );

        _burnBatch(from, ids, amounts);
    }

    function setCraftingContract(address _craftingContract) external onlyOwner{
        craftingContract = _craftingContract;
    }

    address public itemShop;

    function setItemShop(address _itemShop) external onlyOwner {
        itemShop = _itemShop;
    }
}