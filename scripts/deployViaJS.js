const { ethers } = require("hardhat");
require("dotenv").config();
const contractJson = require('../artifacts/contracts/DCTDstaking.sol/StakingPool.json');



async function main(){
    const url = process.env.AVAXTESTNET_URL || "";
    console.log(url);
    const provider = new ethers.providers.JsonRpcProvider(url);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY  || "", provider);
    console.log(wallet.address)
    const balance = await wallet.getBalance();
    console.log(balance);

    const contractFactory = new ethers.ContractFactory(contractJson.abi, contractJson.bytecode, wallet);
    //console.log(contractFactory);
    const syrup = "0xa5eF5227CA9909A5F65Ab4241f3b40db60D1654a"; // token, which will be staked
    const rewardToken = "0x8CD88612e27aC8E01520F4333c58c97de69cd665"; // token, which will be sent as reward
    const rewardPerBlock = 120;// reward per block given to users 
    const startBlock = 34; // from which block the staking starts
    const bonusEndBlock = 350; // Ending block of the staking

    const contract = await contractFactory.deploy(syrup, rewardToken, rewardPerBlock, startBlock, bonusEndBlock);
    console.log("Deployed on: ", contract.address);

}

main()


