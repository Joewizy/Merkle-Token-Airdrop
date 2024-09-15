// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import{IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712{
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    // ERRORS
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    // STATE VARIABLES
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    // define the message hash struct
    struct AirdropClaim{
        address account;
        uint256 amount;
    }
    
    // EVENTS
    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1.0") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32 [] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        if(s_hasClaimed[account] == true){
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // Verify the signature
        if(!_isValidSignature(account, getMessageHash(account, amount), v, r, s)){
            revert MerkleAirdrop__InvalidSignature();
        }

        //calculate using the account and the amount, HASH = LEAF NODE
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)){
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true; // stop users from making multiple claims and exhausting the contract.
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns(bytes32){
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

     /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getMerkleRoot() public view returns(bytes32){
        return i_merkleRoot;
    }

    function getAirdropToken() public view returns(IERC20){
        return i_airdropToken;
    }

     /*//////////////////////////////////////////////////////////////
                             INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _isValidSignature(address signer, bytes32 digest, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (bool){
        (address actualSigner, ,) = ECDSA.tryRecover(digest, _v, _r, _s);
        return (actualSigner == signer);
    }
}