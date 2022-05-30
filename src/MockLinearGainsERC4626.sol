// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IMintable} from "./interfaces/IMintable.sol";
import {BaseMockERC4626} from "./abstract/BaseMockERC4626.sol";

contract MockLinearGainsERC4626 is BaseMockERC4626 {
    uint256 internal _lastCompoundTimestamp;
    uint256 internal _totalAssets;

    uint256 internal _gainsPerSecond;

    constructor(
        address _asset,
        IMintable minter,
        string memory _name,
        string memory _symbol,
        uint256 gainsPerSecond
    ) BaseMockERC4626(_asset, _minter, _name, _symbol) {
        _gainsPerSecond = gainsPerSecond;
    }

    function _unrealisedGains() internal view returns (uint256) {
        return (block.timestamp - _lastCompoundTimestamp) * _gainsPerSecond;
    }

    function totalAssets() public view virtual override returns (uint256) {
        if (_totalAssets == 0) {
            return 0;
        }
        return _totalAssets + _unrealisedGains();
    }

    function beforeWithdraw(uint256 assets, uint256 shares)
        internal
        virtual
        override
    {
        tick();
        _totalAssets -= assets;
    }

    function afterDeposit(uint256 assets, uint256 shares)
        internal
        virtual
        override
    {
        tick();
        _totalAssets += assets;
    }

    function tick() public virtual override {
        uint256 _newAssets = _unrealisedGains();

        _totalAssets += _newAssets;
        _lastCompoundTimestamp = block.timestamp;

        _minter.mintTo(address(this), _newAssets);
    }
}
