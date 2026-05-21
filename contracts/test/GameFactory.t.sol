// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameFactory} from "../src/GameFactory.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {GameToken} from "../src/GameToken.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";

contract GameFactoryTest is Test {
    GameFactory factory;
    GameToken game;
    GoldToken gold;

    address owner = address(1);

    function setUp() public {
        factory = new GameFactory();

        game = new GameToken(address(this));
        gold = new GoldToken(address(this));
    }

    function testCreateGoldTokenWithCreate() public {
        address token = factory.createGoldToken(owner);

        assertTrue(token != address(0));
    }

    function testCreatedGoldTokenHasCorrectOwner() public {
        address token = factory.createGoldToken(owner);

        GoldToken created = GoldToken(token);

        assertEq(created.owner(), owner);
    }

    function testPredictCreate2Address() public {
        bytes32 salt = keccak256("POOL_1");

        address predicted = factory.predictAMMAddress(
            address(game),
            address(gold),
            salt
        );

        address actual = factory.createAMMCreate2(
            address(game),
            address(gold),
            salt
        );

        assertEq(predicted, actual);
    }

    function testCreate2AMMHasCorrectTokens() public {
        bytes32 salt = keccak256("POOL_2");

        address ammAddress = factory.createAMMCreate2(
            address(game),
            address(gold),
            salt
        );

        ResourceAMM amm = ResourceAMM(ammAddress);

        assertEq(address(amm.token0()), address(game));
        assertEq(address(amm.token1()), address(gold));
    }

    function testCreate2DifferentSaltDifferentAddress() public {
        bytes32 salt1 = keccak256("POOL_3");
        bytes32 salt2 = keccak256("POOL_4");

        address pool1 = factory.createAMMCreate2(
            address(game),
            address(gold),
            salt1
        );

        address pool2 = factory.createAMMCreate2(
            address(game),
            address(gold),
            salt2
        );

        assertTrue(pool1 != pool2);
    }

    function testCreate2SameSaltReverts() public {
        bytes32 salt = keccak256("POOL_5");

        factory.createAMMCreate2(
            address(game),
            address(gold),
            salt
        );

        vm.expectRevert();

        factory.createAMMCreate2(
            address(game),
            address(gold),
            salt
        );
    }
}