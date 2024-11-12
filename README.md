# Bitcoin Wallet Scanner

A Swift-based Bitcoin wallet scanner that generates random wallets and checks their balances using the blockchain.info API. This tool is designed for educational purposes to demonstrate cryptographic operations and blockchain API interactions.

## Features

- Generates random Bitcoin addresses using CryptoKit
- Checks wallet balances using blockchain.info API
- Saves results to separate files:
  - `found_wallets.txt`: Wallets with positive balance
  - `empty_wallets.txt`: Empty wallets (address only)
  - `empty_wallets_with_pkey.txt`: Empty wallets with private keys
- Rate limit handling with automatic retry
- Multi-threaded scanning capability
- Progress tracking with real-time console output
- Robust error handling and retry mechanism

## Requirements

- macOS 12.0 or later
- Swift 5.5 or later
- Required Swift packages:
  - CryptoKit
  - RIPEMD160
  - BigInt

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/bitcoin-wallet-scanner.git
cd bitcoin-wallet-scanner
```

## Usage

1. Build the project:
```bash
swift build -c release
```

2. Run the scanner:
```bash
swift run BTCScanner
```

You can specify the number of threads when running the scanner:
```swift
let scanner = BTCScanner(numThreads: 12)
```

### Output Files

The scanner generates three types of output files:

- `found_wallets.txt`:
```
YYYY-MM-DD HH:mm:ss | Bitcoin Address | Private Key | Balance BTC
```

- `empty_wallets.txt`:
```
Bitcoin Address
```

- `empty_wallets_with_pkey.txt`:
```
Bitcoin Address | Private Key
```

### Console Output

The scanner provides real-time feedback with the following indicators:
- ✓ Checked: Successfully scanned address
- 💰 Found: Discovered wallet with positive balance
- ❌ Error: API or network error
- ⏳ Rate limit: Default 60 second cooldown down due to API rate limit

## Implementation Details

### Key Components

1. **SharedState Actor**: Manages thread-safe state tracking
2. **BTCScanner Class**: Main implementation including:
   - Bitcoin address generation
   - Balance checking via API
   - Multi-threaded scanning
   - File I/O operations

### Security Features

- Uses secure random number generation for private keys
- Implements standard Bitcoin address generation algorithm
- Handles API responses securely
- Implements rate limiting and retry mechanism

## API Usage

The scanner uses the blockchain.info API to check wallet balances:
```
https://api.blockchain.info/haskoin-store/btc/address/{address}/balance
```

Rate limiting is implemented with:
- Maximum 3 retry attempts
- 60-second cooldown between retries
- User-Agent header to identify requests

## Best Practices

1. Adjust `numThreads` based on your system capabilities
2. Monitor API rate limits and adjust timeout values if needed
3. Regularly backup output files

## Disclaimer

This tool is for educational purposes only. Please be aware that:
- Randomly generating Bitcoin addresses has an extremely low probability of finding active wallets
- Excessive API requests may result in IP blocking
- Always respect API rate limits and terms of service

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Acknowledgments

- blockchain.info for their API service
