// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Errors.sol";
import "./lib/Events.sol";

contract StakingPool {
    address public immutable owner;
    IERC20 public immutable token;
    uint256 public immutable unstakeFee;
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

    constructor(address _token, uint256 _unstakeFee) {
        if (_token == address(0)) revert Errors.InvalidAmount();
        owner = msg.sender;
        token = IERC20(_token);
        unstakeFee = _unstakeFee;
    }

    function stake(uint256 _amount) external {
        if (_amount == 0) revert Errors.InvalidAmount();
        
        stakeId++;
        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: _amount,
            stakeTime: block.timestamp
        });
        
        Staker storage staker = stakers[msg.sender];
        staker.numberOfStakes++;
        staker.amount += _amount;
        staker.rewards += (_amount * 10) / 100;
        
        if (!token.transferFrom(msg.sender, address(this), _amount)) revert Errors.TransferFailed();
        
        emit Events.Staked(msg.sender, _amount, stakeId);
    }

    function unStake(uint256 _stakeId) external {
        Stake storage stake_ = stakes[_stakeId];
        if (stake_.staker != msg.sender) revert Errors.Unauthorized();
        if (stake_.amount == 0) revert Errors.InvalidStakeId();
        
        uint256 fee = (stake_.amount * unstakeFee) / 100;
        uint256 amountAfterFee = stake_.amount - fee;
        
        delete stakes[_stakeId];
        stakers[msg.sender].amount -= stake_.amount;
        
        if (!token.transfer(msg.sender, amountAfterFee)) revert Errors.TransferFailed();
        
        emit Events.Unstaked(msg.sender, amountAfterFee, _stakeId);
    }

    function getStake(uint256 _stakeId) external view returns (Stake memory) {
        return stakes[_stakeId];
    }

    function getAllStakes() external view returns (Stake[] memory) {
        Stake[] memory allStakes = new Stake[](stakeId);
        for (uint256 i = 1; i <= stakeId; i++) {
            allStakes[i - 1] = stakes[i];
        }
        return allStakes;
    }
}