
let reserveRatio = 142857; // kappa ~ 6
let theta = 350000 // 35% in ppm
let p0 =  1
let initialRaise = 300000
let fundingPool // tbd
let friction = 20000 // 2% in ppm
let gasPrice = 15000000000 // 15gwei

var ReserveTokenMock = artifacts.require("ERC20Mintable");
var CommonsToken = artifacts.require("CommonsToken");
var FundingPoolMock = artifacts.require("FundingPoolMock");

module.exports = async function(deployer) {
  let fundingPool = await deployer.deploy(FundingPoolMock)
  let reserveToken = await deployer.deploy(ReserveTokenMock)
  await deployer.deploy(CommonsToken, reserveToken.address, reserveRatio, theta, p0, initialRaise, fundingPool.address, friction, gasPrice);
};


//
// deployer.deploy(HoldingRole).then(function(holdingRoleInstance) {
//     let holdingRoleAddress = holdingRoleInstance.address
//     return deployer.deploy(Treasury, holdingRoleAddress).then(function(treasuryInstance) {
//       let treasuryAddress = treasuryInstance.address
//       return deployer.deploy(SubsidiaryRegistry, treasuryAddress, holdingRoleAddress, defaultZeroBalance).then(function(subsidiaryRegistryInstance) {
//         let subsidiaryRegistryAddress = subsidiaryRegistryInstance.address
//         return deployer.deploy(Settlement, treasuryAddress, subsidiaryRegistryAddress, holdingRoleAddress).then(function(settlementInstance) {
//           let settlementAddress = settlementInstance.address
//           return deployer.deploy(IntercompanyPurchaseOrders, treasuryAddress, subsidiaryRegistryAddress, holdingRoleAddress).then(function(intercompanyPurchaseOrdersInstance) {
//             let intercompanyPurchaseOrdersAddress= intercompanyPurchaseOrdersInstance.address
//             treasuryInstance.addTrustedContract(settlementAddress)
//             treasuryInstance.addTrustedContract(subsidiaryRegistryAddress)
//             return
