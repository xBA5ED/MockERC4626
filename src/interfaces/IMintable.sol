// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IMintable {
    function mintTo(address _to, uint256 _amount) external;
}
