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

    function setUp() public virtual;

    function testMetadata() public virtual {
        // We don't test 'name', 'symbol' and 'decimals' since they don't have to be present
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

        uint256[] memory _depositShares = new uint256[](_addresses.length);

        for (uint256 _i; _i < _addresses.length; _i++) {
            address _user = _addresses[_i];

            if(_user == address(0)){
                continue;
            }

            // This way '_addresses' and '_amounts' do not need to have the exact same length
            // We just reuse some previous amounts if we run out
            uint256 _amount = _amounts[_i % _amounts.length];

            // We can't deposit 0 tokens
            if(_amount == 0 || _amount > vault.maxDeposit(_user)){
                continue;
            }

            // Mint the user the needed tokens
            minter.mint(_user, _amount);

            // Start acting as the user
            vm.startPrank(_user);

            // Approve the vault to the users assets
            asset.approve(address(vault), _amount);

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
        }

        for (uint256 _i; _i < _addresses.length; _i++) {
            address _user = _addresses[_i];
            uint256 _shares = _depositShares[_i];

            if(_shares == 0){
                continue;
            }

            // TODO: Make sure this is the correct call
            uint256 _amount = vault.convertToAssets(_shares);
            uint256 _balanceBefore = asset.balanceOf(_user);

            // Withdraw the assets from the vault
            vm.prank(_user);
            vault.withdraw(_amount, _user, _user);

            assertEq(asset.balanceOf(_user), _balanceBefore + _amount);
        }
    }
}
