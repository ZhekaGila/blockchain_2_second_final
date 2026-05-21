// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract GoldToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Gold Token", "GLD")
        Ownable(initialOwner)    
    {
        _mint(initialOwner, 1_000_000 ether);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function supportsInterface(bytes4) public pure returns (bool) {
    return false;
}
}