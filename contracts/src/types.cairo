#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct PredictionMarket {
    pub title: ByteArray,
    pub market_id: u256,
    pub description: ByteArray,
    pub choices: (Choice, Choice),
    pub category: felt252,
    pub is_resolved: bool,
    pub is_open: bool,
    pub end_time: u64,
    pub status: MarketStatus,
    pub winning_choice: Option<Choice>,
    pub total_shares_option_one: u256,
    pub total_shares_option_two: u256,
    pub total_pool: u256,
    pub prediction_market_type: u8, // 0 - normal predicion market, 1 - crypto prediction market, 2 - sports prediction, 3 - buisness market
    pub crypto_prediction: Option<
        (felt252, u128),
    >, // the crypto asset (e.g., BTC, ETH) | target_value:  Target price value for the prediction
    /// @dev depreciated
    pub sports_prediction: Option<(u64, bool)>,
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
    Resolved: Outcome,
}

#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct UserStake {
    pub shares_a: u256, // Fixed-point shares
    pub shares_b: u256, // Fixed-point shares
    pub total_invested: u256 // Fixed-point amount
}

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store, Debug)]
pub enum Outcome {
    #[default]
    Option1,
    Option2,
}
