# Decentralized Crowdfunding Platform

A blockchain-based crowdfunding platform built with Solidity that enables transparent, trustless fundraising campaigns with automatic fund distribution and refund mechanisms.

## 🌟 Features

### Core Functionality
- **Campaign Creation**: Users can create fundraising campaigns with customizable goals and deadlines
- **Secure Contributions**: Contributors can fund campaigns with automatic tracking
- **Automatic Fund Distribution**: Successful campaigns trigger automatic fund release to creators
- **Refund System**: Failed campaigns automatically enable refunds for all contributors
- **Platform Fees**: Configurable platform fee system for sustainability

### Security Features
- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard
- **Access Control**: Role-based permissions with Ownable pattern
- **Input Validation**: Comprehensive parameter validation
- **Emergency Controls**: Owner emergency withdrawal capabilities

## 🚀 Getting Started

### Prerequisites
- Node.js (v16+ recommended)
- Hardhat or Truffle
- MetaMask or similar Web3 wallet
- OpenZeppelin Contracts v4.7+

### Installation

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd crowdfunding-platform
```

2. **Install dependencies**
```bash
npm install
```

3. **Install OpenZeppelin contracts**
```bash
npm install @openzeppelin/contracts
```

### Deployment

1. **Compile the contract**
```bash
npx hardhat compile
```

2. **Deploy to local network**
```bash
npx hardhat run scripts/deploy.js --network localhost
```

3. **Deploy to testnet (e.g., Sepolia)**
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

## 📋 Contract Overview

### Main Contract: `CrowdfundingPlatform`

#### Key Structures
```solidity
struct Campaign {
    address payable creator;
    string title;
    string description;
    uint256 goalAmount;
    uint256 raisedAmount;
    uint256 deadline;
    bool isActive;
    bool goalReached;
    bool fundsWithdrawn;
    uint256 contributorCount;
}
```

#### Core Functions

| Function | Description | Access |
|----------|-------------|---------|
| `createCampaign()` | Create a new fundraising campaign | Public |
| `contribute()` | Contribute ETH to a campaign | Public |
| `withdrawFunds()` | Withdraw funds from successful campaign | Creator only |
| `requestRefund()` | Request refund from failed campaign | Contributors |
| `cancelCampaign()` | Cancel campaign (no contributions only) | Creator only |

## 🎯 Usage Examples

### Creating a Campaign
```solidity
// Create a 30-day campaign with 10 ETH goal
createCampaign(
    "Save the Ocean",
    "Help us clean up ocean plastic waste",
    10 ether,
    30  // 30 days
);
```

### Contributing to a Campaign
```solidity
// Contribute 1 ETH to campaign ID 0
contribute{value: 1 ether}(0);
```

### Withdrawing Funds (Successful Campaign)
```solidity
// Creator withdraws funds after goal is reached
withdrawFunds(0);
```

### Requesting Refund (Failed Campaign)
```solidity
// Contributor requests refund after deadline passes
requestRefund(0);
```

## 🔧 Configuration

### Platform Fee
- **Default**: 2.5% (250 basis points)
- **Maximum**: 10% (1000 basis points)
- **Adjustable**: Only by contract owner

```solidity
// Set platform fee to 1.5%
setPlatformFee(150);
```

### Campaign Duration Limits
- **Minimum**: 1 day
- **Maximum**: 365 days

## 📊 Events

The contract emits the following events for frontend integration:

```solidity
event CampaignCreated(uint256 indexed campaignId, address indexed creator, string title, uint256 goalAmount, uint256 deadline);
event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount, uint256 totalRaised);
event CampaignFunded(uint256 indexed campaignId, uint256 totalAmount);
event FundsWithdrawn(uint256 indexed campaignId, address indexed creator, uint256 amount, uint256 platformFee);
event RefundIssued(uint256 indexed campaignId, address indexed contributor, uint256 amount);
event CampaignCancelled(uint256 indexed campaignId, address indexed creator);
```

## 🛡️ Security Considerations

### Implemented Protections
- **Reentrancy Guard**: Prevents reentrancy attacks on fund transfers
- **Access Control**: Function-level permissions
- **Input Validation**: Comprehensive parameter checking
- **Integer Overflow**: Uses Solidity 0.8+ built-in protection

### Best Practices
- Always check campaign status before interacting
- Verify deadlines and goal amounts
- Monitor events for state changes
- Use proper error handling in frontend integration

## 🧪 Testing

### Run Tests
```bash
npx hardhat test
```

### Test Coverage
```bash
npx hardhat coverage
```

### Example Test Cases
- Campaign creation with various parameters
- Contribution scenarios (success/failure)
- Fund withdrawal after goal reached
- Refund processing after deadline
- Edge cases and error conditions

## 📱 Frontend Integration

### Web3 Integration Example
```javascript
// Connect to contract
const contract = new ethers.Contract(contractAddress, abi, signer);

// Create campaign
await contract.createCampaign("Title", "Description", ethers.utils.parseEther("10"), 30);

// Contribute to campaign
await contract.contribute(campaignId, { value: ethers.utils.parseEther("1") });

// Listen for events
contract.on("ContributionMade", (campaignId, contributor, amount, totalRaised) => {
    console.log(`New contribution: ${ethers.utils.formatEther(amount)} ETH`);
});
```

## 🌐 Network Deployment

### Mainnet Considerations
- **Gas Optimization**: Consider batch operations for multiple contributions
- **Fee Structure**: Review platform fees for mainnet economics
- **Upgrades**: Consider proxy patterns for future upgrades

### Testnet Addresses
- **Sepolia**: `0x...` (Add after deployment)
- **Goerli**: `0x...` (Add after deployment)
- **Mumbai**: `0x...` (Add after deployment)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Solidity style guide
- Add comprehensive tests for new features
- Update documentation
- Ensure gas optimization

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Resources

- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Ethereum Development](https://ethereum.org/developers/)

## ⚠️ Disclaimer

This smart contract is provided for educational and development purposes. Always conduct thorough testing and security audits before deploying to mainnet with real funds

![image](https://github.com/user-attachments/assets/8c72e948-fa56-4a76-991a-55db52384cdf)
