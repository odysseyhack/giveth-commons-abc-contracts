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

  await deployer.deploy(CommonsToken,
    ReserveTokenMockInstance.address,
    reserveRatio,
    gasPrice,
    theta,
    p0,
    initialRaise,
    FundingPoolMockInstance.address,
    friction, {gas: 10000000}
    );
};
