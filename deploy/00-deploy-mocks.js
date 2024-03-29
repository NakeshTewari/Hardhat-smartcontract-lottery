const { ethers } = require("ethers") 
const { developmentChains } = require("../hepler-hardhat-config")

const BASE_FEE =  "250000000000000000"  // 0.25 is the premium
const GAS_PRICE_LINK = 1e9 //calculated value based on the gas price of the chain

// Chainlink Nodes pay the gas fees to give us randomness & do external execution

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const args = [BASE_FEE, GAS_PRICE_LINK]

    if (developmentChains.includes(network.name)) {
        log("Local network detected! Deploying mocks...")
        // deploy a mock vrfcoordinator...
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: args,
        })

        log("Mocks Deployed!")
        log("---------------------------------------------------")
    }
}

module.exports.tags=["all","mocks"]
