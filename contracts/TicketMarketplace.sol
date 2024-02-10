// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {

    address _coinAddress;
    address _owner;
    TicketNFT public _ticketNFT;
    uint128 _currentEventId;
    struct Event {
        uint128 maxTickets;
        uint256 nextTicketToSell;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }
    Event[] private _events;


    constructor(address coinAddress) ITicketMarketplace() {
        // create ticketNFT
        _coinAddress = coinAddress;
        _owner = msg.sender;
         _ticketNFT = new TicketNFT();
        _currentEventId = 0;
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external {
        if (msg.sender != _owner)
            revert("Unauthorized access");
        Event memory newEvent = Event(maxTickets, 0, pricePerTicket, pricePerTicketERC20);
        _events.push(newEvent);
        emit EventCreated(_currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        _currentEventId++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external {
        if (msg.sender != _owner)
            revert("Unauthorized access");
        if (newMaxTickets < _events[eventId].maxTickets)
            revert("The new number of max tickets is too small!");
        _events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external {
        if (msg.sender != _owner)
            revert("Unauthorized access");
        _events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external {
        if (msg.sender != _owner)
            revert("Unauthorized access");
        _events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

//    function mkID(uint128 eventId, uint256 ticket) private view returns (u)

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external {
        uint256 _price;
        unchecked { _price = _events[eventId].pricePerTicket * ticketCount; }
        if (_price / _events[eventId].pricePerTicket != ticketCount)
            revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");

        if (msg.value < _price)
            revert("Not enough funds supplied to buy the specified number of tickets.");
        if (ticketCount > _events[eventId].maxTickets - _events[eventId].nextTicketToSell)
            revert("We don't have that many tickets left to sell!");

        for (uint128 i=0; i < ticketCount; ++i) {
            uint256 seat = _events[eventId].nextTicketToSell;
            uint256 event256 = eventId;
            uint256 id = (event256 << 128) + seat;
            _ticketNFT.mintFromMarketPlace(msg.sender, id);
            _events[eventId].nextTicketToSell++;
        }

        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        uint256 _price;
        unchecked { _price = _events[eventId].pricePerTicketERC20 * ticketCount; }
        if (_price / _events[eventId].pricePerTicketERC20 != ticketCount)
            revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        uint256 senderBalance = IERC20(_coinAddress).balanceOf(msg.sender);
        if (senderBalance < _price)
            revert("Not enough funds supplied to buy the specified number of tickets.");
        if (ticketCount > _events[eventId].maxTickets - _events[eventId].nextTicketToSell)
            revert("We don't have that many tickets left to sell!");

        for (uint128 i=0; i < ticketCount; ++i) {
            uint256 seat = _events[eventId].nextTicketToSell;
            uint256 event256 = eventId;
            uint256 id = (event256 << 128) + seat;
            _ticketNFT.mintFromMarketPlace(msg.sender, id);
            _events[eventId].nextTicketToSell++;
        }

        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) external {
        if (msg.sender != _owner)
            revert("Unauthorized access");
        _coinAddress = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    function nftContract() public view returns (address) { return address (_ticketNFT); }

    function events(uint128 eventId) public view returns (Event memory) { return _events[eventId]; }

    function ERC20Address() public view returns (address) { return _coinAddress; }

    function owner() public view returns (address) { return _owner; }

    function currentEventId() public view returns (uint128) { return _currentEventId; }
}