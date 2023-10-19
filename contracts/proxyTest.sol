// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EdexaNamingService2 {
    struct Domain {
        address owner;
        address resolver;
        uint256 expiration;
    }
    address public currentImplementation;
    address public owner;
    mapping(string => uint256) public suffixPrices;
    mapping(string => Domain) domains;
    mapping(address => string[]) addressToDomains;

    event DomainRegistered(
        string name,
        address indexed owner,
        address resolver,
        uint256 expiration
    );
    event DomainRenewed(string name, uint256 newExpiration);
    event DomainOwnershipTransferred(
        string name,
        address indexed previousOwner,
        address indexed newOwner
    );
    event ResolverChanged(string name, address indexed resolver);
    event SuffixPriceChanged(string suffix, uint256 newCost);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    modifier onlyDomainOwner(string memory domainName) {
        require(
            domains[domainName].owner == msg.sender,
            "You are not the owner of this domain."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setSuffixPrice(string calldata suffix, uint256 newCost)
        external
        onlyOwner
    {
        suffixPrices[suffix] = newCost;
        emit SuffixPriceChanged(suffix, newCost);
    }

    function toLowerCase(string memory str)
        internal
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint256 i = 0; i < bStr.length; i++) {
            if (uint8(bStr[i]) >= 65 && uint8(bStr[i]) <= 90) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function registerDomain(
        string calldata name,
        address initialResolver,
        uint256 registrationYears,
        string calldata chosenSuffix
    ) external payable {
        require(suffixPrices[chosenSuffix] != 0, "Invalid suffix");

        string memory lowerName = toLowerCase(name);
        require(
            bytes(lowerName).length > 0 && bytes(lowerName).length <= 15,
            "Name should be between 1 and 15 characters."
        );

        string memory domainName = string(
            abi.encodePacked(lowerName, chosenSuffix)
        );

        bool isExpired = domains[domainName].expiration < block.timestamp;

        require(
            domains[domainName].owner == address(0) || isExpired,
            "Domain is already owned or not yet expired"
        );

        if (isExpired) {
            _removeDomainFromOwner(domains[domainName].owner, domainName);
        }

        uint256 totalCost = suffixPrices[chosenSuffix] * registrationYears;
        require(
            msg.value >= totalCost,
            "Insufficient funds to register the domain for the specified years"
        );

        uint256 expiration = block.timestamp + registrationYears * 1 minutes;
        domains[domainName] = Domain(msg.sender, initialResolver, expiration);
        addressToDomains[msg.sender].push(domainName);

        emit DomainRegistered(
            domainName,
            msg.sender,
            initialResolver,
            expiration
        );

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function renewDomain(string calldata domainName, uint256 registrationYears)
        external
        payable
        onlyDomainOwner(domainName)
    {
        uint256 suffixPosition = _getSuffixPosition(domainName);
        string memory suffix = _extractSuffix(domainName, suffixPosition);

        uint256 cost = suffixPrices[suffix] * registrationYears;
        require(
            msg.value >= cost,
            "Insufficient funds to renew the domain for the specified years"
        );

        domains[domainName].expiration += registrationYears * 365 days;
        emit DomainRenewed(domainName, domains[domainName].expiration);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function transferDomainOwnership(string calldata domainName, address newOwner)
        external
        onlyDomainOwner(domainName)
    {
        require(
            domains[domainName].expiration >= block.timestamp,
            "Domain has expired."
        );

        address previousOwner = domains[domainName].owner;
        domains[domainName].owner = newOwner;

        _removeDomainFromOwner(previousOwner, domainName);
        addressToDomains[newOwner].push(domainName);

        emit DomainOwnershipTransferred(domainName, previousOwner, newOwner);
    }

    function changeResolver(string calldata domainName, address newResolver)
        external
        onlyDomainOwner(domainName)
    {
        require(
            domains[domainName].expiration >= block.timestamp,
            "Domain has expired."
        );

        domains[domainName].resolver = newResolver;
        emit ResolverChanged(domainName, newResolver);
    }

    function getDomainInfo(string calldata domainName)
        external
        view
        returns (
             address domainOwner,
            address resolver,
            uint256 expiration
        )
    {
        return (
            domains[domainName].owner,
            domains[domainName].resolver,
            domains[domainName].expiration
        );
    }

    function getDomainsByOwner(address domainOwner)
        external
        view
        returns (string[] memory)
    {
        return addressToDomains[domainOwner];
    }

    function isDomainAvailable(string calldata domainName)
        external
        view
        returns (bool)
    {
        return domains[domainName].owner == address(0) || domains[domainName].expiration < block.timestamp;
    }

    function _removeDomainFromOwner(
        address domainOwner,
        string memory domainName
    ) internal {
        string[] storage ownerDomains = addressToDomains[domainOwner];
        for (uint256 i = 0; i < ownerDomains.length; i++) {
            if (
                keccak256(abi.encodePacked(ownerDomains[i])) ==
                keccak256(abi.encodePacked(domainName))
            ) {
                ownerDomains[i] = ownerDomains[ownerDomains.length - 1];
                ownerDomains.pop();
                break;
            }
        }
    }

    function _getSuffixPosition(string memory domainName)
        internal
        pure
        returns (uint256)
    {
        bytes memory domainBytes = bytes(domainName);
        for (uint256 i = domainBytes.length; i > 0; i--) {
            if (domainBytes[i - 1] == ".") {
                return i;
            }
        }
        revert("No suffix found");
    }

    function _extractSuffix(string memory domainName, uint256 position)
        internal
        pure
        returns (string memory)
    {
        bytes memory domainBytes = bytes(domainName);
        bytes memory result = new bytes(domainBytes.length - position);
        for (uint256 i = position; i < domainBytes.length; i++) {
            result[i - position] = domainBytes[i];
        }
        return string(result);
    }

    function withdrawCurrency(uint256 amt) public  {
        payable(msg.sender).transfer(amt);
    }

    function withdrawToken(address token, uint256 amt) public onlyOwner {
        IERC20(token).transfer(msg.sender, amt);
    }

}
           
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
