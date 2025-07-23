use starknet::ContractAddress;

// ================ Individual Event Structs ================

#[derive(Drop, starknet::Event)]
pub struct ModeratorAdded {
    pub moderator: ContractAddress,
    pub added_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct ModeratorRemoved {
    pub moderator: ContractAddress,
    pub removed_by: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct EmergencyPaused {
    pub paused_by: ContractAddress,
    pub reason: ByteArray,
}

#[derive(Drop, starknet::Event)]
pub struct MarketCreated {
    pub market_id: u256,
    pub creator: ContractAddress,
    pub market_type: u8,
}

#[derive(Drop, starknet::Event)]
pub struct MarketResolved {
    pub market_id: u256,
    pub resolver: ContractAddress,
    pub winning_choice: u8,
}

#[derive(Drop, starknet::Event)]
pub struct WagerPlaced {
    pub market_id: u256,
    pub user: ContractAddress,
    pub choice: u8,
    pub amount: u256,
    pub fee_amount: u256,
    pub net_amount: u256,
    pub wager_index: u8,
}

#[derive(Drop, starknet::Event)]
pub struct FeesCollected {
    pub market_id: u256,
    pub fee_amount: u256,
    pub fee_recipient: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct WinningsCollected {
    pub market_id: u256,
    pub user: ContractAddress,
    pub amount: u256,
    pub wager_index: u8,
}

#[derive(Drop, starknet::Event)]
pub struct BetPlaced {
    pub market_id: u256,
    pub user: ContractAddress,
    pub choice: u8,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct MarketDurationExtended {
    pub market_id: u256,
    pub updated_by: ContractAddress,
    pub new_end_time: u64,
}

#[derive(Drop, starknet::Event)]
pub struct MarketDetailsModified {
    pub market_id: u256,
    pub updated_by: ContractAddress,
}

// ================ Main Event Enum ================

#[derive(Drop, starknet::Event)]
pub enum Event {
    ModeratorAdded: ModeratorAdded,
    ModeratorRemoved: ModeratorRemoved,
    EmergencyPaused: EmergencyPaused,
    MarketCreated: MarketCreated,
    MarketResolved: MarketResolved,
    WagerPlaced: WagerPlaced,
    FeesCollected: FeesCollected,
    WinningsCollected: WinningsCollected,
    BetPlaced: BetPlaced,
    MarketDurationExtended: MarketDurationExtended,
    MarketDetailsModified: MarketDetailsModified,
}
