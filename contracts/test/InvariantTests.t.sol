// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";

import {GameToken} from "../src/GameToken.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";
import {YieldVault} from "../src/YieldVault.sol";

contract Handler is Test {
    GameToken public game;
    GoldToken public gold;
    ResourceAMM public amm;
    YieldVault public vault;

    address public user = address(1);

    constructor(
        GameToken _game,
        GoldToken _gold,
        ResourceAMM _amm,
        YieldVault _vault
    ) {
        game = _game;
        gold = _gold;
        amm = _amm;
        vault = _vault;



        vm.startPrank(user);

        game.approve(address(amm), type(uint256).max);
        gold.approve(address(amm), type(uint256).max);

        gold.approve(address(vault), type(uint256).max);

        amm.addLiquidity(1000 ether, 1000 ether);

        vm.stopPrank();
    }

    function swapGame(uint256 amount) public {
        amount = bound(amount, 1 ether, 100 ether);

        vm.startPrank(user);

        amm.swap(address(game), amount, 0);

        vm.stopPrank();
    }

    function swapGold(uint256 amount) public {
        amount = bound(amount, 1 ether, 100 ether);

        vm.startPrank(user);

        amm.swap(address(gold), amount, 0);

        vm.stopPrank();
    }

    function depositVault(uint256 amount) public {
        amount = bound(amount, 1 ether, 100 ether);

        vm.startPrank(user);

        vault.deposit(amount, user);

        vm.stopPrank();
    }

    function withdrawVault(uint256 amount) public {
        uint256 shares = vault.balanceOf(user);

        if (shares == 0) return;

        amount = bound(amount, 1, shares);

        vm.startPrank(user);

        vault.redeem(amount, user, user);

        vm.stopPrank();
    }
}

contract InvariantTests is StdInvariant, Test {
    GameToken game;
    GoldToken gold;
    ResourceAMM amm;
    YieldVault vault;

    Handler handler;

    uint256 initialK;

    function setUp() public {
        game = new GameToken(address(this));
        gold = new GoldToken(address(this));

        amm = new ResourceAMM(address(game), address(gold));
        vault = new YieldVault(gold, address(this));

        game.mint(address(1), 1_000_000 ether);
        gold.mint(address(1), 1_000_000 ether);

        handler = new Handler(
            game,
            gold,
            amm,
            vault
        );

        targetContract(address(handler));

        initialK =
            amm.reserve0() *
            amm.reserve1();
    }

    // -------------------------------------------------
    // AMM INVARIANTS
    // -------------------------------------------------

    function invariant_KNeverDecreases() public view {
        uint256 currentK =
            amm.reserve0() *
            amm.reserve1();

        assertGe(currentK, initialK);
    }

    function invariant_ReservesNeverZeroAfterInit() public view {
        assertGt(amm.reserve0(), 0);
        assertGt(amm.reserve1(), 0);
    }

    function invariant_TotalSupplyMatchesLP() public view {
        assertGt(amm.totalSupply(), 0);
    }

    // -------------------------------------------------
    // VAULT INVARIANTS
    // -------------------------------------------------

    function invariant_TotalAssetsGTEZero() public view {
        assertGe(vault.totalAssets(), 0);
    }

    function invariant_VaultSupplyGTEZero() public view {
        assertGe(vault.totalSupply(), 0);
    }
}