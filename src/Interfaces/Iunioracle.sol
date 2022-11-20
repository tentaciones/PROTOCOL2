pragma solidity ^0.8.7;
interface IUniswapV3Twap{
    function getInverseConvertion (address token0,uint128 colAmount,uint256 time) external view returns (uint);
    function estimateAmountOut ( address token0,uint128 colAmount,uint256 time) external view returns (uint);
}