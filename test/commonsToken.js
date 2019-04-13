const { BN, constants, expectEvent, shouldFail } = require('openzeppelin-test-helpers');

const CommonsToken = artifacts.require("CommonsToken.sol");
const FundingPoolMock = artifacts.require("FundingPoolMock.sol");
const ReserveTokenMock = artifacts.require("./contracts/vendor/ERC20/ERC20.sol");

contract("CommonsToken", ([reserveTokenMinter, contractCreator, hatcherOne, hatcherTwo, lateInvestor]) => {
  const reserveRatio = 142857; // kappa ~ 6
  const theta = 350000; // 35% in ppm
  const p0 =  1;
  const initialRaise = 300000;
  const friction = 20000; // 2% in ppm
  const gasPrice = 15000000000; // 15gwei
  beforeEach(async function() {
    this.fundingPool = await FundingPoolMock.new();
    this.reserveToken = await ReserveTokenMock.new(reserveTokenMinter)
    this.commonsToken = await CommonsToken.new(
      this.reserveToken.address,
      gasPrice,
      theta,
      p0,
      initialRaise,
      this.fundingPool.address,
      friction
    )
  })
  describe('hatchContribute', function () {
    describe('When we are in the hatch phase', function() {
      describe('When the contribution does not reach the initialRaise', function() {
        describe('When the commonToken can pull the reserve token', function() {
          // increase raised
          // pull reservetoken from the contributer to our account
          // set the initialContributions for the hatcher
          // mint bonding curve tokens to the bondingcurve contract
        })
        describe("When the commonToken cannot pull the reserve token", function() {
          //revert
        })
      })
      describe("When the contribution reaches the initial raise", function() {
        // increase raised
        // pull reservetoken from the contributer to our account
        // set the initialContributions for the hatcher
        // mint bonding curve tokens to the bondingcurve contract
      })
      describe("When the contribution reaches over the initial raise", function() {
        // increase raised
        // pull reservetoken from the contributer to our account
        // set the initialContributions for the hatcher
        // mint bonding curve tokens to the bondingcurve contract
      })
    })
    describe("When we are not in the hatch phase", function() {

    })
  });

  describe("fundsAllocated", function() {
    describe("When the sender is the fundingPool", function() {
      describe("When we have not yet allocated all the initial funds", function() {
        describe("When we don't allocate all the initial funds", function() {
          //totalUnlocked increases to less than 100%
        })
        describe("When we allocate all the initial funds", function() {
          //totalUnlocked 100%

        })
        describe("When we allocate more than the initial funds", function() {
          //totalUnlocked 100%
        })
      })

    })
    describe("When the sender is not the fundingPool", function() {
      //reverts

    })
  })

// scenarios
// 1. Init
// // D0, P0, Theta -> show what curve looks like + initialRaise value (calculated)
// 2. PostMVP: Hatch Params
// // minimum hatcher contribution, hatch sale deadline
// 3. PostMVP: Init
// // Exit Fee %

// TODO:
// Initialization
// - initialization w/ correct values, verify math works & values are set properly
// - initialization w/ bunk values, verify all assertion cases are working
// - make sure funding & reserve pool are setup correctly
// - make sure no owns any of the tokens
// - verify it's in hatch phase
// Hatch
// - minimum hatch contribution is honored
// - hatch threshold is correct
// - we can purchase amount of tokens
// - we can calculate what our token amount will be give some DAI
// - price changes appropriately
// - if we reach the threshold, hatchphase -> openphase
// - if we reach threshold, money is sent to the funding pool
// - - test for "spillover"
// - verify we can't sell anything
// - calculating "return"
// OpenPhase
// - TODO: vesting, fees, buying, selling
