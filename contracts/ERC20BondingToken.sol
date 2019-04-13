pragma solidity ^0.5.0;

import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "zos-lib/contracts/Initializable.sol";
import "./BondingCurveToken.sol";

// TODO: time limit  (deadline of the hatch)
// TODO: minimum contribution limit
/**
 * @title Token Bonding Curve
 * @dev Token backed Bonding curve contract
 */
contract ERC20BondingToken is Initializable, BondingCurveToken {

  ERC20 reserveToken;
  uint256 friction;
  uint256 denominator = 1000000;
  address fundingPool;

  function initialize(
    uint32 _reserveRatio,
    uint256 _gasPrice,
    address _reserveToken,
    uint256 _friction,
    uint256 _denominator,
    address _fundingPool
  ) initializer public {
    BondingCurveToken.initialize(_reserveRatio, _gasPrice);
    reserveToken = ERC20(_reserveToken);
    friction = _friction;
    denominator = _denominator;
    fundingPool = _fundingPool;
  }

  /**
   * @dev Mint tokens
   *
   * @param amount Amount of tokens to deposit
   */
  function _curvedMint(uint256 amount) internal returns (uint256) {
    require(reserveToken.transferFrom(msg.sender, address(this), amount));
    super._curvedMint(amount);
  }

  /**
   * @dev Burn tokens
   *
   * @param amount Amount of tokens to burn
   */
  function _curvedBurn(uint256 amount) internal returns (uint256) {
    uint256 reimbursement = super._curvedBurn(amount);
    uint256 transferable = (1 - (friction / denominator) * reimbursement);
    reserveToken.transfer(msg.sender, transferable);
    reserveToken.transfer(fundingPool, reimbursement - transferable);
  }

  function poolBalance() public view returns(uint256) {
    return reserveToken.balanceOf(address(this));
  }
}
