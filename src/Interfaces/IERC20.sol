// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC2 {
   
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

      function transfer(address to, uint256 amount) external returns (bool);

   
}
