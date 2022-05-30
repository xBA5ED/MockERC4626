// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

import {IMintable} from "../interfaces/IMintable.sol";

abstract contract BaseMockERC4626 is ERC4626 {
    // Types of fees
    uint256 private _depositFeePPM;
    uint256 private _withdrawFeePPM;

    // If 0 disabled
    uint256 private _maxRedeem;
    uint256 private _maxDeposit;
    uint256 private _maxMint;
    uint256 private _maxWithdraw;

    // The address implementing the `IMintable` interface that we can call to mint more of `_asset`
    IMintable internal _minter;

    constructor(
        address _asset,
        IMintable minter,
        string memory _name,
        string memory _symbol
    ) ERC4626(ERC20(_asset), _name, _symbol) {
        _minter = minter;
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _maxDeposit == 0 ? type(uint256).max : _maxDeposit;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        return _maxMint == 0 ? type(uint256).max : _maxMint;
    }

    function maxWithdraw(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 _ownerMaxWithdraw = convertToAssets(balanceOf[owner]);

        return
            _ownerMaxWithdraw < _maxWithdraw ? _ownerMaxWithdraw : _maxWithdraw;
    }

    function maxRedeem(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 _ownerBalance = balanceOf[owner];

        if (_maxRedeem != 0 && _maxRedeem < _ownerBalance) {
            return _maxRedeem;
        }

        return _ownerBalance;
    }

    /** 
        @dev handles the housekeeping (such as compounding)
    */
    function tick() public virtual;
}
