// SPDX-License-Identifier: UNLICENCED
// edexa masterchannel has store

pragma solidity ^0.8.0;

import '@openzeppelin/contracts@4.5.0/access/Ownable.sol';

contract MasterChannelLedger is Ownable{

    struct MasterChannelRecord {
        string data;
        uint256 timestamp;
    }

    MasterChannelRecord[] public ledger;
    mapping(string => MasterChannelRecord) public MasterChannelDataToRecord;

    function addMasterChannelRecord(string memory _data) public onlyOwner {
        require(MasterChannelDataToRecord[_data].timestamp == 0, "Data already exists in the ledger");

        MasterChannelRecord memory newRecord = MasterChannelRecord({
            data: _data,
            timestamp: block.timestamp
        });

        ledger.push(newRecord);
        MasterChannelDataToRecord[_data] = newRecord;
    }

    function getAllData() public view returns (string[] memory, uint256[] memory) {
        uint256 count = ledger.length;
        string[] memory data = new string[](count);
        uint256[] memory timestamps = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            data[i] = ledger[i].data;
            timestamps[i] = ledger[i].timestamp;
        }

        return (data, timestamps);
    }

    function getTimestampForData(string memory _data) public view returns (uint256) {
        require(MasterChannelDataToRecord[_data].timestamp != 0, "data not found in the ledger");
        return MasterChannelDataToRecord[_data].timestamp;
    }
}


