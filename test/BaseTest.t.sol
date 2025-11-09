// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test, console } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { KipuBank } from "../src/KipuBank.sol";


abstract contract BaseTest is Test {

    KipuBank public sKipu;

    // Uniswap V2 Router (mainnet)
    address constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Sample tokens on mainnet (USDC, WETH)
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // NUEVO: Usamos la dirección estándar de WETH en Mainnet
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IERC20 public usdc = IERC20(USDC_ADDRESS);
    // NUEVO: Renombramos la variable a 'weth'
    IERC20 public weth = IERC20(WETH_ADDRESS);

    IERC20 public dai = IERC20(DAI_ADDRESS);

    // Test actor
    address constant FACUNDO = address(0x77);

    // WETH tiene 18 decimales. 1e17 es 0.1 WETH.
    uint256 constant WETH_INITIAL_AMOUNT = 1e17; // 0.1 WETH (since WETH has 18 decimals)
    uint256 constant USDC_INITIAL_AMOUNT = 10_000_000_000;
    uint256 constant DAI_INITIAL_AMOUNT = 10_000 * 1e18;

    function setUp() public virtual {
        // create fork using env var ETH_RPC_URL
        string memory rpc = vm.envString("ETH_RPC_URL");
        vm.createSelectFork(rpc);

        // deploy contract
        sKipu = new KipuBank( 
            100_000_000_000, 
            5000_000_000, 
            FACUNDO, 
            address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419), 
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), 
            ROUTER);

        // Fond FACUNDO con WETH
        deal(WETH_ADDRESS, FACUNDO, WETH_INITIAL_AMOUNT);
        deal(USDC_ADDRESS, FACUNDO, USDC_INITIAL_AMOUNT);
        deal(DAI_ADDRESS, FACUNDO, DAI_INITIAL_AMOUNT);
        
        // OPCIONAL: También fundamos con ETH nativo, ya que es más natural para el usuario
        vm.deal(FACUNDO, WETH_INITIAL_AMOUNT); 

        console.log("Fork created with RPC:", rpc);
        // NUEVO: Log del balance de WETH
        console.log("FACUNDO WETH balance:", weth.balanceOf(FACUNDO));
    }
    function _pauseAsOwner() internal {
        sKipu.pauseContract();
    }

    function _approveToken(address token) internal {
        sKipu.pauseContract(); // si hace falta pausar antes de aprobar
        sKipu.approveToken(token);
    }
    function _unpauseAsOwner() internal {
        sKipu.unpauseContract();
    }
}