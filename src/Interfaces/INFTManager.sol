interface INFTManager {
        function createPosition(
        address recepient,
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _liquidity,
        uint256 kValueAtDeltaK,
        uint256 _locusId,
        string memory pairOf
    ) external returns (uint tokenId);
    


    function getPoolandUpdateLiquidity(
        uint256 _tokenId,
        uint256 _amount,
        uint256 colFactor,
        uint256 interestRate,
        uint256 updateOption
    ) external ;


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);


    function withdraw(uint256 Id) external returns (uint256 _amount);



    function burn(uint256 Id) external;
}