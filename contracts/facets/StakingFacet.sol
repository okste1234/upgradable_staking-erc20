// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";

contract StakingFacet {
    event Stake(address _staker, uint256 _amount, uint256 _timeStaked);
    LibAppStorage.Layout internal l;

    error NoMoney(uint256 balance);

    function stake(uint256 _amount) public {
        require(
            _amount <= 50_000_000e18,
            "cannot stake more than 50_000_000e18"
        );
        require(_amount > 0, "NotZero");
        require(msg.sender != address(0));
        uint256 balance = l.balances[msg.sender];
        require(balance >= _amount, "NotEnough");
        //transfer out tokens to self
        LibAppStorage._transferFrom(msg.sender, address(this), _amount);
        //do staking math
        LibAppStorage.UserStake storage s = l.userDetails[msg.sender];
        if (l.stakers.length == 0) {
            l.stakers.push(address(0));
        }
        for (uint i = 0; i < l.stakers.length; i++) {
            if (!(l.stakers[i] == msg.sender)) {
                s.id = l.stakerCounts;
                l.stakers.push(msg.sender);
                l.stakerCounts = l.stakerCounts + 1;
            }
        }

        s.stakedTime = block.timestamp;
        s.amount += _amount;
        l.lastStakedTime = block.timestamp;
        l.totalStaked += _amount;
        emit Stake(msg.sender, _amount, block.timestamp);
    }

    function checkRewards(
        address _staker
    ) public view returns (uint256 userPendingRewards) {
        LibAppStorage.UserStake memory s = l.userDetails[_staker];
        if (s.stakedTime > 0) {
            uint256 duration = block.timestamp - s.stakedTime;
            uint256 rewardPerYear = s.amount * LibAppStorage.APY;
            uint256 reward = rewardPerYear / 3154e7;
            userPendingRewards = reward * duration;
        }
    }

    event y(uint);

    // function calculateUserReward(
    //     address _staker
    // ) public view returns (uint256 reward_) {
    //     LibAppStorage.UserStake storage s = l.userDetails[_staker];
    //     if (s.stakedTime > 0) {
    //         uint256 stakedDuration = block.timestamp - s.stakedTime;
    //         uint256 totalStakedDuration = block.timestamp - l.lastStakedTime;

    //         uint256 rewardTotal = totalRewardAvailable();
    //         if (rewardTotal == 0) return 0;

    //         reward_ =
    //             (stakedDuration *
    //                 s.amount *
    //                 rewardTotal *
    //                 totalStakedDuration) /
    //             ((l.totalStaked / l.stakerCounts) * l.lastStakedTime * 3154e7);
    //     }
    // }

    function calculateUserReward(
        address _staker
    ) public view returns (uint256 reward_) {
        LibAppStorage.UserStake storage s = l.userDetails[_staker];
        if (block.timestamp > l.lastStakedTime && s.stakedTime > 0) {
            uint256 duration = block.timestamp - s.stakedTime;
            reward_ =
                (duration * s.amount * totalRewardAvailable()) /
                ((l.totalStaked / l.stakerCounts) * 3154e7);
        }
    }

    function totalRewardAvailable()
        internal
        view
        returns (uint256 calculateReward)
    {
        uint256 reward_tot_Supply = IRCX(l.rewardToken).totalSupply();
        if (reward_tot_Supply > 0) {
            calculateReward =
                (l.totalStaked * reward_tot_Supply) /
                (l.stakerCounts * l.totalStaked);
        }
    }

    function unstake(uint256 _amount) public {
        LibAppStorage.UserStake storage s = l.userDetails[msg.sender];
        // uint256 reward = checkRewards(msg.sender);
        uint256 reward = calculateUserReward(msg.sender);

        if (s.amount < _amount) revert NoMoney(s.amount);
        //unstake
        l.balances[address(this)] -= _amount;
        s.amount -= _amount;
        l.totalStaked -= _amount;
        // s.stakedTime = s.amount > 0 ? block.timestamp : 0;
        if (s.amount > 0) {
            s.stakedTime = block.timestamp;
        } else {
            s.stakedTime = block.timestamp;
            //This shifts the input value from the array to the last value in the array
            l.stakers[s.id] = l.stakers[l.stakers.length - 1];
            l.stakers.pop();
            l.stakerCounts - 1;
        }
        LibAppStorage._transferFrom(address(this), msg.sender, _amount);
        //check rewards
        l.lastStakedTime = 0;
        emit y(reward);
        if (reward > 0) {
            IRCX(l.rewardToken).transfer(msg.sender, reward);
        }
    }
}

interface IRCX {
    function mint(address _to, uint256 _amount) external;

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}
