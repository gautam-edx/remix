// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    address public currentImplementation;
    address public owner;

    constructor(address initialImplementation) {
        currentImplementation = initialImplementation;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function upgradeTo(address newImplementation) external onlyOwner {
        currentImplementation = newImplementation;
    }

    fallback() external payable {
        address implementation = currentImplementation;
        require(implementation != address(0), "Implementation not set");
        bytes memory data = msg.data;

        assembly {
            let result := delegatecall(
                gas(),
                implementation,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let size := returndatasize()

            // Fetch the free memory pointer
            let ptr := mload(0x40)

            returndatacopy(ptr, 0, size)

            // Set the next free memory slot (after storing the returndata)
            mstore(0x40, add(ptr, size))

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}