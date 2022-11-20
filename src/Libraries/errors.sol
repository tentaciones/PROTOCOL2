pragma solidity 0.8.7;

contract errors{
   error TimestampTooLarge();
   error LOCUS_NOT_IN_EXISTENCE();
   error NOT_OWING();
   error CANT_BE_LIQUIDATED();
   error INPUT_DATA_SHOULD_BE_GREATER_THAN_ZERO();
   error NO_PENDING_LIQUIDITY_UPDATE_FOR_LOCUSES();
  error NON_EXITING_POSITION();
  error INVALID_AMOUNT();
  error  INVALID_PRICE_FROM_ORACLE();
}