# Cryptopaws Smart Contracts

Smart contracts for the Cryptopaws platform, handling donations and organization management on the blockchain.

## Prerequisites

- Foundry (forge, anvil, cast)
- Node.js (for testing)
- Git

## Installation

```bash
# Clone the repository
git clone https://github.com/MeowDev9/Cryptopaws-Smart-Contracts.git

# Install dependencies
forge install
```

## Project Structure

```
contracts/
├── src/                # Source files
│   ├── DonationContract.sol    # Main donation contract
│   └── ...
├── test/              # Test files
├── script/            # Deployment scripts
└── lib/              # Dependencies
```

## Contracts

### DonationContract.sol
The main contract that handles:
- Organization registration
- Donation processing
- Donation tracking
- Organization status management

## Development

### Compile Contracts
```bash
forge build
```

### Run Tests
```bash
forge test
```

### Deploy Contracts
```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
```

## Testing

Run the test suite:
```bash
forge test -vv
```

## Security

This project uses:
- OpenZeppelin contracts for security
- Foundry for testing and deployment
- Solidity best practices

## License

MIT License
