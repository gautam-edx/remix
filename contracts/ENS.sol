// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EdexaNameService{
    address owner;
    mapping(address => string) public names;

    event NameRegistered(address indexed user, string name);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this operation");
        _;
    }

    function registerName(string calldata name) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 255, "Name is too long");
        names[msg.sender] = name;
        emit NameRegistered(msg.sender, name);
    }

    function getName(address user) public view returns (string memory) {
        return names[user];
    }

    function getNameForUser(address user) public view returns (string memory) {
        string memory name = names[user];
        if (bytes(name).length > 0) {
            return string(abi.encodePacked(name, ".edx"));
        } else {
            return "";
        }
    }

    function updateName(string calldata name) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 255, "Name is too long");
        names[msg.sender] = name;
        emit NameRegistered(msg.sender, name);
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
