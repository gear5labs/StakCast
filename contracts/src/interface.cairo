use starknet::ContractAddress;
use starknet::storage::Map;
// Data Structures
#[derive(Drop, Serde, starknet::Store)]
pub struct Market {
    pub creator: ContractAddress,
    pub title: ByteArray,
    pub description: ByteArray,
    pub category: ByteArray,
    pub start_time: u64,
    pub end_time: u64,
    pub resolution_time: u64,
    pub total_stake: u256,
    pub min_stake: u256,
    pub max_stake: u256,
    pub num_outcomes: u32,
    pub validator: ContractAddress,
}

#[storage]
struct Storage {
    markets: Map<u32, Market>,
    market_outcomes: Map<(u32, u32), felt252>, // (market_id, outcome_index) -> outcome
    stakes_per_outcome: Map<(u32, u32), u256>, // (market_id, outcome_index) -> stake
    admin: ContractAddress // Admin address for access control
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Position {
    pub amount: u256,
    pub outcome_index: u32,
    pub claimed: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store, Debug, PartialEq)]
#[allow(starknet::store_no_default_variant)]
pub enum MarketStatus {
    Active,
    Closed,
    Resolved,
    Disputed,
    Cancelled,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct MarketOutcome {
    pub winning_outcome: u32,
    pub resolution_details: felt252,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct ValidatorInfo {
    pub stake: u256,
    pub markets_resolved: u32,
    pub disputed_resolutions: u32, // Added
    pub accuracy_score: u32,
    pub active: bool,
    pub last_resolution_time: u64, // Added
    pub validator_index: u32 // Added
}

// New Struct for Market Details
#[derive(Drop, Serde, starknet::Store)]
pub struct MarketDetails {
    pub market: Market,
    pub status: MarketStatus,
    pub outcome: Option<MarketOutcome>,
}

// Interfaces
#[starknet::interface]
pub trait IPredictionMarket<TContractState> {
    // Market Operations
    #[external(v0)]
    fn create_market(
        ref self: TContractState,
        title: ByteArray,
        description: ByteArray,
        category: ByteArray,
        start_time: u64,
        end_time: u64,
        outcomes: Array<felt252>,
        min_stake: u256,
        max_stake: u256,
    ) -> u32;

    #[external(v0)]
    fn take_position(ref self: TContractState, market_id: u32, outcome_index: u32, amount: u256);

    #[external(v0)]
    fn claim_winnings(ref self: TContractState, market_id: u32);

    // Getters
    #[external(v0)]
    fn get_market_details(self: @TContractState, market_id: u32) -> MarketDetails;

    #[external(v0)]
    fn get_user_position(self: @TContractState, user: ContractAddress, market_id: u32) -> Position;

    #[external(v0)]
    fn get_market_stats(self: @TContractState, market_id: u32) -> (u256, Array<u256>);

    // Administration
    fn assign_validator(ref self: TContractState, market_id: u32);

    #[external(v0)]
    fn resolve_market(
        ref self: TContractState, market_id: u32, winning_outcome: u32, resolution_details: felt252,
    );

    fn dispute_market(ref self: TContractState, market_id: u32, reason: felt252);

    #[external(v0)]
    fn cancel_market(ref self: TContractState, market_id: u32, reason: felt252);

    fn set_market_validator(ref self: TContractState, market_validator: ContractAddress);

    #[external(v0)]
    fn deposit(ref self: TContractState, amount: u256);

    #[external(v0)]
    fn withdraw(ref self: TContractState, amount: u256);

    #[external(v0)]
    fn get_balance(self: @TContractState, user: ContractAddress) -> u256; // New getter
}

#[starknet::interface]
pub trait IMarketValidator<TContractState> {
    // Validator Operations
    #[external(v0)]
    fn register_validator(ref self: TContractState, stake: u256);

    #[external(v0)]
    fn resolve_market(
        ref self: TContractState, market_id: u32, winning_outcome: u32, resolution_details: felt252,
    );

    #[external(v0)]
    fn slash_validator(
        ref self: TContractState, validator: ContractAddress, amount: u256, reason: felt252,
    );

    // Getters
    #[external(v0)]
    fn get_validator_info(self: @TContractState, validator: ContractAddress) -> ValidatorInfo;

    #[external(v0)]
    fn is_active_validator(self: @TContractState, validator: ContractAddress) -> bool;

    // Instead of returning an array of validators,
    // use this function to retrieve a validator by its index.
    #[external(v0)]
    fn get_validator_by_index(self: @TContractState, index: u32) -> ContractAddress;

    // Optionally, you can add a helper to retrieve the validator count.
    #[external(v0)]
    fn get_validator_count(self: @TContractState) -> u32;

    #[external(v0)]
    fn set_role(
        ref self: TContractState, recipient: ContractAddress, role: felt252, is_enable: bool,
    );
    // New function to set the PredictionMarket address
    fn set_prediction_market(ref self: TContractState, prediction_market: ContractAddress);

    fn get_prediction_market(self: @TContractState) -> ContractAddress;

    #[external(v0)]
    fn is_admin(self: @TContractState, role: felt252, address: ContractAddress) -> bool;
}

#[starknet::interface]
pub trait IERC20<TContractState> {
    // Token Operations
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;

    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;

    // Getters
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;

    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
}

// Events
#[derive(Drop, starknet::Event)]
pub struct MarketCreated {
    pub market_id: u32,
    pub creator: ContractAddress,
    pub title: ByteArray,
    pub start_time: u64,
    pub end_time: u64,
    pub min_stake: u256,
    pub max_stake: u256,
}

#[derive(Drop, starknet::Event)]
pub struct PositionTaken {
    pub market_id: u32,
    pub user: ContractAddress,
    pub outcome_index: u32,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct MarketResolved {
    pub market_id: u32,
    pub outcome: u32,
    pub resolver: ContractAddress,
    pub resolution_details: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct WinningsClaimed {
    pub market_id: u32,
    pub user: ContractAddress,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct ValidatorRegistered {
    pub validator: ContractAddress,
    pub stake: u256,
}

#[derive(Drop, starknet::Event)]
pub struct ValidatorSlashed {
    pub validator: ContractAddress,
    pub amount: u256,
    pub reason: felt252,
}

#[derive(Copy, Drop, starknet::Event)]
struct MarketDisputed {
    pub market_id: u32,
    pub disputer: ContractAddress,
    pub reason: felt252,
}

#[event]
#[derive(Drop, starknet::Event)]
pub enum Event {
    MarketCreated: MarketCreated,
    PositionTaken: PositionTaken,
    MarketResolved: MarketResolved,
    WinningsClaimed: WinningsClaimed,
    MarketDisputed: MarketDisputed,
}
