import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  // Deploy the staking token (ERC-20)
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy();
  await token.waitForDeployment();
  console.log(`Token deployed at: ${await token.getAddress()}`);

  // Deploy the reward token (ERC-20)
  const RewardToken = await ethers.getContractFactory("Token");
  const rewardToken = await RewardToken.deploy();
  await rewardToken.waitForDeployment();
  console.log(`Reward Token deployed at: ${await rewardToken.getAddress()}`);

  // Define unstake fee (example: 5%)
  const unstakeFee = 5;

  // Deploy the StakingPool with the correct constructor arguments
  const StakingPool = await ethers.getContractFactory("StakingPool");
  const stakingPool = await StakingPool.deploy(
    await token.getAddress(), // Staking token address
    await rewardToken.getAddress(), // Reward token address
    unstakeFee // Unstake fee percentage
  );
  await stakingPool.waitForDeployment();

  console.log(`StakingPool deployed at: ${await stakingPool.getAddress()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
