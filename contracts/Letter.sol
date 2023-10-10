// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LetterStorage {

    address public owner;
    
    struct Letter {
        uint256 date;
        string ipfsLink;
    }
    
    mapping(uint256 => Letter) public letters;
    uint256 public letterCount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addLetter(string memory _ipfsLink) public onlyOwner {
        letters[letterCount] = Letter(block.timestamp, _ipfsLink);
        letterCount++;
    }

    function updateLetter(uint256 _index, uint256 _newDate, string memory _newIpfsLink) public onlyOwner {
        require(_index < letterCount, "Invalid index");
        letters[_index] = Letter(_newDate, _newIpfsLink);
    }

    function deleteLetter(uint256 _index) public onlyOwner {
        require(_index < letterCount, "Invalid index");
        
        // Move the last element to the deleted slot and then delete the last element
        if (_index < letterCount - 1) {
            letters[_index] = letters[letterCount - 1];
        }
        delete letters[letterCount - 1];
        letterCount--;
    }

    function getLetterCount() public view returns (uint256) {
        return letterCount;
    }

    function getLetter(uint256 _index) public view returns (uint256, string memory) {
        require(_index < letterCount, "Invalid index");
        Letter memory letter = letters[_index];
        return (letter.date, letter.ipfsLink);
    }

    function getAllLetters() public view returns (Letter[] memory) {
        Letter[] memory allLetters = new Letter[](letterCount);
        for (uint256 i = 0; i < letterCount; i++) {
            allLetters[i] = letters[i];
        }
        return allLetters;
    }

}
//