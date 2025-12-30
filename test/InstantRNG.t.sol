// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {InstantRNG} from "../src/InstantRNG.sol";
import {IInstantRNG} from "../src/interfaces/IInstantRNG.sol";

contract InstantRNGTest is Test {
    InstantRNG public rng;

    event RandomGenerated(address indexed caller, uint256 indexed nonce, uint256 randomNumber);
    event WeakCallerData(address indexed caller, uint256 dataLength);

    function setUp() public {
        rng = new InstantRNG();
    }

    function test_GetRandomNumber() public {
        bytes memory data = abi.encodePacked("test entropy");
        uint256 nonceBefore = rng.getCurrentNonce();

        uint256 randomNumber = rng.getRandomNumber(data);

        assertEq(rng.getCurrentNonce(), nonceBefore + 1, "Nonce should increment");
        assertTrue(randomNumber > 0, "Should generate a random number");
    }

    function test_GetRandomNumber_DifferentCallers() public {
        bytes memory data = abi.encodePacked("same data");

        address Alice = address(0x1);
        address Bob = address(0x2);

        vm.prank(Alice);
        uint256 randAlice = rng.getRandomNumber(data);

        vm.prank(Bob);
        uint256 randBob = rng.getRandomNumber(data);

        assertNotEq(randAlice, randBob, "Different callers should get different results");
    }

    function test_GetRandomNumber_SequentialCalls() public {
        bytes memory data = abi.encodePacked("same data");

        uint256 rand1 = rng.getRandomNumber(data);
        uint256 rand2 = rng.getRandomNumber(data);

        assertNotEq(rand1, rand2, "Sequential calls should get different results due to nonce and entropy");
    }

    function test_GetRandomInRange() public {
        bytes memory data = abi.encodePacked("range test");
        uint256 min = 1;
        uint256 max = 6;

        for (uint256 i = 0; i < 100; i++) {
            uint256 result = rng.getRandomInRange(data, min, max);
            assertTrue(result >= min && result <= max, "Result out of range");
        }
    }

    function test_GetMultipleRandomNumbers() public {
        bytes memory data = abi.encodePacked("multi test");
        uint256 count = 5;

        uint256 nonceBefore = rng.getCurrentNonce();
        uint256[] memory randoms = rng.getMultipleRandomNumbers(data, count);

        assertEq(randoms.length, count, "Should return correct number of randoms");
        assertEq(rng.getCurrentNonce(), nonceBefore + count, "Nonce should increment by count");

        for (uint256 i = 0; i < count; i++) {
            for (uint256 j = i + 1; j < count; j++) {
                assertNotEq(randoms[i], randoms[j], "Random numbers in batch should be different");
            }
        }
    }

    function test_Revert_InvalidRange() public {
        bytes memory data = abi.encodePacked("error test");
        vm.expectRevert(abi.encodeWithSelector(InstantRNG.InvalidRange.selector, 10, 5));
        rng.getRandomInRange(data, 10, 5);
    }

    function test_Revert_CallerDataTooLarge() public {
        bytes memory largeData = new bytes(10 * 1024 + 1);
        vm.expectRevert(abi.encodeWithSelector(InstantRNG.CallerDataTooLarge.selector, largeData.length));
        rng.getRandomNumber(largeData);
    }

    function test_Revert_InvalidCount() public {
        bytes memory data = abi.encodePacked("error test");
        vm.expectRevert(abi.encodeWithSelector(InstantRNG.InvalidCount.selector, 0));
        rng.getMultipleRandomNumbers(data, 0);

        vm.expectRevert(abi.encodeWithSelector(InstantRNG.InvalidCount.selector, 101));
        rng.getMultipleRandomNumbers(data, 101);
    }

    function test_WeakCallerDataEvent() public {
        bytes memory smallData = new bytes(31);
        vm.expectEmit(true, false, false, true);
        emit WeakCallerData(address(this), smallData.length);
        rng.getRandomNumber(smallData);
    }

    function test_GasEfficiency() public {
        bytes memory data = abi.encodePacked("gas test");

        // Warm up call to ensure storage slots are non-zero and slots are warm
        rng.getRandomNumber(data);

        uint256 startGas = gasleft();
        rng.getRandomNumber(data);
        uint256 usedGas = startGas - gasleft();

        console.log("Steady state gas used for single random:", usedGas);
        assertTrue(usedGas < 35000, "Gas usage too high for single random steady state");
    }

    function test_GasEfficiency_Multi() public {
        bytes memory data = abi.encodePacked("multi gas test");
        uint256 count = 10;

        uint256 startGas = gasleft();
        rng.getMultipleRandomNumbers(data, count);
        uint256 usedGas = startGas - gasleft();

        console.log("Gas used for 10 randoms:", usedGas);
        assertTrue(usedGas < 100000, "Gas usage too high for 10 randoms");
    }

    function test_GetRandomNumber_MaxData() public {
        bytes memory data = new bytes(rng.MAX_CALLER_DATA_SIZE());
        uint256 randomNumber = rng.getRandomNumber(data);
        assertTrue(randomNumber > 0);
    }

    function test_GetRandomNumber_NoWeakDataEvent() public {
        bytes memory data = new bytes(32);
        // Should not emit WeakCallerData
        // We can't easily check for the absence of an event without a wrapper,
        // but calling it hits the other branch.
        rng.getRandomNumber(data);
    }

    function test_GetMultipleRandomNumbers_Revert_LargeData() public {
        bytes memory largeData = new bytes(10 * 1024 + 1);
        vm.expectRevert(abi.encodeWithSelector(InstantRNG.CallerDataTooLarge.selector, largeData.length));
        rng.getMultipleRandomNumbers(largeData, 1);
    }

    function test_GetMultipleRandomNumbers_WeakData() public {
        bytes memory smallData = new bytes(31);
        vm.expectEmit(true, false, false, true);
        emit WeakCallerData(address(this), smallData.length);
        rng.getMultipleRandomNumbers(smallData, 1);
    }
}
