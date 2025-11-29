# Cross-Chain Price Feed Oracle

## Overview

Automatically mirror official Chainlink Price Feeds from an origin chain to a destination chain using Reactive Network's event-driven architecture. The destination chain exposes a read interface compatible with `AggregatorV3Interface`, enabling DeFi applications to consume price data where native Chainlink feeds are unavailable.

### How It Works

1. **Origin Chain**: Listen to Chainlink aggregator events (AnswerUpdated) to capture round data (roundId, answer, updatedAt, etc.)
2. **Reactive Contract**: Subscribe to events and encode cross-chain messages with feed data
3. **Destination Chain**: Store price data in a minimal FeedProxy contract that exposes the standard AggregatorV3Interface for downstream applications

## Contracts

Core contracts can be found in the `src/pricefeed-oracle` directory:

1. **PriceFeedProxy (Destination)**: `PriceFeedProxy.sol` - Stores price feed data (roundId, answer, startedAt, updatedAt, answeredInRound, decimals, description) and exposes `AggregatorV3Interface` functions for downstream applications to read price data to consume price data where native Chainlink feeds are unavailable.

2. **PriceFeedReactive (Reactive Network)**: `PriceFeedReactive.sol` - Listens for `AnswerUpdated` event from the Chainlink aggregator on the origin chain, decodes price updates, and sends cross-chain messages to the destination FeedProxy to update price data.

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/en/download/)

- [Foundry](https://book.getfoundry.sh/)

To set up foundry environment, run:

```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

- Etherem wallet with Some funds on origin and destination chains

To deploy contracts, follow these steps, making sure you substitute the appropriate keys, addresses, and endpoints where necessary. You will need the following environment variables configured appropriately to follow this script:

```.env
DESTINATION_RPC=
REACTIVE_RPC=
PRIVATE_KEY=
ORIGIN_CHAINID=
ORIGIN_ADDR=
DESTINATION_CHAINID=
DESTINATION_ADDR=
SYSTEM_CONTRACT_ADDR=
DESTINATION_CALLBACK_SENDER_ADDR=
FEED_DECIMALS=
FEED_DESCRIPTION=
FEED_VERSION=
```

You can use the recommended Sepolia RPC URL: `https://rpc2.sepolia.org`.

Load the environment variables:

```bash
source .env
```

### Compile & Deploy Contracts

This project is scaffolded using Foundry, a smart contract development toolchain. Please refer to the [Foundry documentation](https://book.getfoundry.sh/) for more details.

Directory Structure:

```bash
├── README.md
├── lib # forge, reactive libs
├── src
│    ├── pricefeed-oracle #
│         ├── PriceFeedProxy.sol # AggregatorV3 Compatible Price Feed proxy contract for downstream dapps
│         ├── PriceFeedReactive.sol # Price Feed reactive contract
```

Install dependencies and compile the contracts:

```bash
forge install

forge compile
```

Deploy the `PriceFeedProxy` contract with authorized callback sender on destination(i.e Avalanche) and assign the `Deployed to` address from the response to `DESTINATION_ADDR`.

```bash
forge create src/pricefeed-oracle/PriceFeedProxy.sol:PriceFeedProxy --rpc-url $DESTINATION_RPC --private-key $PRIVATE_KEY --constructor-args $DESTINATION_CALLBACK_SENDER_ADDR $FEED_DECIMALS $FEED_DESCRIPTION
```

### Callback Payment

To ensure a successful callback, `PriceFeedProxy` contract must have an ETH balance. You can find more details [here](https://dev.reactive.network/economy#callback-payments). To fund the callback contracts, run the following command:

```bash
cast send $DESTINATION_ADDR --rpc-url $DESTINATION_RPC --private-key $PRIVATE_KEY --value 0.5ether
```

### Deploy Reactive Contract

Deploy the `PriceFeedReactive.sol` (reactive contract), configuring it to listen to `AnswerUpdated` event on origin contract, Triggering callback on `PriceFeedProxy.sol` contract to updat price feed data accordingly.

```bash
forge create --rpc-url $REACTIVE_RPC --private-key $PRIVATE_KEY src/pricefeed-oracle/PriceFeedReactive.sol:PriceFeedReactive --constructor-args $SYSTEM_CONTRACT_ADDR $ORIGIN_CHAINID $ORIGIN_ADDR $DESTINATION_CHAINID $DESTINATION_ADDR $FEED_DECIMALS $FEED_DESCRIPTION $FEED_VERSION
```

### Test the Setup

### Deployed Contracts

- **PriceFeedProxy(Destination) contract:** [0x95358311803B5A7E159A42D7cAA80da770Fa8238](https://sepolia.etherscan.io/address/0x95358311803B5A7E159A42D7cAA80da770Fa8238)
- **PriceFeedReactive contract:** [0xd231fE46b4A8500d4aDD5AD98EC3c4ca56E7dee4](https://lasna.reactscan.net/address/0xc7203561ef179333005a9b81215092413ab86ae9/contract/0xd231fe46b4a8500d4add5ad98ec3c4ca56e7dee4)
- **RVM:** [0xc7203561EF179333005a9b81215092413aB86aE9](https://lasna.reactscan.net/address/0xc7203561ef179333005a9b81215092413ab86ae9)

### Running the Demo

### Demo

#### Workflow Example

## Built With

- [Reactive Network](https://reactive.network) - Facilitates seamless cross-chain and multi-chain interactions, breaking down barriers for true blockchain interoperability.
- [Reactive Library](https://dev.reactive.network/reactive-library#overview) - Set of abstract contracts and interfaces that reduce boilerplate by integrating common functionalities
- [Foundry](https://book.getfoundry.sh/) - A smart contract development toolchain. It provides a set of tools to help you build, test, and deploy smart contracts.
- [Solidity](https://docs.soliditylang.org/en/v0.8.24/) - Ethereum's smart contract programming language

## Safety & Security

This is experimental software and subject to change over time.

This is a proof of concept and is not ready for production use. It is not audited and has not been tested for security. Use at your own risk. I do not give any warranties and will not be liable for any loss incurred through any use of this codebase.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
