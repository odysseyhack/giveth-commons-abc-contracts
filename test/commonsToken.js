const { BN, constants, expectEvent, shouldFail } = require('openzeppelin-test-helpers');

const CommonsToken = artifacts.require("CommonsToken.sol");
const FundingPoolMock = artifacts.require("FundingPoolMock.sol");
const ReserveTokenMock = artifacts.require("./contracts/vendor/ERC20/ERC20Mintable.sol");

contract("CommonsToken", ([reserveTokenMinter, contractCreator, hatcherOne, hatcherTwo, lateInvestor]) => {
  const reserveRatio = 142857; // kappa ~ 6
  const theta = 350000; // 35% in ppm
  const p0 =  1;
  const initialRaise = 300000;
  const friction = 20000; // 2% in ppm
  const gasPrice = 15000000000; // 15gwei
  const duration = 604800; // 1 week in seconds
  const minimalContribution = 100 // in xDai

  beforeEach(async function() {
    this.fundingPool = await FundingPoolMock.new();
    this.reserveToken = await ReserveTokenMock.new(reserveTokenMinter);
    this.commonsToken = await CommonsToken.new(
      this.reserveToken.address,
      reserveRatio,
      gasPrice,
      theta,
      p0,
      initialRaise,
      this.fundingPool.address,
      friction,
      duration,
      minimalContribution,
      { gas: 10000000 }
    );
    await this.reserveToken.mint(hatcherOne, 10000);
    await this.reserveToken.mint(hatcherTwo, 10000);
  })

  describe('hatchContribute', function () {
    describe('When we are in the hatch phase', function() {
      describe("When we are within the duration deadline", function() {
        describe('When the contribution does not reach the initialRaise', function() {
          const amountToFundExtern = 200;
          describe("When there is sufficient contribution", function() {
            describe('When the commonToken can pull the external token', function() {
              beforeEach(async function() {
                console.log(await this.reserveToken.balanceOf(hatcherOne));
                //  await this.reserveToken.approve(this.reserveToken.address, amountToFundExtern);
                console.log(amountToFundExtern)
                await this.reserveToken.transfer(hatcherTwo, 200, {from: hatcherOne});
                console.log(await this.reserveToken.balanceOf(hatcherOne))
                console.log(await this.reserveToken.balanceOf(hatcherTwo))
              //  await this.commonsToken.hatchContribute(amountToFundExtern, {from: hatcherOne});
              })

              it("Should have increased the total amount raised", async function() {
                let raisedExternal = await this.commonsToken.raisedExternal()
                assert.equal(raisedExternal, amountToFundExtern);
              })

              it("Should have allocated the external tokens to the bonding curve", async function() {
                let externalTokensOwned = await this.reserveToken.balanceOf(this.commonsToken.address);
                assert.equal(externalTokensOwned, amountToFundExtern);
              })

              it("Should have set the initial external contributions for the hatcher", async function() {
                let initialContributions = await this.commonsToken.initialContributions(hatcherOne)[0];
                assert.equal(initialContributions, amountToFundExtern);
              })

              it("Should have set the locked internal tokens for the hatcher", async function() {
                let lockedInternalTokens = await this.commonsToken.initialContributions(hatcherOne)[1];
                assert.equal(lockedInternalTokens, amountToFundExtern * p0);
              })
            })
            describe("When the commonToken cannot pull the reserve token", function() {
              //revert
            })
          })
          describe("When there is no sufficient contribution", function() {

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
      describe("When we are outside the duration deadline", function() {
        //reverts
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

  describe("burn", function() {
    describe("When we are not in the hatching phase", function() {
      describe("When the callee has enough internal tokens", function() {
        // burn tokens
        // transfer 1-friction to the callee in external token to the callee
        // transfer fridction to the funding pool
      })
      describe("When the callee has not enough internal tokens", function() {
        //revert
      })
    })

    describe("When we are in the hatchin phase", function() {
      //reverts
    })
  })

  describe("mint", function() {
    describe("when we are not in the hatching phase", function() {


    })
    describe("When we are in the hatching phase", function() {

    })
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
