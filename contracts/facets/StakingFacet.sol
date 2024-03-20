// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "../interfaces/IERC20.sol";
import {LibStake} from "../libraries/LibAppStorage.sol";

contract StakingFacet {
    LibStake.StakeStorage ss

    // custom errors
    error ADDRESS_ZERO();
    error INVALID_AMOUNT();
    error INSUFFICIENT_AMOUNT();
    error USER_HAS_NO_STAKE();
    error NO_REWARD_TO_CLIAM();

    // events
    event stakingSuccessful(address _staker, uint256 _amount);
    event claimSuccessful(address _staker, uint256 _amount);
    event unStakeSuccessful(address _staker, uint256 _amount);

    // stake function
    function stake(uint256 _amount) external {

        if (msg.sender == address(0)) {
            revert ADDRESS_ZERO();
        }

        if (_amount <= 0) {
            revert INVALID_AMOUNT();
        }

        if (IERC20(ss.erc20Token).balanceOf(msg.sender) < _amount) {
            revert INSUFFICIENT_AMOUNT();
        }

        require(
            IERC20(ss.erc20Token).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "failed to transfer"
        );

        ss.stakes[msg.sender] = LibStake.StakeInfo(_amount, block.timestamp, 0);

        emit stakingSuccessful(msg.sender, _amount);
    }

    // function unstake
    function unStake() external {
        if (msg.sender == address(0)) {
            revert ADDRESS_ZERO();
        }

        if (ss.stakes[msg.sender].amountStaked <= 0) {
            revert USER_HAS_NO_STAKE();
        }

        LibStake.StakeInfo memory _staker = ss.stakes[msg.sender];
        uint256 _reward = _staker.reward + calculateReward();

        ss.stakes[msg.sender].reward = 0;
        ss.stakes[msg.sender].timeStaked = 0;
        ss.stakes[msg.sender].amountStaked = 0;

        IERC20(ss.rewardToken).transfer(
            msg.sender,
            _staker.amountStaked + _reward
        );

        emit unStakeSuccessful(msg.sender, _staker.amountStaked + _reward);
    }

    // cliam reward function
    function cliamReward() external {

        if (ss.stakes[msg.sender].amountStaked <= 0) {
            revert NO_REWARD_TO_CLIAM();
        }

        uint256 _reward = ss.stakes[msg.sender].reward + calculateReward();

        ss.stakes[msg.sender].reward = 0;
        ss.stakes[msg.sender].timeStaked = block.timestamp;

        IERC20(ss.rewardToken).transfer(msg.sender, _reward);

        emit claimSuccessful(msg.sender, _reward);
    }

    // calculateReward function
    function calculateReward() public view returns (uint256) {

        uint256 _callerStake = ss.stakes[msg.sender].amountStaked;

        if (_callerStake <= 0) {
            revert USER_HAS_NO_STAKE();
        }

        return
            (block.timestamp - ss.stakes[msg.sender].timeStaked) *
            ss.rewardRate *
            _callerStake;
    }
}
