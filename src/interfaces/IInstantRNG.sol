// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IInstantRNG
 * @notice Interface for the Instant Random Number Generator
 * @author DevAngelo (https://x.com/cryptoangelodev)
 */
interface IInstantRNG {
    /**
     * @notice Generates a random number using provided caller data and on-chain entropy
     * @param callerData Arbitrary bytes for additional entropy
     * @return randomNumber A 256-bit random unsigned integer
     */
    function getRandomNumber(bytes calldata callerData) external returns (uint256 randomNumber);

    /**
     * @notice Generates a random number within a specific range
     * @param callerData Arbitrary bytes for additional entropy
     * @param min Minimum value (inclusive)
     * @param max Maximum value (inclusive)
     * @return result A random number in range [min, max]
     */
    function getRandomInRange(
        bytes calldata callerData,
        uint256 min,
        uint256 max
    ) external returns (uint256 result);

    /**
     * @notice Generates multiple random numbers in a single call
     * @param callerData Arbitrary bytes for additional entropy
     * @param count Number of random numbers to generate
     * @return randomNumbers Array of random uint256 numbers
     */
    function getMultipleRandomNumbers(
        bytes calldata callerData,
        uint256 count
    ) external returns (uint256[] memory randomNumbers);

    /**
     * @notice Returns the current nonce
     * @return uint256 Current nonce value
     */
    function getCurrentNonce() external view returns (uint256);
}
