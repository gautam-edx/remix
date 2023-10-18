// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthereumNamingService {
    struct Domain {
        address owner;
        address resolver;
    }

    mapping(string => Domain) domains;

    event DomainRegistered(string name, address indexed owner, address resolver);
    event DomainOwnershipTransferred(string name, address indexed previousOwner, address indexed newOwner);
    event ResolverChanged(string name, address indexed resolver);

    modifier onlyOwner(string memory name) {
        require(domains[name].owner == msg.sender, "You are not the owner of this domain.");
        _;
    }

    function registerDomain(string calldata name, address initialResolver) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(domains[name].owner == address(0), "Domain is already owned");
        
        domains[name] = Domain(msg.sender, initialResolver);
        emit DomainRegistered(name, msg.sender, initialResolver);
    }

    function transferOwnership(string calldata name, address newOwner) external onlyOwner(name) {
        address previousOwner = domains[name].owner;
        domains[name].owner = newOwner;
        emit DomainOwnershipTransferred(name, previousOwner, newOwner);
    }

    function changeResolver(string calldata name, address newResolver) external onlyOwner(name) {
        domains[name].resolver = newResolver;
        emit ResolverChanged(name, newResolver);
    }

    function getDomainInfo(string calldata name) external view returns (address owner, address resolver) {
        owner = domains[name].owner;
        resolver = domains[name].resolver;
    }
}
