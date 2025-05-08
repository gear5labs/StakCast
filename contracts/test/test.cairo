// utils.cairo

use starknet::ContractAddress;
use starknet::storage_access::Store; // Required for storage mapping values

// Struct representing an outcome within a prediction market.
// It needs a unique ID within the market and a description.
// We'll use felt252 for IDs and descriptions for simplicity in Cairo.
// In a real DApp, descriptions might be IPFS hashes or indices into off-chain data.
#[derive(Drop, starknet::Store, Clone)]
struct Outcome {
    id: u32, // Unique ID within the market (u32 should be sufficient for outcome count)
    description: felt252, // Felt representation of the outcome description
}

// Enum representing the possible states of a prediction market.
#[derive(Drop, starknet::Store)]
enum MarketStatus {
    Open, // Market is accepting unit purchases
    Resolved, // Market outcome has been set, claims are possible
    Cancelled, // Market was cancelled, funds might be refundable (out of MVP scope)
}

// Struct representing a single prediction market.
#[derive(Drop, starknet::Store)]
struct Market {
    creator: ContractAddress, // Address that created the market
    question: felt252, // Felt representation of the market question
    outcomes: Array<Outcome>, // List of possible outcomes for this market
    status: MarketStatus, // Current status of the market
    total_market_volume: u128, // Total number of units purchased across all outcomes (using u128 for potential large volume)
    resolved_outcome_id: u32, // The ID of the winning outcome once resolved (0 if not resolved or cancelled)
    // Add timestamps later if needed (creation_time, resolution_time)
}