// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IMintable} from "../../interfaces/IMintable.sol";
import {IERC4626} from "../../interfaces/IERC4626.sol";

abstract contract BaseMockERC4626Test is Test {
    IERC4626 internal vault;
    IMintable internal minter;
    ERC20 internal asset;

    uint256 secondsPerBlock = 15;

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function setUp() public virtual;

    function testMetadata() public virtual {
        // Name, Symbol and Decimal are optional in the ERC20 standard
        assertEq(vault.asset(), address(asset));
    }

    function testMultipleDepositWithdraw(
        address[] memory _addresses,
        uint64[] memory _amounts,
        uint8[] memory _nBlocksInbetweenActions
    ) public virtual {
        vm.assume(_addresses.length > 0);
        vm.assume(_amounts.length > 0);
        vm.assume(_nBlocksInbetweenActions.length > 0);

        uint256 _depositCount;
        uint256[] memory _depositShares = new uint256[](_addresses.length);

        // Perform the deposits for all the users
        for (uint256 _i; _i < _addresses.length; _i++) {
            address _user = _addresses[_i];

            if (_user == address(0) || _user == address(vault) || _user == address(asset)) {
                continue;
            }

            // This way '_addresses' and '_amounts' do not need to have the exact same length
            // We just reuse some previous amounts if we run out
            uint256 _amount = _amounts[_i % _amounts.length];

            // We can't deposit 0 tokens
            if (_amount == 0 || _amount > vault.maxDeposit(_user)) {
                continue;
            }

            // Mint the user the needed tokens
            minter.mint(_user, _amount);

            // Start acting as the user
            vm.startPrank(_user);

            // Get the amount of shares that will be minted
            uint256 _shares = vault.previewDeposit(_amount);

            // If the asset amount is very small (ex. 1), rounding may make the amount of shares 0
            // In this case depositing is not possible
            if(_shares == 0){
                vm.stopPrank();
                continue;
            }

            // Approve the vault to the users assets
            asset.approve(address(vault), _amount);

            // The 'Deposit' event we expect to be emitted
            vm.expectEmit(true, true, true, true);
            emit Deposit(_user, _user, _amount, _shares);

            // Deposit the assets into the vault
            _depositShares[_i] = vault.deposit(_amount, _user);

            // Stop acting as the user
            vm.stopPrank();

            // Fast forward block timestamp and block number
            uint256 _nBlockToForward = _nBlocksInbetweenActions[
                _i % _nBlocksInbetweenActions.length
            ];
            vm.roll(block.number + _nBlockToForward);
            vm.warp(block.timestamp + _nBlockToForward * secondsPerBlock);

            _depositCount++;
        }

        // Make sure we are performing deposits/withdrawals in this test
        vm.assume(_depositCount > 0);

        // Perform the withdrawals
        for (uint256 _i; _i < _addresses.length; _i++) {
            address _user = _addresses[_i];
            uint256 _shares = _depositShares[_i];

            if (_shares == 0) {
                continue;
            }

            // Start acting as the user
            vm.startPrank(_user);

            // We call previewRedeem as the user, it should return the exact amount
            uint256 _amount = vault.previewRedeem(_shares);
            uint256 _balanceBefore = asset.balanceOf(_user);

            // The 'Withdraw' event we expect to be emitted
            vm.expectEmit(true, true, true, true);
            emit Withdraw(_user, _user, _user, _amount, _shares);

            // Withdraw the assets from the vault
            vault.withdraw(_amount, _user, _user);

            vm.stopPrank();

            // Check if the user received the exact amount promised
            assertEq(asset.balanceOf(_user), _balanceBefore + _amount);

            // Fast forward block timestamp and block number
            uint256 _nBlockToForward = _nBlocksInbetweenActions[
                _i % _nBlocksInbetweenActions.length
            ];
            vm.roll(block.number + _nBlockToForward);
            vm.warp(block.timestamp + _nBlockToForward * secondsPerBlock);
        }

        // Sanity check
        assertEq(vault.totalSupply(), 0);
    }

      function testMultipleMintRedeem(
        address[] memory _addresses,
        uint64[] memory _sharesAmounts,
        uint8[] memory _nBlocksInbetweenActions
    ) public virtual {
        vm.assume(_addresses.length > 0);
        vm.assume(_sharesAmounts.length > 0);
        vm.assume(_nBlocksInbetweenActions.length > 0);

        uint256 _depositCount;
        uint256[] memory _depositShares = new uint256[](_addresses.length);

        // Perform the deposits for all the users
        for (uint256 _i; _i < _addresses.length; _i++) {
            address _user = _addresses[_i];

            if (_user == address(0) || _user == address(vault) || _user == address(asset)) {
                continue;
            }

            // This way '_addresses' and '_amounts' do not need to have the exact same length
            // We just reuse some previous amounts if we run out
            uint256 _shares = _sharesAmounts[_i % _sharesAmounts.length];

            // We can't deposit 0 tokens
            if (_shares == 0 || _shares > vault.maxMint(_user)) {
                continue;
            }

            _depositShares[_i] = _shares;

            vm.prank(_user);
            uint256 _assets = vault.previewMint(_shares);

            // Mint the user the needed tokens
            minter.mint(_user, _assets);

            // Start acting as the user
            vm.startPrank(_user);

            // Approve the vault to the users assets
            asset.approve(address(vault), _assets);

            // The 'Deposit' event we expect to be emitted
            vm.expectEmit(true, true, true, true);
            emit Deposit(_user, _user, _assets, _shares);

            // Deposit the assets into the vault
            vault.mint(_shares, _user);

            // Stop acting as the user
            vm.stopPrank();

            // Fast forward block timestamp and block number
            uint256 _nBlockToForward = _nBlocksInbetweenActions[
                _i % _nBlocksInbetweenActions.length
            ];
            vm.roll(block.number + _nBlockToForward);
            vm.warp(block.timestamp + _nBlockToForward * secondsPerBlock);

            _depositCount++;
        }

        // Make sure we are performing deposits/withdrawals in this test
        vm.assume(_depositCount > 0);

        // Perform the withdrawals
        for (uint256 _i; _i < _addresses.length; _i++) {
            address _user = _addresses[_i];
            uint256 _shares = _depositShares[_i];

            if (_shares == 0) {
                continue;
            }

            // Start acting as the user
            vm.startPrank(_user);

            // We call previewRedeem as the user, it should return the exact amount
            uint256 _amount = vault.previewRedeem(_shares);
            uint256 _balanceBefore = asset.balanceOf(_user);

            // The 'Withdraw' event we expect to be emitted
            vm.expectEmit(true, true, true, true);
            emit Withdraw(_user, _user, _user, _amount, _shares);

            // Withdraw the assets from the vault
            vault.redeem(_shares, _user, _user);

            vm.stopPrank();

            // Check if the user received the exact amount promised
            assertEq(asset.balanceOf(_user), _balanceBefore + _amount);

            // Fast forward block timestamp and block number
            uint256 _nBlockToForward = _nBlocksInbetweenActions[
                _i % _nBlocksInbetweenActions.length
            ];
            vm.roll(block.number + _nBlockToForward);
            vm.warp(block.timestamp + _nBlockToForward * secondsPerBlock);
        }

        // Sanity check
        assertEq(vault.totalSupply(), 0);
    }
}
