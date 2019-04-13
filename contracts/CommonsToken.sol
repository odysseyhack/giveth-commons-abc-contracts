pragma solidity ^0.5.0;

import "./BondingCurveToken.sol";

contract CommonsToken is BondingCurveToken {

  // --- STRUCT DELCARATIONS: ---

  // PreHatchContribution is a contribution in the curve hatching phase.
  // Each contribution is an amount of reserve tokens.
  // Each contribution also tracks the percentage of tokens that was unlocked.
  struct PreHatchContribution {
    uint256 amount;
    uint256 percentTokenUnlocked;
  }

  // --- CONSTANTS: ---

  // The denominator of each contribuition.
  // All contributions are measuted in ppm (parts per million).
  uint256 constant DENOMINATOR_PPM = 1000000;

  // --- STORAGE: ---

  // External (reserve) token contract.
  ERC20 public externalToken;

  // Address of the funding pool contract.
  address public fundingPool;

  // Curve parameters:
  uint256 public theta;
  uint256 public p0;
  uint256 public initialRaise;
  uint256 public friction;

  // Total amount of EXTERNAL tokens raised:
  uint256 public raisedExternal;

  // Curve state (has it been hatched?).
  bool public isHatched;

  // Mapping of hatchers to contributions.
  mapping(address => PreHatchContribution) contribs;

  // Total percentage of INTERNAL tokens unlocked (in parts per million).
  uint256 private unlockedInternal;

  // --- MODIFIERS: ---

  modifier whileHatched(bool _hatched) {
    require(isHatched == _hatched, "Curve must be hatched");
    _;
  }

  modifier onlyFundingPool() {
    require(msg.sender == fundingPool, "Must be called by the funding pool");
    _;
  }

  modifier onlyHatcher() {
    require(contribs[msg.sender].amount != 0, "Must be called by a hatcher");
    _;
  }

  modifier mustBeInPPM(uint256 _val) {
    require(_val <= DENOMINATOR_PPM, "Value must be in PPM");
    _;
  }

  modifier mustBeNonZeroAdr(address _adr) {
    require(_adr != address(0), "Address must not be zero");
    _;
  }

  // --- INTERNAL FUNCTIONS: ---

  function _ppmToPercent(uint256 _val)
    internal
    pure
    returns (uint256 resultPPM)
  {
    return _val / DENOMINATOR_PPM;
  }

  // Try and pull the given amount of reserve token into the contract balance.
  // Reverts if there is no approval.
  function _pullExternalTokens(uint256 _amount)
    internal
  {
    externalToken.transferFrom(msg.sender, address(this), _amount);
  }

  // End the hatching phase of the curve.
  // Allow the fundingPool to pull theta times the balance into their control.
  // NOTE: 1 - theta is reserve.
  function _endHatchPhase()
    internal
  {
    uint256 amount = initialRaise * _ppmToPercent(theta);

    _burn(address(this), amount);
    _mint(fundingPool, amount);
    isHatched = true;
  }

  // We mint to contributor account and lock the tokens.
  // Theoretically, the price is increasing (up to P1),
  // but since we are in the hatching phase, the actual price will stay P0.
  // The contract will hold the locked tokens.
  function _mintInternalAndLock(
    address _adr,
    uint256 _amount
  )
    internal
  {
    _mint(address(this), calculateCurvedMintReturn(_amount));
    contribs[_adr].amount += _amount;
  }

  // Constructor.
  constructor(
    address _externalToken,
    uint32 _reserveRatio,
    uint256 _gasPrice,
    uint256 _theta,
    uint256 _p0,
    uint256 _initialRaise,
    address _fundingPool,
    uint256 _friction
  )
    public
    mustBeNonZeroAdr(_externalToken)
    mustBeNonZeroAdr(_fundingPool)
    mustBeInPPM(_theta)
    mustBeInPPM(_friction)
    BondingCurveToken(_reserveRatio, _gasPrice)
  {
    theta = _theta;
    p0 = _p0;
    initialRaise = _initialRaise;
    fundingPool = _fundingPool;
    friction = _friction;

    externalToken = ERC20(_externalToken);
  }

  /**
   * @dev Mint tokens
   *
   * @param amount Amount of tokens to deposit
   */
  function _curvedMint(uint256 amount) internal returns (uint256) {
    require(externalToken.transferFrom(msg.sender, address(this), amount));
    super._curvedMint(amount);
  }

  /**
   * @dev Burn tokens
   *
   * @param amount Amount of tokens to burn
   */
  function _curvedBurn(uint256 amount) internal returns (uint256) {
    uint256 reimbursement = super._curvedBurn(amount);
    uint256 transferable = (1 - (friction / DENOMINATOR_PPM) * reimbursement);
    externalToken.transfer(msg.sender, transferable);
    externalToken.transfer(fundingPool, reimbursement - transferable);
  }

  // --- PUBLIC FUNCTIONS: ---

  function mint(uint256 _amount)
    public
    whileHatched(true)
  {
    _curvedMint(_amount);
  }

  function burn(uint256 _amount)
    public
    whileHatched(true)
  {
    _curvedBurn(_amount);
  }

  function hatchContribute(uint256 _value)
    public
    whileHatched(false)
  {
    uint256 contributed = _value;

    if(raisedExternal < initialRaise) {
      raisedExternal += _value;
      _pullExternalTokens(contributed);
    } else {
      contributed = initialRaise - raisedExternal;
      raisedExternal = initialRaise;
      _pullExternalTokens(contributed);
      _endHatchPhase();
    }
    _mintInternalAndLock(msg.sender, contributed);
  }

  function fundsAllocated(uint256 _value)
    public
    onlyFundingPool
    whileHatched(true)
  {
    // Currently, we unlock a 1/1 proportion of tokens.
    // We could set a different proportion:
    //  100.000 funds spend => 50000 worth of funds unlocked.
    // We should only update the total unlocked when it is less than 100%
    if(unlockedInternal < DENOMINATOR_PPM) {
      unlockedInternal += (_value * DENOMINATOR_PPM / initialRaise);
    }
  }

  function claimTokens()
    public
    whileHatched(true)
    onlyHatcher
  {
    require(contribs[msg.sender].percentTokenUnlocked < unlockedInternal);
    // allocationPercentage = (initialContributions[msg.sender].contributed / initialRaise)
    // -- percentage of the total contribution during the hatch phase of the msg.sender
    // totalAllocated = allocationPercentage * p0 == total tokens allocated to hatcher (locked + unlocked)
    // toBeunlockedInternal = totalUnlocked - initialContributionRegistry[msg.sender.percentageUnlocked
    // -- percentage in ppm that we want to unlock
    // toBeUnlockedPercentage = toBeunlockedInternal / denominator
    // toBeUnlocked = Percentage * totalAllocated
    uint256 toBeUnlocked = (contribs[msg.sender].amount / initialRaise) * p0 *
        ((unlockedInternal - contribs[msg.sender].percentTokenUnlocked) / DENOMINATOR_PPM);
    // we burn the token previously minted to our account and mint tokens to the hatcher
    _burn(address(this), toBeUnlocked);
    _mint(msg.sender, toBeUnlocked);
  }

  function poolBalance()
    public
    view
    returns(uint256)
  {
    return externalToken.balanceOf(address(this));
  }
}
