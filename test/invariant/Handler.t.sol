// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, consol2 } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;
    address liquidityProvider = makeAddr("lp");
    address swapper = makeAddr("swapper");

    // Ghost variables
    int256 startingX;
    int256 startingY;

    int256 public expectedDeltaX; // change in token balances
    int256 public expectedDeltaY;

    int256 public actualDeltaX; // change in token balances
    int256 public actualDeltaY;

    // int256 endingX;
    // int256 endingY;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(pool.getWeth());
        poolToken = ERC20Mock(pool.getPoolToken());
    }

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 outputWeth) public {
        outputWeth = bound(outputWeth, 0, type(uint64).max);

        if (outputWeth >= weth.balanceOf(poll)) {
            return;
        }

        // This what we want as the result weth ratio
        // ∆x = (β/(1-β)) * x
        // x * y = k where k = ∆x
        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth, 
            poolToken.balanceOf(address(pool)), 
            weth.balanceOf(address(pool))
        );

        if (poolTokenAmount > type(uint64).max) {
            return;
        }

        // wethAmount = bound(wethAmount, 0, type(uint64).max);
        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(poolToken.balanceOf(address(this)));
        expectedDeltaY = int256(-1) * int256(outputWeth); // When loosing weth, expected delta Y will be negative
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(poolTokenAmount));

        if (poolToken.balanceOf(swapper) < poolTokenAmount) {
            poolToken.mint(swapper, poolTokenAmount - poolToken.balanceOf(swapper) + 1);
        }

        // doing the actual swap
        vm.startPrank(swapper);
            poolToken.approve(address(pool), type(uint256).max); // ???? is this not suppose to be type(int64).max?
            pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingX = poolToken.balanceOf(address(this));
        uint256 endingY = weth.balanceOf(address(this));

        // the expected result of swapping weth for poolToken
        // ∆y = (α/(1+α)) * y
        actualDeltaX = int256(endingX) - int256(startingX);
        actualDeltaY = int256(endingY) - int256(startingY);
    }

    // writing a minimal test for
    // deposit, swapExactOutput
    function deposit(uint256 wethAmount) public {
        // It should be a reasonable amount, also try to avoid overflow error by using uint64 max
        // (18.446744073709551615) as a bound
        wethAmount = bound(wethAmount, 0, type(uint64).max);
        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(poolToken.balanceOf(address(this)));
        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        // deposit the token
        vm.prank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(liquidityProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);
        pool.deposit(wethAmount, 0, uint256(expectedDeltaX), uint64(block.timestamp));
        vm.stopPrank();

        // check if the deposited is the same as expected ration
        // the actual amounts of lp and weth in the pool
        uint2566 endingX = poolToken.balanceOf(address(this));
        uint2566 endingY = weth.balanceOf(address(this));

        // the expected result of swapping weth for poolToken
        // ∆y = (α/(1+α)) * y
        actualDeltaX = int256(endingX) - int256(startingX);
        actualDeltaY = int256(endingY) - int256(startingY);
    }
}
