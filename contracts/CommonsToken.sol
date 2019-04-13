pragma solidity ^0.5.0;

import "./ERC20BondingToken.sol";

contract CommonsToken is ERC20BondingToken {

  // --- STRUCT DELCARATIONS: ---
  struct initialContributionRegistry {
    uint256 contributed;
    uint256 percentageTokenUnlocked;
  }

  // --- CONSTANTS: ---
  uint256 constant denominator = 1000000;

  // --- STORAGE: ---
  ERC20 public reserveToken;
  uint256 public theta;
  uint256 public p0;
  uint256 public initialRaise;
  uint256 public raised;
  address public fundingPool;
  uint256 public friction;
  bool public isInHatchingPhase;

  mapping(address => initialContributionRegistry) initialContributions;

  //TODO: define
  uint256 totalUnlocked;

  // --- MODIFIERS: ---
  modifier notHatchingPhase() {
    require(!isInHatchingPhase, "Must not be in hatching phase");
    _;
  }

  modifier hatchingPhase() {
    require(isInHatchingPhase, "Must be in hatcing phase");
    _;
  }

  // Try and pull the given amount of reserve token into the contract balance.
  // Reverts if there is no approval.
  function _pullReserveTokens(uint256 amount)
    internal
  {
    reserveToken.transferFrom(msg.sender, address(this), amount);
  }

  // initialize the curve
  constructor(
    address _reserveToken,
    uint32 _reserveRatio,
    uint256 _gasPrice,
    uint256 _theta,
    uint256 _p0,
    uint256 _initialRaise,
    address _fundingPool,
    uint256 _friction
  ) public ERC20BondingToken(
      reserveRatio,
      _gasPrice,
      _reserveToken,
      friction,
      _fundingPool
    )
  {
      require(theta <= denominator, "Theta should be a percentage in ppm");
      require(_reserveToken != address(0), "Reservetoken is not correctly defined");
      require(_fundingPool != address(0), "Fundingpool is not correctly defined");
      require(_friction <= denominator, "Friction should be a percentage in ppm");
      reserveToken = ERC20(_reserveToken);
      theta = _theta;
      p0 = _p0;
      initialRaise = _initialRaise;
      fundingPool = _fundingPool;
      friction = _friction;
  }

  function mint(uint256 amount)
    public
    notHatchingPhase
  {
    _curvedMint(amount);
  }

  function burn(uint256 amount)
    public
    notHatchingPhase
  {
    _curvedBurn(amount);
  }

  function hatchContribute(uint256 _value)
    public
    hatchingPhase
  {
    uint256 contributed;
    if(raised < initialRaise) {
      raised += _value;
      // We call the DAI contract and try to pull DAI to this contract.
      // Reverts if there is no approval.
      reserveToken.transferFrom(msg.sender, address(this), contributed);
    } else {
      contributed = initialRaise - raised;
      raised = initialRaise;
      isInHatchingPhase = false;
      // We call the DAI contract and try to pull DAI to this contract.
      // Reverts if there is no approval.
      reserveToken.transferFrom(msg.sender, address(this), contributed);
      // Once we reached the hatch phase, we allow the fundingPool
      // to pull theta times the balance into their control.
      // 1 - theta is reserve.
      uint256 toBeTransfered = initialRaise * (theta / denominator);
      _burn(address(this), toBeTransfered);
      reserveToken.approve(fundingPool, toBeTransfered);
    }
    // We mint to our account.
    // Theoretically, the price is increasing (up to P1), but since we are in the hatching phase, the
    // actual price stays P0.
    uint256 amountToMint = calculateCurvedMintReturn(contributed);
    _mint(address(this), amountToMint);
    initialContributions[msg.sender].contributed += contributed;
  }

  function fundsAllocated(uint256 _value)
    public
    notHatchingPhase
  {
    require(msg.sender == fundingPool);
    // TODO: now, we unlock based on 1 / 1 proportion.
    // This could also be another proportion:
    // -- i.e. 100.000 funds spend => 50000 worth of funds unlocked
    // We should only update the total unlocked when it is less than 100%
    if(totalUnlocked < denominator) {
      totalUnlocked += (_value * denominator / initialRaise);
    }
  }

  function claimTokens()
    public
    notHatchingPhase
  {
    require(initialContributions[msg.sender].contributed != 0);
    require(initialContributions[msg.sender].percentageTokenUnlocked < totalUnlocked);
    // allocationPercentage = (initialContributions[msg.sender].contributed / initialRaise)
    // -- percentage of the total contribution during the hatch phase of the msg.sender
    // totalAllocated = allocationPercentage * p0 == total tokens allocated to hatcher (locked + unlocked)
    // toBeUnlockedPPM = totalUnlocked - initialContributionRegistry[msg.sender.percentageUnlocked
    // -- percentage in ppm that we want to unlock
    // toBeUnlockedPercentage = toBeUnlockedPPM / denominator
    // toBeUnlocked = Percentage * totalAllocated
    uint256 toBeUnlocked = (initialContributions[msg.sender].contributed / initialRaise) * p0 *
        ((totalUnlocked - initialContributions[msg.sender].percentageTokenUnlocked) / denominator);
    // we burn the token previously minted to our account and mint tokens to the hatcher
    _burn(address(this), toBeUnlocked);
    _mint(msg.sender, toBeUnlocked);
  }
}
