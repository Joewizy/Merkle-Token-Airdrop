// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import{Test, console} from "forge-std/Test.sol";
import{JoewiToken} from "../src/JoewiToken.sol";
import{MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import{DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import{IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import{MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import{ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test{
    JoewiToken token;
    MerkleAirdrop airdrop;
    address user;
    address public gasPayer;
    uint256 userPrivatKey;

    bytes32 ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 AMOUNT_TO_CLAIM = (25 * 1e18); // 25 JoewiToken
    uint256 AMOUNT_TO_MINT = AMOUNT_TO_CLAIM * 4;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [proofOne, proofTwo ];
    
    function setUp() public{
        if(!isZkSyncChain()){
            // If not ZkSynChain then deploy with script
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
        token = new JoewiToken();
        airdrop = new MerkleAirdrop(ROOT, token);
        token.mint(token.owner(), AMOUNT_TO_MINT);
        token.transfer(address(airdrop), AMOUNT_TO_MINT);
        }
        gasPayer = makeAddr("gasPayer");
        (user, userPrivatKey) = makeAddrAndKey("user");
        console.log("User address:", user);
        console.log("Joewi token address:", address(token));
    }

    function signMessage(uint256 userPrivatKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s){
        bytes32 hashedMessage = airdrop.getMessageHash(account, AMOUNT_TO_CLAIM);
        (v, r, s) = vm.sign(userPrivatKey,hashedMessage );
    }  

    function testClaim() public {
        uint256 startingBalance = token.balanceOf(user);

        // get the signature
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivatKey, user);
        vm.stopPrank();

        // The user paying the gas (gasPayer) calls the claim function
        vm.startPrank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof, v, r, s);
        
        uint256 endingBalance = token.balanceOf(user);
        console.log("Starting Balance:", startingBalance);
        console.log("Ending Balance:", endingBalance);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM); 
    }

    function testUsersCannotClaimTwice() public {
        // get the signature
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivatKey, user);
        vm.stopPrank();

        // The user paying the gas (gasPayer) calls the claim function
        vm.startPrank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof, v, r, s);
        // gasPayer tries to claim airdrop again for user should revert
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof, v, r, s);
    }

     function testOnlySignedUsersCanClaim() public {
        uint8 v;
        bytes32 r; 
        bytes32 s;
        // get the signature
        vm.startPrank(user);
        vm.stopPrank();

        // The user paying the gas (gasPayer) tires to claim for user with user approving
        vm.startPrank(gasPayer);
        // would revert because user did not sign the key for gasPayer to claim airdrop
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof, v, r, s);
    }
}