// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@reactive-lib/abstract-base/AbstractCallback.sol";

contract PriceFeedProxy is AbstractCallback {
    address owner;

    uint8 public decimals;
    string public description;
    uint256 public version = 1;

    // Price feed data
    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    // Latest round data
    RoundData public latestRound;

    // Historical round data
    mapping(uint80 => RoundData) public rounds;

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event CallbackReceived(
        address indexed sender,
        address indexed origin,
        uint80 indexed roundId,
        int256 answer,
        uint8 decimals,
        string description,
        uint256 version,
        uint256 startedAt,
        uint256 updatedAt
    );

    constructor(
        address _callback_sender,
        uint8 _decimals,
        string memory _description
    )
        AbstractCallback(_callback_sender) // Set desired callback address for secure bridging
    {
        owner = msg.sender;
        decimals = _decimals;
        description = _description;
    }

    /**
     * @notice Updates the price feed with new data by the reactive contract
     * @param sender The address of the sender (reactvm). Will always be the ReactVM address
     * @param roundId The round ID
     * @param answer The latest answer (price)
     * @param updatedAt The timestamp when the round was updated
     * @param startedAt The timestamp when the round started
     */
    function updateAnswer(
        address sender,
        address origin,
        uint80 roundId,
        int256 answer,
        uint8 _decimals,
        string memory _description,
        uint256 _version,
        uint256 startedAt,
        uint256 updatedAt
    ) public authorizedSenderOnly {
        require(sender == owner, "No Permission!"); // sender is the reactvm address(deployer)
        require(roundId > latestRound.roundId, "Invalid roundId");
        require(answer > 0, "Invalid answer");

        // Update latest round data
        latestRound = RoundData(roundId, answer, startedAt, updatedAt, roundId);
        // Update historical round data
        rounds[roundId] = latestRound;

        // update decimals, description, version if changed
        // if (decimals != _decimals) {
        //     decimals = _decimals;
        // }
        // if (keccak256(bytes(description)) != keccak256(bytes(_description))) {
        //     description = _description;
        // }
        // if (version != _version) {
        //     version = _version;
        // }
        emit AnswerUpdated(answer, roundId, updatedAt);
        emit CallbackReceived(
            sender,
            origin,
            roundId,
            answer,
            _decimals,
            _description,
            _version,
            startedAt,
            updatedAt
        );
    }

    /**
     * @notice Gets the round data for a specific round ID.
     * @dev Reverts with "No data present" if no data is available for the given round ID.
     * @param _roundId The round ID to get the data for
     * @return roundId The round ID
     * @return answer The answer for the round
     * @return startedAt The timestamp when the round started
     * @return updatedAt The timestamp when the round was updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        RoundData memory round = rounds[_roundId];
        require(round.updatedAt > 0, "No data present");
        return (
            round.roundId,
            round.answer,
            round.startedAt,
            round.updatedAt,
            round.answeredInRound
        );
    }

    /**
     *  @notice Gets the latest round data. Reverts with "No data present" if no data is available.
     * @return roundId The latest round ID
     * @return answer The latest answer
     * @return startedAt The timestamp when the latest round started
     * @return updatedAt The timestamp when the latest round was updated
     * @return answeredInRound The round ID in which the latest answer was computed
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(latestRound.updatedAt > 0, "No data present");
        return (
            latestRound.roundId,
            latestRound.answer,
            latestRound.startedAt,
            latestRound.updatedAt,
            latestRound.answeredInRound
        );
    }
}
