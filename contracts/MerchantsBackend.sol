//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Backend {
    address public owner;
    bool public paused = false;


    constructor() {
        owner = msg.sender;
    }


    struct Painting {
        address owner;
        address creator;
        uint price;
        bool selling;
    }


    enum Currency { Wei, Ether}


    mapping(bytes32=>Painting) public paintings;
    mapping(address=>uint) public balances;


    modifier onlyOwner() {
        require(msg.sender==owner, "you are not the owner");
        _;
    }

    modifier isNotPaused() {
        require(paused==false, "marketplace paused");
        _;
    }

    bool private entered = false;
    modifier nonReentrant() {
        require(!entered, "Reentrancy attack");
        entered = true;
        _;
        entered = false;
    }


    event PaintingCreated(string);
    event ListingCreated(string);
    event ListingUpdated(string);
    event ListingCanceled(string);
    event PaintingSold(string);
    event Withdraw(address , uint );


    function createPainting(string calldata name) external isNotPaused{
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        require(paintings[n].owner==address(0), "Painting exists");
        paintings[n] = Painting(msg.sender,msg.sender,0,false);
        emit PaintingCreated(name);
    }

    function sell(string calldata name, uint _price, Currency c) external isNotPaused{
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        require(paintings[n].owner!=address(0), "Painting does not exist");
        require(msg.sender==paintings[n].owner, "You are not the owner");
        require(_price>0, "Set price");
        if (c == Currency.Ether) {
            paintings[n].price = _price*1 ether;
        }
        else if (c == Currency.Wei){
            paintings[n].price = _price;
        }
        else {
            revert("Unsupported currency");
        }
        paintings[n].selling = true;
        emit ListingCreated(name);
    }

    function updateListingPrice(string calldata name, uint newPrice, Currency c) external isNotPaused{
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        require(msg.sender==paintings[n].owner, "You are not the owner");
        require(paintings[n].selling == true, "Painting not listed");
        if (c == Currency.Ether) {
            paintings[n].price = newPrice*1 ether;
        }
        else if (c == Currency.Wei){
            paintings[n].price = newPrice;
        }
        else {
            revert("Unsupported currency");
        }
        emit ListingUpdated(name);
    }

    function cancelListing(string calldata name) external isNotPaused{
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        require(msg.sender==paintings[n].owner, "You are not the owner");
        require(paintings[n].selling == true, "Painting not listed");
        paintings[n].selling = false;
        emit ListingCanceled(name);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }


    //napravi ownera (ili adminite?) da moje da vzimat feevote toest slagash feevote da otivat v backend
    function receiveMoney() external payable nonReentrant isNotPaused{
        require(balances[msg.sender]>0,"You have no money for receiving");
        uint amount = balances[msg.sender];
        balances[msg.sender]=0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent==true,"Transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    receive() virtual external payable {}
}