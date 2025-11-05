>  Blockchain-based solution for transparent and secure mining rights management

## 🌟 Overview

MineRight is a revolutionary decentralized platform built on Stacks blockchain that transforms how mining claims are registered, verified, and managed. Using Clarity smart contracts, we solve critical issues in the mining industry including fraudulent claims, overlapping land rights, and royalty disputes.

## ✨ Key Features

- 🗺️ **GPS-Linked NFT Claims**: Each mining right is represented as an NFT with precise GPS coordinates
- 🌍 **Environmental Compliance**: Community-driven scoring system for environmental impact
- 💰 **Automated Royalties**: Smart contract-based royalty distribution system  
- 🤝 **Multi-Signature Licensing**: Government and local body approval requirements
- 🔄 **Claim Trading**: Transfer mining rights between parties securely
- ⏰ **Time-Based Claims**: Automatic expiry and extension mechanisms
- 🏠 **Claim Leasing**: Temporary rental system for flexible claim utilization
- 🛒 **Decentralized Marketplace**: Peer-to-peer trading platform for mining claims

## 🏗️ Contract Functions

### 📝 Claim Registration
```clarity
(register-claim latitude longitude area-hectares mineral-type royalty-rate)
```
Register a new mining claim with GPS coordinates and mineral specifications.

### ✅ Approval System
```clarity
(approve-claim-government claim-id)
(approve-claim-local-body claim-id)
```
Multi-signature approval from government and local authorities.

### 🌱 Environmental Compliance
```clarity
(vote-compliance claim-id score)
(update-compliance-score claim-id new-score)
```
Community voting and scoring for environmental compliance (0-100 scale).

### 💸 Royalty Management
```clarity
(deposit-royalty claim-id amount)
(withdraw-royalty claim-id amount)
```
Automated royalty deposit and withdrawal system.

### 🔄 Claim Operations
```clarity
(transfer-claim claim-id new-owner)
(extend-claim claim-id additional-blocks)
(revoke-claim claim-id)
```
Transfer ownership, extend validity, or revoke claims.

### 🏠 Claim Leasing
```clarity
(create-lease claim-id lessee duration-blocks rent-per-block)
(pay-lease-rent claim-id)
(terminate-lease claim-id)
```
Lease mining claims to other users with automated rent collection.

### 🛒 Decentralized Marketplace
```clarity
(list-claim-for-sale claim-id price)
(buy-claim listing-id)
(cancel-listing listing-id)
```
Peer-to-peer marketplace for buying and selling mining claims with instant settlement.

## � Usage Instructions

### 🚀 Getting Started

1. **Setup Clarinet Environment**
   ```bash
   clarinet new mining-project
   cd mining-project
   ```

2. **Deploy the Contract**
   ```bash
   clarinet deploy
   ```

3. **Register Your First Claim**
   ```clarity
   (contract-call? .mining-claims register-claim 
     40750000    ;; Latitude (40.75° * 1000000)
     -73980000   ;; Longitude (-73.98° * 1000000)
     u100        ;; 100 hectares
     "gold"      ;; Mineral type
     u50)        ;; 5% royalty rate (50/1000)
   ```

### 🔍 Query Functions

```clarity
;; Get claim details
(contract-call? .mining-claims get-claim u1)

;; Check approval status
(contract-call? .mining-claims get-claim-approvals u1)

;; View compliance score
(contract-call? .mining-claims get-compliance-score u1)

;; Check coordinate conflicts
(contract-call? .mining-claims check-coordinate-overlap 40750000 -73980000)
```

## 🎯 Use Cases

- 🏢 **Mining Companies**: Register and manage claims transparently
- 🏛️ **Government Agencies**: Approve and oversee mining operations
- 🌱 **Environmental Groups**: Monitor and score compliance
- 🏘️ **Local Communities**: Participate in governance decisions
- 👥 **Investors**: Trade mining rights as tokenized assets
- 👤 **Claim Owners**: Lease claims for additional revenue streams
- 🛒 **Traders**: Buy and sell mining claims on the decentralized marketplace

## 🔧 Technical Specifications

- **Blockchain**: Stacks (Bitcoin Layer 2)
- **Language**: Clarity Smart Contracts
- **Coordinate System**: GPS coordinates (latitude/longitude × 1,000,000)
- **Royalty Precision**: Basis points (1/1000th percent)
- **Compliance Scale**: 0-100 scoring system
- **Default Claim Duration**: ~1 year (52,560 blocks)
- **Lease Duration**: Block-based timing system
- **Rent Precision**: Per-block STX payments
- **Marketplace Settlement**: Instant STX transfers for claim purchases

## 🛡️ Security Features

- ✅ Coordinate overlap prevention
- ✅ Multi-signature approval requirements  
- ✅ Access control for sensitive operations
- ✅ Input validation and bounds checking
- ✅ Error handling with descriptive codes

## 📊 Error Codes

| Code | Description |
|------|-------------|
| u1   | Unauthorized access |
| u2   | Claim not found |
| u3   | Coordinate already claimed |
| u4   | Invalid GPS coordinates |
| u5   | Insufficient approvals |
| u6   | Invalid compliance score |
| u7   | Claim not active |
| u8   | Invalid royalty rate |
| u15  | Invalid lease duration |
| u16  | Invalid rent rate |
| u17  | No rent due |
| u18  | Invalid marketplace price |

## 🤝 Contributing

We welcome contributions! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

*Built with ❤️ on Stacks blockchain for a more transparent mining industry*
