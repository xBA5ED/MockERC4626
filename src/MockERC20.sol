// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IMintable} from "./interfaces/IMintable.sol";

contract MockERC20 is ERC20, IMintable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address _to, uint256 _amount) external virtual override {
        _mint(_to, _amount);
    }
}
