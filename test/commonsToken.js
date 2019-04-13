// const CommonsToken = artifact.require("CommonsToken");

contract("CommonsToken", accounts => {
  it("some test case", async () => {
  });
});

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
