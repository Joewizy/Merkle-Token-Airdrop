# Merkle Token Airdrop: Token Creation and Claim System

## Installation
**To get started install both Git and Foundry**

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git): After installation make sure to run *****git --version***** to confirm installation if you see a response like *****git version 2.34.1*****
then it was successful.

- [Foundry](https://getfoundry.sh/): After installation run *****forge --version***** if you see a response like *****forge 0.2.0 (8549aad 2024-08-19T00:21:29.325298874Z)***** then it was successful.

## Clone the repository
```shell
git clone https://github.com/Joewizy/Merkle-Token-Airdrop
cd Merkle-Token-Airdrop
forge install
forge build
```
# Usage

## Pre-Deployment: Generating Merkle Proofs

To airdrop funds, you'll need to generate Merkle proofs for a set of addresses. If you wish to use the default addresses and proofs provided in this repository, you can skip to the [Deploy](#deploy) section.

If you want to use a custom set of addresses (defined in the `whitelist` list within `GenerateInput.s.sol`), follow these steps:

1. **Update Addresses**: Modify the array of addresses in `GenerateInput.s.sol` to include the addresses you want to airdrop funds to.

2. **Generate Input File and Merkle Proofs**:

   - **Using `make`**:
     ```bash
     make merkle
     ```

   - **Using Direct Commands**:
     ```bash
     forge script script/GenerateInput.s.sol:GenerateInput
     forge script script/MakeMerkle.s.sol:MakeMerkle
     ```

3. **Retrieve Merkle Root**:
   - After running the above commands, find the Merkle root (there may be multiple, but they will all be the same) in `script/target/output.json`.
   - For zkSync deployments, paste the root into the `Makefile` as `ROOT`.
   - For Ethereum/Anvil deployments, update the `s_merkleRoot` variable in `DeployMerkleAirdrop.s.sol` with the retrieved root.

# Deploy 

## Deploy to Anvil

```bash
# Run a local anvil node
make anvil
# Then, open a second terminal and run
make deploy
```

## Interacting with deployed contracts using 
Copy the JoewiToken and Airdrop contract addresses and paste them into the `AIRDROP_ADDRESS` and `TOKEN_ADDRESS` variables in the `MakeFile`

The following steps allow the second default anvil address (`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`) to call claim and pay for the gas on behalf of the first default anvil address (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`) which will recieve the airdrop. 

### Sign your airdrop claim  

```bash
# in another terminal
make sign
```

Retrieve the signature bytes outputted to the terminal and add them to `Interact.s.sol` *making sure to remove the `0x` prefix*. 

Additionally, if you have modified the claiming addresses in the merkle tree, you will need to update the proofs in this file too (which you can get from `output.json`)

### Claim your airdrop

Then run the following command:

```bash
make claim
```

### Check claim amount

Then, check the claiming address balance has increased by running
* Get **balanceOf** Default Anvil address after claiming the airdrop.
```shell
cast call 0x8464135c8F25Da09e49BC8782676a84730C318bC "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```
cast call [token address] "[args]" [address to get balanceOf]

### Or you can use

```bash
make balance
```

NOTE: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` is the default anvil address which has recieved the airdropped tokens.


## Test

```shell
$ forge test
```
### Test Coverage
```shell
$ forge coverage
```
To view detailed test coverage reports for your contracts
### Gas Snapshots
You can estimate how much gas things cost by running:

```shell
$ forge snapshot
```
And you'll see an output file called **.gas-snapshot**

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```