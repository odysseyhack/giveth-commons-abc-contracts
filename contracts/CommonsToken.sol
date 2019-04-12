pragma solidity ^0.4.25;

import "./ERC20BondingToken.sol";

contract CommonsToken is ERC20BondingToken {

  address _reserveToken,
  uint32 _reserveRatio,
  uint256 _theta,
  uint256 _p0,
  uint256 _initialRaise,
  address _fundingPool,
  uint256 _friction
  uint256 _gasPrice

  function initialize(
      ERC20 _reserveToken,
      uint32 _reserveRatio,
      uint256 _theta,
      uint256 _p0,
      uint256 _initialRaise,
      address _fundingPool,
      uint256 _friction
      uint256 _gasPrice
  ) initializer public {
    ERC20BondingToken.initialize(
        _reserveToken,
        _reserveRatio,
        _theta,
        _p0,
        _initialRaise,
        _fundingPool,
        _friction,
        _gasPrice
    );
  }

  function mint(uint256 amount) public {
    require(!isInHatchingPhase);
    _curvedMint(amount);
  }

  function burn(uint256 amount) public {
    require(!isInHatchingPhase);
    _curvedBurn(amount);
  }

  function hatchContribute(uint256 value) public {
      require(isInHatchingPhase);
      uint256 contributed;
      if(raised < initialRaise) {
          contributed = value;
          raised += contributed;
          // we call the DAI contract and try to pull DAI to this contract. Reverts if there is no approval.
          reserveToken.transferFrom(msg.sender, address(this), contributed);
      } else {
          contributed = initialRaised - raised;
          raised = initialRaise;
          isInHatchingPhase = false;
          // we call the DAI contract and try to pull DAI to this contract. Reverts if there is no approval.
          reserveToken.transferFrom(msg.sender, address(this), contributed);
          // once we reached the hatch phase, we allow the fundingPool to pull theta times the balance into their control. 1 - theta is reserve
          reserveToken.approve(fundingPool, reserveToken.balanceOf(address(this)) * (theta / DENOMINATOR));
      }
      // we mint to our account. Theoretically, the price is increasing (up to P1), but since we are in the hatching phase, the actual price stays P0
      uint256 amountToMint = calculateCurvedMintReturn(contributed);
      _mint(address(this).balance, amountToMint);
      initialContributions[msg.sender].contributed += contributed;
  }

  function fundsAllocated(uint value) public {
      require(!isInHatchingPhase);
      require(msg.sender == fundingPool);
      //TODO: now, we unlock based on 1 / 1 proportion. This could also be another proportion: i.e. 100.000 funds spend => 50000 worth of funds unlocked
      // we should only update the total unlocked when it is less than 100%
      if(totalUnlocked < DENOMINATOR) {
        totalUnlocked += (value * DENOMINATOR / initialRaise);
      }
  }

  function claimTokens() public {
      require(!isInHatchingPhase);
      require(initialContributions[msg.sender].contributed != 0);
      require(initialContributions[msg.sender].percentageTokenUnlocked < totalUnlocked);
      // allocationPercentage = (initialContributions[msg.sender].contributed / initialRaise) == percentage of the total contribution during the hatch phase of the msg.sender
      // totalAllocated = allocationPercentage * p0 == total tokens allocated to hatcher (locked + unlocked)
      // toBeUnlockedPPM = totalUnlocked - initialContributionRegistry[msg.sender.percentageUnlocked == percentage in ppm that we want to unlock
      // toBeUnlockedPercentage = toBeUnlockedPPM / DENOMINATOR
      // toBeUnlocked = Percentage * totalAllocated
      uint256 toBeUnlocked = (initialContributions[msg.sender].contributed / initialRaise) * p0 *
          ((totalUnlocked - initialContributionRegistry[msg.sender.percentageUnlocked]) / DENOMINATOR);
      // we burn the token previously minted to our account and mint tokens to the hatcher
      _burn(balanceOf(address(this)), toBeUnlocked)
      _mint(msg.sender, toBeUnlocked);
    }
}
