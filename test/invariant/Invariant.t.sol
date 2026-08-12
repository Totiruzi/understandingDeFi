// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { ./Handler.t.sol};

contract Invariant is StdInvariant, Test {
    // these pools have 2 assets (tokens)
    ERC20Mock poolToken;
    ERC20Mock weth;

    // The pool needs the contracts
    PoolFactory factory;
    TSwapPool pool;

    Handler handler;

    int256 constant STARTING_X = 100e18; // starting ERC20 / poolToken
    int256 constant STARTING_Y = 54e18; // starting WETH

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();

        // Create the pool contract
        factory = new PoolFactory(address(weth));

        // create the pool it's self.
        pool = TSwapPool(factory.createPool(address(weth)));

        // establish the existing ration for swap
        poolToken._mint(address(this), (uint256(STARTING_X)));
        weth._mint(address(this), (uint256(STARTING_Y)));

        // we need to give the pool the approval to manage our asserts
        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // Deposit into the pool, give the X & Y balance
        pool.deposit(uint256(STARTING_Y), uint256(STARTING_Y), uint256(STARTING_X), uint64(block.timestamp));

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selector[0] = handler.deposit.selector;
        selector[0] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysTheSame() public {
        // assert() // ??????
        // The change in the size of the pool size ratio weth should follow this function:
        // ∆x = (β/(1-β)) * x
        // In a handler
        // actual delta
        // actual delta X ==  ∆x = (β/(1-β)) * x
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }
}
