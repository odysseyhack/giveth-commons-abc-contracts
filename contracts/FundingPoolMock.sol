pragma solidity ^0.5.0;

import "CommonsToken.sol";

contract FundingPoolMock {

    CommonsToken commonsToken;

    constructor(address commonstoken) {
        commonsToken = CommonsToken(commonsToken);
    }

    function allocateFunds(address to, uint256 amount) {
        commonsToken.fundsAllocated(value);
        commonsToken.transfer()

    }
}
