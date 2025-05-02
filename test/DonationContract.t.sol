// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DonationContract.sol";

contract DonationContractTest is Test {
    DonationContract public donationContract;
    address public owner;
    address public organization;
    address public donor;
    address public organizationWallet;

    function setUp() public {
        owner = address(this);
        organization = address(0x1);
        donor = address(0x2);
        organizationWallet = address(0x3);

        donationContract = new DonationContract();
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
        ) = donationContract.getOrganizationInfo(organization);

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
        donationContract.donate{value: 0.5 ether}(organization, "Test donation");
        vm.stopPrank();

        // Check organization stats
        (
            ,
            ,
            ,
            ,
            uint256 orgTotalDonations,
            uint256 uniqueDonors
        ) = donationContract.getOrganizationInfo(organization);

        assertEq(orgTotalDonations, 0.5 ether);
        assertEq(uniqueDonors, 1);

        // Check donor history
        DonationContract.Donation[] memory history = donationContract.getDonorHistory(donor);
        assertEq(history.length, 1);
        assertEq(history[0].donor, donor);
        assertEq(history[0].organization, organization);
        assertEq(history[0].amount, 0.5 ether);
        assertEq(history[0].message, "Test donation");
    }

    function test_SetMinDonationAmount() public {
        uint256 newAmount = 0.02 ether;
        donationContract.setMinDonationAmount(newAmount);
        assertEq(donationContract.minDonationAmount(), newAmount);
    }

    function test_RevertWhen_DonatingBelowMinAmount() public {
        // Register organization
        vm.startPrank(organization);
        donationContract.registerOrganization("Test Org", "Test Description", payable(organizationWallet));
        vm.stopPrank();

        // Try to donate below min amount
        vm.deal(donor, 0.005 ether);
        vm.startPrank(donor);
        vm.expectRevert("Donation amount too low");
        donationContract.donate{value: 0.005 ether}(organization, "Test donation");
    }

    function test_RevertWhen_DonatingToInactiveOrganization() public {
        // Register organization
        vm.startPrank(organization);
        donationContract.registerOrganization("Test Org", "Test Description", payable(organizationWallet));
        donationContract.setOrganizationStatus(false);
        vm.stopPrank();

        // Try to donate to inactive organization
        vm.deal(donor, 1 ether);
        vm.startPrank(donor);
        vm.expectRevert("Organization not active");
        donationContract.donate{value: 0.5 ether}(organization, "Test donation");
    }
} 