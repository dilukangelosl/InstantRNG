# Instant RNG

A high-efficiency, single-transaction random number generator designed for Monad, ApeChain, and other high-performance EVM networks. Instant RNG provides validator-resistant randomness without external oracles, optimized for gaming, NFTs, and medium-stakes applications.

Created by DevAngelo (https://x.com/cryptoangelodev).

## Deployed Addresses

| Network | Chain ID | Address |
|---------|----------|---------|
| **Monad Testnet** | 143 | `0x2F7d61910Cb99764Ae2F751690668d3d3D59449d` |
| **ApeChain** | 33139 | `0x2F7d61910Cb99764Ae2F751690668d3d3D59449d` |

## Features

- Instant: Single-transaction generation. No waiting for callback/fulfillment.
- Gas Efficient: ~33k gas for a single random number, ~50k for a batch of 10.
- Secure: Uses 11 entropy sources + an evolving internal entropy pool.
- Deterministic: Same address across all chains using CREATE2.
- Simple API: Integration takes less than 5 lines of code.
- Reliability: 100% test coverage on core contract logic.

## Status

| Component | Coverage |
|-----------|----------|
| **Core Contract** | 100% (Lines/Functions/Branches) |
| **Monad Testnet** | Deployed |
| **ApeChain** | Deployed & Verified |

## Installation

```bash
forge install dilukangelosl/InstantRNG
```

### Remappings

To use clean imports, add the following to your `remappings.txt`:

```text
InstantRNG/=lib/InstantRNG/src/
```

## Setup

Create a `.env` file based on the example:

```bash
cp .env.example .env
```

Update the `PRIVATE_KEY` and RPC URLs in the `.env` file before deploying.

### Minimal Interface Integration (No Import)

If you don't want to install the library as a dependency, you can simply define the minimal interface at the top of your contract file:

```solidity
interface IInstantRNG {
    function getRandomInRange(bytes calldata callerData, uint256 min, uint256 max) external returns (uint256);
    function getRandomNumber(bytes calldata callerData) external returns (uint256);
    function getMultipleRandomNumbers(bytes calldata callerData, uint256 count) external returns (uint256[] memory);
}

contract MyDiceGame {
    IInstantRNG public constant rng = IInstantRNG(0x2F7d61910Cb99764Ae2F751690668d3d3D59449d);

    function roll() external returns (uint256) {
        return rng.getRandomInRange(abi.encodePacked(msg.sender), 1, 6);
    }
}
```

### 1. Import the Interface (Standard Method)

First, import `IInstantRNG.sol` in your contract.

```solidity
import {IInstantRNG} from "InstantRNG/interfaces/IInstantRNG.sol";
```

### 2. Initialize the Contract

Store the address of the deployed Instant RNG contract.

```solidity
contract MyDiceGame {
    IInstantRNG public immutable rng;

    constructor(address _rngAddress) {
        rng = IInstantRNG(_rngAddress);
    }
}
```

### 3. Generate Random Numbers

#### Simple Dice Roll (Range)

```solidity
function rollDice() external returns (uint256) {
    // Provide additional entropy from your contract state
    bytes memory entropy = abi.encodePacked(msg.sender, block.timestamp, "dice-roll");
    
    // Get a number between 1 and 6 (inclusive)
    uint256 result = rng.getRandomInRange(entropy, 1, 6);
    return result;
}
```

#### NFT Multi-Trait Generation (Batch)

```solidity
function mintNFT() external {
    bytes memory entropy = abi.encodePacked(msg.sender, totalSupply(), blockhash(block.number - 1));
    
    // Generate 5 random numbers at once
    uint256[] memory traits = rng.getMultipleRandomNumbers(entropy, 5);
    
    // Use traits for attributes
}
```

## Best Practices

To maximize the security of the randomness:
1. Rich Caller Data: Always abi.encodePacked dynamic values like msg.sender, block.timestamp, and your own contract's internal state.
2. Never for High Stakes: While highly resistant, this is pseudo-random. For values > $10,000, consider a Commit-Reveal scheme or Chainlink VRF.
3. Single Transaction: Remember that results are instant. This is great for UX but be mindful of validator reordering risks.

## Development

### Build
```shell
$ forge build
```

### Test
```shell
$ forge test -vv
```

### Deploy (CREATE2)
The deployment script is pre-configured to use a deterministic salt.
```shell
$ source .env
$ forge script script/Deploy.s.sol --rpc-url $MONAD_RPC_URL --broadcast --verify
```

## License

MIT - Developed by DevAngelo (https://x.com/cryptoangelodev)
