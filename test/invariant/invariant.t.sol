// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";

contract Invariant is StdInvariant, Test {
    // these pools have 2 assets (tokens)
    ERC20Mock poolToken;
    ERC20Mock weth;


    // The pool needs the contracts
    PoolFactory factory;
    TSwapPool pool;


    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();

        // Create the pool contract
        factory = new PoolFactory(address(weth));

        // create the pool it's self. 
        pool = TSwapPool(factory.createPool(address(weth)));

        // establish the existing ration for swap


    }
} 