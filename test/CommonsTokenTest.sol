pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CommonsToken.sol";

contract CommonsTokenTest {
  function testItDoesAThing() public {
    CommonsToken token = CommonsToken(DeployedAddresses.CommonsToken());

    token.something(53);

    Assert.equal(token.getSomething(), 53, "It should be 53");
  }
}
