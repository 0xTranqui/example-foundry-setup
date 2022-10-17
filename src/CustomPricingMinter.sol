// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {ERC721DropMinterInterface} from "./ERC721DropMinterInterface.sol";

/**
 * 
 * @author max@ourzora.com
 *
 */

contract CustomPricingMinter is 
    Ownable
{

    // ERRORS
    error WrongPrice();
    error MinterNotAuthorized();

    // EVENTS
    event NonBundleMint (
        address minter,
        uint256 quantity,
        uint256 totalPrice
    );

    event BundleMint (
        address minter,
        uint256 quantity,
        uint256 totalPrice
    );

    event NonBundlePerTokenPriceUpdated (
        address owner,
        uint256 newPrice
    );

    event BundlePerTokenPriceUpdated (
        address owner,
        uint256 newPrice
    );

    event BundleQuantityUpdated (
        address owner,
        uint256 newQuantity
    );        

    // CONSTANTS
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");

    // VARIABLES
    uint256 public nonBundlePerTokenPrice;
    uint256 public bundlePerTokenPrice;
    uint256 public bundleQuantity;

    // CONSTRUCTOR
    constructor(
        uint256 _nonBundlePerTokenPrice,
        uint256 _bundlePerTokenPrice, 
        uint256 _bundleQuantity 
    ) {

        nonBundlePerTokenPrice = _nonBundlePerTokenPrice;
        bundlePerTokenPrice = _bundlePerTokenPrice;
        bundleQuantity = _bundleQuantity;
    }

    // MINTING FUNCTIONALITY
    function flexibleMint(
        // address of Minting Module
        address customPricingMinter,
        // address of ZORA collection to target
        address zoraDROP, 
        // address of dsired recipient of minted tokens
        address mintRecipient,
        // quantity of tokens to mint
        uint256 quantity
        ) external payable {

        if (                    
            !ERC721DropMinterInterface(zoraDROP).hasRole(MINTER_ROLE, customPricingMinter)
            
        ) {
            revert MinterNotAuthorized();
        }


        // check to see if quantity is less than bundle quantity
        //  if so, price per mint = nonBundlePrice

        if (quantity < bundleQuantity) {

            uint256 totalPrice = quantity * nonBundlePerTokenPrice;        

            if (msg.value != totalPrice) {

                revert WrongPrice();
            } 
            ERC721DropMinterInterface(zoraDROP).adminMint(mintRecipient, quantity);

            emit BundleMint(msg.sender, quantity, totalPrice);
        }

        // this contains the bundle pricing logic 
        if (msg.value != bundlePerTokenPrice * quantity) {
            revert WrongPrice();
        } 
        ERC721DropMinterInterface(zoraDROP).adminMint(mintRecipient, quantity);

        emit BundleMint(msg.sender, quantity, bundlePerTokenPrice * quantity);
    }

    // ADMIN FUNCTIONS
    function setNonBundlePerTokenPrice(uint256 _newPrice) public onlyOwner {
        nonBundlePerTokenPrice = _newPrice;

        emit NonBundlePerTokenPriceUpdated(msg.sender, _newPrice);
    } 

    function setBundlePerTokenPrice(uint256 _newPrice) public onlyOwner {
        bundlePerTokenPrice = _newPrice;

        emit BundlePerTokenPriceUpdated(msg.sender, _newPrice);
    }

    function setBundleQuantity(uint256 _newQuantity) public onlyOwner {
        bundleQuantity = _newQuantity;

        emit BundleQuantityUpdated(msg.sender, _newQuantity);
    }         

    // VIEW FUNCTIONS
    function fullBundlePrice() external view returns (uint256) {
        return bundlePerTokenPrice * bundleQuantity;
    }

}
