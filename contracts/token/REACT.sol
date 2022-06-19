// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Catalyst_Reaction_Token is ERC20("Reaction", "REACT") {

    constructor(uint256 maxSupply)
    {
        _mint(msg.sender, maxSupply);
    }
}
