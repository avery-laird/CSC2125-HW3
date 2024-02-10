// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {

    address _owner;

    constructor()  ERC1155("") {
        _owner = msg.sender;
    }

    function mintFromMarketPlace(address to, uint256 nftId) external {}

    function owner() public view returns (address) { return _owner; }
}