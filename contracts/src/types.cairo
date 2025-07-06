/// Represents a general prediction market with binary (yes/no) outcomes
/// Used for any type of prediction that doesn't fit crypto or sports categories
#[derive(Drop, Serde, starknet::Store)]
pub struct PredictionMarket {
    pub title: ByteArray, // Market title/question
    pub market_id: u256, // Unique identifier for the market
    pub description: ByteArray, // Detailed description of the prediction
    pub choices: (Choice, Choice), // Binary choices (typically Yes/No)
    pub category: felt252, // Category identifier for market classification
    pub image_url: ByteArray, // URL to market image/icon
    pub is_resolved: bool, // Whether the market has been resolved
    pub is_open: bool, // Whether the market is accepting new bets
    pub end_time: u64, // Timestamp when the market closes
    pub winning_choice: Option<Choice>, // The winning choice after resolution
    pub total_pool: u256 // Total amount staked in the market
}


/// Represents a cryptocurrency price prediction market
/// Used for predictions about crypto asset prices (e.g., "Will BTC be above $X by date Y?")
#[derive(Drop, Serde, starknet::Store)]
pub struct CryptoPrediction {
    pub title: ByteArray,
    pub market_id: u256,
    pub description: ByteArray,
    pub choices: (Choice, Choice),
    pub category: felt252,
    pub image_url: ByteArray,
    pub is_resolved: bool,
    pub is_open: bool,
    pub end_time: u64,
    pub winning_choice: Option<Choice>,
    pub total_pool: u256,
    pub comparison_type: u8, // 0 -> less than amount, 1 -> greater than amount
    pub asset_key: felt252, // Identifier for the crypto asset (e.g., BTC, ETH)
    pub target_value: u128 // Target price value for the prediction
}


/// Represents a sports event prediction market
/// Used for predictions about sports match outcomes
#[derive(Drop, Serde, starknet::Store)]
pub struct SportsPrediction {
    pub title: ByteArray,
    pub market_id: u256,
    pub description: ByteArray,
    pub choices: (Choice, Choice),
    pub category: felt252,
    pub image_url: ByteArray,
    pub is_resolved: bool,
    pub is_open: bool,
    pub end_time: u64,
    pub winning_choice: Option<Choice>,
    pub total_pool: u256,
    pub event_id: u64, // External API event ID for automatic resolution
    pub team_flag: bool // Flag indicating if this is a team-based prediction
}

/// Represents a business prediction market with binary (yes/no) outcomes
/// Used for predictions about business (e.g., "Will over 50% of Fortune 500 companies adopt
/// blockchain solutions by 2026?")
#[derive(Drop, Serde, starknet::Store)]
pub struct BusinessPrediction {
    pub title: ByteArray, // Market title/question
    pub market_id: u256, // Unique identifier for the market
    pub description: ByteArray, // Detailed description of the prediction
    pub choices: (Choice, Choice), // Binary choices (typically Yes/No)
    pub category: felt252, // Category identifier for market classification
    pub image_url: ByteArray, // URL to market image/icon
    pub is_resolved: bool, // Whether the market has been resolved
    pub is_open: bool, // Whether the market is accepting new bets
    pub end_time: u64, // Timestamp when the market closes
    pub winning_choice: Option<Choice>, // The winning choice after resolution
    pub total_pool: u256, // Total amount staked in the market
    pub event_id: u64 // External API event ID for automatic resolution
}

// ================ Supporting Types ================

/// Represents a choice in a prediction market with its associated stake
#[derive(Copy, Serde, Drop, starknet::Store, PartialEq, Hash)]
pub struct Choice {
    pub label: felt252, // Text label for the choice
    pub staked_amount: u256 // Total amount staked on this choice
}

/// Represents a user's stake in a prediction market
#[derive(Drop, Serde, starknet::Store)]
pub struct UserStake {
    pub amount: u256, // Amount staked by the user
    pub claimed: bool // Whether the user has claimed their winnings
}

/// Represents a user's bet on a specific choice in a market
#[derive(Drop, Serde, starknet::Store)]
pub struct UserBet {
    pub choice: Choice, // The choice the user bet on
    pub stake: UserStake // The user's stake details
}
