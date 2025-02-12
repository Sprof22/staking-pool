import { expect } from "chai";
import { ethers } from "hardhat";
import { StakingPool, Token } from "../typechain-types"; // Adjust import path if needed

describe("StakingPool", function () {
  
  it("Should deploy the staking pool and set the owner", async function () {
    const [owner] = await ethers.getSigners();

    // Deploy Token
    const TokenFactory = await ethers.getContractFactory("Token");
    const token = (await TokenFactory.deploy()) as Token;
    await token.waitForDeployment();

    // Deploy Staking Pool
    const unstakeFee = ethers.parseUnits("2", 18);
    const StakingPoolFactory = await ethers.getContractFactory("StakingPool");
    const stakingPool = (await StakingPoolFactory.deploy(token, token, unstakeFee)) as StakingPool;
    await stakingPool.waitForDeployment();

    expect(await stakingPool.owner()).to.equal(owner.address);
  });

  it("Should initialize unstake fee correctly", async function () {
    const [owner] = await ethers.getSigners();
    
    const TokenFactory = await ethers.getContractFactory("Token");
    const token = (await TokenFactory.deploy()) as Token;
    await token.waitForDeployment();

    const unstakeFee = ethers.parseUnits("2", 18);
    const StakingPoolFactory = await ethers.getContractFactory("StakingPool");
    const stakingPool = (await StakingPoolFactory.deploy(token, token, unstakeFee)) as StakingPool;
    await stakingPool.waitForDeployment();

    expect(await stakingPool.unstakeFee()).to.equal(unstakeFee);
  });

  it("Should reject staking 0 tokens", async function () {
    const [owner, account1] = await ethers.getSigners();
    
    const TokenFactory = await ethers.getContractFactory("Token");
    const token = (await TokenFactory.deploy()) as Token;
    await token.waitForDeployment();

    const unstakeFee = ethers.parseUnits("2", 18);
    const StakingPoolFactory = await ethers.getContractFactory("StakingPool");
    const stakingPool = (await StakingPoolFactory.deploy(token, token, unstakeFee)) as StakingPool;
    await stakingPool.waitForDeployment();

    const zeroAmount = ethers.parseUnits("0", 18);
    await expect(stakingPool.connect(account1).stake(zeroAmount)).to.be.revertedWithCustomError(
      stakingPool,
      "InvalidAmount"
    );
  });

  it("Should increment stakeId when a user stakes", async function () {
    const [owner, account1, account2] = await ethers.getSigners();
    
    const TokenFactory = await ethers.getContractFactory("Token");
    const token = (await TokenFactory.deploy()) as Token;
    await token.waitForDeployment();

    const unstakeFee = ethers.parseUnits("2", 18);
    const StakingPoolFactory = await ethers.getContractFactory("StakingPool");
    const stakingPool = (await StakingPoolFactory.deploy(token, token, unstakeFee)) as StakingPool;
    await stakingPool.waitForDeployment();

    const stakeAmount = ethers.parseUnits("20", 18);
    
    // Fund accounts & approve staking
    await token.transfer(account1.address, stakeAmount);
    await token.connect(account1).approve(stakingPool, stakeAmount);
    await stakingPool.connect(account1).stake(stakeAmount);

    expect(await stakingPool.stakeId()).to.equal(1);

    await token.transfer(account2.address, stakeAmount);
    await token.connect(account2).approve(stakingPool, stakeAmount);
    await stakingPool.connect(account2).stake(stakeAmount);

    expect(await stakingPool.stakeId()).to.equal(2);
  });

});
