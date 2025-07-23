use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use crate::types::{BetActivity, Outcome, PredictionMarket, UserStake};

// ================ Contract Interface ================

/// Main interface for the Prediction Hub contract
/// Handles creation, management, and resolution of prediction markets
#[starknet::interface]
pub trait IPredictionHub<TContractState> {
    // ================ Market Creation ================

    //create a new prediction market with binary (yes/no) choices
    fn create_predictions(
        ref self: TContractState,
        title: ByteArray,
        description: ByteArray,
        choices: (felt252, felt252),
        category: u8,
        end_time: u64,
        prediction_market_type: u8,
        crypto_prediction: Option<(felt252, u128)>,
    );

    // ================ Market Queries ================

    /// Returns the total number of prediction markets created
    fn get_prediction_count(self: @TContractState) -> u256;

    /// Retrieves a specific prediction market by ID
    fn get_prediction(self: @TContractState, market_id: u256) -> PredictionMarket;

    /// Returns an array of all active prediction markets
    fn get_all_predictions_by_market_category(
        self: @TContractState, category: u8,
    ) -> Array<PredictionMarket>;

    fn get_market_activity(self: @TContractState, market_id: u256) -> Array<BetActivity>;

    /// Returns an array of all active prediction markets
    fn get_all_predictions(self: @TContractState) -> Array<PredictionMarket>;

    /// Returns an array of all active general prediction markets
    // fn get_all_general_predictions(self: @TContractState) -> Array<PredictionMarket>;

    /// Returns an array of all active crypto prediction markets
    // fn get_all_crypto_predictions(self: @TContractState) -> Array<PredictionMarket>;

    /// Returns an array of all active sports prediction markets
    // fn get_all_sports_predictions(self: @TContractState) -> Array<PredictionMarket>;

    // get current market status of markets
    fn get_market_status(self: @TContractState, market_id: u256) -> (bool, bool);

    fn get_all_open_markets(self: @TContractState) -> Array<PredictionMarket>;
    fn get_all_locked_markets(self: @TContractState) -> Array<PredictionMarket>;
    fn get_all_resolved_markets(self: @TContractState) -> Array<PredictionMarket>;

    fn get_all_closed_bets_for_user(
        self: @TContractState, user: ContractAddress,
    ) -> Array<PredictionMarket>;
    fn get_all_open_bets_for_user(
        self: @TContractState, user: ContractAddress,
    ) -> Array<PredictionMarket>;
    fn get_all_locked_bets_for_user(
        self: @TContractState, user: ContractAddress,
    ) -> Array<PredictionMarket>;
    fn get_all_bets_for_user(
        self: @TContractState, user: ContractAddress,
    ) -> Array<PredictionMarket>;

    /// Returns an array of market IDs that a user has participated in
    fn get_user_market_ids(self: @TContractState, user: ContractAddress) -> Array<u256>;

    // ================ Betting Functions ================

    /// Returns the protocol token contract address
    fn get_protocol_token(self: @TContractState) -> ContractAddress;

    /// Returns current betting restrictions (min, max amounts)
    fn get_betting_restrictions(self: @TContractState) -> (u256, u256);

    /// Returns market liquidity information
    fn get_market_liquidity(self: @TContractState, market_id: u256) -> u256;

    /// Returns total value locked across all markets
    fn get_total_value_locked(self: @TContractState) -> u256;

    /// Returns an array of all active predictiona markets
    fn get_active_prediction_markets(self: @TContractState) -> Array<PredictionMarket>;

    /// Returns an array of all active general prediction markets
    // fn get_active_general_prediction_markets(self: @TContractState) -> Array<PredictionMarket>;

    /// Returns an array of all active sport prediction markets
    // fn get_active_sport_markets(self: @TContractState) -> Array<PredictionMarket>;

    /// Returns an array of all active crypto prediction markets
    // fn get_active_crypto_markets(self: @TContractState) -> Array<PredictionMarket>;

    /// Returns an array of all resolved general prediction markets
    fn get_all_resolved_prediction_markets(self: @TContractState) -> Array<PredictionMarket>;

    fn is_prediction_market_open_for_betting(ref self: TContractState, market_id: u256) -> bool;

    // ================ Market Resolution ================

    /// Resolves a prediction market by setting the winning option (replacement for
    /// resolve_prediction)
    fn resolve_prediction(ref self: TContractState, market_id: u256, winning_choice: u8);

    // place bet functions
    fn calculate_share_prices(self: @TContractState, market_id: u256) -> (u256, u256);

    fn buy_shares(ref self: TContractState, market_id: u256, choice: u8, amount: u256);

    fn get_user_stake_details(
        self: @TContractState, market_id: u256, user: ContractAddress,
    ) -> UserStake;

    fn claim(ref self: TContractState, market_id: u256);

    /// Returns the contract admin address
    fn get_admin(self: @TContractState) -> ContractAddress;

    /// Returns the address receiving platform fees
    fn get_fee_recipient(self: @TContractState) -> ContractAddress;

    /// Sets a new fee recipient address
    fn set_fee_recipient(ref self: TContractState, recipient: ContractAddress);

    /// Opens or closes a market for new bets
    fn toggle_market_status(ref self: TContractState, market_id: u256, market_type: u8);

    /// Adds a new moderator who can create/resolve predictions
    fn add_moderator(ref self: TContractState, moderator: ContractAddress);

    /// Administrative function to reset all prediction markets
    fn remove_all_predictions(ref self: TContractState);
    /// Upgrades the contract implementation (admin only)
    fn upgrade(ref self: TContractState, impl_hash: ClassHash);

    // ================ Market Update Functions ================

    /// Extends a market's duration by updating its end_time (admin/moderator only)
    fn extend_market_duration(ref self: TContractState, market_id: u256, new_end_time: u64);

    /// Modifies a market's description (admin/moderator only)
    fn modify_market_details(ref self: TContractState, market_id: u256, new_description: ByteArray);
}
