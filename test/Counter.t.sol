// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/FactoryContract.sol";
import "../src/sol5.sol";
import "../src/OracleUni.sol";
import "./mock/MockERC20.sol";
import "../src/NitroFinaceLiquidityPositions.sol";
import "../src/Interfaces/Iweth.sol";
//import "../src/NFTManager.sol";


import "../src/Interfaces/Isol4.sol"; 
import "../src/Obtenir.sol";
contract CounterTest is Test, Obtenir {
   Factory public factoryContract;
   NFTManager public nftmanager;
   UniswapV3Twap public oracle;
   MockERC20 public mockErc1;
   MockERC20 public mockErc2;
   MockERC20 public mockStable;
   NitroFinaceLiquidityPositions public lp;
    SOL5 public sol5;
    Obtenir public obt;

   
    address deployer = address(1);
    address user = address(2);
    address governor=address(3);

    function setUp() public {
        vm.startPrank(deployer);
        nftmanager=new NFTManager();
        factoryContract=new Factory(governor,address(nftmanager) );
        mockErc1= new MockERC20();
        mockErc2=new MockERC20();
        mockStable= new MockERC20();
        //oracle= new UniswapV3Twap(0x1F98431c8aD98523631AE4a59f267346ea31F984, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 3000 );
        obt=new Obtenir();
        lp=new NitroFinaceLiquidityPositions();
   
        vm.stopPrank();
        vm.startPrank(user);
        mockErc1.mint(user, 1000000000000000000000);
        mockErc2.mint(user, 10000000000000000000000 );
       // mockErc1.approve(address(sol5), 1);
       // mockErc1.approve(address(sol5), 1);
        vm.stopPrank();

    }
/*
        address _priceOrcale,
        address _nft,
        address _token1,
        address _token0,
        uint24 _poolfee
Factory tests
*/

    function test_successCreatePool()public{
         vm.startPrank(user);
       (, bool hh)=factoryContract.deploy(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 3000);
        assertEq(hh,true);
        vm.stopPrank();

    }

    function test_revertCreatePool()public{
        vm.startPrank(user);
       (, bool hh)=factoryContract.deploy(address(mockErc1), address(mockErc2), 3);
        assertEq(hh,true);
         vm.stopPrank();
       

    }

    function test_successAddStableAddress() public{
        vm.startPrank(governor);
        //factoryContract.AddStableAddress(address(mockStable));
        vm.stopPrank();
    }

    function test_revertAddStableAddress() public{
        vm.startPrank(user);
        //factoryContract.AddStableAddress(address(mockStable));
        vm.stopPrank();
    }

    

    /*

uniOracle tests
*/
//tests if the uniOracle was succesfull created, reverts if successfull
   /* function test_revertGetPoolAddress()public{
        vm.startPrank(user);
        assertEq(oracle.pool(), 0x0000000000000000000000000000000000000000);
    }

    function test_revertGetPrice()public {
       (uint l)= oracle.estimateAmountOut(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 1000000000000000000, 10);
       assertEq(l, 0);
    }

    function test_revertGetInverseConvertion()public {
        (uint l)=oracle.getInverseConvertion(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 1000000000000000000, 10);
       assertEq(l, 0);
    }*/

    
 

    function test_revertnewSol5()public {
        
       (SOL5 sol, bool hh)=factoryContract.deploy(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 3000);
        assertEq(hh,true);
        
        assertEq(sol.token0(), address(0));
        assertEq(sol.token1(), address(0));
        
       vm.stopPrank();

    }

    function test_successAddLiquidity()public{
                      vm.startPrank(governor);
        //factoryContract.AddStableAddress(address(mockStable));
        vm.stopPrank();
      vm.startPrank(user);

        (SOL5 sol, bool hh)=factoryContract.deploy(address(mockErc1), address(mockErc2), 3000);
        assertEq(hh,true);
        mockErc1.mint(user, 1000000000000000000000);
        mockErc2.mint(user, 10000000000000000000000 );
        assertEq(mockErc1.balanceOf(user),2000000000000000000000 );
        mockErc1.approve(address(sol), 1000000000);
        mockErc2.approve(address(sol), 1000000000);

        //IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).deposit{value:10 ether}();
        //IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).approve(address(sol), 10 ether);
        
        //assertEq(IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(user), 10 ether);
        sol.addLiquidity( 80,10,6000);
       //assertEq(lp.ownerOf(1), user);
        (uint cf, uint ir, uint lid, uint amount, uint k,  bool init)=sol.getLocus(80,10);
        //(uint cf, uint ir, uint lid, uint amount, uint k,  bool init)=obt.getPoolLocus(Isol4(sol),80,10);
        
        assertEq(cf, 80);
        assertEq(ir, 10);
        assertEq(amount, 6000);
        assertEq(k, 1e10);
        assertEq(init, true);
        assertEq(sol.TotalPositionSize(cf,ir), 6000);
        assertEq(sol.NFTidToAmount(1), 6000);
    }
    function test_successaddCollateral()public{
        (SOL5 sol, bool hh)=factoryContract.deploy(address(mockErc1), address(mockErc2), 3000);
        assertEq(hh,true);
        assertEq(sol.token0(), address(0));
        assertEq(sol.token1(), address(0));
        mockErc2.approve(address(sol), 1000000000);
        mockErc1.approve(address(sol), 1000000000);
        mockErc1.mint(user, 1000000000000000000000);
         assertEq(mockErc2.allowances(user, address(sol)), 0);
        assertEq(mockErc1.allowances(user, address(sol)), 0);
        
        //sol.addCollateral(1000);
        //assertEq(sol.collateralAmount(user), 1);
    }

    function test_successSwapExactInputSingle()public{
        //IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).deposit{value:10 ether}();
        //IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(1 ether);
        //assertEq(IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(user), 10 ether);
        //sol5.swapExactInputSingle(1 ether, 10);
    }

    function test_createPosition() public{
       
        nftmanager.createPosition(user, 80, 10, 800, 10,1, "eth/usdc");
    }

    function test_obtenirSuccess()public{
                          vm.startPrank(governor);
       // factoryContract.AddStableAddress(address(mockStable));
       // factoryContract.AddStableAddress(address(mockErc1));
       // factoryContract.AddStableAddress(address(mockErc2));
        vm.stopPrank();
      vm.startPrank(user);

        (SOL5 sol, bool hh)=factoryContract.deploy(address(mockErc1), address(mockErc2), 3000);
        assertEq(hh,true);
        mockErc1.mint(user, 1000000000000000000000);
        mockErc2.mint(user, 10000000000000000000000 );
        assertEq(mockErc1.balanceOf(user),2000000000000000000000 );
        mockErc1.approve(address(sol), 1000000000);
        mockErc2.approve(address(sol), 1000000000);

        sol.addLiquidity( 80,10,6000);
       //assertEq(lp.ownerOf(1), user);
        (uint cf, uint ir, uint lid, uint amount, uint k,  bool init)=sol.getLocus(80,10);

        obt.getPoolLocus(address (sol),80,10);

    }




}
