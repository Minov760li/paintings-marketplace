//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Backend} from "./MerchantsBackend.sol";

contract Marketplace is Backend{
    address immutable backend;
    
    constructor(address _backend) {
        require(msg.sender==owner, "You are not the owner");
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
        emit PaintingSold(name);
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

    receive() override external payable {}
}