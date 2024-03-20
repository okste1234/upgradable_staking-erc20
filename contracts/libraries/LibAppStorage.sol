// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibAppStorage {
    struct Layout {
        uint256 currentNo;
        string name;
    }

    struct ERC20 {
        string _name;
        string _symbol;
        uint8 _decimal;
        uint256 _totalSupply;
        mapping(address => uint256) _balances;
        mapping(address => mapping(address => uint256)) _allowances;
        address _owner;
    }

    // stake info storage
    struct StakingStorage {
        mapping(address => uint) balanceOf;
        mapping(address => uint) stakeTime;
        mapping(address => uint) rewards;
        uint256 totalSupply;
    }
}
