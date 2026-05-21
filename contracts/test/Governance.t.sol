// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameToken} from "../src/GameToken.sol";
import {GameGovernor} from "../src/GameGovernor.sol";
import {Crafting} from "../src/Crafting.sol";
import {GameItems} from "../src/GameItems.sol";

import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {IGovernor} from "openzeppelin-contracts/contracts/governance/IGovernor.sol";

contract GovernanceTest is Test {
    GameToken token;
    GameGovernor governor;
    TimelockController timelock;
    GameItems items;
    Crafting crafting;

    address voter = address(1);

    function setUp() public {
        token = new GameToken(address(this));

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        timelock = new TimelockController(
            2 minutes,
            proposers,
            executors,
            address(this)
        );

        governor = new GameGovernor(token, timelock);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));

        items = new GameItems(address(this));
        crafting = new Crafting(address(this), address(items));
        items.setCraftingContract(address(crafting));

        crafting.transferOwnership(address(timelock));

        token.mint(voter, 100_000 ether);

        vm.prank(voter);
        token.delegate(voter);
    }

    function createRecipeProposal()
        internal
        returns (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        )
    {
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);

        targets[0] = address(crafting);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(
            crafting.setSwordRecipe.selector,
            1,
            1,
            1
        );

        description = "Change sword recipe to 1-1-1";

        vm.prank(voter);
        proposalId = governor.propose(
            targets,
            values,
            calldatas,
            description
        );
    }

    function testVotingPowerAfterDelegate() public view {
        assertEq(token.getVotes(voter), 100_000 ether);
    }

    function testCreateProposal() public {
        (uint256 proposalId, , , , ) = createRecipeProposal();

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));
    }

    function testProposalBecomesActive() public {
        (uint256 proposalId, , , , ) = createRecipeProposal();

        vm.roll(block.number + governor.votingDelay() + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));
    }

    function testVoteForProposal() public {
        (uint256 proposalId, , , , ) = createRecipeProposal();

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(voter);
        governor.castVote(proposalId, 1);

        (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        ) = governor.proposalVotes(proposalId);

        assertEq(againstVotes, 0);
        assertGt(forVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function testProposalSucceededAfterVotingPeriod() public {
        (uint256 proposalId, , , , ) = createRecipeProposal();

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(voter);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + governor.votingPeriod() + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));
    }

    function testQueueProposal() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        ) = createRecipeProposal();

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(voter);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + governor.votingPeriod() + 1);

        governor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));
    }

    function testExecuteProposalChangesRecipe() public {
        (
            uint256 proposalId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        ) = createRecipeProposal();

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(voter);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + governor.votingPeriod() + 1);

        governor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        vm.warp(block.timestamp + 3 minutes);

        governor.execute(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        assertEq(crafting.woodCost(), 1);
        assertEq(crafting.stoneCost(), 1);
        assertEq(crafting.ironCost(), 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));
    }

    function testNonTimelockCannotChangeRecipeAfterTransfer() public {
        vm.expectRevert();
        crafting.setSwordRecipe(1, 1, 1);
    }
}