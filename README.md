# Bitcoin Wallet Scanner

A Swift-based Bitcoin wallet scanner that generates random wallets and checks their balances.

## Features

- Generates random Bitcoin addresses using CryptoKit
- Checks wallet balances using blockchain.info API
- Saves results to separate files:
  - `found_wallets.txt`: Wallets with positive balance
  - `empty_wallets.txt`: Empty wallets (address only)
  - `empty_wallets_with_pkey.txt`: Empty wallets with private keys
- Rate limit handling with automatic retry
- Multi-threaded scanning capability

## Requirements

- macOS 12.0 or later
- Swift 5.5 or later

## Installation

1. Clone the repository: 