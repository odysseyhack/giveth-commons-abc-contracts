
let reserveRatio = 142857; // kappa ~ 6
let _theta = 350000 // 35% in ppm
let _p0 =  1
let _initialRaise = 300000
address _fundingPool
uint256 _friction,
uint256 _gasPrice

var reserveToken = artifacts.require("openzeppelin-eth/contracts/token/ERC20/ERC20.sol");
var CommonsToken = artifacts.require("./CommonsToken.sol");

module.exports = function(deployer) {
  deployer.deploy(CommonsToken, );
};
