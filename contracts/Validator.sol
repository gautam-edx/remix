// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract ValidatorDepositContract is ReentrancyGuard, Ownable, Pausable {
    // Mapping to store validator node addresses to their associated validator account addresses
    mapping(address => address) public validatorNodeToAccount;
    
    // Mapping to store the deposited balances for each validator account
    mapping(address => uint256) public depositedBalances;

    // Mapping to store the total deposited amount for each validator node
    mapping(address => uint256) public totalDepositedAmount;

    // Array to store all validator node addresses
    address[] public allValidatorNodes;

    uint256 public withdrawalFeePercentage = 10; // 10% fee by default
    address public edxAccount = address(0); // Default edxAccount
    
    constructor() Ownable(msg.sender) {}
    
    // Function for validator nodes to deposit Ether and link to their account
    function deposit() external payable nonReentrant whenNotPaused {
        address validatorAccountAddress = validatorNodeToAccount[msg.sender];
        require(validatorAccountAddress != address(0), "Validator node not linked");
        depositedBalances[validatorAccountAddress] += msg.value; // Deposit to the associated account
        totalDepositedAmount[msg.sender] += msg.value; // Update the total deposited amount for the node
        
        // If the validator node address is not already in the array, add it
        if (!contains(allValidatorNodes, msg.sender)) {
            allValidatorNodes.push(msg.sender);
        }
    }
    
    // Function for validator accounts to withdraw their deposited Ether
    function withdraw() external nonReentrant whenNotPaused{
        uint256 depositAmount = depositedBalances[msg.sender];
        require(depositAmount > 0, "No funds available to withdraw");
        
        uint256 fee = (depositAmount * withdrawalFeePercentage) / 100; // Calculate fee dynamically
        uint256 withdrawAmount = depositAmount - fee; // Calculate the amount to be withdrawn
        
        depositedBalances[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawAmount);
        
        if (edxAccount != address(0)) {
            payable(edxAccount).transfer(fee); // Transfer the fee to edxAccount if set
        }
    }
    
    // Function to link or update a validator node address to a validator account address
    function linkValidatorNode(address validatorNodeAddress, address validatorAccountAddress) external onlyOwner{
        validatorNodeToAccount[validatorNodeAddress] = validatorAccountAddress;

          // If the validator node address is not already in the array, add it
        if (!contains(allValidatorNodes, validatorNodeAddress)) {
            allValidatorNodes.push(validatorNodeAddress);
        }
    }

    // Function to delete a validator node
    function deleteValidatorNode(address validatorNodeAddress) external onlyOwner {

        address associatedAddress = validatorNodeToAccount[validatorNodeAddress];
        uint256 depositAmount = depositedBalances[associatedAddress];
        uint256 fee = (depositAmount * withdrawalFeePercentage) / 100; // Calculate fee dynamically
        uint256 withdrawAmount = depositAmount - fee; // Calculate the amount to be withdrawn
        depositedBalances[associatedAddress] = 0;
        payable(associatedAddress).transfer(withdrawAmount);
        if (edxAccount != address(0)) {
            payable(edxAccount).transfer(fee); // Transfer the fee to edxAccount if set
        }


        // Remove the validator node from the allValidatorNodes array
        for (uint256 i = 0; i < allValidatorNodes.length; i++) {
            if (allValidatorNodes[i] == validatorNodeAddress) {
                // Swap the node to delete with the last node in the array and then shrink the array
                allValidatorNodes[i] = allValidatorNodes[allValidatorNodes.length - 1];
                allValidatorNodes.pop();
                break;
            }
        }

        // Clear the mappings for the deleted node
        delete validatorNodeToAccount[validatorNodeAddress];
        delete totalDepositedAmount[validatorNodeAddress];
    }

    // Function to set the withdrawal fee percentage (owner only)
    function setWithdrawalFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        withdrawalFeePercentage = _feePercentage;
    }

    // Function to set the edxAccount address (owner only)
    function setEdxAccount(address _account) external onlyOwner {
        edxAccount = _account;
    }

    // Function to pause the contract (only callable by the owner)
    function pauseContract() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only callable by the owner)
    function unpauseContract() external onlyOwner {
       _unpause();
    }

    // Function to fetch details of a specific validator node
    function getValidatorNodeDetails(address validatorNodeAddress) external view returns (address, uint256, uint256) {
        address associatedAddress = validatorNodeToAccount[validatorNodeAddress];
        uint256 sentAmount = totalDepositedAmount[validatorNodeAddress];
        uint256 remainingBalance = depositedBalances[associatedAddress];
        
        return (associatedAddress, sentAmount, remainingBalance);
    }

    // Function to fetch details of all validator nodes
    function fetchAllValidatorNodeDetails() external view returns (address[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        uint256 totalNodes = allValidatorNodes.length;
        address[] memory nodeAddresses = new address[](totalNodes);
        address[] memory associatedAddresses = new address[](totalNodes);
        uint256[] memory sentAmounts = new uint256[](totalNodes);
        uint256[] memory remainingBalances = new uint256[](totalNodes);

        for (uint256 i = 0; i < totalNodes; i++) {
            address nodeAddress = allValidatorNodes[i];
            address associatedAddress = validatorNodeToAccount[nodeAddress];
            uint256 sentAmount = totalDepositedAmount[nodeAddress];
            uint256 remainingBalance = depositedBalances[associatedAddress];
            
            nodeAddresses[i] = nodeAddress;
            associatedAddresses[i] = associatedAddress;
            sentAmounts[i] = sentAmount;
            remainingBalances[i] = remainingBalance;
        }

        return (nodeAddresses, associatedAddresses, sentAmounts, remainingBalances);
    }

    // Function to check if an element exists in an array
    function contains(address[] storage array, address element) internal view returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }
    
}