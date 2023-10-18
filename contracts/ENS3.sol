// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EdexaNamingService {
    struct Domain {
        address owner;
        address resolver;
        uint256 expiration;
    }

    string public suffix = ".edx";
    uint256 public registrationCost = 1 ether;
    address public owner;
    mapping(string => Domain) domains;
    mapping(address => string[]) addressToDomains;

    event DomainRegistered(string name, address indexed owner, address resolver, uint256 expiration);
    event DomainRenewed(string name, uint256 newExpiration);
    event DomainOwnershipTransferred(string name, address indexed previousOwner, address indexed newOwner);
    event ResolverChanged(string name, address indexed resolver);
    event SuffixChanged(string newSuffix);
    event RegistrationCostChanged(uint256 newCost);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyDomainOwner(string memory name) {
        string memory domainName = string(abi.encodePacked(name, suffix));
        require(domains[domainName].owner == msg.sender, "You are not the owner of this domain.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setSuffix(string calldata newSuffix) external onlyOwner {
        suffix = newSuffix;
        emit SuffixChanged(newSuffix);
    }

    function setRegistrationCost(uint256 newCost) external onlyOwner {
        registrationCost = newCost;
        emit RegistrationCostChanged(newCost);
    }

    function registerDomain(string calldata name, address initialResolver, uint256 registrationYears) external payable {
        require(bytes(name).length > 0 && bytes(name).length <= 15, "Name should be between 1 and 15 characters.");
        require(domains[name].owner == address(0), "Domain is already owned");
        require(!hasSuffix(name), "Domain name should not include the suffix");
        uint256 totalCost = registrationCost * registrationYears;
        require(msg.value >= totalCost, "Insufficient funds to register the domain for the specified years");

        string memory domainName = string(abi.encodePacked(name, suffix));
        uint256 expiration = block.timestamp + registrationYears * 365 days;
        domains[domainName] = Domain(msg.sender, initialResolver, expiration);
        addressToDomains[msg.sender].push(domainName);  // Update the address-to-domain mapping
        
        emit DomainRegistered(domainName, msg.sender, initialResolver, expiration);

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function renewDomain(string calldata name, uint256 registrationYears) external payable onlyDomainOwner(name) {
        string memory domainName = string(abi.encodePacked(name, suffix));
        uint256 cost = registrationCost * registrationYears;
        require(msg.value >= cost, "Insufficient funds to renew the domain for the specified years");

        domains[domainName].expiration += registrationYears * 365 days;
        emit DomainRenewed(domainName, domains[domainName].expiration);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function transferOwnership(string calldata name, address newOwner) external onlyDomainOwner(name) {
        string memory domainName = string(abi.encodePacked(name, suffix));
        address previousOwner = domains[domainName].owner;
        domains[domainName].owner = newOwner;

        // Update the address-to-domain mappings for both old and new owners
        _removeDomainFromOwner(previousOwner, domainName);
        addressToDomains[newOwner].push(domainName);
        
        emit DomainOwnershipTransferred(domainName, previousOwner, newOwner);
    }

    function changeResolver(string calldata name, address newResolver) external onlyDomainOwner(name) {
        string memory domainName = string(abi.encodePacked(name, suffix));
        domains[domainName].resolver = newResolver;
        emit ResolverChanged(domainName, newResolver);
    }

    function getDomainInfo(string calldata name) external view returns (address domainOwner, address resolver, uint256 expiration) {
        string memory domainName = string(abi.encodePacked(name, suffix));
        return (domains[domainName].owner, domains[domainName].resolver, domains[domainName].expiration);
    }

    function getDomainsByOwner(address domainOwner) external view returns (string[] memory) {
        return addressToDomains[domainOwner];
    }

    function hasSuffix(string memory name) internal view returns (bool) {
        bytes memory nameBytes = bytes(name);
        bytes memory suffixBytes = bytes(suffix);

        if (nameBytes.length < suffixBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < suffixBytes.length; i++) {
            if (nameBytes[nameBytes.length - suffixBytes.length + i] != suffixBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function isDomainAvailable(string calldata name) external view returns (bool) {
        string memory domainName = string(abi.encodePacked(name, suffix));
        return domains[domainName].owner == address(0);
    }

    function _removeDomainFromOwner(address domainOwner, string memory domainName) internal {
        string[] storage ownerDomains = addressToDomains[domainOwner];
        for (uint256 i = 0; i < ownerDomains.length; i++) {
            if (keccak256(abi.encodePacked(ownerDomains[i])) == keccak256(abi.encodePacked(domainName))) {
                ownerDomains[i] = ownerDomains[ownerDomains.length - 1];
                ownerDomains.pop();
                break;
            }
        }
    }
}
