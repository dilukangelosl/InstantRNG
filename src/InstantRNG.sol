// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IInstantRNG} from "./interfaces/IInstantRNG.sol";

/**
 * @title InstantRNG
 * @notice A high-efficiency, single-transaction random number generator for Monad and other EVM chains.
 * @dev Uses multiple on-chain entropy sources and an evolving entropy pool to generate pseudo-random numbers.
 * @author DevAngelo (https://x.com/cryptoangelodev)
 */
contract InstantRNG is IInstantRNG {
    /// @notice Error thrown when the range for getRandomInRange is invalid
    error InvalidRange(uint256 min, uint256 max);
    /// @notice Error thrown when callerData exceeds the 10KB limit
    error CallerDataTooLarge(uint256 length);
    /// @notice Error thrown when requested count of random numbers is invalid
    error InvalidCount(uint256 count);

    /// @notice Maximum allowed size for callerData to prevent DOS
    uint256 public constant MAX_CALLER_DATA_SIZE = 10 * 1024; // 10KB
    /// @notice Maximum count for multiple random numbers
    uint256 public constant MAX_COUNT = 100;

    /// @notice Current nonce, increments on every call
    uint256 private _nonce;
    /// @notice Evolving entropy pool, updated after every call
    uint256 private _entropy;

    /**
     * @notice Emitted when a batch of random numbers is generated
     * @param caller Person who called the RNG
     * @param startNonce First nonce used in the batch
     * @param randomNumbers The generated random numbers
     */
    event BatchRandomGenerated(address indexed caller, uint256 indexed startNonce, uint256[] randomNumbers);

    /**
     * @notice Emitted when a random number is generated
     * @param caller Person who called the RNG
     * @param nonce Current nonce used for generation
     * @param randomNumber The generated random number
     */
    event RandomGenerated(address indexed caller, uint256 indexed nonce, uint256 randomNumber);

    /**
     * @notice Emitted when callerData is potentially too small for good entropy
     * @param caller Person who called the RNG
     * @param dataLength Length of the callerData provided
     */
    event WeakCallerData(address indexed caller, uint256 dataLength);

    constructor() {
        // Initialize entropy using initial block data
        _entropy = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, block.number, block.chainid, msg.sender))
        );
    }

    /**
     * @inheritdoc IInstantRNG
     */
    function getRandomNumber(bytes calldata callerData) public override returns (uint256 randomNumber) {
        if (callerData.length > MAX_CALLER_DATA_SIZE) {
            revert CallerDataTooLarge(callerData.length);
        }

        if (callerData.length < 32) {
            emit WeakCallerData(msg.sender, callerData.length);
        }

        uint256 currentNonce = _nonce;
        uint256 currentEntropy = _entropy;

        randomNumber = _calculateRandom(callerData, currentNonce, currentEntropy, 0);

        // Update state
        _nonce = currentNonce + 1;
        _entropy = uint256(keccak256(abi.encodePacked(currentEntropy, randomNumber, block.timestamp)));

        emit RandomGenerated(msg.sender, currentNonce, randomNumber);
    }

    /**
     * @inheritdoc IInstantRNG
     */
    function getRandomInRange(bytes calldata callerData, uint256 min, uint256 max)
        external
        override
        returns (uint256 result)
    {
        if (max <= min) {
            revert InvalidRange(min, max);
        }

        uint256 randomNumber = getRandomNumber(callerData);
        result = min + (randomNumber % (max - min + 1));
    }

    /**
     * @inheritdoc IInstantRNG
     */
    function getMultipleRandomNumbers(bytes calldata callerData, uint256 count)
        external
        override
        returns (uint256[] memory randomNumbers)
    {
        if (count == 0 || count > MAX_COUNT) {
            revert InvalidCount(count);
        }

        if (callerData.length > MAX_CALLER_DATA_SIZE) {
            revert CallerDataTooLarge(callerData.length);
        }

        if (callerData.length < 32) {
            emit WeakCallerData(msg.sender, callerData.length);
        }

        randomNumbers = new uint256[](count);
        uint256 currentEntropy = _entropy;
        uint256 currentNonce = _nonce;

        // Pre-hash values that are constant throughout the transaction
        bytes32 sharedContext = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                block.number,
                blockhash(block.number - 1),
                msg.sender,
                tx.origin,
                tx.gasprice,
                callerData,
                address(this).balance
            )
        );

        for (uint256 i = 0; i < count; i++) {
            uint256 nonceToUse = currentNonce + i;

            // Generate random number using pre-hashed context + varying factors
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(sharedContext, nonceToUse, currentEntropy, i)));

            randomNumbers[i] = randomNumber;

            // Update local entropy for the next iteration in the batch
            currentEntropy = uint256(keccak256(abi.encodePacked(currentEntropy, randomNumber, block.timestamp)));
        }

        // Update state variables once after the loop
        _nonce = currentNonce + count;
        _entropy = currentEntropy;

        emit BatchRandomGenerated(msg.sender, currentNonce, randomNumbers);
    }

    /**
     * @inheritdoc IInstantRNG
     */
    function getCurrentNonce() external view override returns (uint256) {
        return _nonce;
    }

    /**
     * @notice Internal function to calculate a random number based on shared entropy
     */
    function _calculateRandom(bytes calldata callerData, uint256 nonceToUse, uint256 entropyPool, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    block.number,
                    blockhash(block.number - 1),
                    msg.sender,
                    tx.origin,
                    tx.gasprice,
                    callerData,
                    nonceToUse,
                    entropyPool,
                    address(this).balance,
                    index
                )
            )
        );
    }
}
