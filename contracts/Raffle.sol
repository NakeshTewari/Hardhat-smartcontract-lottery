//Raffle

//Enter the lottery (paying some amount)
//Pick a random winner (verifiably random)
//Winner to be selected every X minutes -> completly automated

//Chainlink Oracle -> Randomness,Automated Execution (Chainlink Keeper)

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/**@title A sample Raffle Contract
 * @author Nakesh Tewari
 * @notice This contract is for creating an untamperable decentralized smart contract
 * @dev This implements Chainlink VRF v2 and Chainlink Keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    } // uint256 0=OPEN, 1=CALCULATING

    /*State Variable*/
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //Lottery Variables
    address private s_recentWinner;
    RaffleState private s_raffleState; // to pending,open,closed,calculating
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /*Events*/
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /*functions */
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint16 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));

        //Named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink keeper nodes call they look for the 'upkeepNeeded' to return true.
     * The following should be true in order to return true:
     * 1. Our time interval should have passed
     * 2. The lottery should have at least 1 player, and have some ETh
     * 3. Our subscription is funded with LINK
     * 4. The lottery should be in an "open" state.
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view override returns (bool upKeepNeeded, bytes memory /* performData*/) {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (isOpen && timePassed && hasBalance && hasPlayers && upKeepNeeded);

        // (block.timestamp -last block timestamp) > interval
    }

    function performUpkeep(bytes calldata /*perform*/) external override {
        //Request the random number
        // Once we get it,do something with it
        //2 transaction process

        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gasLane (Max gas that you are willing to pay)
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success)
        if (!success) {
            revert Raffle__NotEnoughETHEntered();
        }
        emit WinnerPicked(recentWinner);
    }

    /*View /Pure functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function gerRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
}
