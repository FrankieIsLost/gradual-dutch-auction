# Gradual Dutch Auction • [![CI](https://github.com/FrankieIsLost/gradual-dutch-auction/actions/workflows/CI.yml/badge.svg)](https://github.com/FrankieIsLost/gradual-dutch-auction/actions/workflows/CI.yml)

An reference implementation of Gradual Dutch Auctions. GDAs enable the efficient sale of assets that do not have liquid markets.
  
This repo contains implementations of both discrete GDAs, which are useful for selling NFTs, and continuous GDAs, which are useful for selling fungible tokens. We also include a python notebook modeling the mechanisms behaviour.

## Getting Started

```sh
git clone https://github.com/FrankieIsLost/gradual-dutch-auction
cd gradual-dutch-auction
git submodule update --init --recursive  ##initialize submodule dependencies
forge build
```

## Testing 

This repo utilizes forge FFI (foreign function interfaces) for correctness testing. In this case, FFI tests compute GDA prices in Soldity, and the call out to a python script which implements the same logic, to ensure price parity. FFI tests need elevated permissions to run. 

In order to run non-ffi tests, you can run the following command: 

```
forge test --no-match-test FFI
```

To run ffi tests, run the following: 

```
forge test --match-test FFI --ffi 
```
