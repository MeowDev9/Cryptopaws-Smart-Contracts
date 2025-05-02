// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/DonationContract.sol";

contract DeployScript {
    function run() external {
        DonationContract donationContract = new DonationContract();
    }
}