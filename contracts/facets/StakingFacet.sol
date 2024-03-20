// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IERC20.sol";
import "../libraries/LibAppStorage.sol";

contract StakingFacet {
    LibAppStorage.StakingStorage internal s;

    IERC20 private stakeToken;
    IERC20 private rewardToken;

    event Unstaked(
        address indexed _sender,
        address indexed _to,
        uint _amountToBeTransfered
    );
    event StakingSuccessful(address sender, uint _amount);

    function init(address _stakedToken, address _rewardToken) external {
        stakeToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
    }

    function stake(uint _amount) external {
        require(msg.sender != address(0), "Address Zero");
        require(_amount >= 0, "Invalid amount");
        require(
            IERC20(stakeToken).balanceOf(msg.sender) >= _amount,
            "insuffiecient balance"
        );
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount);
        s.balanceOf[msg.sender] += _amount;
        s.totalSupply += _amount;
        s.stakeTime[msg.sender] = block.timestamp;

        emit StakingSuccessful(msg.sender, _amount);
    }

    function calculateBalanceWithInterest(
        address _user
    ) private view returns (uint256) {
        require(_user != address(0), "Address Zero");

        if (s.balanceOf[_user] == 0) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp - s.stakeTime[_user];
        uint256 partialYearPercentage = (stakingDuration * 100) / (365 days); // Percentage of the year staked
        uint256 interest = (s.balanceOf[_user] * 120 * partialYearPercentage) /
            10000; // Adjusted for partial year
        return s.balanceOf[_user] + interest;
    }

    function unstaked() external {
        uint256 _totalReward = calculateBalanceWithInterest(msg.sender);
        s.balanceOf[msg.sender] = 0;
        IERC20(rewardToken).transferFrom(
            address(this),
            msg.sender,
            _totalReward
        );
        emit Unstaked(address(this), msg.sender, _totalReward);
    }

    function contractBalance() external view returns (uint) {
        return IERC20(stakeToken).balanceOf(address(this));
    }
}
