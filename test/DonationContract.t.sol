// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DonationContract.sol";

// Mock Chainlink Aggregator for testing
contract MockAggregatorV3 {
    int256 private _price;
    
    constructor(int256 price) {
        _price = price;
    }
    
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, _price, 0, block.timestamp, 0);
    }
}

contract DonationContractTest is Test {
    DonationContract public donationContract;
    MockAggregatorV3 public mockPriceFeed;
    address public owner;
    address public organization;
    address public donor;
    address public organizationWallet;

    function setUp() public {
        owner = address(this);
        organization = address(0x1);
        donor = address(0x2);
        organizationWallet = address(0x3);

        // Deploy mock price feed with $2000/ETH (with 8 decimals)
        mockPriceFeed = new MockAggregatorV3(200000000000); // $2000 with 8 decimals
        
        // Deploy contract
        donationContract = new DonationContract();
        
        // Mock the price feed address by deploying our mock at the expected address
        vm.etch(0x694AA1769357215DE4FAC081bf1f309aDC325306, address(mockPriceFeed).code);
        // Set the mock's price storage in the target address
        vm.store(0x694AA1769357215DE4FAC081bf1f309aDC325306, bytes32(0), bytes32(uint256(200000000000))); // $2000 with 8 decimals
    }

    function test_RegisterOrganization() public {
        vm.startPrank(organization);
        donationContract.registerOrganization("Test Org", "Test Description", payable(organizationWallet));
        vm.stopPrank();

        (
            string memory name,
            string memory description,
            address walletAddress,
            bool isActive,
            uint256 orgTotalDonations,
            uint256 uniqueDonors
        ) = donationContract.getOrganizationInfo(organizationWallet); // Check organizationWallet, not organization

        assertEq(name, "Test Org");
        assertEq(description, "Test Description");
        assertEq(walletAddress, organizationWallet);
        assertTrue(isActive);
        assertEq(orgTotalDonations, 0);
        assertEq(uniqueDonors, 0);
    }

    function test_Donate() public {
        // Register organization
        vm.startPrank(organization);
        donationContract.registerOrganization("Test Org", "Test Description", payable(organizationWallet));
        vm.stopPrank();

        // Make donation
        vm.deal(donor, 1 ether);
        vm.startPrank(donor);
        donationContract.donate{value: 0.5 ether}(organizationWallet, "Test donation"); // Use organizationWallet
        vm.stopPrank();

        // Check organization stats
        (,,,, uint256 orgTotalDonations, uint256 uniqueDonors) = donationContract.getOrganizationInfo(organizationWallet); // Use organizationWallet

        assertEq(orgTotalDonations, 0.5 ether);
        assertEq(uniqueDonors, 1);

        // Check donor history
        DonationContract.Donation[] memory history = donationContract.getDonorHistory(donor);
        assertEq(history.length, 1);
        assertEq(history[0].donor, donor);
        assertEq(history[0].organization, organizationWallet); // Use organizationWallet
        assertEq(history[0].amount, 0.5 ether);
        assertEq(history[0].message, "Test donation");
    }

    function test_EthAmountForUsd() public {
        uint256 usdAmount = 10; // $10
        uint256 ethAmount = donationContract.ethAmountForUsd(usdAmount);
        assertGt(ethAmount, 0, "ETH amount should be greater than 0");
    }

    function test_MinUsdDonation() public {
        uint256 minUsd = donationContract.minUsdDonation();
        assertEq(minUsd, 5, "Minimum USD donation should be $5");
    }

    function test_RevertWhen_DonatingBelowMinAmount() public {
        // Register organization
        vm.startPrank(organization);
        donationContract.registerOrganization("Test Org", "Test Description", payable(organizationWallet));
        vm.stopPrank();

        // Try to donate below min amount ($5 USD worth of ETH)
        // At $2000/ETH, $5 = 0.0025 ETH, so 0.001 ETH should be too low
        vm.deal(donor, 0.01 ether);
        vm.startPrank(donor);
        vm.expectRevert("Donation amount too low");
        donationContract.donate{value: 0.001 ether}(organizationWallet, "Test donation"); // Use organizationWallet
    }

    function test_RevertWhen_DonatingToInactiveOrganization() public {
        // Register organization
        vm.startPrank(organization);
        donationContract.registerOrganization("Test Org", "Test Description", payable(organizationWallet));
        vm.stopPrank();

        // Set organization to inactive - must be called by the organization wallet address
        vm.startPrank(organizationWallet);
        donationContract.setOrganizationStatus(false);
        vm.stopPrank();

        // Try to donate to inactive organization
        vm.deal(donor, 1 ether);
        vm.startPrank(donor);
        vm.expectRevert("Organization not active");
        donationContract.donate{value: 0.5 ether}(organizationWallet, "Test donation"); // Use organizationWallet
    }
}
