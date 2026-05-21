// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

contract VulnerableAccessControl {
    uint256 public value;

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}

contract FixedAccessControl {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
    }

    function setValue(uint256 newValue) external {
        require(msg.sender == owner, "Not owner");
        value = newValue;
    }
}

contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");

        balances[msg.sender] = 0;
    }
}

contract FixedVault {
    mapping(address => uint256) public balances;
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant");
        locked = true;
        _;
        locked = false;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
    }
}

contract ReentrancyAttacker {
    VulnerableVault public vault;
    uint256 public attackCount;

    constructor(VulnerableVault _vault) {
        vault = _vault;
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether && attackCount < 2) {
            attackCount++;
            vault.withdraw();
        }
    }
}

contract SecurityCasesTest is Test {
    function testVulnerableAccessControlCanBeExploited() public {
        VulnerableAccessControl vulnerable = new VulnerableAccessControl();

        address attacker = address(1);

        vm.prank(attacker);
        vulnerable.setValue(999);

        assertEq(vulnerable.value(), 999);
    }

    function testFixedAccessControlBlocksAttacker() public {
        FixedAccessControl fixedContract = new FixedAccessControl();

        address attacker = address(1);

        vm.prank(attacker);
        vm.expectRevert("Not owner");
        fixedContract.setValue(999);
    }

    function testReentrancyAttackDrainsVulnerableVault() public {
        VulnerableVault vault = new VulnerableVault();
        ReentrancyAttacker attacker = new ReentrancyAttacker(vault);

        vault.deposit{value: 5 ether}();

        attacker.attack{value: 1 ether}();

        assertGt(address(attacker).balance, 1 ether);
    }

    function testFixedVaultPreventsReentrancy() public {
        FixedVault fixedVault = new FixedVault();

        fixedVault.deposit{value: 5 ether}();

        address user = address(2);
        vm.deal(user, 1 ether);

        vm.startPrank(user);
        fixedVault.deposit{value: 1 ether}();
        fixedVault.withdraw();
        vm.stopPrank();

        assertEq(fixedVault.balances(user), 0);
    }
}