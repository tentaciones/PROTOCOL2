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

    ISwapRouter private constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Twap private immutable priceOracle;
    NFTManager immutable NFT;
    address public immutable token0;
    address public immutable token1;
 
    IWETH immutable _Weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint24 poolFee;


    uint256 locusTracker = 1;
    uint256 liquidationThreshold;
    uint256 LiquidationFee;
    uint256 totalBorrow;
    uint256 totalAvailableLiquidity;

    uint256 private constant DELTA_K_PRECISION = 1e10;
    uint256 private constant K_MANTISSA = 1e6;
    uint256 private constant SECONDS_PER_YEAR = 31536000;

    struct TOKENID {
        uint256 _tokenId;
    }

    mapping(address => uint256) public collateralAmount;
    mapping(address => uint256) public collateralValue;
    mapping(address => uint256) public borrowedValue;
    mapping(address => uint256) private tmcr;
    mapping(address => uint256) private air;
    mapping(address => uint64) private borrowerTimer;
    mapping(uint256 => uint256) public NFTidToAmount;
    mapping(uint256 => TOKENID[]) public locusToNftId;
    mapping(uint256 => mapping(uint256 => uint64))
        private LastDebtAccuredTimeLocus;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public userNftPerLocus;

    mapping(uint256 => mapping(uint256 => BORROWTRANSACTIONS[]))
        public LocusBorrowData;
    mapping(uint256 => mapping(uint256 => uint256)) public TotalPositionSize;
    mapping(uint256 => mapping(uint256 => uint256))
        public AmountBorrowedFromLocus;
    mapping(uint256 => mapping(uint256 => uint256))
        private AmountBorrowedFromLocuswithInterest;


    constructor(
        address _priceOrcale,
        address _nft,
        address _token0,
        address _token1,
        uint24 _poolfee
    ) {
        NFT = NFTManager(_nft);
        token0 = _token0;
        token1 = _token1;

        priceOracle = IUniswapV3Twap(_priceOrcale);
        poolFee = _poolfee;
        liquidationThreshold = 90;
        LiquidationFee = 10;
    }

    function addLiquidity(
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _value
    ) external {
        LOCUS memory data = getLocus[_collateralFactor][_interestRate];
        if (
            data.collateralFactor != _collateralFactor &&
            data.interestRate != _interestRate
        ) {
            _create(_collateralFactor, _interestRate, _value);
        } else {
            _update(_collateralFactor, _interestRate, _value);
        }
    }
function _create(
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _value
    ) internal {
        if (_collateralFactor > 0 && _interestRate > 0 && _value > 0) {
            uint256 kInitialValue = DELTA_K_PRECISION;
            put(_collateralFactor, _interestRate, locusTracker, _value);

            /*TransferHelper.safeTransferFrom(
                token1,
                msg.sender,
                address(this),
                _value
            );*/
            IERC20(token1).transferFrom(msg.sender, address(this), _value);
      
            uint nextId = NFT.createPosition(
                msg.sender,
                _collateralFactor,
                _interestRate,
                _value,
                kInitialValue,
                locusTracker,
                string(
                    abi.encodePacked(
                        (IERC20Metadata(token0).symbol),
                        "/",
                        (IERC20Metadata(token1).symbol)
                    )
                )
            );

            NFTidToAmount[nextId] = _value;
            TOKENID[] storage data = locusToNftId[locusTracker];
            data.push(TOKENID({_tokenId: nextId}));
            userNftPerLocus[msg.sender][_collateralFactor][
                _interestRate
            ] = nextId;
            TotalPositionSize[_collateralFactor][_interestRate] += _value;
            totalAvailableLiquidity+=_value;
            locusTracker++;
        } else {
            revert INPUT_DATA_SHOULD_BE_GREATER_THAN_ZERO();
        }
    }

    
    function _update(
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _value
    ) internal {
        if (_collateralFactor > 0 && _interestRate > 0 && _value > 0) {
            LOCUS storage data = getLocus[_collateralFactor][_interestRate];
            /*TransferHelper.safeTransferFrom(
                token1,
                msg.sender,
                address(this),
                _value
            );*/
            IERC20(token1).transferFrom(msg.sender, address(this), _value);
    
if (
                AmountBorrowedFromLocus[_collateralFactor][_interestRate] == 0
            ) {
                uint nextId = NFT.createPosition(
                    msg.sender,
                    _collateralFactor,
                    _interestRate,
                    _value,
                    1 * DELTA_K_PRECISION,
                    data.locusId,
                    string(
                        abi.encodePacked(
                            (IERC20Metadata(token0).symbol),
                            "/",
                            (IERC20Metadata(token1).symbol)
                        )
                    )
                );
                NFTidToAmount[nextId] = _value;
                TOKENID[] storage tokenId = locusToNftId[locusTracker];
                tokenId.push(TOKENID({_tokenId: nextId}));
                data.liquidity += _value;
                totalAvailableLiquidity+=_value;
                TotalPositionSize[_collateralFactor][_interestRate] += _value;
            } else {
                accuredK(_collateralFactor, _interestRate);
                uint256 amount = SafeMath.div(_value * 1e10, data.k);
                uint nextId = NFT.createPosition(
                    msg.sender,
                    _collateralFactor,
                    _interestRate,
                    amount,
                    data.k,
                    data.locusId,
                    string(
                        abi.encodePacked(
                            (IERC20Metadata(token0).symbol),
                            "/",
                            (IERC20Metadata(token1).symbol)
                        )
                    )
                );
                NFTidToAmount[nextId] += amount;
                data.liquidity += _value;
                totalAvailableLiquidity+=_value;
                TOKENID[] storage tokenId = locusToNftId[locusTracker];
                TotalPositionSize[_collateralFactor][_interestRate] += amount;
                tokenId.push(TOKENID({_tokenId: nextId}));
            }
        } else {
            revert INPUT_DATA_SHOULD_BE_GREATER_THAN_ZERO();
        }
    }

    function updatePosition(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _colFactor,
        uint256 _interestRate,
        uint256 _updateOption
    ) external {
        accuredK(_colFactor, _interestRate);
        LOCUS storage data = getLocus[_colFactor][_interestRate];
        if (data.initialized != true) revert NON_EXITING_POSITION();
        uint256 amount = SafeMath.div(_amount * 1e10, data.k);
        if (_updateOption == 1) {
            /*TransferHelper.safeTransferFrom(
                token1,
                msg.sender,
                address(this),
                _amount
            );*/
            IERC20(token1).transferFrom(msg.sender, address(this), _amount);

            NFT.getPoolandUpdateLiquidity(
                _tokenId,
                amount,
                _colFactor,
                _interestRate,
                _updateOption
            );
            TotalPositionSize[_colFactor][_interestRate] += amount;
            NFTidToAmount[_tokenId] += _amount;
            data.liquidity += _amount;
            totalAvailableLiquidity+=amount;
        } else if (_amount == NFTidToAmount[_tokenId]) {
            withdrawLiquidity(_tokenId, _colFactor, _interestRate);
        } else {
            require(
                NFTidToAmount[_tokenId] >= _amount,
                "IL"
            );
            NFT.getPoolandUpdateLiquidity(
                _tokenId,
                amount,
                _colFactor,
                _interestRate,
                _updateOption
            );
            NFTidToAmount[_tokenId] -= _amount;
            data.liquidity -= _amount;
            totalAvailableLiquidity-=amount;
            TotalPositionSize[_colFactor][_interestRate] -= amount;
            //TransferHelper.safeTransfer(token1, msg.sender, _amount);
            IERC20(token1).transfer(msg.sender, _amount);
        }
    }

    //locusid

function borrow(
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _value
    ) external {
        if (borrowedValue[msg.sender] == 0) {
            _initBorrow(_collateralFactor, _interestRate, _value);
        } else {
            _subBorrows(_collateralFactor, _interestRate, _value);
        }
    }

    function _initBorrow(
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _value
    ) internal {
        cook();
        //accuredinterest correct
        LOCUS storage data = getLocus[_collateralFactor][_interestRate];
        if (data.initialized != true) revert NON_EXITING_POSITION();
        if (
            data.collateralFactor != _collateralFactor &&
            data.interestRate != _interestRate
        ) {
            revert LOCUS_NOT_IN_EXISTENCE();
        } else {
            require(
                collateralValue[msg.sender] > _value,
                "NEC"
            );
            require(
                FullMath.mulDivRoundingUp(
                    collateralValue[msg.sender],
                    _collateralFactor,
                    100
                ) > _value,
                "MXB"
            );
            require(_value <= data.liquidity, "NEC");
            borrowedValue[msg.sender] += (_value * 1e27);
            tmcr[msg.sender] = _collateralFactor;
            AmountBorrowedFromLocus[_collateralFactor][_interestRate] += _value;
            AmountBorrowedFromLocuswithInterest[_collateralFactor][
                _interestRate
            ] += (_value * 1e27);

            //TransferHelper.safeTransfer(token1, msg.sender, _value);
            IERC20(token1).transfer(msg.sender, _value);
            data.liquidity -= _value;
            totalAvailableLiquidity-=_value;
            air[msg.sender] = _interestRate;
            BORROWTRANSACTIONS[]
                storage borrowData = addressToBorrowTransaction[msg.sender];
            borrowData.push(
                BORROWTRANSACTIONS({
                    interestRateBorrowedAt: _interestRate,
                    collateralFactorBorrowedAt: _collateralFactor,
                    totalBorrowed: _value,
                    borrower: msg.sender,
                    locusId: data.locusId,
                    lastAccuredTimeStamp: uint64(block.timestamp)
                })
            );

            BORROWTRANSACTIONS[] storage Locusdata = LocusBorrowData[
                _collateralFactor
            ][_interestRate];
            Locusdata.push(
                BORROWTRANSACTIONS({
                    interestRateBorrowedAt: _interestRate,
                    collateralFactorBorrowedAt: _collateralFactor,
                    totalBorrowed: _value,
                    borrower: msg.sender,
                    locusId: data.locusId,
                    lastAccuredTimeStamp: uint64(block.timestamp)
                })
            );
        }
    }
function _subBorrows(
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _value
    ) internal {
        cook();
        //accuredinterestrate correction
        LOCUS storage data = getLocus[_collateralFactor][_interestRate];
        if (data.initialized != true) revert NON_EXITING_POSITION();
        if (
            data.collateralFactor != _collateralFactor &&
            data.interestRate != _interestRate
        ) {
            revert LOCUS_NOT_IN_EXISTENCE();
        } else {
            BORROWTRANSACTIONS[]
                storage borrowData = addressToBorrowTransaction[msg.sender];
            require(
                collateralValue[msg.sender] > _value,
                "NEC"
            );
            require(_value <= data.liquidity, "NEL");
            _tmcr(_collateralFactor, _interestRate, _value);
            uint256 MaxiBorrow = FullMath.mulDivRoundingUp(
                collateralValue[msg.sender],
                tmcr[msg.sender],
                100
            );
            require(
                _value <= MaxiBorrow,
                "NECB"
            );
            require(
                _value <=
                    FullMath.mulDivRoundingUp(
                        _collateralFactor,
                        collateralValue[msg.sender],
                        100
                    ),
                "p"
            );
            borrowedValue[msg.sender] += (_value * 1e27);
            AmountBorrowedFromLocus[_collateralFactor][_interestRate] += _value;
            AmountBorrowedFromLocuswithInterest[_collateralFactor][
                _interestRate
            ] += _value * 1e27;
            data.liquidity -= _value;
            totalAvailableLiquidity-=_value;
            uint256 newInterestRate;
            air[msg.sender] += newInterestRate;
            BORROWTRANSACTIONS[] storage Locusdata = LocusBorrowData[
                _collateralFactor
            ][_interestRate];
            Locusdata.push(
                BORROWTRANSACTIONS({
                    interestRateBorrowedAt: _interestRate,
                    collateralFactorBorrowedAt: _collateralFactor,
                    totalBorrowed: _value,
                    borrower: msg.sender,
                    locusId: data.locusId,
                    lastAccuredTimeStamp: uint64(block.timestamp)
                })
            );
            for (uint256 i; i < borrowData.length; i++) {
                if (
                    borrowData[i].collateralFactorBorrowedAt ==
                    data.collateralFactor &&
                    borrowData[i].interestRateBorrowedAt == data.interestRate
                ) {
                    borrowData[i].totalBorrowed += _value;

                    //TransferHelper.safeTransfer(token1, msg.sender, _value);
                    IERC20(token1).transfer(msg.sender, _value);
                } else {
                    borrowData.push(
                        BORROWTRANSACTIONS({
                            interestRateBorrowedAt: _interestRate,
                            collateralFactorBorrowedAt: _collateralFactor,
                            totalBorrowed: _value,
                            borrower: msg.sender,
                            locusId: data.locusId,
                            lastAccuredTimeStamp: uint64(block.timestamp)
                        })
                    );
                    //TransferHelper.safeTransfer(token1, msg.sender, _value);
                    IERC20(token1).transfer(msg.sender, _value);
                }
            }
        }
    }
function _tmcr(
        uint256 _collateralFactor,
        uint256 _interestRate,
        uint256 _value
    ) internal {
        BORROWTRANSACTIONS[] storage borrowData = addressToBorrowTransaction[
            msg.sender
        ];
        if (borrowData.length == 0) {
            tmcr[msg.sender] = 0;
        } else {
            uint256 presumedDebt = borrowedValue[msg.sender].div(1e27) +
                (_value);
            uint256 yColFactor = FullMath.mulDivRoundingUp(
                _value,
                100,
                presumedDebt
            );
            uint256 bColFactor = FullMath.mulDivRoundingUp(
                yColFactor,
                _collateralFactor,
                100
            );
            uint256 bInterestRate = FullMath.mulDivRoundingUp(
                yColFactor,
                _interestRate,
                100
            );

            tmcr[msg.sender] = 0;
            air[msg.sender] = 0;
            for (uint256 i; i < borrowData.length; i++) {
                uint256 zColFactor = FullMath.mulDivRoundingUp(
                    borrowData[i].totalBorrowed,
                    100,
                    presumedDebt
                );
                uint256 aColFactor = FullMath.mulDivRoundingUp(
                    zColFactor,
                    borrowData[i].collateralFactorBorrowedAt,
                    100
                );
                uint256 aInterestRate = FullMath.mulDivRoundingUp(
                    zColFactor,
                    borrowData[i].interestRateBorrowedAt,
                    100
                );
                tmcr[msg.sender] += aColFactor;
                air[msg.sender] += aInterestRate;
            }

            tmcr[msg.sender] += bColFactor;
            air[msg.sender] += bInterestRate;
        }
    }

    function addCollateral(uint _amount) external payable {
        /*TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            _amount
        );*/
             IERC20(token0).transferFrom(msg.sender, address(this), _amount);
        collateralAmount[msg.sender] += msg.value;
        collateralValue[msg.sender] = priceOracle.getInverseConvertion(
            token0,
            uint128(collateralAmount[msg.sender]),
            10
        );
    }

    function addCollateralETH() external payable {
   
        _Weth.deposit{value: msg.value}();
        collateralAmount[msg.sender] += msg.value;
        collateralValue[msg.sender] = priceOracle.getInverseConvertion(
            token0,
            uint128(collateralAmount[msg.sender]),
            10
        );
    }

    /*function getWeth() public payable {
        _Weth.deposit{value: msg.value}();
    }*/

    //should be internal
    function withdrawLiquidity(
        uint256 _id,
        uint256 _colFactor,
        uint256 _interestRate
    ) internal {
        cook();
        accuredK(_colFactor, _interestRate);
        LOCUS storage data = getLocus[_colFactor][_interestRate];
        if (data.initialized != true) revert NON_EXITING_POSITION();
        require(NFT.ownerOf(_id) == msg.sender, "NO");
        //LOCUS storage data = locus[_id];
        NFT.transferFrom(msg.sender, address(this), _id);
        NFTidToAmount[_id] = 0;
        uint256 value = NFT.withdraw(_id);
        uint256 _amount = FullMath.mulDivRoundingUp(value, data.k, 1e10);
        NFT.burn(_id);
        data.liquidity -= _amount;
        totalAvailableLiquidity-=_amount;
        TotalPositionSize[_colFactor][_interestRate] += _amount;
        //TransferHelper.safeTransfer(token1, msg.sender, _amount);
        IERC20(token1).transfer(msg.sender, _amount);
    }
    function withdrawCollateral(uint256 _amount) external payable {
        cook();
        if (_amount <= 0) revert INVALID_AMOUNT();
        require(
            _amount <= collateralAmount[msg.sender],
            "AGC"
        );
        if (borrowedValue[msg.sender] == 0) {
            collateralAmount[msg.sender] -= _amount;
            (bool sent, ) = payable(msg.sender).call{value: _amount}("");
            require(sent, "FSE");
        } else {
            validatWithdraw(msg.sender, _amount);
        }
    }

    function validatWithdraw(address recepient, uint256 _amount)
        internal
        returns (uint256 pass)
    {
        uint256 factor = (
            (tmcr[recepient] * collateralValue[recepient]).div(100)
        ) - borrowedValue[recepient].div(1e27);
        require(
            _amount < factor,
            "CWCB"
        );
        collateralAmount[recepient] -= _amount;
        (bool sent, ) = payable(recepient).call{value: _amount}("");
        require(sent, "FSE");
        pass = 1;

        return pass;
    }

    //increase of data.Liquidity

    function calrepayExp(uint _totalborrow, uint _amount)
        internal
        view
        returns (uint repayAmount)
    {
        uint debt = borrowedValue[msg.sender].div(1e27);
        uint percentage = FullMath.mulDivRoundingUp(_totalborrow, 100, debt);
        repayAmount = FullMath.mulDivRoundingUp(percentage, _amount, 100);
    }

    function repay(uint256 _amount) external {
        cook();
        //accureInterestRate(); correct
        BORROWTRANSACTIONS[] storage borrowData = addressToBorrowTransaction[
            msg.sender
        ];

        //if (data.initialized != true) revert NON_EXITING_POSITION();
        if (borrowData.length == 0) {
            revert NOT_OWING();
        }
        for (uint256 i; i < borrowData.length; i++) {
            // if (
            //     data.collateralFactor ==
            //     borrowData[i].collateralFactorBorrowedAt &&
            //     data.interestRate == borrowData[i].interestRateBorrowedAt
            // ) {
            // require(
            //     _amount <= (borrowedValue[msg.sender].div(1e27)), //1e23
            //     "amount more than borrowed amount"
            //);
            LOCUS storage data = getLocus[
                borrowData[i].collateralFactorBorrowedAt
            ][borrowData[i].interestRateBorrowedAt];
            /*TransferHelper.safeTransferFrom(
                token1,
                msg.sender,
                address(this),
                _amount
            );*/
            IERC20(token1).transferFrom(msg.sender, address(this), _amount);

            data.liquidity += calrepayExp(borrowData[i].totalBorrowed, _amount);
            totalAvailableLiquidity+=calrepayExp(borrowData[i].totalBorrowed, _amount);
            AmountBorrowedFromLocus[borrowData[i].collateralFactorBorrowedAt][
                borrowData[i].interestRateBorrowedAt
            ] -= calrepayExp(borrowData[i].totalBorrowed, _amount);
            AmountBorrowedFromLocuswithInterest[
                borrowData[i].collateralFactorBorrowedAt
            ][borrowData[i].interestRateBorrowedAt] -= ((
                calrepayExp(borrowData[i].totalBorrowed, _amount)
            ) * 1e27);
            if (_amount == (borrowedValue[msg.sender].div(1e27))) {
                //1e23
                borrowData[i] = borrowData[borrowData.length - 1];
                borrowData.pop();
                (borrowedValue[msg.sender] == 0);
            } else {
                borrowData[i].totalBorrowed -= calrepayExp(
                    borrowData[i].totalBorrowed,
                    _amount
                );
            }
        }
        borrowedValue[msg.sender] -= _amount.mul(1e27);
    }
      function getHealthFactor(address _borrower)
        public
        view
        returns (uint256 healthFactor)
    {
        uint256 x = SafeMath.mul(borrowedValue[_borrower].div(1e27), 100);
        return
            FullMath.mulDivRoundingUp(
                collateralValue[_borrower] * 1e10,
                liquidationThreshold,
                x
            );
    }

  function swapExactInputSingle(uint128 amountIn, uint32 secondsOf)
        public
        returns (uint256 amountOut)
    {
        // msg.sender must approve this contract

        // Transfer the specified amount of DAI to this contract.
        //TransferHelper.safeTransfer(token0, address(swapRouter), amountIn);
        IERC20(token0).transfer(address(swapRouter), amountIn);

        // Approve the router to spend DAI.
        //TransferHelper.safeApprove(token0, address(swapRouter), amountIn);
       IERC20(token0).approve(address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        uint amountMinimun = priceOracle.estimateAmountOut(
            token0,
            amountIn,
            secondsOf
        );
        if (amountMinimun <= 0) revert INVALID_PRICE_FROM_ORACLE();
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to exactInputSingle executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function liquidate(address _borrower) external {
        cook();
        require(borrowedValue[_borrower] > 0, "NB");

        uint256 healthFactor = getHealthFactor(_borrower);
        uint128 amountOfcoll = uint128(collateralAmount[_borrower]);

        if (healthFactor < 1e10) {
            BORROWTRANSACTIONS[] memory borrowData = addressToBorrowTransaction[
                _borrower
            ];
            collateralAmount[_borrower] = 0;
            borrowedValue[_borrower] = 0;
            collateralValue[_borrower] = 0;

            swapExactInputSingle(amountOfcoll, 10);
            //(bool sent, ) = payable(auctionPool).call{value: amountOfcoll}("");
            // token0.deposit{value: amountOfcoll}();
            //require(sent, "Failed to send Ether");
            for (uint256 i; i < borrowData.length; i++) {
                liquidatedTransactions.push(
                    LIQUIDATEDTRANSACTIONS({
                        locusId: borrowData[i].locusId,
                        interestRateBorrowedAt: borrowData[i]
                            .interestRateBorrowedAt,
                        collateralFactorBorrowedAt: borrowData[i]
                            .collateralFactorBorrowedAt,
                        amountLiquidatedFromPool: borrowData[i].totalBorrowed
                    })
                );
                AmountBorrowedFromLocus[
                    borrowData[i].collateralFactorBorrowedAt
                ][borrowData[i].interestRateBorrowedAt] -= borrowData[i]
                    .totalBorrowed;

                AmountBorrowedFromLocuswithInterest[
                    borrowData[i].collateralFactorBorrowedAt
                ][borrowData[i].interestRateBorrowedAt] -= (borrowData[i]
                    .totalBorrowed * 1e27);
            }

            borrowData = new BORROWTRANSACTIONS[](0);
            allLiquidators.push(msg.sender);
            UpdatePoolAfterLiquidation();
        } else if (healthFactor >= 1e10) {
            revert CANT_BE_LIQUIDATED();
        }
    }

    function UpdatePoolAfterLiquidation() public {
        if (liquidatedTransactions.length == 0) {
            revert NO_PENDING_LIQUIDITY_UPDATE_FOR_LOCUSES();
        } else {
            for (uint256 i; i > liquidatedTransactions.length; i++) {
                LIQUIDATEDTRANSACTIONS
                    storage LiquidationData = liquidatedTransactions[i];
                LOCUS storage data = getLocus[
                    LiquidationData.collateralFactorBorrowedAt
                ][LiquidationData.interestRateBorrowedAt];
                if (LiquidationData.locusId == data.locusId) {
                    data.liquidity += LiquidationData.amountLiquidatedFromPool;
                     totalAvailableLiquidity+=LiquidationData.amountLiquidatedFromPool;
                    LiquidationData.amountLiquidatedFromPool = 0;
                }
            }
        }
    }

    function chackIfLiquidationIsAllowed(address _borrower)
        external
        view
        returns (bool CAN_BE_LIQUIDATED)
    {
        require(borrowedValue[_borrower] > 0, "NB");
        uint256 healtFactor = getHealthFactor(_borrower);
        if (healtFactor < 1e10) {
            return true;
        } else if (healtFactor >= 1e10) {
            return false;
        }
    }

    function setLiquidationThreshold(uint256 _LiquidationFee) external {
        LiquidationFee = _LiquidationFee;
        liquidationThreshold = 100 - _LiquidationFee;
    }

    function cook() internal {
        collateralValue[msg.sender] = priceOracle.getInverseConvertion(
            token0,
            uint128(collateralAmount[msg.sender]),
            10
        );
        //getPricetoken1();
        //getPriceEth();
    }

    function getNowInternal() internal view virtual returns (uint64) {
        if (block.timestamp >= 2**64) revert TimestampTooLarge();
        return uint64(block.timestamp);
    }

    function calBorrowInt(uint256 _collateralFactor, uint256 _interestRate)
        internal
    {
        uint64 now_ = getNowInternal();
        uint64 formerTime = LastDebtAccuredTimeLocus[_collateralFactor][
            _interestRate
        ];
        uint64 timeElapsed;
        if (formerTime == 0) {
            timeElapsed = now_;
            LastDebtAccuredTimeLocus[_collateralFactor][_interestRate] = now_;
        } else {
            timeElapsed = now_ - formerTime;
        }

        uint256 acuuredDebt = SafeMath.mul(_interestRate, timeElapsed);
        uint256 timeDf = SafeMath.mul(100, SECONDS_PER_YEAR);
        uint256 debt = AmountBorrowedFromLocuswithInterest[_collateralFactor][
            _interestRate
        ];
        uint256 gwt = FullMath.mulDivRoundingUp(acuuredDebt, debt, timeDf);
        AmountBorrowedFromLocuswithInterest[_collateralFactor][
            _interestRate
        ] += gwt;
        LastDebtAccuredTimeLocus[_collateralFactor][_interestRate] = now_;
    }

    function accuredK(uint256 _collateralFactor, uint256 _interestRate)
        internal
        returns (uint256 newK)
    {
        LOCUS storage data = Position.getLocus[_collateralFactor][
            _interestRate
        ];
        calBorrowInt(_collateralFactor, _interestRate);

        uint256 newDebt = (data.liquidity.mul(1e27)).add(
            AmountBorrowedFromLocuswithInterest[_collateralFactor][
                _interestRate
            ]
        );
        uint256 position_size = TotalPositionSize[_collateralFactor][
            _interestRate
        ].mul(1e17);
        data.k = newDebt.div(position_size);
        return data.k;
    }

  

    function accureInterestRateChange(uint256 _interestRate) internal {
        uint64 now_ = getNowInternal();
        uint64 formerTime = borrowerTimer[msg.sender];
        uint64 timeElapsed;
        if (formerTime == 0) {
            timeElapsed = now_;
            borrowerTimer[msg.sender] = now_;
        } else {
            timeElapsed = now_ - formerTime;
        }
        uint256 acuuredDebt = SafeMath.mul(_interestRate, timeElapsed);
        uint256 timeDf = SafeMath.mul(100, SECONDS_PER_YEAR);
        uint256 debt = borrowedValue[msg.sender];

        uint256 gwt = FullMath.mulDivRoundingUp(acuuredDebt, debt, timeDf);

        borrowedValue[msg.sender] += gwt;
        borrowerTimer[msg.sender] = now_;
    }

   /*function getValueofInvariant(
        uint256 _collateralFactor,
        uint256 _interestRate
    ) public view returns (uint256 invariantValue) {
        LOCUS memory data = getLocus[_collateralFactor][_interestRate];
        if (data.k == 0) {
            invariantValue = 1e10;
        } else {
            invariantValue = data.k;
        }
    }

    function getPresumedPositionSize(
        uint256 _amount,
        uint256 _collateralFactor,
        uint256 _interestRate
    ) public view returns (uint256 positionSize) {
        LOCUS memory data = getLocus[_collateralFactor][_interestRate];
        if (data.k == 0) {
            uint256 invariantValue = 1e10;
            positionSize = (_amount * 1e10) / invariantValue;
        } else {
            uint256 invariantValue = data.k;
            positionSize = (_amount * 1e10) / invariantValue;
        }
    }

    function getAllUserBorrowedTransaction()
        public
        view
        returns (BORROWTRANSACTIONS[] memory)
    {
        return addressToBorrowTransaction[msg.sender];
    }

    function getUserLiquidationPoint(address _user)
        public
        view
        returns (uint256 liquidationPoint)
    {
        liquidationPoint = ((collateralValue[_user] * liquidationThreshold) /
            100);
    }

    function getAvaliableLiquidity(
        uint256 _collateralFactor,
        uint256 _interestRate
    ) public view returns (uint256 avaliableLiquidity) {
        LOCUS memory data = getLocus[_collateralFactor][_interestRate];
        avaliableLiquidity = data.liquidity;
        return avaliableLiquidity;
    }

    function getAllExistingLocus()public view returns(LOCUS []memory){
        return allExistingLocus;
    }*/

    receive() external payable {}

    fallback() external payable {}
}