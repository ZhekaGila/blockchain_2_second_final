// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GoldToken} from "./GoldToken.sol";
import {ResourceAMM} from "./ResourceAMM.sol";

contract GameFactory {
    event GoldTokenCreated(address indexed token);
    event AMMCreated(address indexed amm, address indexed token0, address indexed token1, bytes32 salt);

    function createGoldToken(address owner) external returns (address token) {
        GoldToken gold = new GoldToken(owner);
        token = address(gold);

        emit GoldTokenCreated(token);
    }

    function createAMMCreate2(address token0, address token1, bytes32 salt) external returns (address amm) {
        ResourceAMM pool = new ResourceAMM{salt: salt}(token0, token1);
        amm = address(pool);

        emit AMMCreated(amm, token0, token1, salt);
    }

    function predictAMMAddress(address token0, address token1, bytes32 salt) external view returns (address predicted) {
        bytes memory bytecode = abi.encodePacked(type(ResourceAMM).creationCode, abi.encode(token0, token1));

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        predicted = address(uint160(uint256(hash)));
    }
}
