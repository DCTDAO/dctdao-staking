const { expect } = require("chai");
const { ethers } = require("hardhat");


async function deploy(lockingStarts, stackingStarts, stackingEnds, minimal) {
  const tokenContract = await ethers.getContractFactory("Token");
  const token = await tokenContract.deploy();

  await token.deployed();

  const DCTDNFTstakingContract = await ethers.getContractFactory("DCTDNFTstaking");
  const DCTDNFTstaking = await DCTDNFTstakingContract.deploy(
    "TestStaking",
    token.address,
    lockingStarts,
    stackingStarts,
    stackingEnds,
    minimal
    );
  return { token, DCTDNFTstaking };
}

function getTimeFromNow(delay) {
  return Math.ceil(Date.now()/1000) + delay;
}


describe("Greeter", function () {


  



  
  


  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
