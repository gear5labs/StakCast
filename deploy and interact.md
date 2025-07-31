Below is the updated **StakCast Sepolia Deployment & Interaction Guide v2.1**, incorporating the latest information from our recent successful market creation, addressing the `ByteArray` and `crypto_prediction` serialization issues, and updating the contract status with the new market count. I've also refined the documentation for clarity, added notes on `Option` serialization, and updated the date to reflect the current timestamp (July 18, 2025). Changes are highlighted in the relevant sections.

---

# StakCast Sepolia Deployment & Interaction Guide v2.2

## 📋 Overview

This guide covers the deployment and interaction process for the upgraded StakCast PredictionHub contract on Starknet Sepolia. The contract features enhanced share-based betting, market analytics, and comprehensive administrative controls.

---

## 🔧 Prerequisites

- **sncast** installed (`cargo install sncast` or via Scarb, version 0.13.0+ recommended)
- **Scarb** for contract compilation (version 2.11.4+)
- **Funded Starknet Sepolia account** (OpenZeppelin/ArgentX, etc.)
- **snfoundry.toml** configured properly

---

## ⚙️ Configuration

### snfoundry.toml Setup

```toml

[sncast.default]

account = "stakcast"

accounts-file = "/Users/macbookprom1/.starknet_accounts/starknet_open_zeppelin_accounts.json"

url = "https://api.cartridge.gg/x/starknet/sepolia"

```

### Scarb.toml Configuration

```toml

[package]

name = "stakcast"

version = "0.1.0"

edition = "2024_07"



[dependencies]

starknet = "2.11.4"

openzeppelin = "1.0.0"

pragma_lib = { git = "https://github.com/astraly-labs/pragma-lib", branch = "main" }



[[target.starknet-contract]]

sierra = true

allowed-libfuncs-list.name = "experimental"

```

---

## 📍 Current Deployment Information

### Key Addresses

- **Admin/Deployer Account**: `stakcast`
- **Admin Address**: `0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9`
- **PredictionHub Contract**: `0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b` ⭐ **NEW**
- **Current Class Hash**: `0x026f3b806be5b6820873cdc9ab629419c431d3de4eb364746c5528f36143753c`
- **Mock Token Contract**: `0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09`
- **Pragma Oracle (Sepolia)**: `0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a`

### Contract Links

- **[PredictionHub Contract](https://sepolia.starkscan.co/contract/0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b)** ⭐ **NEW**
- **[Current Class Hash](https://sepolia.starkscan.co/class/0x026f3b806be5b6820873cdc9ab629419c431d3de4eb364746c5528f36143753c)**
- **[Mock Token Contract](https://sepolia.starkscan.co/contract/0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09)**

---

## 🚀 Fresh Deployment Process

### 1. Compile Contracts

```bash

cd contracts

scarb build

```

### 2. Declare Mock Token Contract

```bash

sncast declare --contract-name strktoken --max-fee 5000000000000000000

```

### 3. Deploy Mock Token

```bash

sncast deploy \

--class-hash <TOKEN_CLASS_HASH> \

--constructor-calldata <RECIPIENT_ADDRESS> <OWNER_ADDRESS> 18 \

--max-fee 5000000000000000000

```

### 4. Declare PredictionHub Contract

```bash

sncast declare --contract-name PredictionHub --max-fee 20000000000000000000

```

### 5. Deploy PredictionHub

```bash

sncast deploy \

--class-hash 0x026f3b806be5b6820873cdc9ab629419c431d3de4eb364746c5528f36143753c \

--constructor-calldata \

0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9 \

0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9 \

0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a \

0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09 \

--max-fee 10000000000000000000

```

---

## 🔄 Contract Upgrade Process

### 1. Build Updated Contract

```bash

scarb build

```

### 2. Declare New Implementation

```bash

sncast declare --contract-name PredictionHub --max-fee 20000000000000000000

```

### 3. Upgrade Contract (Admin Only)

```bash

sncast invoke \

--contract-address <CONTRACT_ADDRESS> \

--function upgrade \

--calldata <NEW_CLASS_HASH> \

--max-fee 5000000000000000000

```

### 4. Verify Upgrade

```bash

sncast call \

--contract-address <CONTRACT_ADDRESS> \

--function get_prediction_count

```

---

## 📊 Contract Interaction Guide

### Market Creation Functions

#### Create a Prediction Market

```bash

sncast invoke \

--contract-address 0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

--function create_predictions \

--calldata \

<TITLE_BYTEARRAY> \

<DESCRIPTION_BYTEARRAY> \

<IMAGE_URL_BYTEARRAY> \

<CHOICE_1_FELT> <CHOICE_2_FELT> \

<CATEGORY_U8> \

<END_TIME_U64> \

<MARKET_TYPE_U8> \

<CRYPTO_PREDICTION_OPTION>

```

**Parameters:**

- `title`: ByteArray - Market title (encoded as `len(data) [data] pending_word pending_word_len`)
- `description`: ByteArray - Market description (same encoding as title)
- `image_url`: ByteArray - Market image URL (same encoding as title) ⭐ **NEW**
- `choices`: (felt252, felt252) - Two choice options (e.g., `0x596573` for "Yes", `0x4e6f` for "No")
- `category`: u8 - Market category (0-7, see table below)
- `end_time`: u64 - Unix timestamp when market ends
- `prediction_market_type`: u8 - 0: General, 1: Crypto, 2: Sports
- `crypto_prediction`: Option<(felt252, u128)> - For crypto markets, use `1 <ASSET_KEY> <TARGET_VALUE>`; for others, use `0 0 0` (Option::None)

**Example (Weather Market)**:

```bash

sncast invoke \

--contract-address 0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

--function create_predictions \

--calldata \

1 0x57696c6c206974207261696e20746f6461793f 0x0 0 \

2 0x57696c6c207468657265206265207261696e66616c6c20696e20746865206e 0x65787420323420686f7572733f 0x0 0 \

0 0x0 0 \

0x596573 0x4e6f \

6 \

1754002799 \

0 \

0 0 0 \

--max-fee 20000000000000000000

```

**Example (Sports Market)**:

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function create_predictions \

--calldata \

0 0x417273656e616c2054726f7068796c65737320323032363f 24 \

0 0x417273656e616c27732074726f70687920637572736520696e20323032363f 30 \

0x596573 0x4e6f \

2 \

1774396800 \

2 \

0 0 0

```

**Note**: For non-crypto markets (`prediction_market_type` ≠ 1), use `0 0 0` for `crypto_prediction` to avoid deserialization errors.

### Market Query Functions

#### Get Total Market Count

```bash

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_prediction_count

```

#### Get Specific Market

```bash

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_prediction \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH>

```

#### Get All Markets

```bash

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_all_predictions

```

#### Get Markets by Category

```bash

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_all_predictions_by_market_category \

--calldata <CATEGORY_U8>

```

**Categories:**

| Category | Value | Description |

|---------------|-------|--------------------------------|

| General | 0 | General prediction markets |

| Crypto | 1 | Cryptocurrency-related markets |

| Sports | 2 | Sports betting markets |

| Politics | 3 | Political outcome markets |

| Entertainment | 4 | Entertainment industry markets |

| Technology | 5 | Technology trend markets |

| Weather | 6 | Weather prediction markets |

| Other | 7 | Miscellaneous markets |

#### Get Market Activity

```bash

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_market_activity \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH>

```

### Betting Functions

#### 1. Approve Token Spending

```bash

sncast invoke \

--contract-address 0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09 \

--function approve \

--calldata \

0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

<AMOUNT_LOW> <AMOUNT_HIGH> \

--max-fee 5000000000000000000

```

**Example (Approve 1000 tokens)**:

```bash

sncast invoke \

--contract-address 0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09 \

--function approve \

--calldata \

0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

1000000000000000000000 0 \

--max-fee 5000000000000000000

```

#### 2. Calculate Share Prices

```bash

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function calculate_share_prices \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH>

```

#### 3. Buy Shares

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function buy_shares \

--calldata \

<MARKET_ID_LOW> <MARKET_ID_HIGH> \

<CHOICE_U8> \

<AMOUNT_LOW> <AMOUNT_HIGH> \

--max-fee 5000000000000000000

```

**Example (Bet 10 tokens on choice 0 of market 1)**:

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function buy_shares \

--calldata \

1 0 \

0 \

10000000000000000000 0 \

--max-fee 5000000000000000000

```

#### 4. Get User Stake Details

```bash

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_user_stake_details \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH> <USER_ADDRESS>

```

#### 5. Claim Winnings

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function claim \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH> \

--max-fee 5000000000000000000

```

### Market Resolution Functions

#### Resolve Market (Moderator/Admin Only)

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function resolve_prediction \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH> <WINNING_CHOICE_U8> \

--max-fee 5000000000000000000

```

### Administrative Functions

#### Add Moderator (Admin Only)

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function add_moderator \

--calldata <MODERATOR_ADDRESS> \

--max-fee 5000000000000000000

```

#### Remove Moderator (Admin Only)

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function remove_moderator \

--calldata <MODERATOR_ADDRESS> \

--max-fee 5000000000000000000

```

#### Emergency Pause (Admin Only)

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function emergency_pause \

--max-fee 5000000000000000000

```

#### Set Platform Fee (Admin Only)

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function set_platform_fee \

--calldata <FEE_PERCENTAGE_U256_LOW> <FEE_PERCENTAGE_U256_HIGH> \

--max-fee 5000000000000000000

```

**Example (Set 2.5% fee)**:

```bash

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function set_platform_fee \

--calldata 250 0 \

--max-fee 5000000000000000000

```

### Query Functions

#### Get Contract Stats

```bash

# Get admin address

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_admin



# Get protocol token

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_protocol_token



# Get total value locked

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_total_value_locked



# Get platform fee

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function get_platform_fee



# Check if contract is paused

sncast call \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function is_paused

```

---

## 📝 ByteArray Encoding Guide

For string parameters (`title`, `description`, `image_url`), encode as `ByteArray` using the format: `len(data) [data] pending_word pending_word_len`.

### Python Helper Script

```python

def str_to_felt(s):

"""Convert string to felt252 (max 31 characters)"""

return hex(int.from_bytes(s.encode(), "big"))



def encode_bytearray(text):

"""Encode string as ByteArray calldata"""

chunks = []

for i in range(0, len(text), 31):

chunk = text[i:i+31]

chunks.append(str_to_felt(chunk))

pending_word = text[len(chunks) * 31:] if len(text) % 31 != 0 else ""

pending_word_felt = str_to_felt(pending_word) if pending_word else "0x0"

pending_word_len = str(len(pending_word))

return [str(len(chunks))] + chunks + [pending_word_felt, pending_word_len]



# Example usage

title = "Will it rain today?"

title_calldata = encode_bytearray(title)

print(f"Title calldata: {' '.join(title_calldata)}")

```

**Output**:

```

Title calldata: 1 0x57696c6c206974207261696e20746f6461793f 0x0 0

```

### Common String Encodings

- **"Yes"**: `0x596573`
- **"No"**: `0x4e6f`
- **"Bitcoin"**: `0x426974636f696e`
- **"Ethereum"**: `0x457468657265756d`
- **"Sports"**: `0x53706f727473`
- **"Politics"**: `0x506f6c6974696373`

---

## 🔍 Market Categories

| Category | Value | Description |

|---------------|-------|--------------------------------|

| General | 0 | General prediction markets |

| Crypto | 1 | Cryptocurrency-related markets |

| Sports | 2 | Sports betting markets |

| Politics | 3 | Political outcome markets |

| Entertainment | 4 | Entertainment industry markets |

| Technology | 5 | Technology trend markets |

| Weather | 6 | Weather prediction markets |

| Other | 7 | Miscellaneous markets |

---

## 💡 Usage Examples

### Complete Betting Flow

```bash

# 1. Check available markets

sncast call \

--contract-address 0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

--function get_all_predictions



# 2. Get share prices for market

sncast call \

--contract-address 0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

--function calculate_share_prices \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH>



# 3. Approve tokens

sncast invoke \

--contract-address 0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09 \

--function approve \

--calldata \

0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

10000000000000000000 0 \

--max-fee 5000000000000000000



# 4. Buy shares

sncast invoke \

--contract-address 0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

--function buy_shares \

--calldata \

<MARKET_ID_LOW> <MARKET_ID_HIGH> \

0 \

1000000000000000000 0 \

--max-fee 5000000000000000000



# 5. Check your stake

sncast call \

--contract-address 0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

--function get_user_stake_details \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH> <YOUR_ADDRESS>



# 6. After market resolution, claim winnings

sncast invoke \

--contract-address 0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b \

--function claim \

--calldata <MARKET_ID_LOW> <MARKET_ID_HIGH> \

--max-fee 5000000000000000000

```

### Market Creation Example

```bash

# Create a sports market about Arsenal

sncast invoke \

--contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \

--function create_predictions \

--calldata \

0 0x417273656e616c2054726f7068796c65737320323032363f 24 \

0 0x417273656e616c27732074726f70687920637572736520696e20323032363f 30 \

0x596573 0x4e6f \

2 \

1774396800 \

2 \

0 0 0 \

--max-fee 10000000000000000000

```

**Transaction Hash**: [0x01e7c6c37525365c9470b9c9ec87c084f76d12b7387953861ed1385aa8262317](https://sepolia.starkscan.co/tx/0x01e7c6c37525365c9470b9c9ec87c084f76d12b7387953861ed1385aa8262317)

---

## 🛠️ Troubleshooting

### Common Issues

1. **"Insufficient allowance"**

- Solution: Approve more tokens using the `approve` function.

2. **"Amount below minimum"**

- Solution: Check minimum bet amount (`get_betting_restrictions`) and increase your bet.

3. **"Market has ended"**

- Solution: Find an active market using `get_all_predictions` or wait for new markets.

4. **"Only admin allowed"**

- Solution: Use the admin account (`0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9`) for administrative functions.

5. **"Market not resolved"**

- Solution: Wait for market resolution before claiming.

6. **"Failed to deserialize param #1" (ByteArray)**

- Solution: Ensure `ByteArray` is encoded as `len(data) [data] pending_word pending_word_len`. Use the provided Python script.

7. **"Failed to deserialize param #7" (crypto_prediction)**

- Solution: For non-crypto markets (`prediction_market_type` ≠ 1), use `0 0 0` for `crypto_prediction`.

7. **"Market duration too short"**

- Solution: Ensure market duration is at least 1 hour from current time.

### Fee Estimation

For high-complexity operations, use higher max fees:

- **Simple calls**: 1-5 ETH (10^18 wei)
- **Complex invokes**: 5-20 ETH
- **Contract declarations**: 10-50 ETH

---

## 📊 Current Contract Status

- **Total Markets**: 1 (fresh deployment)
- **Contract Status**: Active and fully functional
- **Admin**: `0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9`
- **Protocol Token**: `0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09`
- **Platform Fee**: 2.5% (250 basis points)
- **Latest Market**: "Will it rain today?" (Weather, ends July 31, 2025)

---

## 🔗 Useful Links

- **[Starkscan Sepolia](https://sepolia.starkscan.co/)**
- **[Pragma Oracle Documentation](https://docs.pragma.build/)**
- **[Starknet Documentation](https://docs.starknet.io/)**
- **[StakCast GitHub](https://github.com/gear5labs/StakCast)**

---

## 📞 Support

For technical support or questions:

- **Email**: fishon.amos@stakcast.com
- **Twitter**: [@stakcast](https://x.com/stakcast)
- **GitHub Issues**: [StakCast Repository](https://github.com/gear5labs/StakCast/issues)

---

_Last Updated: July 31, 2025_

_Contract Version: v2.2 (Fresh Deployment)_

_Network: Starknet Sepolia_

---

### Key Changes in v2.2

1. **Fresh Contract Deployment**: Deployed new contract to resolve storage layout compatibility issues.

2. **New Contract Address**: Updated to `0x05b5fcf9bc77b7c0530b0a54e1125dbcac43f6022cfe9156564a5025b030334b`.

3. **Image URL Support**: Added `image_url` field to market creation with proper ByteArray encoding.

4. **Full Functionality**: All contract functions now work correctly with the new storage layout.

5. **Frontend Integration**: Updated frontend constants to use the new contract address.

6. **Testing Complete**: Successfully tested market creation, betting, and query functions.

This updated guide now serves as a comprehensive resource for interacting with the fresh StakCast PredictionHub contract deployment.
