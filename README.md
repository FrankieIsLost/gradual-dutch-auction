# Gradual Dutch Auction • [![CI](https://github.com/FrankieIsLost/gradual-dutch-auction/actions/workflows/CI.yml/badge.svg)](https://github.com/FrankieIsLost/gradual-dutch-auction/actions/workflows/CI.yml)

An implementation of Continuous and Discrete Gradual Dutch Auctions. GDAs enable better price discovery when selling assets.

This repo contains a sample solidity implementation, as well as python notebook modeling the mechanisms behaviour. Correctness testing between python and solidity versions is done via Forge FFI. 

## Getting Started

```sh
git clone https://github.com/FrankieIsLost/gradual-dutch-auction
cd gradual-dutch-auction
git submodule update --init --recursive  ##initialize submodule dependencies
forge build
forge test --no-match-test FFI ##run non-FFI tests
forge test --match-test FFI --ffi ##run FFI tests
```
