#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct PredictionMarket {
    pub title: ByteArray,
    pub market_id: u256,
    pub description: ByteArray,
    pub choices: (Outcome, Outcome),
    pub category: MarketCategory,
    pub is_resolved: bool,
    pub is_open: bool,
    pub end_time: u64,
    pub status: MarketStatus,
    pub winning_choice: Option<u8>,
    pub total_shares_option_one: u256,
    pub total_shares_option_two: u256,
    pub total_pool: u256,
    pub crypto_prediction: Option<
        (felt252, u128),
    > // the crypto asset (e.g., BTC, ETH) | target_value:  Target price value for the prediction
}

#[derive(Copy, Drop, Serde, starknet::Store, PartialEq)]
pub enum MarketCategory {
    #[default]
    Normal, // 0
    Politics, // 1
    Sports, // 2
    Crypto, // 3
    Business, // 4
    Entertainment, // 5
    Science, // 6
    Other // 7
}

pub fn num_to_market_category(category_input: u8) -> MarketCategory {
    match category_input {
        0 => MarketCategory::Normal,
        1 => MarketCategory::Politics,
        2 => MarketCategory::Sports,
        3 => MarketCategory::Crypto,
        4 => MarketCategory::Business,
        5 => MarketCategory::Entertainment,
        6 => MarketCategory::Science,
        7 => MarketCategory::Other,
        _ => MarketCategory::Normal // Default case
    }
}


#[derive(Copy, Drop, Serde, starknet::Store, PartialEq)]
pub struct MarketStats {
    pub total_traders: u256, // Total number of unique traders
    pub traders_option_a: u256, // Number of traders on option A
    pub traders_option_b: u256, // Number of traders on option B
    pub amount_staked_option_a: u256, // Total amount staked on option A
    pub amount_staked_option_b: u256, // Total amount staked on option B
    pub total_trades: u256 // Total number of trades executed
}

// Protocol stats
// instead of having protocol details everywhere and unor

// ================ Supporting Types ================

/// Represents a choice in a prediction market with its associated stake
#[derive(Copy, Serde, Drop, starknet::Store, PartialEq, Hash)]
pub struct Choice {
    pub label: felt252, // Text label for the choice
    pub staked_amount: u256 // Total amount staked on this choice
}

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store, Debug)]
pub enum MarketStatus {
    #[default]
    Active,
    Locked,
    Resolved: Outcome,
}

#[derive(Drop, Copy, Serde, starknet::Store, Clone)]
pub struct UserStake {
    pub shares_a: u256, // Fixed-point shares
    pub shares_b: u256, // Fixed-point shares
    pub total_amount_a: u256, // Fixed-point amount
    pub total_amount_b: u256, // Fixed-point amount
    pub total_invested: u256 // Fixed-point amount
}

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store, Debug)]
pub enum Outcome {
    #[default]
    Option1: felt252,
    Option2: felt252,
}

/// Represents a single bet activity for the bet graph
#[derive(Copy, Drop, Serde, starknet::Store, PartialEq)]
pub struct BetActivity {
    pub choice: u8, // 0 or 1 
    pub amount: u256,
}
