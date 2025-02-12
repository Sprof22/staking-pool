import { time, loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("Token Deployment", function () {
  
  it("Should deploy the token and assign total supply to the owner", async function () {
    const [owner] = await ethers.getSigners();

    // Deploy Token contract
    const TokenFactory = await ethers.getContractFactory("Token");
    const token = (await TokenFactory.deploy());
    await token.waitForDeployment();

    const totalSupply = await token.totalSupply();
    const ownerBalance = await token.balanceOf(owner.address);

    // Ensure owner has all the tokens
    expect(ownerBalance).to.equal(totalSupply);
  });

  it("Should have correct token name and symbol", async function () {
    const TokenFactory = await ethers.getContractFactory("Token");
    const token = (await TokenFactory.deploy());
    await token.waitForDeployment();

    expect(await token.name()).to.equal("Token");
    expect(await token.symbol()).to.equal("TKN");
  })
})