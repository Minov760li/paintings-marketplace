//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Backend {
    // address public owner;
    // bool public paused = false;
    // mapping(bytes32=>Painting) public paintings;
    // mapping(address=>uint) public balances;


    struct Painting {
        address owner;
        address creator;
        uint price;
        bool selling;
    }


    enum Currency { Wei, Ether}


    modifier onlyOwner() {
        address owner;
        assembly {
            owner := sload(0)
        }
        require(msg.sender==owner, "you are not the owner");
        _;
    }

    modifier isNotPaused() {
        bool paused;
        assembly {
            paused := sload(1)
        }
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



    function createPainting(string calldata name) external {
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        bytes32 base = _paintingsSlot(n);
        address paintingOwner;
        assembly {
            paintingOwner := sload(base)
        }
        require(paintingOwner==address(0), "Painting exists");
        _createPainting(base);
    }

    function sell(string calldata name, uint _price, Currency c) external {
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        bytes32 base = _paintingsSlot(n);
        (address owner_,,,) = _loadPainting(n);
        require(owner_!=address(0), "Painting does not exist");
        require(msg.sender==owner_, "You are not the owner");
        require(_price>0, "Set price");
        if (c == Currency.Ether) {
            assembly {
                sstore(add(base, 2), mul(_price, 1000000000000000000))
            }
            //paintings[n].price = _price*1 ether;
        }
        else if (c == Currency.Wei){
            assembly {
                sstore(add(base, 2), _price)
            }
            //paintings[n].price = _price;
        }
        else {
            revert("Unsupported currency");
        }
        assembly {
            sstore(add(base, 3), 1)
        }
        //paintings[n].selling = true;
    }

    function updateListingPrice(string calldata name, uint newPrice, Currency c) external {
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        bytes32 base = _paintingsSlot(n);
        (address owner_,,, bool selling_) = _loadPainting(n);
        require(msg.sender==owner_, "You are not the owner");
        require(selling_ == true, "Painting not listed");
        if (c == Currency.Ether) {
            assembly {
                sstore(add(base, 2), mul(newPrice, 1000000000000000000))
            }
            //paintings[n].price = _price*1 ether;
        }
        else if (c == Currency.Wei){
            assembly {
                sstore(add(base, 2), newPrice)
            }
            //paintings[n].price = _price;
        }
        else {
            revert("Unsupported currency");
        }
    }

    function cancelListing(string calldata name) external {
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name length");
        bytes32 n = keccak256(bytes(name));
        bytes32 base = _paintingsSlot(n);
        (address owner_,,, bool selling_) = _loadPainting(n);
        require(msg.sender==owner_, "You are not the owner");
        require(selling_ == true, "Painting not listed");
        assembly {
            sstore(add(base, 3), 0)
        }
        //paintings[n].selling = false;
    }

    function receiveMoney() external payable nonReentrant {
        bytes32 msgsender;
        assembly {
            msgsender := shl(96, caller())
        }
        bytes32 base = _balancesSlot(msgsender);
        (uint balanceOfmsgsender) = _loadBalances(msgsender);
        require(balanceOfmsgsender>0,"You have no money for receiving");
        uint amount = balanceOfmsgsender;
        assembly {
            sstore(base, 0)
            //balances[msg.sender]=0;
        }
        
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent==true,"Transfer failed");
    }

    function _paintingsSlot(bytes32 key) internal pure returns(bytes32 result) {
        assembly {
            mstore(0x00, key)
            mstore(0x20, 3)
            result := keccak256(0x00,0x40)
        }
    }

    function _balancesSlot(bytes32 key) internal pure returns(bytes32 result) {
        assembly {
            mstore(0x00, key)
            mstore(0x20, 4)
            result := keccak256(0x00,0x40)
        }
    }

    function _loadPainting(bytes32 key) internal view returns(address owner,address creator, uint price, bool selling) {
        bytes32 base = _paintingsSlot(key);

        assembly {
            owner := sload(base)
            creator := sload(add(base, 1))
            price := sload(add(base, 2))
            selling := sload(add(base, 3))
        }
    }

    function _loadBalances(bytes32 key) internal view returns(uint balancE) {
        bytes32 base = _balancesSlot(key);

        assembly {
            balancE := sload(base)
        }
    }

    function _createPainting(bytes32 base) internal {
        assembly {
            sstore(base, caller())
            sstore(add(base, 1), caller())
            sstore(add(base, 2), 0)
            sstore(add(base, 3), 0)
        }
    }
}