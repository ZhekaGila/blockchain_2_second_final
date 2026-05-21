// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract YulMath {
    function solidityAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function yulAdd(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := add(a, b)
        }
    }

    function solidityMul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    function yulMul(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := mul(a, b)
        }
    }
}
