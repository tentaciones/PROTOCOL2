pragma solidity 0.8.7;
interface Isol4 {
        struct LOCUS{
        uint256 collateralFactor;
        uint256 interestRate;
        uint256 locusId;
        uint256 liquidity;
        uint256 k;
        bool initialized;
    }

    struct BORROWTRANSACTIONS{
        uint256 interestRateBorrowedAt;
        uint256 collateralFactorBorrowedAt;
        uint256 totalBorrowed;
        address borrower;
        uint locusId;
        uint64 lastAccuredTimeStamp;
        
       
    }

    struct MARKETDATA{
        string token0;
        string token1;
        address market;
        
    }

    struct MYIMAGES {
        string _img;
    }

    function getLocus(uint colFactor, uint intRate) external view returns(LOCUS memory);
    function allExistingLocus()external view returns (LOCUS [] memory);
    function collateralValue(address _user)external view returns (uint);
    function liquidationThreshold()external view returns (uint);
    function addressToBorrowTransaction(address _user)external view returns (BORROWTRANSACTIONS[] memory);
    function allMarkets(uint index)external view returns (MARKETDATA [] memory);
    function allmyPositionsImages()external view returns (MYIMAGES [] memory);
    
    
    
    
    
}