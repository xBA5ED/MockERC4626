// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../abstract/BaseMockERC4626Test.sol";

import {MockLinearGainsERC4626} from "../../vaults/MockLinearGainsERC4626.sol";
import {MockERC20} from "../../MockERC20.sol";

contract MockLinearGainsERC4626Test is BaseMockERC4626Test {
    function setUp() public virtual override {
        // Create the valuable asset
        asset = new MockERC20("MockAsset", "MAsset", 18);
        vm.label(address(asset), "MockAsset");

        // Since we are using MockERC20 we can just use the token directly
        minter = IMintable(address(asset));

        // Create the MockLinearGainsERC4626 vault
        vault = IERC4626(
            address(
                new MockLinearGainsERC4626(
                    address(asset),
                    minter,
                    "MockVault",
                    "MAsset",
                    1000
                )
            )
        );
        vm.label(address(vault), "MockVault");
    }
}
