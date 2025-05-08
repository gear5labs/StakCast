// interface.cairo

// Import necessary types directly from the prediction_market contract module.
use super::{Market, MarketStatus, Outcome}; // Import structs/enums defined in the main module
use starknet::ContractAddress;

#[starknet::interface]
trait IPredictionMarket<TContractState> {
    // Function to create a new prediction market.
    // For MVP, let's assume user creation is allowed, though admin review/gating could be added later.
    // Returns the ID of the newly created market.
    fn create_market(ref self: TContractState, question: felt252, outcomes: Array<felt252>) -> u64;

    // Function for users to purchase units for a specific outcome.
    // The 'amount' here refers to the number of units, NOT the token amount.
    fn purchase_units(ref self: TContractState, market_id: u64, outcome_id: u32, amount: u128);

    // Function for a Validator to resolve a market.
    // This should have access control.
    fn resolve_market(ref self: TContractState, market_id: u64, winning_outcome_id: u32);

    // Function for winning users to claim their rewards.
    fn claim_rewards(ref self: TContractState, market_id: u64);

    // --- Getter Functions ---

    // Get details of a specific market by ID.
    fn get_market(self: @TContractState, market_id: u64) -> Market;

    // Get a user's positions (units held) in a specific market for a specific outcome.
    fn get_user_position(self: @TContractState, user: ContractAddress, market_id: u64, outcome_id: u32) -> u128;

    // Get the total units purchased for a specific outcome in a market.
    fn get_total_outcome_units(self: @TContractState, market_id: u64, outcome_id: u32) -> u128;

    // Get the total volume (units) for a specific market across all outcomes.
    fn get_market_total_volume(self: @TContractState, market_id: u64) -> u128;

    // Get the resolved outcome ID for a market.
    fn get_resolved_outcome_id(self: @TContractState, market_id: u64) -> u32;

    // Get the total number of markets created.
    fn get_market_count(self: @TContractState) -> u64;

    // Get the address of the ERC20 token used for purchases.
    fn get_erc20_token_address(self: @TContractState) -> ContractAddress;

    // Check if an address is a validator.
    fn is_validator(self: @TContractState, address: ContractAddress) -> bool;
}