// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@reactive-lib/interfaces/IReactive.sol";
import "@reactive-lib/interfaces/ISystemContract.sol";
import "@reactive-lib/abstract-base/AbstractReactive.sol";

contract ChainlinkPriceFeedReactive is IReactive, AbstractReactive {
    // states for reactive logic
    uint64 private constant GAS_LIMIT = 1000000;
    uint256 private counter;

    address immutable destination;
    uint256 immutable destinationChainId;
    uint8 immutable decimals;
    string description;
    uint256 immutable version = 1;

    uint256 private constant AGGREGATOR_ANSWER_UPDATED_TOPIC =
        uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));

    event Event(
        uint256 indexed chain_id,
        address indexed _contract,
        uint256 indexed topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3,
        bytes data,
        uint256 counter
    );

    constructor(
        address _service,
        uint256 _originChainId,
        address _origin,
        uint256 _destinationChainId,
        address _destination,
        uint8 _decimals,
        string memory _description,
        uint256 _version
    ) {
        destination = _destination;
        destinationChainId = _destinationChainId;
        decimals = _decimals;
        description = _description;
        version = _version;
        service = ISystemContract(payable(_service));
        if (!vm) {
            service.subscribe(
                _originChainId,
                _origin,
                AGGREGATOR_ANSWER_UPDATED_TOPIC,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }

    /**
     * @notice Reacts to the event that meets the subscription criteria
     * @dev This function is called by the ReactVM only
     * @dev Decodes the respective event and encode the payload(function to call and input args) to be sent to the destination chain
     * @dev Emits Callback with necessary destination data. The emitted Callback event will be caught by the reactive network and forwarded to the destination chain with the payload
     * @param log Data structure containing the information about the intercepted log record.
     */
    function react(LogRecord calldata log) external vmOnly {
        emit Event(
            log.chain_id,
            log._contract,
            log.topic_0,
            log.topic_1,
            log.topic_2,
            log.topic_3,
            log.data,
            ++counter
        );
        if (log.topic_0 == AGGREGATOR_ANSWER_UPDATED_TOPIC) {
            // Decode the event data
            (int256 answer, uint256 updatedAt, uint256 roundId) = abi.decode(
                log.data,
                (int256, uint256, uint256)
            );

            // Prepare the payload for the destination chain
            bytes memory payload = abi.encodeWithSignature(
                "updateAnswer(address,address,uint80,int256,uint8,string,uint256,uint256,uint256)",
                address(0), // Eventually be replaced with Reactvm address
                log._contract, // source contract address
                uint80(roundId),
                answer,
                decimals, // price feed decimals
                description, // price feed description
                version, // price feed version
                block.timestamp, // startedAt TBF
                updatedAt
            );

            // Emit the Callback event with destination data
            emit Callback(destinationChainId, destination, GAS_LIMIT, payload);
        }
    }
}
