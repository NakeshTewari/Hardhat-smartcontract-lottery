const { EtherSymbol } = require("ethers")
const { ethers } = require("hardhat")

const networkConfig = {
    5: {
        name: "rinkey",
        vrfCoordinatorV2: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
        entranceFee: ethers.utils.parseEther("0.1"),
        gasLane: "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
        subscriptionId:"0",
        callbackGasLimit: "500000", // 500,000
        interval:"30",
    },
    31337:{
        name:"hardhat",
        entranceFee: ethers.utils.parseEther("0.1"),
        gasLane:"0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
        callbackGasLimit: "500000", // 500,000
        interval:"30",
    }
}

const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
}
