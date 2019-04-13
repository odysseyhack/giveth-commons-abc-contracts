pragma solidity ^0.5.0;

import "./vendor/ERC20/ERC20.sol";
import "./BondingCurveToken.sol";

// TODO: time limit  (deadline of the hatch)
// TODO: minimum contribution limit
/**
 * @title Token Bonding Curve
 * @dev Token backed Bonding curve contract
 */
contract ERC20BondingToken is BondingCurveToken {

  // --- CONSTANTS: ---
  uint256 constant denominator = 1000000;

  // --- STORAGE: ---
  ERC20 public reserveToken;
  uint256 public friction;
  address public fundingPool;

  // /**
  //  * @dev initialize augmented bonding curve
  //  * @param _reserveToken this is the token which is being allocated as a reserve pool + funding pool (xDai)
  //  * @param get's used by the bancorFormula and is equal to the connectorWeight (CW).
  //  *  The connectorWeight is related to Kappa as CW = 1 / (k+1).
  //  *  Source:
  //  *  https://medium.com/@billyrennekamp/converting-between-bancor-and-bonding-curve-price-formulas-9c11309062f5.
  //  *  Note: 142857 ~> kappa = 6
  //  * @param _theta this is the percentage (in ppm) of funds that gets allocated to the funding pool
  //  * @param _p0 the price at which hatchers can buy into the Curve => the price in reservetoken (dai) per native token
  //  * @param _initialRaise (initialRaise, d0, in DAI), the goal of the Hatch phase
  //  * @param _fundingPool the address (organization, DAO, entity) to which we transfer theta times the contribution
  //  *  during the hatching phase
  //  * @param _friction fee (percentage in ppm) which is paid to the funding pool, every time a person calls curvedBurn
  //  * @param _gasPrice mitigation against front-running attacks by forcing all users to pay the same gas price
  //  */
constructor(
    uint32 _reserveRatio,
    uint256 _gasPrice,
    address _reserveToken,
    uint256 _friction,
    address _fundingPool
  ) public
    BondingCurveToken(_reserveRatio, _gasPrice)
  {
    reserveToken = ERC20(_reserveToken);
    friction = _friction;
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
