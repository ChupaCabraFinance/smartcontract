

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Taxable.sol";

contract Chupa is ReentrancyGuard, ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, Taxable{

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE"); // Snapshot is the only role allowed to make a snapshot to count tokens held at a certain block.
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");  // Governor is the only role allowed to enable/disable a tax or change the tax amount.
    bytes32 public constant PRESIDENT_ROLE = keccak256("PRESIDENT_ROLE");  // President is the only role allowed to change the tax destination address.
    bytes32 public constant EXCLUDED_ROLE = keccak256("EXCLUDED_ROLE");   // Any address added to this excluded role will be excluded from taxes, if turned on.

    constructor()
        ERC20("ChupaCabraV2", "CHUPA")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);
        _grantRole(PRESIDENT_ROLE, msg.sender);
        _grantRole(EXCLUDED_ROLE, msg.sender);
        _mint(msg.sender, 13051666666 * 10 ** decimals()); // Mint 10,000 $Chupa to deployer.
    }

/// @dev Add the public function for the SNAPSHOT_ROLE to make a snapshot:

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

/// @dev Add the public functions for the GOVERNOR_ROLE to enable, disable, an update the tax:

    function enableTax() public onlyRole(GOVERNOR_ROLE) {
        _taxon();
    }

    function disableTax() public onlyRole(GOVERNOR_ROLE) {
        _taxoff();
    }

    function updateTax(uint newtax) public onlyRole(GOVERNOR_ROLE) {
        _updatetax(newtax);
    }

/// @dev Add the public function for the PRESIDENT_ROLE to update the tax destination address:

    function updateTaxDestination(address newdestination) public onlyRole(PRESIDENT_ROLE) {
        _updatetaxdestination(newdestination);
    }

/// @dev Override _beforeTokenTransfer() as required by certain contracts. 

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

/// @dev Override the _transfer() function to perform the necessary tax functions:

   function _transfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20) // Specifies only the ERC20 contract for the override.
        nonReentrant // Prevents re-entrancy attacks.
    {
        if(hasRole(EXCLUDED_ROLE, from) || hasRole(EXCLUDED_ROLE, to) || !taxed()) { // If to/from a tax excluded address or if tax is off...
            super._transfer(from, to, amount); // Transfers 100% of amount to recipient.
        } else { // If not to/from a tax excluded address & tax is on...
            require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance"); // Makes sure sender has the required token amount for the total.
            // If the above requirement is not met, then it is possible that the sender could pay the tax but not the recipient, which is bad...
            super._transfer(from, taxdestination(), amount*thetax()/10000); // Transfers tax to the tax destination address.
            super._transfer(from, to, amount*(10000-thetax())/10000); // Transfers the remainder to the recipient.
        }
    }

    function mint(address to, uint256 amount) public onlyRole(PRESIDENT_ROLE) {
        _mint(to, amount);
    }
}
