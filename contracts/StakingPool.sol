// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Errors.sol";
import "./lib/Events.sol";

contract StakingPool {
    address public immutable owner;
    IERC20 public immutable token;
    IERC20 public rewardToken;
    uint256 public unstakeFee;
    uint256 public rewardRatePerSecond;
    uint256 public lockDuration;
    uint256 public totalRewardsDistributed;
    uint256 public totalRewardsAvailable;
    uint256 public stakeId;

    struct Staker {
        uint256 numberOfStakes;
        uint256 rewards;
        uint256 amount;
    }

    struct Stake {
        address staker;
        uint256 amount;
        uint256 stakeTime;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => Stake) public stakes;
    mapping(address => uint256[]) private userStakeIds;

    constructor(address _token, address _rewardToken, uint256 _unstakeFee) {
        if (_token == address(0) || _rewardToken == address(0)) revert Errors.InvalidAmount();
        owner = msg.sender;
        token = IERC20(_token);
        rewardToken = IERC20(_rewardToken);
        unstakeFee = _unstakeFee;
    }

    function stake(uint256 _amount) external {
        if (_amount == 0) revert Errors.InvalidAmount();

        // Update state before external call
        stakeId++;
        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: _amount,
            stakeTime: block.timestamp
        });

        Staker storage staker = stakers[msg.sender];
        staker.numberOfStakes++;
        staker.amount += _amount;

        userStakeIds[msg.sender].push(stakeId);

        // External call
        if (!token.transferFrom(msg.sender, address(this), _amount)) revert Errors.TransferFailed();

        emit Events.Staked(msg.sender, _amount, stakeId);
    }

    function unStake(uint256 _stakeId) external {
        Stake storage stake_ = stakes[_stakeId];
        if (stake_.staker != msg.sender) revert Errors.Unauthorized();
        if (stake_.amount == 0) revert Errors.InvalidStakeId();
        if (block.timestamp < stake_.stakeTime + lockDuration) revert Errors.InvalidStakeId();

        uint256 reward = calculateReward(_stakeId);
        uint256 fee = (stake_.amount * unstakeFee) / 100;
        uint256 amountAfterFee = stake_.amount - fee;

        // Update state before external calls
        delete stakes[_stakeId];
        stakers[msg.sender].amount -= stake_.amount;
        stakers[msg.sender].rewards += reward;
        totalRewardsDistributed += reward;

        // External calls
        if (!token.transfer(msg.sender, amountAfterFee)) revert Errors.TransferFailed();
        if (reward > 0 && rewardToken.balanceOf(address(this)) >= reward) {
            rewardToken.transfer(msg.sender, reward);
        }

        emit Events.Unstaked(msg.sender, amountAfterFee + reward, _stakeId);
    }

    function calculateReward(uint256 _stakeId) public view returns (uint256) {
        Stake memory stake = stakes[_stakeId];
        uint256 timeElapsed = block.timestamp - stake.stakeTime;
        return (stake.amount * rewardRatePerSecond * timeElapsed) / 1e18;
    }

    function fundRewards(uint256 _amount) external {
        if (msg.sender != owner) revert Errors.Unauthorized();
        if (_amount == 0) revert Errors.InvalidAmount();

        // Update state before external call
        totalRewardsAvailable += _amount;

        // External call
        rewardToken.transferFrom(msg.sender, address(this), _amount);
    }

    function emergencyWithdraw() external {
        if (msg.sender != owner) revert Errors.Unauthorized();

        // Update state before external call
        uint256 balance = token.balanceOf(address(this));

        // External call
        token.transfer(owner, balance);
    }

    function setUnstakeFee(uint256 _fee) external {
        if (msg.sender != owner) revert Errors.Unauthorized();
        unstakeFee = _fee;
    }

    function setRewardRate(uint256 _rate) external {
        if (msg.sender != owner) revert Errors.Unauthorized();
        rewardRatePerSecond = _rate;
    }

    function setLockDuration(uint256 _duration) external {
        if (msg.sender != owner) revert Errors.Unauthorized();
        lockDuration = _duration;
    }

    function getStake(uint256 _stakeId) external view returns (Stake memory) {
        return stakes[_stakeId];
    }

    function getAllStakes(uint256 limit, uint256 offset) external view returns (Stake[] memory) {
        uint256 end = stakeId < offset + limit ? stakeId : offset + limit;
        if (end <= offset) return new Stake[](0);

        Stake[] memory result = new Stake[](end - offset);
        for (uint256 i = offset + 1; i <= end; i++) {
            result[i - offset - 1] = stakes[i];
        }
        return result;
    }

    function getUserStakeIds(address _user) external view returns (uint256[] memory) {
        return userStakeIds[_user];
    }
}