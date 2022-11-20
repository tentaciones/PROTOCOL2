//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Positions.sol";
import "./NFTManager.sol";

import "./Libraries/errors.sol";
import "./Libraries/SafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "./BorrowLogic.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
//import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./Interfaces/Iunioracle.sol";
import "./Interfaces/Iweth.sol";


//require errors 
//INSUFFICIENT LIQUIDITY =IL
//not enough collateral =NEC
//more than max borrow=MXB
//not enough liquidity=NEL
//not enough collateral to support more borrow=NECB
//NOT OWNER=NO
//amount greater than available collateral=AGC
//Failed to send Ether=FSE
//cant withdraw collateral used to support borrow=CWCB
//no borrow=NB

contract SOL5 is Position, errors, BorrowLogic {
    using SafeMath for uint256;
    using FullMath for uint256;

}