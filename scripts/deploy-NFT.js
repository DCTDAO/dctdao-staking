// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");


function getTimeFromNow(delay) {
  return Math.ceil(Date.now()/1000) + delay;
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  
  const tokenContract = await ethers.getContractFactory("Token");
  const token = await tokenContract.deploy();
  //const DCTDNFTstaking = await DCTDNFTstakingContract.deploy("Hello, Hardhat!");

  //await DCTDNFTstaking.deployed();
  await token.deployed();
  const decimals = await token.decimals();
  console.log("Token addr: ", token.address);

  const DCTDNFTstakingContract = await ethers.getContractFactory("DCTDNFTstaking");
  const DCTDNFTstaking = await DCTDNFTstakingContract.deploy(
    "TestStaking",
    token.address,
    getTimeFromNow(0),
    getTimeFromNow(60),
    getTimeFromNow(60 * 5),
    1000 * decimals
    );
    
    



  console.log("DCTDNFTstaking addr: ", DCTDNFTstaking.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
