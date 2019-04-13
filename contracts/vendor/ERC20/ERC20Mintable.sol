pragma solidity ^0.5.0;

import "../Initializable.sol";
import "../access/roles/MinterRole.sol";

import "./ERC20.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is Initializable, ERC20, MinterRole {
    function initialize(address sender) public initializer {
        MinterRole.initialize(sender);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    uint256[50] private ______gap;
}
