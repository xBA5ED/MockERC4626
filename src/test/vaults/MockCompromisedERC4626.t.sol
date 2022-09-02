// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../abstract/BaseMockERC4626Test.sol";

import {MockCompromisedERC4626} from "../../vaults/MockCompromisedERC4626.sol";
import {MockERC20} from "../../MockERC20.sol";

contract MockCompromisedERC4626Test is BaseMockERC4626Test {
    function setUp() public virtual override {
        // Create the valuable asset
        asset = new MockERC20("MockAsset", "MAsset", 18);
        vm.label(address(asset), "MockAsset");

        // Since we are using MockERC20 we can just use the token directly
        minter = IMintable(address(asset));

        // Create the MockLinearGainsERC4626 vault
        vault = IERC4626(
            address(
                new MockCompromisedERC4626(
                    address(asset),
                    minter,
                    "MockVault",
                    "MAsset",
                    1000
                )
            )
        );
        vm.label(address(vault), "Mock Compromised Vault");
    }

    function testMultipleDepositWithdraw(
        address[] memory _addresses,
        uint64[] memory _amounts,
        uint8[] memory _nBlocksInbetweenActions
    ) public override {}

    function testMultipleMintRedeem(
        address[] memory _addresses,
        uint64[] memory _sharesAmounts,
        uint8[] memory _nBlocksInbetweenActions
    ) public override {}

    function testMintHackWithdraw(address _user, uint64 _amount) public {
        address hacker = address(0xf00ba6);
        vm.assume(_user != address(0));
        vm.assume(_user != address(vault));
        vm.assume(_user != address(asset));
        vm.assume(_user != hacker);
        vm.assume(_amount != 0);
        vm.assume(_amount <= vault.maxDeposit(_user));

        // Mint the user the needed tokens
        minter.mint(_user, _amount);

        // Start acting as the user
        vm.startPrank(_user);

        // Get the amount of shares that will be minted
        uint256 _shares = vault.previewDeposit(_amount);

        // Only proceed if some share value can can be received
        if (_shares > 0) {
            // Approve the vault to the users assets
            asset.approve(address(vault), _amount);

            // The 'Deposit' event we expect to be emitted
            vm.expectEmit(true, true, true, true);
            emit Deposit(_user, _user, _amount, _shares);

            // Deposit the assets into the vault
            _shares = vault.deposit(_amount, _user);

            // Stop acting as the user
            vm.stopPrank();

            // Start acting as the hacker
            vm.startPrank(hacker);

            // We call previewRedeem as the user, it should return the exact amount
            uint256 _amount = vault.previewRedeem(_shares);
            uint256 _balanceBefore = asset.balanceOf(hacker);

            // drain the vault
            vault.withdraw(_amount, hacker, hacker);

            vm.stopPrank();

            // Check if the hacker received all the funds and the total supply is empty
            assertEq(asset.balanceOf(hacker), _balanceBefore + _amount);
            assertEq(vault.totalSupply(), 0);
        }
    }

    function testMintHackRedeem(address _user, uint64 _shares) public {
        address hacker = address(0xf00ba6);
        vm.assume(_user != address(0));
        vm.assume(_user != address(vault));
        vm.assume(_user != address(asset));
        vm.assume(_user != hacker);
        vm.assume(_shares != 0);
        vm.assume(_shares <= vault.maxMint(_user));

        // Start acting as the user
        vm.startPrank(_user);
        uint256 _assets = vault.previewMint(_shares);

        // Mint the user the needed tokens
        minter.mint(_user, _assets);

        // Approve the vault to the users assets
        asset.approve(address(vault), _assets);

        // The 'Deposit' event we expect to be emitted
        vm.expectEmit(true, true, true, true);
        emit Deposit(_user, _user, _assets, _shares);

        // Deposit the assets into the vault
        vault.mint(_shares, _user);

        // Stop acting as the user
        vm.stopPrank();

        // Start acting as the hacker
        vm.startPrank(hacker);

        // We call previewRedeem as the user, it should return the exact amount
        uint256 _amount = vault.previewRedeem(_shares);
        uint256 _balanceBefore = asset.balanceOf(hacker);

        // drain the vault
        vault.redeem(_shares, hacker, hacker);

        vm.stopPrank();

        // Check if the hacker received all the funds and the total supply is empty
        assertEq(asset.balanceOf(hacker), _balanceBefore + _amount);
        assertEq(vault.totalSupply(), 0);
    }
}
