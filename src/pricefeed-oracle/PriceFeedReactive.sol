// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IReactive} from "@reactive-lib/interfaces/IReactive.sol";
import {ISystemContract} from "@reactive-lib/interfaces/ISystemContract.sol";
import {AbstractReactive} from "@reactive-lib/abstract-base/AbstractReactive.sol";

contract PriceFeedReactive is IReactive, AbstractReactive {
    // states for reactive logic
    uint64 private constant GAS_LIMIT = 1000000;

    address immutable destination;
    uint256 immutable destinationChainId;
    uint8 immutable decimals;
    string description;
    uint256 immutable version = 1;

    uint256 private constant AGGREGATOR_ANSWER_UPDATED_TOPIC =
        uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));

    constructor(
        address _service,
        uint256 _originChainId,
        address _origin,
        uint256 _destinationChainId,
        address _destination,
        uint8 _feed_decimals,
        string memory _feed_description,
        uint256 _feed_version
    ) {
        destination = _destination;
        destinationChainId = _destinationChainId;
        decimals = _feed_decimals;
        description = _feed_description;
        version = _feed_version;
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
