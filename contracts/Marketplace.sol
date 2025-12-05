//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Backend} from "./MerchantsBackend.sol";

contract Marketplace {
    bool private entered = false;
    address public owner;
    bool public paused = false;
    mapping(bytes32=>Painting) public paintings;
    mapping(address=>uint) public balances;

    address immutable backend;
    bytes4[5] functions = [
    bytes4(keccak256("createPainting(string)")),
    bytes4(keccak256("sell(string, uint256, uint8)")),
    bytes4(keccak256("updateListingPrice(string, uint256, uint8)")),
    bytes4(keccak256("cancelListing(string)")),
    bytes4(keccak256("receiveMoney()"))
    ];

    constructor(address _backend) {
        owner = msg.sender;
        backend = _backend;
    }

    function buy(string calldata name) public payable isNotPaused nonReentrant{
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        require(paintings[n].owner!=address(0),"Painting does not exist");
        require(msg.sender!=paintings[n].owner,"You are the owner");
        require(paintings[n].selling==true, "Painting not for sale");
        require(balances[msg.sender]>=paintings[n].price, "Not enough money");
        balances[msg.sender]-=paintings[n].price;
        balances[paintings[n].owner]+=paintings[n].price-(paintings[n].price*10/100)-(paintings[n].price*2/100);
        balances[paintings[n].creator]+=paintings[n].price*10/100;
        balances[owner]+=paintings[n].price*2/100;
        paintings[n].owner = msg.sender;
        paintings[n].selling = false;
    }

    function deposit() public payable isNotPaused{
        require(msg.value>0, "No money sended");
        balances[msg.sender]+=msg.value;
    }

    function info(string calldata name) public isNotPaused view returns(Painting memory) {
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        return paintings[n];
    }



    struct Painting {
        address owner;
        address creator;
        uint price;
        bool selling;
    }



    modifier onlyOwner() {
        require(msg.sender==owner, "you are not the owner");
        _;
    }

    modifier isNotPaused() {
        require(paused==false, "marketplace paused");
        _;
    }

    // bool private entered = false;
    modifier nonReentrant() {
        require(!entered, "Reentrancy attack");
        entered = true;
        _;
        entered = false;
    }


    
    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }


    receive() external payable {}

    fallback() external payable isNotPaused nonReentrant{
        bytes4 selector;
        assembly {
            selector := calldataload(0)
            selector := shr(224, selector)  
        }
        bool allowed = false;
        for (uint i=0;i<functions.length;i++) {
            if (functions[i]==selector) {
                allowed = true;
                break;
            }
        }
        require(allowed==true,"Function not allowed");
        (bool success, bytes memory data) = backend.delegatecall(msg.data);
        require(success, "call failed");
        assembly {
        return(add(data, 32), mload(data))
            }
    }
}