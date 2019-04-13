pragma solidity ^0.5.0;

import "./BondingCurveToken.sol";

contract CommonsToken is BondingCurveToken {

  event LogVal(uint256 val);

  // --- STRUCT DELCARATIONS: ---

  // PreHatchContribution is a contribution in the curve hatching phase.
  // Each contribution is an amount of reserve tokens.
  // Each contribution also tracks the percentage of tokens that was unlocked.
  struct PreHatchContribution {
    uint256 paidExternal;
    uint256 lockedInternal;
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

  // Minimal EXTERNAL token contribution:
  uint256 public minExternalContribution;

  // Total amount of EXTERNAL tokens raised:
  uint256 public raisedExternal;

  // Total amount of unlocked INTERNAL tokens.
  uint256 private unlockedInternal;

  // Curve state (has it been hatched?).
  bool public isHatched;

  // Time by which the curve must be hatched.
  uint256 public hatchDeadline;

  // Mapping of hatchers to contributions.
  mapping(address => PreHatchContribution) initialContributions;

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
    require(initialContributions[msg.sender].paidExternal != 0, "Must be called by a hatcher");
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

  modifier mustBeLargeEnoughContribution(uint256 _amountExternal) {
    uint256 totalAmountExternal = initialContributions[msg.sender].paidExternal + _amountExternal;
    require(totalAmountExternal >= minExternalContribution, "Insufficient contribution");
    _;
  }

  modifier expiredStatus(bool _wantExpire) {
    bool expired = now <= hatchDeadline;
    if (_wantExpire) {
      require(!expired, "Curve hatch time has expired");
    }
    require(expired, "Curve hatch time has expired");
    _;
  }

  // --- INTERNAL FUNCTIONS: ---

  // function _ppmToPercent(uint256 _val)
  //   internal
  //   pure
  //   returns (uint256 resultPPM)
  // {
  //   return _val / DENOMINATOR_PPM;
  // }

  // Try and pull the given amount of reserve token into the contract balance.
  // Reverts if there is no approval.
  function _pullExternalTokens(uint256 _amount)
    internal
  {
    externalToken.transfer(address(this), _amount);
  }

  // End the hatching phase of the curve.
  // Allow the fundingPool to pull theta times the balance into their control.
  // NOTE: 1 - theta is reserve.
  function _endHatchPhase()
    internal
  {
    uint256 amountFundingPool = initialRaise * (theta / DENOMINATOR_PPM);
    uint256 amountReserve = initialRaise * ((1-theta) / DENOMINATOR_PPM);

    // _transfer(address(this), fundingPool, amount);

    // Mint INTERNAL tokens to the funding pool:
    _mint(fundingPool, amountFundingPool);

    // Mint INTERNAL tokens to the reserve:
    _mint(address(this), amountReserve);

    // End the hatching phase.
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
    // Increase the amount paid in EXTERNAL tokens.
    initialContributions[_adr].paidExternal += _amount;

    // Lock the INTERNAL tokens, total is EXTERNAL amount * price of internal token during the raise.
    initialContributions[_adr].lockedInternal += _amount * p0;
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
    uint256 _friction,
    uint256 _duration,
    uint256 _minExternalContribution
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

    hatchDeadline = now + _duration;
    minExternalContribution = _minExternalContribution;

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
    return reimbursement;
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
    returns (uint256)
  {
    return _curvedBurn(_amount);
  }

  function hatchContribute(uint256 _value)
    public
    mustBeLargeEnoughContribution(_value)
    whileHatched(false)
    expiredStatus(false)
  {
    uint256 contributed = _value;

    if(raisedExternal < initialRaise) {
      emit LogVal(1);
      raisedExternal += _value;
      _pullExternalTokens(contributed);
    } else {
      emit LogVal(0);
      contributed = initialRaise - raisedExternal;
      raisedExternal = initialRaise;
      _pullExternalTokens(contributed);
      _endHatchPhase();
    }

    _mintInternalAndLock(msg.sender, contributed);
  }

  function fundsAllocated(uint256 _externalAllocated)
    public
    onlyFundingPool
    whileHatched(true)
  {
    // Currently, we unlock a 1/1 proportion of tokens.
    // We could set a different proportion:
    //  100.000 funds spend => 50.000 worth of funds unlocked.
    // We should only update the total unlocked when it is less than 100%.

    // TODO: add vesting period ended flag and optimise check.
    unlockedInternal += _externalAllocated / p0;
    if (unlockedInternal >= initialRaise * p0) {
      unlockedInternal += initialRaise * p0;
    }
  }

  function claimTokens()
    public
    whileHatched(true)
    onlyHatcher
  {
    require(initialContributions[msg.sender].lockedInternal > 0);

    uint256 paidExternal = initialContributions[msg.sender].paidExternal;
    uint256 lockedInternal = initialContributions[msg.sender].lockedInternal;

    // The total amount of INTERNAL tokens that should have been unlocked.
    uint256 shouldHaveUnlockedInternal = (paidExternal / initialRaise) * unlockedInternal;
    // The amount of INTERNAL tokens that was already unlocked.
    uint256 previouslyUnlockedInternal = (paidExternal / p0) - lockedInternal;
    // The amount that can be unlocked.
    uint256 toUnlock = shouldHaveUnlockedInternal - previouslyUnlockedInternal;

    initialContributions[msg.sender].lockedInternal -= toUnlock;
    _transfer(address(this), msg.sender, toUnlock);
  }

  function refund()
    public
    whileHatched(false)
    expiredStatus(true)
  {
    // Refund the EXTERNAL tokens from the contibution.
    uint256 paidExternal = initialContributions[msg.sender].paidExternal;
    externalToken.transfer(msg.sender, paidExternal);
  }

  function poolBalance()
    public
    view
    returns(uint256)
  {
    return externalToken.balanceOf(address(this));
  }
}
