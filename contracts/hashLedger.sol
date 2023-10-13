// SPDX-License-Identifier: UNLICENCED
// edexa masterchannel has store

pragma solidity ^0.8.0;

import '@openzeppelin/contracts@4.5.0/access/Ownable.sol';

contract HashLedger is Ownable{

    struct HashRecord {
        bytes20 hash;
        uint256 timestamp;
    }

    HashRecord[] public ledger;
    mapping(bytes20 => HashRecord) public hashToRecord;

    function addHash(bytes20 _hash) public onlyOwner {
        require(hashToRecord[_hash].timestamp == 0, "Hash already exists in the ledger");

        HashRecord memory newRecord = HashRecord({
            hash: _hash,
            timestamp: block.timestamp
        });

        ledger.push(newRecord);
        hashToRecord[_hash] = newRecord;
    }

    function getAllHashes() public view returns (bytes20[] memory, uint256[] memory) {
        uint256 count = ledger.length;
        bytes20[] memory hashes = new bytes20[](count);
        uint256[] memory timestamps = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            hashes[i] = ledger[i].hash;
            timestamps[i] = ledger[i].timestamp;
        }

        return (hashes, timestamps);
    }

    function getTimestampForHash(bytes20 _hash) public view returns (uint256) {
        require(hashToRecord[_hash].timestamp != 0, "Hash not found in the ledger");
        return hashToRecord[_hash].timestamp;
    }
}


