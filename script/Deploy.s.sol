// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/DonationContract.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        DonationContract donationContract = new DonationContract();
        console.log("Contract deployed at:", address(donationContract));
        vm.stopBroadcast();
    }
}