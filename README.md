# Digital Collectibles

A ready to use smart contract to digitalize collectibles on the Blockchain.

## Motivation

Imagine owning a rare trading card, a limited-edition print, or a one-of-a-kind piece of artwork - except it lives entirely in the digital world. That's exactly what a digital collectible on the blockchain is.

At the heart of every digital collectible is a simple but powerful idea: no two items are exactly alike. Each collectible has its own unique identity, like a serial number stamped into it permanently. This identity can never be duplicated, forged, or altered by anyone, not even the original creator.

Here are some of the key features of digital collectibles:
- **Every collectible gets a unique ID**: Think of it like a serial number on a rare banknote. No two digital collectibles share the same ID ever.
- **Ownership is recorded publicly**: The blockchain acts like a giant public ledger. Anyone can look up who owns what, completely transparent and tamper-proof.
- **You can buy, sell, or gift it**: Ownership can be transferred to anyone in the world. When you sell it, the ledger updates automatically without paperwork nor middleman.
- **Each item can carry its own story**: Creators can attach details to each collectible: its name, image, history, and more. This information travels with the item forever.

## Usage

- Clone this repository.
- Make changes to samples/DCCollection.sol to fit your needs.
- Install Foundry from here https://www.getfoundry.sh/.
- Run the `DeployDCCollection.s.sol` script using Forge to deploy it into the blockchain. You will need to set `PRIVATE_KEY`, `COLLECTION_NAME`, `COLLECTION_SYMBOL` environment variables first.
- Run the `ApplyZeroGas.s.sol` script using Forge to apply ZeroGas on Viction. This will need `PRIVATE_KEY`, `COLLECTION_ADDRESS` environment variables and you have at least 10 VIC.
