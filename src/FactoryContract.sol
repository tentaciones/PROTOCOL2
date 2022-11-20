pragma solidity 0.8.7;

import "./OracleUni.sol";
import "./sol5.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
//require errors explanation
//NOT ALLOWED STABLE=NAS
//Factory: Only Governor=FAG
//Already Initialized=AI
contract Factory {
    address immutable governor;
    address[] internal AllowedStablePair = [
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    ];
    address immutable facoryAddress =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address immutable NFTManagerAddress;

    constructor(address _governor, address _NFTManagerAddress) {
        governor = _governor;
        NFTManagerAddress = _NFTManagerAddress;
    }
    struct MARKETDATA{
        string token0;
        string token1;
        address market;
        
    }
    MARKETDATA []public allMarkets;
    mapping(address => mapping(address => bool)) private initialized;
    mapping(address => mapping(address => address)) public getPool;
    mapping(address => mapping(address => address)) public getPoolOracle;
    
    


    modifier onlyOwner() {
        require(msg.sender == governor, "FAG");
        _;
    }

    function createOracle(
        address token0,
        address token1,
        uint24 fee
    ) internal returns (address FactoryAddress) {
        for (uint i = 0; i < AllowedStablePair.length; i++) {
            if (token1 == AllowedStablePair[i]) {
                FactoryAddress = address(
                    new UniswapV3Twap(facoryAddress, token0, token1, fee)
                );
            }
        }
        //require(FactoryAddress != address(0), "NAS");
        getPoolOracle[token0][token1] = FactoryAddress;
        getPoolOracle[token1][token0] = FactoryAddress;
    }

    function deploy(
        address token0,
        address token1,
        uint24 fee
    ) external returns (SOL5 pool, bool deployed) {
        require(initialized[token0][token1] == false, "AI");
        pool = (
            new SOL5(
                createOracle(token0, token1, fee),
                NFTManagerAddress,
                token1,
                token0,
                fee
            )
        );
        initialized[token0][token1] = true;
        initialized[token1][token0] = true;
        getPool[token0][token1] = address(pool);
        getPool[token1][token0] = address(pool);
        allMarkets.push(MARKETDATA({token0:IERC20Metadata(token0).symbol(), token1:IERC20Metadata(token1).symbol(), market:address(pool)}));
        deployed= true;
        
    }

    /*function AddStableAddress(address StableAddress) external onlyOwner{
        AllowedStablePair.push(StableAddress);
        
    }

    function getAllMarket()public view returns(MARKETDATA [] memory){
      return  allMarkets;
    }*/
}