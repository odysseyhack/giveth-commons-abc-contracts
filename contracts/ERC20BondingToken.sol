pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "zos-lib/contracts/Initializable.sol";
import "./BondingCurveToken.sol";

//TODO: time limit  (deadline of the hatch)
// TODO: minimum contribution limit
/**
 * @title Token Bonding Curve
 * @dev Token backed Bonding curve contract
 */
contract ERC20BondingToken is Initializable, BondingCurveToken {

  ERC20 public reserveToken;
  uint256 public theta;
  uint256 public p0;
  uint256 public initialRaise;
  uint256 public raised;
  address public fundingPool;
  uint256 public friction;
  bool public isInHatchingPhase;

  uint256 private DENOMINATOR = 1000000;

  struct initialContributionRegistry {
      uint256 contributed;
      uint256 percentageTokenUnlocked;
  }

  mapping(address => initialContributionRegistry) initialContributions;


  /**
   * @dev initialize augmented bonding curve
   * @param reserveToken this is the token which is being allocated as a reserve pool + funding pool (xDai)
   * @param get's used by the bancorFormula and is equal to the connectorWeight (CW). The connectorWeight is related to Kappa as CW = 1 / (k+1). Source: https://medium.com/@billyrennekamp/converting-between-bancor-and-bonding-curve-price-formulas-9c11309062f5. 142857 ~> kappa = 6
   * @param _theta this is the percentage (in ppm) of funds that gets allocated to the funding pool
   * @param _p0 the price at which hatchers can buy into the Curve => the price in reservetoken (dai) per native token
   * @param _toRaise (initialRiase, d0, in DAI), the goal of the Hatch phase
   * @param _fundingPool, the address (organization, DAO, entity) to which we transfer theta times the contribution during the hatching phase
   * @param _friction, the fee (percentage in ppm) which is paid to the funding pool, every time a person calls curvedBurn
   * @param _gasPrice, mitigation against front-running attacks by forcing all users to pay the same gas price
   */
  function initialize(
      address _reserveToken,
      uint32 _reserveRatio,
      uint256 _theta,
      uint256 _p0,
      uint256 _initialRaise,
      address _fundingPool,
      uint256 _friction
      uint256 _gasPrice
  ) initializer public {
      require(theta <= DENOMINATOR && theta >= 1, "Theta should be a percentage in ppm");
      require(fundingPool != address(0));
      require(_friction <= DENOMINATOR, "Friction should be a percentage in ppm")
      reserveToken = ERC20(_reserveToken);
      theta = _theta;
      p0 = _p0;
      initialRaise = _initialRaise;
      fundingPool = _fundingPool;
      friction = _friction;
      BondingCurveToken.initialize(_reserveRatio, _gasPrice);
  }

  /**
   * @dev Mint tokens
   *
   * @param amount Amount of tokens to deposit
   */
  function _curvedMint(uint256 amount) internal returns (uint256) {
    require(!isInHatchingPhase);
    require(reserveToken.transferFrom(msg.sender, this, amount));
    super._curvedMint(amount);
  }

  /**
   * @dev Burn tokens
   *
   * @param amount Amount of tokens to burn
   */
  function _curvedBurn(uint256 amount) internal returns (uint256) {
      require(!isInHatchingPhase);
      uint256 reimbursement = super._curvedBurn(amount);
      uint256 transferable = (1 - (friction / DENOMINATOR) * reimbursement;
      reserveToken.transfer(msg.sender, transferable);
      reserveToken.approve(fundingPool, reimbursement - transferable);
  }

  function poolBalance() public view returns(uint256) {
      return reserveToken.balanceOf(this);
  }
}
