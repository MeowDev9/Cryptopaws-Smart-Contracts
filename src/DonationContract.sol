// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DonationContract is Ownable, ReentrancyGuard {
    struct Donation {
        address donor;
        address organization;
        uint256 amount;
        uint256 timestamp;
        string message;
    }

    struct WelfareOrganization {
        string name;
        string description;
        address payable walletAddress;
        bool isActive;
        uint256 totalDonations;
        uint256 uniqueDonors;
        mapping(address => bool) donors;
    }

    mapping(address => WelfareOrganization) public organizations;
    mapping(address => Donation[]) public donorHistory;
    mapping(address => bool) public isOrganization;
    
    uint256 public totalDonations;
    uint256 public totalOrganizations;
    uint256 public minDonationAmount = 0.01 ether;

    event OrganizationRegistered(address indexed organization, string name);
    event DonationMade(address indexed donor, address indexed organization, uint256 amount);
    event OrganizationStatusChanged(address indexed organization, bool isActive);
    event MinDonationAmountUpdated(uint256 newAmount);

    modifier onlyOrganization() {
        require(isOrganization[msg.sender], "Not a registered organization");
        _;
    }

    modifier validDonation() {
        require(msg.value >= minDonationAmount, "Donation amount too low");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function registerOrganization(
        string memory _name,
        string memory _description,
        address payable _walletAddress
    ) external {
        require(!isOrganization[_walletAddress], "Organization already registered");
        require(_walletAddress != address(0), "Invalid wallet address");

        WelfareOrganization storage org = organizations[_walletAddress];
        org.name = _name;
        org.description = _description;
        org.walletAddress = _walletAddress;
        org.isActive = true;

        isOrganization[_walletAddress] = true;
        totalOrganizations++;

        emit OrganizationRegistered(_walletAddress, _name);
    }

    function setOrganizationStatus(bool _isActive) external onlyOrganization {
        organizations[msg.sender].isActive = _isActive;
        emit OrganizationStatusChanged(msg.sender, _isActive);
    }

    function donate(address _organization, string memory _message) 
        external 
        payable 
        nonReentrant 
        validDonation 
    {
        require(isOrganization[_organization], "Organization not found");
        require(organizations[_organization].isActive, "Organization not active");

        WelfareOrganization storage org = organizations[_organization];
        
        // Update organization stats
        org.totalDonations += msg.value;
        if (!org.donors[msg.sender]) {
            org.donors[msg.sender] = true;
            org.uniqueDonors++;
        }

        // Record donation
        Donation memory newDonation = Donation({
            donor: msg.sender,
            organization: _organization,
            amount: msg.value,
            timestamp: block.timestamp,
            message: _message
        });

        donorHistory[msg.sender].push(newDonation);
        totalDonations += msg.value;

        // Transfer funds to organization
        (bool success, ) = org.walletAddress.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit DonationMade(msg.sender, _organization, msg.value);
    }

    function getDonorHistory(address _donor) external view returns (Donation[] memory) {
        return donorHistory[_donor];
    }

    function getOrganizationInfo(address _organization) external view returns (
        string memory name,
        string memory description,
        address walletAddress,
        bool isActive,
        uint256 orgTotalDonations,
        uint256 uniqueDonors
    ) {
        WelfareOrganization storage org = organizations[_organization];
        return (
            org.name,
            org.description,
            org.walletAddress,
            org.isActive,
            org.totalDonations,
            org.uniqueDonors
        );
    }

    function getTotalDonations() external view returns (uint256) {
        return totalDonations;
    }

    function getTotalDonors() external view returns (uint256) {
        return totalOrganizations;
    }

    function setMinDonationAmount(uint256 _amount) external onlyOwner {
        minDonationAmount = _amount;
        emit MinDonationAmountUpdated(_amount);
    }

    // Function to receive ETH
    receive() external payable {}
} 