// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseTest } from "./BaseTest.t.sol";
import { console } from "forge-std/console.sol";

contract KipuBankTest is BaseTest {

  function test_receive() public {
    uint256 amount = 1 gwei;
    console.log("Amount to send on receive function", amount);
    vm.startPrank(FACUNDO);
    vm.expectRevert();
    (bool success, ) = address(sKipu).call{value: amount}("");
    console.log("Estado de haber hecho la transaccion", success);
    vm.stopPrank();
  }

  function test_fallback() public {
    uint256 amount = 1 gwei;
    console.log("Amount to send on receive function", amount);
    bytes memory junk = hex"deadbeef";
    vm.startPrank(FACUNDO);
    vm.expectRevert();
    (bool success, ) = address(sKipu).call{ value: 0.3 ether }(junk);
    console.log("Estado de haber hecho la transaccion", success);
    vm.stopPrank();
  }

  function test_deposit_eth() public {
    uint256 balanceBefore = address(sKipu).balance;
    console.log("Initial Balance", balanceBefore);

    vm.startPrank(FACUNDO);
    sKipu.depositETH{value: 1 gwei}();

    uint256 balanceAfter = address(sKipu).balance;
    console.log("After Balance", balanceAfter);
    vm.stopPrank();
    assertGt(balanceAfter, balanceBefore);
  }

  function test_deposit_usdc() public {
    uint256 balanceBefore = usdc.balanceOf(address(sKipu));
    console.log("Initial USDC balance", balanceBefore);

    vm.startPrank(FACUNDO);
    usdc.approve(address(sKipu), 10_000 * 1e6);
    sKipu.depositUSDC(1_000 * 1e6);

    uint256 balanceAfter = usdc.balanceOf(address(sKipu));
    console.log("After USDC balance", balanceAfter);
    vm.stopPrank();
    assertGt(balanceAfter, balanceBefore);
  }

  function test_pause_contract() public {
    vm.startPrank(FACUNDO);
    sKipu.pauseContract();
    (bool isPaused,,,,) = sKipu.viewContractState();
    vm.stopPrank();
    assertTrue(isPaused);
  }

  function test_approve_token() public {
    bool statusBefore = sKipu.isTokenAllowed(address(dai));
    console.log("Status of token", statusBefore, address(dai));

    vm.startPrank(FACUNDO);
    _pauseAsOwner();
    sKipu.approveToken(address(dai));
    bool statusAfter = sKipu.isTokenAllowed(address(dai));

    vm.stopPrank();
    assertFalse(statusBefore);
    assertTrue(statusAfter);
  }

  function test_deposit_token() public {
    uint256 balanceBefore = usdc.balanceOf(address(sKipu));
    console.log("Initial USDC balance", balanceBefore);

    uint256 deadline = block.timestamp + 30 seconds;
    vm.startPrank(FACUNDO);
    _approveToken(address(dai));
    _unpauseAsOwner();
    dai.approve(address(sKipu), 10_000 * 1e18);    
    sKipu.depositToken(100 * 1e18, 98 * 1e6, DAI_ADDRESS, deadline);

    uint256 balanceAfter = usdc.balanceOf(address(sKipu));
    console.log("After USDC balance", balanceAfter);
    vm.stopPrank();
    assertGt(balanceAfter, balanceBefore);
  }
  
  function test_withdraw_usdc() public {
    vm.startPrank(FACUNDO);
    usdc.approve(address(sKipu), 10_000 * 1e6);
    sKipu.depositUSDC(1_000 * 1e6);
    
    uint256 balanceBefore = usdc.balanceOf(FACUNDO);
    console.log("Before ETH balance", balanceBefore);
    sKipu.withdrawUSDC(900 * 1e6);

    uint256 balanceAfter = usdc.balanceOf(FACUNDO);
    console.log("Before ETH balance", balanceAfter);
    vm.stopPrank();
    assertGt(balanceAfter, balanceBefore);    
  }

  function test_withdraw_eth() public {
    vm.startPrank(FACUNDO);
    sKipu.depositETH{value : 10000 gwei}();
    
    uint256 balanceBefore = usdc.balanceOf(FACUNDO);
    console.log("Before ETH balance", balanceBefore);
    uint256 amount = 1000 gwei;
    sKipu.withdrawETH(amount);

    uint256 balanceAfter = sKipu.balanceOf(FACUNDO, address(0));
    vm.stopPrank();
    assertGt(balanceAfter, balanceBefore);    
  }

  function test_remove_token() public {
    vm.startPrank(FACUNDO);
    _approveToken(address(dai));
    bool statusBefore = sKipu.isTokenAllowed(address(dai));
    sKipu.removeToken(address(dai));
    bool statusAfter = sKipu.isTokenAllowed(address(dai));
    vm.stopPrank();
    assertTrue(statusBefore);
    assertFalse(statusAfter);
  }

  function test_transfer_owner() public {
    vm.startPrank(FACUNDO);
    address owner = sKipu.owner();
    console.log("Previous owner", owner);
    _pauseAsOwner();
    
    sKipu.transferOwnership(OTRO_USER);
    address newOwner = sKipu.owner();
    vm.stopPrank();    
    assertEq(owner, address(FACUNDO));
    assertEq(newOwner, address(OTRO_USER));
  }
} 