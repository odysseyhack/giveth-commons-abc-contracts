const ReserveTokenMock = artifacts.require("ERC20Mintable");
const CommonsToken = artifacts.require("CommonsToken");
const FundingPoolMock = artifacts.require("FundingPoolMock");

const reserveRatio = 142857; // kappa ~ 6
const theta = 350000; // 35% in ppm
const p0 =  1;
const initialRaise = 300000;
const friction = 20000; // 2% in ppm
const gasPrice = 15000000000; // 15gwei


module.exports = async function(deployer, networks, accounts) {
  await deployer.deploy(FundingPoolMock);
  FundingPoolMockInstance = await FundingPoolMock.deployed();

  await deployer.deploy(ReserveTokenMock, accounts[0]);
  ReserveTokenMockInstance = await ReserveTokenMock.deployed();

console.log(FundingPoolMockInstance.address)
  await deployer.deploy(CommonsToken,
    ReserveTokenMockInstance.address,
    reserveRatio,
    gasPrice,
    theta,
    p0,
    initialRaise,
    FundingPoolMockInstance.address,
    friction
    );
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
