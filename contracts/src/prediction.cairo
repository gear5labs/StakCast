use starknet::{
    ContractAddress, get_caller_address, get_block_timestamp,
    storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map}
};
use pragma_lib::types::{DataType};
use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};

use super::interface::{
    IPredictionHub, PredictionMarket, CryptoPrediction, SportsPrediction, Choice, UserStake,
    UserBet
};

// ================ Security Events ================

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
pub struct BetPlaced {
    pub market_id: u256,
    pub user: ContractAddress,
    pub choice: u8,
    pub amount: u256,
}

// ================ Contract Storage ================

#[starknet::contract]
pub mod PredictionHub {
    use super::*;

    #[storage]
    struct Storage {
        // Access control
        admin: ContractAddress,
        moderators: Map<ContractAddress, bool>,
        moderator_count: u32,
        
        // Market data
        prediction_count: u256,
        predictions: Map<u256, PredictionMarket>,
        crypto_predictions: Map<u256, CryptoPrediction>,
        sports_predictions: Map<u256, SportsPrediction>,
        
        // User bets mapping: (user, market_id, market_type, bet_index) -> UserBet
        user_bets: Map<(ContractAddress, u256, u8, u8), UserBet>,
        user_bet_counts: Map<(ContractAddress, u256, u8), u8>,
        
        // Fee management
        fee_recipient: ContractAddress,
        platform_fee_percentage: u256, // Basis points (e.g., 250 = 2.5%)
        
        // Oracle integration
        pragma_oracle: ContractAddress,
        
        // Emergency controls
        emergency_pause_reason: ByteArray,
        is_paused: bool,
        market_creation_paused: bool,
        betting_paused: bool,
        resolution_paused: bool,
        
        // Time-based restrictions
        min_market_duration: u64, // Minimum time a market must be open
        max_market_duration: u64, // Maximum time a market can be open
        resolution_window: u64,   // Time window after market end for resolution
        
        // Reentrancy protection
        reentrancy_guard: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ModeratorAdded: ModeratorAdded,
        ModeratorRemoved: ModeratorRemoved,
        EmergencyPaused: EmergencyPaused,
        MarketCreated: MarketCreated,
        MarketResolved: MarketResolved,
        BetPlaced: BetPlaced,
    }

    // ================ Constructor ================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        fee_recipient: ContractAddress,
        pragma_oracle: ContractAddress,
    ) {
        self.admin.write(admin);
        self.fee_recipient.write(fee_recipient);
        self.platform_fee_percentage.write(250); // 2.5% default fee
        self.pragma_oracle.write(pragma_oracle);
        
        // Set default time restrictions
        self.min_market_duration.write(3600); // 1 hour minimum
        self.max_market_duration.write(31536000); // 1 year maximum
        self.resolution_window.write(604800); // 1 week resolution window
        
        // Initialize security states
        self.is_paused.write(false);
        self.market_creation_paused.write(false);
        self.betting_paused.write(false);
        self.resolution_paused.write(false);
        self.reentrancy_guard.write(false);
    }

    // ================ Security Modifiers ================

    #[generate_trait]
    impl SecurityImpl of SecurityTrait {
        fn assert_not_paused(self: @ContractState) {
            assert(!self.is_paused.read(), 'Contract is paused');
        }

        fn assert_only_admin(self: @ContractState) {
            let caller = get_caller_address();
            assert(self.admin.read() == caller, 'Only admin allowed');
        }

        fn assert_only_moderator_or_admin(self: @ContractState) {
            let caller = get_caller_address();
            let is_admin = self.admin.read() == caller;
            let is_moderator = self.moderators.entry(caller).read();
            
            assert(is_admin || is_moderator, 'Only admin or moderator');
        }

        fn assert_market_creation_not_paused(self: @ContractState) {
            assert(!self.market_creation_paused.read(), 'Market creation paused');
        }

        fn assert_betting_not_paused(self: @ContractState) {
            assert(!self.betting_paused.read(), 'Betting paused');
        }

        fn assert_resolution_not_paused(self: @ContractState) {
            assert(!self.resolution_paused.read(), 'Resolution paused');
        }

        fn assert_valid_market_timing(self: @ContractState, end_time: u64) {
            let current_time = get_block_timestamp();
            let min_duration = self.min_market_duration.read();
            let max_duration = self.max_market_duration.read();
            
            assert(end_time > current_time, 'End time must be in future');
            assert(end_time - current_time >= min_duration, 'Market duration too short');
            assert(end_time - current_time <= max_duration, 'Market duration too long');
        }

        fn assert_market_open(self: @ContractState, market_id: u256, market_type: u8) {
            let current_time = get_block_timestamp();
            
            if market_type == 0 { // General prediction
                let market = self.predictions.entry(market_id).read();
                assert(market.is_open, 'Market is closed');
                assert(!market.is_resolved, 'Market already resolved');
                assert(current_time < market.end_time, 'Market has ended');
            } else if market_type == 1 { // Crypto prediction
                let market = self.crypto_predictions.entry(market_id).read();
                assert(market.is_open, 'Market is closed');
                assert(!market.is_resolved, 'Market already resolved');
                assert(current_time < market.end_time, 'Market has ended');
            } else if market_type == 2 { // Sports prediction
                let market = self.sports_predictions.entry(market_id).read();
                assert(market.is_open, 'Market is closed');
                assert(!market.is_resolved, 'Market already resolved');
                assert(current_time < market.end_time, 'Market has ended');
            } else {
                panic!("Invalid market type");
            }
        }

        fn assert_market_exists(self: @ContractState, market_id: u256, market_type: u8) {
            if market_type == 0 {
                let market = self.predictions.entry(market_id).read();
                assert(market.market_id == market_id, 'Market does not exist');
            } else if market_type == 1 {
                let market = self.crypto_predictions.entry(market_id).read();
                assert(market.market_id == market_id, 'Market does not exist');
            } else if market_type == 2 {
                let market = self.sports_predictions.entry(market_id).read();
                assert(market.market_id == market_id, 'Market does not exist');
            } else {
                panic!("Invalid market type");
            }
        }

        fn assert_valid_choice(self: @ContractState, choice_idx: u8) {
            assert(choice_idx < 2, 'Invalid choice index');
        }

        fn assert_valid_amount(self: @ContractState, amount: u256) {
            assert(amount > 0, 'Amount must be positive');
        }

        fn start_reentrancy_guard(ref self: ContractState) {
            assert(!self.reentrancy_guard.read(), 'Reentrant call');
            self.reentrancy_guard.write(true);
        }

        fn end_reentrancy_guard(ref self: ContractState) {
            self.reentrancy_guard.write(false);
        }
    }

    // ================ IPredictionHub Implementation ================

    #[abi(embed_v0)]
    impl PredictionHubImpl of IPredictionHub<ContractState> {
        
        // ================ Market Creation ================

        fn create_prediction(
            ref self: ContractState,
            title: ByteArray,
            description: ByteArray,
            choices: (felt252, felt252),
            category: felt252,
            image_url: ByteArray,
            end_time: u64,
        ) {
            self.assert_not_paused();
            self.assert_market_creation_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_valid_market_timing(end_time);
            self.start_reentrancy_guard();

            let market_id = self.prediction_count.read() + 1;
            self.prediction_count.write(market_id);

            let (choice_0_label, choice_1_label) = choices;
            let choice_0 = Choice { label: choice_0_label, staked_amount: 0 };
            let choice_1 = Choice { label: choice_1_label, staked_amount: 0 };

            let market = PredictionMarket {
                title,
                market_id,
                description,
                choices: (choice_0, choice_1),
                category,
                image_url,
                is_resolved: false,
                is_open: true,
                end_time,
                winning_choice: Option::None,
                total_pool: 0,
            };

            self.predictions.entry(market_id).write(market);

            self.emit(MarketCreated {
                market_id,
                creator: get_caller_address(),
                market_type: 0,
            });

            self.end_reentrancy_guard();
        }

        fn create_crypto_prediction(
            ref self: ContractState,
            title: ByteArray,
            description: ByteArray,
            choices: (felt252, felt252),
            category: felt252,
            image_url: ByteArray,
            end_time: u64,
            comparison_type: u8,
            asset_key: felt252,
            target_value: u128,
        ) {
            self.assert_not_paused();
            self.assert_market_creation_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_valid_market_timing(end_time);
            assert(comparison_type < 2, 'Invalid comparison type');
            self.start_reentrancy_guard();

            let market_id = self.prediction_count.read() + 1;
            self.prediction_count.write(market_id);

            let (choice_0_label, choice_1_label) = choices;
            let choice_0 = Choice { label: choice_0_label, staked_amount: 0 };
            let choice_1 = Choice { label: choice_1_label, staked_amount: 0 };

            let market = CryptoPrediction {
                title,
                market_id,
                description,
                choices: (choice_0, choice_1),
                category,
                image_url,
                is_resolved: false,
                is_open: true,
                end_time,
                winning_choice: Option::None,
                total_pool: 0,
                comparison_type,
                asset_key,
                target_value,
            };

            self.crypto_predictions.entry(market_id).write(market);

            self.emit(MarketCreated {
                market_id,
                creator: get_caller_address(),
                market_type: 1,
            });

            self.end_reentrancy_guard();
        }

        fn create_sports_prediction(
            ref self: ContractState,
            title: ByteArray,
            description: ByteArray,
            choices: (felt252, felt252),
            category: felt252,
            image_url: ByteArray,
            end_time: u64,
            event_id: u64,
            team_flag: bool,
        ) {
            self.assert_not_paused();
            self.assert_market_creation_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_valid_market_timing(end_time);
            self.start_reentrancy_guard();

            let market_id = self.prediction_count.read() + 1;
            self.prediction_count.write(market_id);

            let (choice_0_label, choice_1_label) = choices;
            let choice_0 = Choice { label: choice_0_label, staked_amount: 0 };
            let choice_1 = Choice { label: choice_1_label, staked_amount: 0 };

            let market = SportsPrediction {
                title,
                market_id,
                description,
                choices: (choice_0, choice_1),
                category,
                image_url,
                is_resolved: false,
                is_open: true,
                end_time,
                winning_choice: Option::None,
                total_pool: 0,
                event_id,
                team_flag,
            };

            self.sports_predictions.entry(market_id).write(market);

            self.emit(MarketCreated {
                market_id,
                creator: get_caller_address(),
                market_type: 2,
            });

            self.end_reentrancy_guard();
        }

        // ================ Market Queries ================

        fn get_prediction_count(self: @ContractState) -> u256 {
            self.prediction_count.read()
        }

        fn get_prediction(self: @ContractState, market_id: u256) -> PredictionMarket {
            self.assert_market_exists(market_id, 0);
            self.predictions.entry(market_id).read()
        }

        fn get_all_predictions(self: @ContractState) -> Array<PredictionMarket> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i = 1;
            
            while i <= count {
                let market = self.predictions.entry(i).read();
                if market.market_id != 0 { // Check if market exists
                    predictions.append(market);
                }
                i += 1;
            };
            
            predictions
        }

        fn get_crypto_prediction(self: @ContractState, market_id: u256) -> CryptoPrediction {
            self.assert_market_exists(market_id, 1);
            self.crypto_predictions.entry(market_id).read()
        }

        fn get_all_crypto_predictions(self: @ContractState) -> Array<CryptoPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i = 1;
            
            while i <= count {
                let market = self.crypto_predictions.entry(i).read();
                if market.market_id != 0 { // Check if market exists
                    predictions.append(market);
                }
                i += 1;
            };
            
            predictions
        }

        fn get_sports_prediction(self: @ContractState, market_id: u256) -> SportsPrediction {
            self.assert_market_exists(market_id, 2);
            self.sports_predictions.entry(market_id).read()
        }

        fn get_all_sports_predictions(self: @ContractState) -> Array<SportsPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i = 1;
            
            while i <= count {
                let market = self.sports_predictions.entry(i).read();
                if market.market_id != 0 { // Check if market exists
                    predictions.append(market);
                }
                i += 1;
            };
            
            predictions
        }

        // ================ Betting Functions ================

        fn place_bet(
            ref self: ContractState,
            market_id: u256,
            choice_idx: u8,
            amount: u256,
            market_type: u8,
        ) -> bool {
            self.assert_not_paused();
            self.assert_betting_not_paused();
            self.assert_market_exists(market_id, market_type);
            self.assert_market_open(market_id, market_type);
            self.assert_valid_choice(choice_idx);
            self.assert_valid_amount(amount);
            self.start_reentrancy_guard();

            let caller = get_caller_address();
            
            // Create user bet
            let choice = if choice_idx == 0 {
                if market_type == 0 {
                    let market = self.predictions.entry(market_id).read();
                    let (choice_0, _choice_1) = market.choices;
                    choice_0
                } else if market_type == 1 {
                    let market = self.crypto_predictions.entry(market_id).read();
                    let (choice_0, _choice_1) = market.choices;
                    choice_0
                } else {
                    let market = self.sports_predictions.entry(market_id).read();
                    let (choice_0, _choice_1) = market.choices;
                    choice_0
                }
            } else {
                if market_type == 0 {
                    let market = self.predictions.entry(market_id).read();
                    let (_choice_0, choice_1) = market.choices;
                    choice_1
                } else if market_type == 1 {
                    let market = self.crypto_predictions.entry(market_id).read();
                    let (_choice_0, choice_1) = market.choices;
                    choice_1
                } else {
                    let market = self.sports_predictions.entry(market_id).read();
                    let (_choice_0, choice_1) = market.choices;
                    choice_1
                }
            };

            let user_stake = UserStake { amount, claimed: false };
            let user_bet = UserBet { choice, stake: user_stake };

            // Update user bets
            let count_key = (caller, market_id, market_type);
            let current_count = self.user_bet_counts.entry(count_key).read();
            let bet_key = (caller, market_id, market_type, current_count);
            
            self.user_bets.entry(bet_key).write(user_bet);
            self.user_bet_counts.entry(count_key).write(current_count + 1);

            // Update market totals
            self._update_market_totals(market_id, market_type, choice_idx, amount);

            self.emit(BetPlaced {
                market_id,
                user: caller,
                choice: choice_idx,
                amount,
            });

            self.end_reentrancy_guard();
            true
        }

        fn get_bet_count_for_market(
            self: @ContractState,
            user: ContractAddress,
            market_id: u256,
            market_type: u8,
        ) -> u8 {
            self.user_bet_counts.entry((user, market_id, market_type)).read()
        }

        fn get_choice_and_bet(
            self: @ContractState,
            user: ContractAddress,
            market_id: u256,
            market_type: u8,
            bet_idx: u8,
        ) -> UserBet {
            let count_key = (user, market_id, market_type);
            let bet_count = self.user_bet_counts.entry(count_key).read();
            assert(bet_idx < bet_count, 'Bet index out of bounds');
            
            let bet_key = (user, market_id, market_type, bet_idx);
            self.user_bets.entry(bet_key).read()
        }

        // ================ Market Resolution ================

        fn resolve_prediction(ref self: ContractState, market_id: u256, winning_choice: u8) {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_market_exists(market_id, 0);
            self.assert_valid_choice(winning_choice);
            self.start_reentrancy_guard();

            let mut market = self.predictions.entry(market_id).read();
            assert(!market.is_resolved, 'Market already resolved');
            
            let current_time = get_block_timestamp();
            assert(current_time >= market.end_time, 'Market not yet ended');
            
            let resolution_deadline = market.end_time + self.resolution_window.read();
            assert(current_time <= resolution_deadline, 'Resolution window expired');

            market.is_resolved = true;
            market.is_open = false;
            
            let winning_choice_struct = if winning_choice == 0 {
                let (choice_0, _choice_1) = market.choices;
                choice_0
            } else {
                let (_choice_0, choice_1) = market.choices;
                choice_1
            };
            
            market.winning_choice = Option::Some(winning_choice_struct);
            self.predictions.entry(market_id).write(market);

            self.emit(MarketResolved {
                market_id,
                resolver: get_caller_address(),
                winning_choice,
            });

            self.end_reentrancy_guard();
        }

        fn resolve_crypto_prediction_manually(
            ref self: ContractState,
            market_id: u256,
            winning_choice: u8,
        ) {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_market_exists(market_id, 1);
            self.assert_valid_choice(winning_choice);
            self.start_reentrancy_guard();

            let mut market = self.crypto_predictions.entry(market_id).read();
            assert(!market.is_resolved, 'Market already resolved');
            
            let current_time = get_block_timestamp();
            assert(current_time >= market.end_time, 'Market not yet ended');

            market.is_resolved = true;
            market.is_open = false;
            
            let winning_choice_struct = if winning_choice == 0 {
                let (choice_0, _choice_1) = market.choices;
                choice_0
            } else {
                let (_choice_0, choice_1) = market.choices;
                choice_1
            };
            
            market.winning_choice = Option::Some(winning_choice_struct);
            self.crypto_predictions.entry(market_id).write(market);

            self.emit(MarketResolved {
                market_id,
                resolver: get_caller_address(),
                winning_choice,
            });

            self.end_reentrancy_guard();
        }

        fn resolve_sports_prediction_manually(
            ref self: ContractState,
            market_id: u256,
            winning_choice: u8,
        ) {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_market_exists(market_id, 2);
            self.assert_valid_choice(winning_choice);
            self.start_reentrancy_guard();

            let mut market = self.sports_predictions.entry(market_id).read();
            assert(!market.is_resolved, 'Market already resolved');
            
            let current_time = get_block_timestamp();
            assert(current_time >= market.end_time, 'Market not yet ended');

            market.is_resolved = true;
            market.is_open = false;
            
            let winning_choice_struct = if winning_choice == 0 {
                let (choice_0, _choice_1) = market.choices;
                choice_0
            } else {
                let (_choice_0, choice_1) = market.choices;
                choice_1
            };
            
            market.winning_choice = Option::Some(winning_choice_struct);
            self.sports_predictions.entry(market_id).write(market);

            self.emit(MarketResolved {
                market_id,
                resolver: get_caller_address(),
                winning_choice,
            });

            self.end_reentrancy_guard();
        }

        fn resolve_crypto_prediction(ref self: ContractState, market_id: u256) {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_market_exists(market_id, 1);
            self.start_reentrancy_guard();

            let mut market = self.crypto_predictions.entry(market_id).read();
            assert(!market.is_resolved, 'Market already resolved');
            
            let current_time = get_block_timestamp();
            assert(current_time >= market.end_time, 'Market not yet ended');

            // Get price from Pragma Oracle
            let oracle = IPragmaABIDispatcher { contract_address: self.pragma_oracle.read() };
            let price_response = oracle.get_data_median(DataType::SpotEntry(market.asset_key));
            let current_price = price_response.price;

            // Determine winning choice based on comparison
            let winning_choice = if market.comparison_type == 0 {
                // Less than target
                if current_price < market.target_value.into() { 0 } else { 1 }
            } else {
                // Greater than target
                if current_price > market.target_value.into() { 0 } else { 1 }
            };

            market.is_resolved = true;
            market.is_open = false;
            
            let winning_choice_struct = if winning_choice == 0 {
                let (choice_0, _choice_1) = market.choices;
                choice_0
            } else {
                let (_choice_0, choice_1) = market.choices;
                choice_1
            };
            
            market.winning_choice = Option::Some(winning_choice_struct);
            self.crypto_predictions.entry(market_id).write(market);

            self.emit(MarketResolved {
                market_id,
                resolver: get_caller_address(),
                winning_choice,
            });

            self.end_reentrancy_guard();
        }

        fn resolve_sports_prediction(
            ref self: ContractState,
            market_id: u256,
            winning_choice: u8,
        ) {
            // This would integrate with sports data API in production
            self.resolve_sports_prediction_manually(market_id, winning_choice);
        }

        // ================ Winnings Management ================

        fn collect_winnings(
            ref self: ContractState,
            market_id: u256,
            market_type: u8,
            bet_idx: u8,
        ) {
            self.assert_not_paused();
            self.assert_market_exists(market_id, market_type);
            self.start_reentrancy_guard();

            let caller = get_caller_address();
            let bet_key = (caller, market_id, market_type, bet_idx);
            
            // Get user's bet
            let count_key = (caller, market_id, market_type);
            let bet_count = self.user_bet_counts.entry(count_key).read();
            assert(bet_idx < bet_count, 'Bet index out of bounds');
            
            let mut user_bet = self.user_bets.entry(bet_key).read();
            assert(!user_bet.stake.claimed, 'Winnings already claimed');

            // Check if market is resolved and user won
            let (is_resolved, winning_choice, total_pool, winning_pool) = self._get_market_resolution_info(market_id, market_type);
            assert(is_resolved, 'Market not resolved');

            let user_won = user_bet.choice.label == winning_choice.label;
            assert(user_won, 'User did not win');

            // Calculate winnings
            let user_stake = user_bet.stake.amount;
            let _winnings = if winning_pool > 0 {
                (user_stake * total_pool) / winning_pool
            } else {
                user_stake // Return original stake if no one won
            };

            // Mark as claimed
            user_bet.stake.claimed = true;
            
            // Update the bet in storage
            self.user_bets.entry(bet_key).write(user_bet);

            self.end_reentrancy_guard();
        }

        fn get_user_claimable_amount(self: @ContractState, user: ContractAddress) -> u256 {
            let mut total_claimable = 0;
            let count = self.prediction_count.read();
            let mut market_id = 1;

            while market_id <= count {
                // Check all market types
                let mut market_type = 0;
                while market_type < 3 {
                    let count_key = (user, market_id, market_type);
                    let bet_count = self.user_bet_counts.entry(count_key).read();
                    
                    if bet_count > 0 {
                        let mut bet_idx = 0;
                        
                        while bet_idx < bet_count {
                            let bet_key = (user, market_id, market_type, bet_idx);
                            let user_bet = self.user_bets.entry(bet_key).read();
                            
                            if !user_bet.stake.claimed {
                                let (is_resolved, winning_choice, total_pool, winning_pool) = 
                                    self._get_market_resolution_info(market_id, market_type);
                                
                                if is_resolved && user_bet.choice.label == winning_choice.label {
                                    let user_stake = user_bet.stake.amount;
                                    let winnings = if winning_pool > 0 {
                                        (user_stake * total_pool) / winning_pool
                                    } else {
                                        user_stake
                                    };
                                    total_claimable += winnings;
                                }
                            }
                            bet_idx += 1;
                        };
                    }
                    market_type += 1;
                };
                market_id += 1;
            };

            total_claimable
        }

        // ================ User Queries ================

        fn get_user_predictions(self: @ContractState, user: ContractAddress) -> Array<PredictionMarket> {
            let mut user_markets = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut market_id = 1;

            while market_id <= count {
                let key = (user, market_id, 0_u8);
                let bet_count = self.user_bet_counts.entry(key).read();
                
                if bet_count > 0 {
                    let market = self.predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        user_markets.append(market);
                    }
                }
                market_id += 1;
            };

            user_markets
        }

        fn get_user_crypto_predictions(self: @ContractState, user: ContractAddress) -> Array<CryptoPrediction> {
            let mut user_markets = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut market_id = 1;

            while market_id <= count {
                let key = (user, market_id, 1_u8);
                let bet_count = self.user_bet_counts.entry(key).read();
                
                if bet_count > 0 {
                    let market = self.crypto_predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        user_markets.append(market);
                    }
                }
                market_id += 1;
            };

            user_markets
        }

        fn get_user_sports_predictions(self: @ContractState, user: ContractAddress) -> Array<SportsPrediction> {
            let mut user_markets = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut market_id = 1;

            while market_id <= count {
                let key = (user, market_id, 2_u8);
                let bet_count = self.user_bet_counts.entry(key).read();
                
                if bet_count > 0 {
                    let market = self.sports_predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        user_markets.append(market);
                    }
                }
                market_id += 1;
            };

            user_markets
        }

        // ================ Administrative Functions ================

        fn get_admin(self: @ContractState) -> ContractAddress {
            self.admin.read()
        }

        fn get_fee_recipient(self: @ContractState) -> ContractAddress {
            self.fee_recipient.read()
        }

        fn set_fee_recipient(ref self: ContractState, recipient: ContractAddress) {
            self.assert_only_admin();
            self.fee_recipient.write(recipient);
        }

        fn toggle_market_status(ref self: ContractState, market_id: u256, market_type: u8) {
            self.assert_only_moderator_or_admin();
            self.assert_market_exists(market_id, market_type);

            if market_type == 0 {
                let mut market = self.predictions.entry(market_id).read();
                market.is_open = !market.is_open;
                self.predictions.entry(market_id).write(market);
            } else if market_type == 1 {
                let mut market = self.crypto_predictions.entry(market_id).read();
                market.is_open = !market.is_open;
                self.crypto_predictions.entry(market_id).write(market);
            } else if market_type == 2 {
                let mut market = self.sports_predictions.entry(market_id).read();
                market.is_open = !market.is_open;
                self.sports_predictions.entry(market_id).write(market);
            }
        }

        fn add_moderator(ref self: ContractState, moderator: ContractAddress) {
            self.assert_only_admin();
            assert(!self.moderators.entry(moderator).read(), 'Already a moderator');
            
            self.moderators.entry(moderator).write(true);
            let current_count = self.moderator_count.read();
            self.moderator_count.write(current_count + 1);

            self.emit(ModeratorAdded {
                moderator,
                added_by: get_caller_address(),
            });
        }

        fn remove_all_predictions(ref self: ContractState) {
            self.assert_only_admin();
            self.prediction_count.write(0);
        }
    }

    // ================ Additional Admin Implementation ================

    #[abi(embed_v0)]
    impl AdditionalAdminImpl of IAdditionalAdmin<ContractState> {
        fn remove_moderator(ref self: ContractState, moderator: ContractAddress) {
            self.assert_only_admin();
            assert(self.moderators.entry(moderator).read(), 'Not a moderator');
            
            self.moderators.entry(moderator).write(false);
            let current_count = self.moderator_count.read();
            self.moderator_count.write(current_count - 1);

            self.emit(ModeratorRemoved {
                moderator,
                removed_by: get_caller_address(),
            });
        }

        fn is_moderator(self: @ContractState, address: ContractAddress) -> bool {
            self.moderators.entry(address).read()
        }

        fn get_moderator_count(self: @ContractState) -> u32 {
            self.moderator_count.read()
        }

        fn emergency_pause(ref self: ContractState, reason: ByteArray) {
            self.assert_only_admin();
            self.is_paused.write(true);
            self.emergency_pause_reason.write(reason.clone());

            self.emit(EmergencyPaused {
                paused_by: get_caller_address(),
                reason,
            });
        }

        fn emergency_unpause(ref self: ContractState) {
            self.assert_only_admin();
            self.is_paused.write(false);
            self.emergency_pause_reason.write("");
        }

        fn pause_market_creation(ref self: ContractState) {
            self.assert_only_admin();
            self.market_creation_paused.write(true);
        }

        fn unpause_market_creation(ref self: ContractState) {
            self.assert_only_admin();
            self.market_creation_paused.write(false);
        }

        fn pause_betting(ref self: ContractState) {
            self.assert_only_admin();
            self.betting_paused.write(true);
        }

        fn unpause_betting(ref self: ContractState) {
            self.assert_only_admin();
            self.betting_paused.write(false);
        }

        fn pause_resolution(ref self: ContractState) {
            self.assert_only_admin();
            self.resolution_paused.write(true);
        }

        fn unpause_resolution(ref self: ContractState) {
            self.assert_only_admin();
            self.resolution_paused.write(false);
        }

        fn set_time_restrictions(
            ref self: ContractState,
            min_duration: u64,
            max_duration: u64,
            resolution_window: u64,
        ) {
            self.assert_only_admin();
            assert(min_duration > 0, 'Min duration must be positive');
            assert(max_duration > min_duration, 'Max must be greater than min');
            assert(resolution_window > 0, 'Resolution window positive');
            
            self.min_market_duration.write(min_duration);
            self.max_market_duration.write(max_duration);
            self.resolution_window.write(resolution_window);
        }

        fn set_platform_fee(ref self: ContractState, fee_percentage: u256) {
            self.assert_only_admin();
            assert(fee_percentage <= 1000, 'Fee cannot exceed 10%'); // 1000 basis points = 10%
            self.platform_fee_percentage.write(fee_percentage);
        }

        fn get_platform_fee(self: @ContractState) -> u256 {
            self.platform_fee_percentage.read()
        }

        fn is_paused(self: @ContractState) -> bool {
            self.is_paused.read()
        }

        fn get_emergency_pause_reason(self: @ContractState) -> ByteArray {
            self.emergency_pause_reason.read()
        }

        fn get_time_restrictions(self: @ContractState) -> (u64, u64, u64) {
            let min_duration = self.min_market_duration.read();
            let max_duration = self.max_market_duration.read();
            let resolution_window = self.resolution_window.read();
            (min_duration, max_duration, resolution_window)
        }
    }

    // ================ Helper Functions ================

    #[generate_trait]
    impl HelperImpl of HelperTrait {
        fn _update_market_totals(
            ref self: ContractState,
            market_id: u256,
            market_type: u8,
            choice_idx: u8,
            amount: u256,
        ) {
            if market_type == 0 {
                let mut market = self.predictions.entry(market_id).read();
                market.total_pool += amount;
                
                let (mut choice_0, mut choice_1) = market.choices;
                if choice_idx == 0 {
                    choice_0.staked_amount += amount;
                } else {
                    choice_1.staked_amount += amount;
                }
                market.choices = (choice_0, choice_1);
                
                self.predictions.entry(market_id).write(market);
            } else if market_type == 1 {
                let mut market = self.crypto_predictions.entry(market_id).read();
                market.total_pool += amount;
                
                let (mut choice_0, mut choice_1) = market.choices;
                if choice_idx == 0 {
                    choice_0.staked_amount += amount;
                } else {
                    choice_1.staked_amount += amount;
                }
                market.choices = (choice_0, choice_1);
                
                self.crypto_predictions.entry(market_id).write(market);
            } else if market_type == 2 {
                let mut market = self.sports_predictions.entry(market_id).read();
                market.total_pool += amount;
                
                let (mut choice_0, mut choice_1) = market.choices;
                if choice_idx == 0 {
                    choice_0.staked_amount += amount;
                } else {
                    choice_1.staked_amount += amount;
                }
                market.choices = (choice_0, choice_1);
                
                self.sports_predictions.entry(market_id).write(market);
            }
        }

        fn _get_market_resolution_info(
            self: @ContractState,
            market_id: u256,
            market_type: u8,
        ) -> (bool, Choice, u256, u256) {
            if market_type == 0 {
                let market = self.predictions.entry(market_id).read();
                if market.is_resolved {
                    let winning_choice = market.winning_choice.unwrap();
                    (true, winning_choice, market.total_pool, winning_choice.staked_amount)
                } else {
                    (false, Choice { label: 0, staked_amount: 0 }, 0, 0)
                }
            } else if market_type == 1 {
                let market = self.crypto_predictions.entry(market_id).read();
                if market.is_resolved {
                    let winning_choice = market.winning_choice.unwrap();
                    (true, winning_choice, market.total_pool, winning_choice.staked_amount)
                } else {
                    (false, Choice { label: 0, staked_amount: 0 }, 0, 0)
                }
            } else {
                let market = self.sports_predictions.entry(market_id).read();
                if market.is_resolved {
                    let winning_choice = market.winning_choice.unwrap();
                    (true, winning_choice, market.total_pool, winning_choice.staked_amount)
                } else {
                    (false, Choice { label: 0, staked_amount: 0 }, 0, 0)
                }
            }
        }
    }
}

// ================ Additional Admin Interface ================

#[starknet::interface]
pub trait IAdditionalAdmin<TContractState> {
    fn remove_moderator(ref self: TContractState, moderator: ContractAddress);
    fn is_moderator(self: @TContractState, address: ContractAddress) -> bool;
    fn get_moderator_count(self: @TContractState) -> u32;
    
    // Emergency controls
    fn emergency_pause(ref self: TContractState, reason: ByteArray);
    fn emergency_unpause(ref self: TContractState);
    
    // Granular pause controls
    fn pause_market_creation(ref self: TContractState);
    fn unpause_market_creation(ref self: TContractState);
    fn pause_betting(ref self: TContractState);
    fn unpause_betting(ref self: TContractState);
    fn pause_resolution(ref self: TContractState);
    fn unpause_resolution(ref self: TContractState);
    
    // Time and fee management
    fn set_time_restrictions(ref self: TContractState, min_duration: u64, max_duration: u64, resolution_window: u64);
    fn set_platform_fee(ref self: TContractState, fee_percentage: u256);
    fn get_platform_fee(self: @TContractState) -> u256;
    
    // Status queries
    fn is_paused(self: @TContractState) -> bool;
    fn get_emergency_pause_reason(self: @TContractState) -> ByteArray;
    fn get_time_restrictions(self: @TContractState) -> (u64, u64, u64);
}
