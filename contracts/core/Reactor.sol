// SPDX-License-Identifier: GPL3-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/INative.sol";

import "hardhat/console.sol";

/**
 * @notice Catalyst's Reactor contract.
 * @dev Can execute any call the owner wants
 * @author Catalyst
 */
contract Reactor is Ownable {
    mapping(address => bool) internal _admins;

    struct Instruction {
        address callee; // contract to call
        bytes callData; // bytes to pass to <call | delegatecall>
        uint256 value; // msg.value to send to callee
        bool delegateCall; // use call delegation
        bool requireSuccess; // revert if operation fails
    }

    struct Reaction {
        Instruction[] instructions;
        bool requireSuccess;
    }

    event Error(
        uint reaction,
        uint instruction,
        string errorData
    );

    modifier onlyAdminOrOwner() {
        require(_admins[msg.sender] || owner() == msg.sender, "REACTOR: Not Allowed");
        _;
    }

    /**
     * @notice This function executes any sequence of reactions given.
     * @param reactions - An array of Reaction (bundles of instructions) to execute.
     * This design enables users to give a hierarchical structure to the operations through the requireSuccess bool.
     * It is thus possible to have a reaction fail and all others succeed as well as
     * have a single instruction fail within a reaction with the latter still succeeding.
     * For instance when executing a zap into a farm if the token swap fails, the whole reaction should fail.
     * Whereas when executing multiple parallel swaps one can fail while rest succeed.
     */
    function executeReactions(Reaction[] calldata reactions)
        public
        onlyAdminOrOwner
        payable
    {
        uint256 outerLoop = reactions.length;
        for (uint256 i; i < outerLoop; ++i) {

            Reaction memory reaction = reactions[i];
            uint256 innerLoop = reaction.instructions.length;
            console.log("Reaction %s:", i);
            bool reactionSuccess = true;
            uint y;

            for (y; y < innerLoop; ++y) {

                console.log("Instruction %s:", y);

                (bool success, bytes memory data) = reaction.instructions[y].delegateCall
                    ? reaction.instructions[y].callee.delegatecall(reaction.instructions[y].callData)
                    : reaction.instructions[y].callee.call{value: reaction.instructions[y].value}(reaction.instructions[y].callData);

                if (!success) {
                    string memory errorData =  _extractRevertReason(data);
                    emit Error(i, y, errorData);
                    console.log("Failed. Error: %s", errorData);
                    if (reaction.instructions[y].requireSuccess) {
                        reactionSuccess = false;
                        // break loop and move onto next Reaction
                        break;
                    }
                }
                // console.log("Completed");
            }

            if (!reactionSuccess) {
                emit Error(i, y, "Reaction failed.");
                // console.log("Reaction %s Failed", i);
                if (reaction.requireSuccess) {
                    // console.log("Abort everything");
                    break;
                }
            }
            reactionSuccess = true;
        }
    }


    function addAdmin(address newAdmin) public onlyOwner {
        _admins[newAdmin] = true;
    }

    function removeAdmin(address admin) public onlyOwner {
        _admins[admin] = false;
    }


    /**
     * @notice Extract the revert reason encoded in the data returned from a low level call
     */
    function _extractRevertReason(bytes memory revertData)
        internal
        pure
        returns (string memory reason)
    {
        uint256 l = revertData.length;
        if (l < 68) return "Unknown Error";
        uint256 t;
        assembly {
            revertData := add(revertData, 4)
            t := mload(revertData) // Save the content of the length slot
            mstore(revertData, sub(l, 4)) // Set proper length
        }
        reason = abi.decode(revertData, (string));
        assembly {
            mstore(revertData, t) // Restore the content of the length slot
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
