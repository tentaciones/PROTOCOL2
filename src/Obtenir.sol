pragma solidity 0.8.7;
import "./Interfaces/Isol4.sol"; 
contract Obtenir {
 


    function getPoolLocus(address sol4,uint colFactor, uint intRate) public view returns( Isol4.LOCUS memory data){
     
       data=  Isol4(sol4).getLocus(colFactor, intRate);
    }

    function getAllExistingLocus(address sol4)public view returns(Isol4.LOCUS []memory data){
        data= Isol4(sol4).allExistingLocus();
    }

    function getAvaliableLiquidity(
        address sol4,
        uint256 _collateralFactor,
        uint256 _interestRate
    ) public view returns (uint256 avaliableLiquidity) {
        Isol4.LOCUS memory data = Isol4(sol4).getLocus(_collateralFactor,_interestRate);
        avaliableLiquidity = data.liquidity;
        return avaliableLiquidity;
    }


    function getUserLiquidationPoint(address sol4, address _user)
        public
        view
        returns (uint256 liquidationPoint)
    {
        liquidationPoint = (Isol4(sol4).collateralValue(_user)* Isol4(sol4).liquidationThreshold()/100 );
    }

    function getAllUserBorrowedTransaction(address sol4)
        public
        view
        returns (Isol4.BORROWTRANSACTIONS[] memory)
    {
        return Isol4(sol4).addressToBorrowTransaction(msg.sender);
    }

    function getPresumedPositionSize(
        address sol4,
        uint256 _amount,
        uint256 _collateralFactor,
        uint256 _interestRate
    ) public view returns (uint256 positionSize) {
        Isol4.LOCUS memory data = Isol4(sol4).getLocus(_collateralFactor,_interestRate);
        if (data.k == 0) {
            uint256 invariantValue = 1e10;
            positionSize = (_amount * 1e10) / invariantValue;
        } else {
            uint256 invariantValue = data.k;
            positionSize = (_amount * 1e10) / invariantValue;
        }
    }

    function getValueofInvariant(
        address sol4,
        uint256 _collateralFactor,
        uint256 _interestRate
    ) public view returns (uint256 invariantValue) {
        Isol4.LOCUS memory data = Isol4(sol4).getLocus(_collateralFactor,_interestRate);
        if (data.k == 0) {
            invariantValue = 1e10;
        } else {
            invariantValue = data.k;
        }
    }


    function getAllMarket (address _factoryContract)public view returns(Isol4.MARKETDATA [] memory data){
       /* for (uint i; i>Isol4(_factoryContract).allMarkets().length;){
           ;
            unchecked { i++; }
        }
        */


        data= Isol4(_factoryContract).allMarkets(0);
    }







    


}