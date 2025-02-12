// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library Events {
        event Staked(address indexed user, uint256 amount, uint256 stakeId);
    event Unstaked(address indexed user, uint256 amount, uint256 stakeId);
}