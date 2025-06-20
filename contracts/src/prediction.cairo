use core::num::traits::Zero;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
use pragma_lib::types::DataType;
use stakcast::admin_interface::IAdditionalAdmin;
use stakcast::interface::{
    BusinessPrediction, Choice, CryptoPrediction, IPredictionHub, PredictionMarket,
    SportsPrediction, UserBet, UserStake,
};
use starknet::storage::{Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};
use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};

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
        business_predictions: Map<u256, BusinessPrediction>,
        // User bets mapping: (user, market_id, market_type, bet_index) -> UserBet
        user_bets: Map<(ContractAddress, u256, u8, u8), UserBet>,
        user_bet_counts: Map<(ContractAddress, u256, u8), u8>,
        // Fee management
        fee_recipient: ContractAddress,
        platform_fee_percentage: u256, // Basis points (e.g., 250 = 2.5%)
        collected_fees: Map<u256, u256>, // market_id -> total_fees_collected
        total_fees_collected: u256,
        // Token integration - Multi-token support
        betting_token: ContractAddress, // Default ERC20 token used for betting (backward compatibility)
        supported_tokens: Map<felt252, ContractAddress>, // Map token names to addresses
        market_token: Map<u256, ContractAddress>, // Map market_id to specific token used
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
        resolution_window: u64, // Time window after market end for resolution
        // Betting restrictions
        min_bet_amount: u256, // Minimum bet amount
        max_bet_amount: u256, // Maximum bet amount per user per market
        // Pool management
        market_liquidity: Map<u256, u256>, // market_id -> available_liquidity
        total_value_locked: u256,
        // Reentrancy protection
        reentrancy_guard: bool,
        user_nonces: Map<ContractAddress, u256>, // Tracks nonce for each user
        market_ids: Map<u256, u256>,
    }

    #[event]
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
    }

    // ================ Constructor ================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        fee_recipient: ContractAddress,
        pragma_oracle: ContractAddress,
        betting_token: ContractAddress,
    ) {
        self.admin.write(admin);
        self.fee_recipient.write(fee_recipient);
        self.platform_fee_percentage.write(250); // 2.5% default fee
        self.pragma_oracle.write(pragma_oracle);

        self.betting_token.write(betting_token);

        // Initialize supported tokens with Starknet mainnet addresses
        self._initialize_supported_tokens();

        // Set default time restrictions
        self.min_market_duration.write(3600); // 1 hour minimum
        self.max_market_duration.write(31536000); // 1 year maximum
        self.resolution_window.write(604800); // 1 week resolution window

        // Set default betting restrictions
        self.min_bet_amount.write(1000000000000000000); // 1 token (18 decimals)
        self.max_bet_amount.write(1000000000000000000000000); // 1M tokens

        // Initialize tracking
        self.total_fees_collected.write(0);
        self.total_value_locked.write(0);

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

            // Check that end_time is in the future first to avoid overflow in subtraction
            assert(end_time > current_time, 'End time must be in future');

            let duration = end_time - current_time;
            assert(duration >= min_duration, 'Market duration too short');
            assert(duration <= max_duration, 'Market duration too long');
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
            } else if market_type == 3 { // Business prediction
                let market = self.business_predictions.entry(market_id).read();
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
            } else if market_type == 3 {
                let market = self.business_predictions.entry(market_id).read();
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
            let min_bet = self.min_bet_amount.read();
            let max_bet = self.max_bet_amount.read();
            assert(amount >= min_bet, 'Amount below minimum');
            assert(amount <= max_bet, 'Amount above maximum');
        }

        fn assert_sufficient_token_balance(
            self: @ContractState, user: ContractAddress, amount: u256,
        ) {
            let token = IERC20Dispatcher { contract_address: self.betting_token.read() };
            let balance = token.balance_of(user);
            assert(balance >= amount, 'Insufficient token balance');
        }

        fn assert_sufficient_allowance(self: @ContractState, user: ContractAddress, amount: u256) {
            let token = IERC20Dispatcher { contract_address: self.betting_token.read() };
            let allowance = token.allowance(user, starknet::get_contract_address());
            assert(allowance >= amount, 'Insufficient token allowance');
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

            let market_id = self._generate_market_id();
            let count = self.prediction_count.read() + 1;
            self.prediction_count.write(count);
            self.market_ids.entry(count).write(market_id);

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

            self.emit(MarketCreated { market_id, creator: get_caller_address(), market_type: 0 });

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

            let market_id = self._generate_market_id();
            let count = self.prediction_count.read() + 1;
            self.prediction_count.write(count);
            self.market_ids.entry(count).write(market_id);

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

            self.emit(MarketCreated { market_id, creator: get_caller_address(), market_type: 1 });

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

            let market_id = self._generate_market_id();
            let count = self.prediction_count.read() + 1;
            self.prediction_count.write(count);
            self.market_ids.entry(count).write(market_id);

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

            self.emit(MarketCreated { market_id, creator: get_caller_address(), market_type: 2 });

            self.end_reentrancy_guard();
        }

        fn create_business_prediction(
            ref self: ContractState,
            title: ByteArray,
            description: ByteArray,
            choices: (felt252, felt252),
            category: felt252,
            image_url: ByteArray,
            end_time: u64,
            event_id: u64,
        ) {
            self.assert_not_paused();
            self.assert_market_creation_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_valid_market_timing(end_time);
            self.start_reentrancy_guard();

            let market_id = self._generate_market_id();
            let count = self.prediction_count.read() + 1;
            self.prediction_count.write(count);
            self.market_ids.entry(count).write(market_id);

            let (choice_0_label, choice_1_label) = choices;
            let choice_0 = Choice { label: choice_0_label, staked_amount: 0 };
            let choice_1 = Choice { label: choice_1_label, staked_amount: 0 };

            let market = BusinessPrediction {
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
            };

            self.business_predictions.entry(market_id).write(market);

            self.emit(MarketCreated { market_id, creator: get_caller_address(), market_type: 3 });

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
            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        predictions.append(market);
                    }
                }
                i += 1;
            }

            predictions
        }

        fn get_crypto_prediction(self: @ContractState, market_id: u256) -> CryptoPrediction {
            self.assert_market_exists(market_id, 1);
            self.crypto_predictions.entry(market_id).read()
        }

        fn get_all_crypto_predictions(self: @ContractState) -> Array<CryptoPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.crypto_predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        predictions.append(market);
                    }
                }
                i += 1;
            }

            predictions
        }

        fn get_sports_prediction(self: @ContractState, market_id: u256) -> SportsPrediction {
            self.assert_market_exists(market_id, 2);
            self.sports_predictions.entry(market_id).read()
        }

        fn get_all_sports_predictions(self: @ContractState) -> Array<SportsPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.sports_predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        predictions.append(market);
                    }
                }
                i += 1;
            }

            predictions
        }

        fn get_business_prediction(self: @ContractState, market_id: u256) -> BusinessPrediction {
            self.assert_market_exists(market_id, 3);
            self.business_predictions.entry(market_id).read()
        }

        fn get_all_business_predictions(self: @ContractState) -> Array<BusinessPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.business_predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        predictions.append(market);
                    }
                }
                i += 1;
            }

            predictions
        }

        fn get_active_prediction_markets(self: @ContractState) -> Array<PredictionMarket> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_open {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_active_sport_markets(self: @ContractState) -> Array<SportsPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.sports_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_open {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_active_crypto_markets(self: @ContractState) -> Array<CryptoPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.crypto_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_open {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_active_business_markets(self: @ContractState) -> Array<BusinessPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.business_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_open {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_resolved_prediction_markets(self: @ContractState) -> Array<PredictionMarket> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_resolved {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_resolved_sport_markets(self: @ContractState) -> Array<SportsPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.sports_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_resolved {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_resolved_crypto_markets(self: @ContractState) -> Array<CryptoPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.crypto_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_resolved {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_resolved_business_markets(self: @ContractState) -> Array<BusinessPrediction> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.business_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_resolved {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }


        fn is_prediction_market_open_for_betting(ref self: ContractState, market_id: u256) -> bool {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_market_exists(market_id, 0);

            let market = self.predictions.entry(market_id).read();
            if market.is_open {
                return true;
            } else {
                return false;
            }
        }

        fn is_crypto_market_open_for_betting(ref self: ContractState, market_id: u256) -> bool {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_market_exists(market_id, 1);

            let market = self.crypto_predictions.entry(market_id).read();
            if market.is_open {
                return true;
            } else {
                return false;
            }
        }

        fn is_sport_market_open_for_betting(ref self: ContractState, market_id: u256) -> bool {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_market_exists(market_id, 2);

            let market = self.sports_predictions.entry(market_id).read();
            if market.is_open {
                return true;
            } else {
                return false;
            }
        }

        fn is_business_market_open_for_betting(ref self: ContractState, market_id: u256) -> bool {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_market_exists(market_id, 3);

            let market = self.business_predictions.entry(market_id).read();
            if market.is_open {
                return true;
            } else {
                return false;
            }
        }
        // ================ Betting Functions ================

        fn place_bet(
            ref self: ContractState, market_id: u256, choice_idx: u8, amount: u256, market_type: u8,
        ) -> bool {
            self.place_wager(market_id, choice_idx, amount, market_type)
        }

        fn place_bet_with_token(
            ref self: ContractState,
            market_id: u256,
            choice_idx: u8,
            amount: u256,
            market_type: u8,
            token_name: felt252,
        ) -> bool {
            self.place_wager_with_token(market_id, choice_idx, amount, market_type, token_name)
        }

        fn place_wager(
            ref self: ContractState, market_id: u256, choice_idx: u8, amount: u256, market_type: u8,
        ) -> bool {
            self.assert_not_paused();
            self.assert_betting_not_paused();
            self.assert_market_exists(market_id, market_type);
            self.assert_market_open(market_id, market_type);
            self.assert_valid_choice(choice_idx);
            self.assert_valid_amount(amount);
            self.start_reentrancy_guard();

            let caller = get_caller_address();
            self.assert_sufficient_token_balance(caller, amount);
            self.assert_sufficient_allowance(caller, amount);

            // Calculate fees
            let fee_percentage = self.platform_fee_percentage.read();
            let fee_amount = (amount * fee_percentage) / 10000; // Basis points conversion
            let net_amount = amount - fee_amount;

            // Transfer tokens from user to contract
            let token = IERC20Dispatcher { contract_address: self.betting_token.read() };
            let success = token.transfer_from(caller, starknet::get_contract_address(), amount);
            assert(success, 'Token transfer failed');

            // Transfer fees to fee recipient
            if fee_amount > 0 {
                let fee_success = token.transfer(self.fee_recipient.read(), fee_amount);
                assert(fee_success, 'Fee transfer failed');

                // Track fees
                let current_market_fees = self.collected_fees.entry(market_id).read();
                self.collected_fees.entry(market_id).write(current_market_fees + fee_amount);
                self.total_fees_collected.write(self.total_fees_collected.read() + fee_amount);

                self
                    .emit(
                        FeesCollected {
                            market_id, fee_amount, fee_recipient: self.fee_recipient.read(),
                        },
                    );
            }

            // Create user bet with net amount
            let choice = self._get_choice_struct(market_id, market_type, choice_idx);
            let user_stake = UserStake { amount: net_amount, claimed: false };
            let user_bet = UserBet { choice, stake: user_stake };

            // Update user bets
            let count_key = (caller, market_id, market_type);
            let current_count = self.user_bet_counts.entry(count_key).read();
            let bet_key = (caller, market_id, market_type, current_count);

            self.user_bets.entry(bet_key).write(user_bet);
            self.user_bet_counts.entry(count_key).write(current_count + 1);

            // Update market totals with net amount
            self._update_market_totals(market_id, market_type, choice_idx, net_amount);

            // Update liquidity tracking
            let current_liquidity = self.market_liquidity.entry(market_id).read();
            self.market_liquidity.entry(market_id).write(current_liquidity + net_amount);
            self.total_value_locked.write(self.total_value_locked.read() + net_amount);

            // Emit comprehensive wager event
            self
                .emit(
                    WagerPlaced {
                        market_id,
                        user: caller,
                        choice: choice_idx,
                        amount,
                        fee_amount,
                        net_amount,
                        wager_index: current_count,
                    },
                );

            self.end_reentrancy_guard();
            true
        }

        fn place_wager_with_token(
            ref self: ContractState,
            market_id: u256,
            choice_idx: u8,
            amount: u256,
            market_type: u8,
            token_name: felt252,
        ) -> bool {
            self.assert_not_paused();
            self.assert_betting_not_paused();
            self.assert_market_exists(market_id, market_type);
            self.assert_market_open(market_id, market_type);
            self.assert_valid_choice(choice_idx);
            self.assert_valid_amount(amount);
            self.start_reentrancy_guard();

            let caller = get_caller_address();

            // Get token address from the mapping
            let token_address = self.get_asset_address(token_name);
            assert(!token_address.is_zero(), 'Unsupported token');

            // Store the token used for this market (for consistency)
            let existing_market_token = self.market_token.entry(market_id).read();
            if existing_market_token.is_zero() {
                self.market_token.entry(market_id).write(token_address);
            } else {
                // Ensure all bets on this market use the same token
                assert(existing_market_token == token_address, 'Market token mismatch');
            }

            self.assert_sufficient_token_balance_for_token(caller, amount, token_address);
            self.assert_sufficient_allowance_for_token(caller, amount, token_address);

            // Calculate fees
            let fee_percentage = self.platform_fee_percentage.read();
            let fee_amount = (amount * fee_percentage) / 10000; // Basis points conversion
            let net_amount = amount - fee_amount;

            // Transfer tokens from user to contract
            let token = IERC20Dispatcher { contract_address: token_address };
            let success = token.transfer_from(caller, starknet::get_contract_address(), amount);
            assert(success, 'Token transfer failed');

            // Transfer fees to fee recipient
            if fee_amount > 0 {
                let fee_success = token.transfer(self.fee_recipient.read(), fee_amount);
                assert(fee_success, 'Fee transfer failed');

                // Track fees
                let current_market_fees = self.collected_fees.entry(market_id).read();
                self.collected_fees.entry(market_id).write(current_market_fees + fee_amount);
                self.total_fees_collected.write(self.total_fees_collected.read() + fee_amount);

                self
                    .emit(
                        FeesCollected {
                            market_id, fee_amount, fee_recipient: self.fee_recipient.read(),
                        },
                    );
            }

            // Create user bet with net amount
            let choice = self._get_choice_struct(market_id, market_type, choice_idx);
            let user_stake = UserStake { amount: net_amount, claimed: false };
            let user_bet = UserBet { choice, stake: user_stake };

            // Update user bets
            let count_key = (caller, market_id, market_type);
            let current_count = self.user_bet_counts.entry(count_key).read();
            let bet_key = (caller, market_id, market_type, current_count);

            self.user_bets.entry(bet_key).write(user_bet);
            self.user_bet_counts.entry(count_key).write(current_count + 1);

            // Update market totals with net amount
            self._update_market_totals(market_id, market_type, choice_idx, net_amount);

            // Update liquidity tracking
            let current_liquidity = self.market_liquidity.entry(market_id).read();
            self.market_liquidity.entry(market_id).write(current_liquidity + net_amount);
            self.total_value_locked.write(self.total_value_locked.read() + net_amount);

            // Emit comprehensive wager event
            self
                .emit(
                    WagerPlaced {
                        market_id,
                        user: caller,
                        choice: choice_idx,
                        amount,
                        fee_amount,
                        net_amount,
                        wager_index: current_count,
                    },
                );

            self.end_reentrancy_guard();
            true
        }

        fn get_bet_count_for_market(
            self: @ContractState, user: ContractAddress, market_id: u256, market_type: u8,
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

            // Verify choice label is valid ('Yes' or 'No')
            assert(
                winning_choice_struct.label == 'Yes' || winning_choice_struct.label == 'No',
                'Invalid winning choice label',
            );

            market.winning_choice = Option::Some(winning_choice_struct);
            self.predictions.entry(market_id).write(market);

            self.emit(MarketResolved { market_id, resolver: get_caller_address(), winning_choice });

            self.end_reentrancy_guard();
        }

        fn resolve_crypto_prediction_manually(
            ref self: ContractState, market_id: u256, winning_choice: u8,
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

            self.emit(MarketResolved { market_id, resolver: get_caller_address(), winning_choice });

            self.end_reentrancy_guard();
        }

        fn resolve_sports_prediction_manually(
            ref self: ContractState, market_id: u256, winning_choice: u8,
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

            self.emit(MarketResolved { market_id, resolver: get_caller_address(), winning_choice });

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
                if current_price < market.target_value.into() {
                    0
                } else {
                    1
                }
            } else {
                // Greater than target
                if current_price > market.target_value.into() {
                    0
                } else {
                    1
                }
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

            self.emit(MarketResolved { market_id, resolver: get_caller_address(), winning_choice });

            self.end_reentrancy_guard();
        }

        fn resolve_sports_prediction(ref self: ContractState, market_id: u256, winning_choice: u8) {
            // This would integrate with sports data API in production
            self.resolve_sports_prediction_manually(market_id, winning_choice);
        }

        fn resolve_business_prediction_manually(
            ref self: ContractState, market_id: u256, winning_choice: u8,
        ) {
            self.assert_not_paused();
            self.assert_resolution_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_market_exists(market_id, 3);
            self.assert_valid_choice(winning_choice);
            self.start_reentrancy_guard();

            let mut market = self.business_predictions.entry(market_id).read();
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

            // Verify choice label is valid ('Yes' or 'No')
            assert(
                winning_choice_struct.label == 'Yes' || winning_choice_struct.label == 'No',
                'Invalid winning choice label',
            );

            market.winning_choice = Option::Some(winning_choice_struct);
            self.business_predictions.entry(market_id).write(market);

            self.emit(MarketResolved { market_id, resolver: get_caller_address(), winning_choice });

            self.end_reentrancy_guard();
        }

        // ================ Winnings Management ================

        fn collect_winnings(
            ref self: ContractState, market_id: u256, market_type: u8, bet_idx: u8,
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
            let (is_resolved, winning_choice, total_pool, winning_pool) = self
                ._get_market_resolution_info(market_id, market_type);
            assert(is_resolved, 'Market not resolved');

            let user_won = user_bet.choice.label == winning_choice.label;
            assert(user_won, 'User did not win');

            // Calculate winnings
            let user_stake = user_bet.stake.amount;
            let winnings = if winning_pool > 0 {
                (user_stake * total_pool) / winning_pool
            } else {
                user_stake // Return original stake if no one won
            };

            // Transfer winnings to user using the correct token for this market
            let market_token_address = self.get_market_token(market_id);
            let token = IERC20Dispatcher { contract_address: market_token_address };
            let success = token.transfer(caller, winnings);
            assert(success, 'Winnings transfer failed');

            // Update liquidity tracking
            let current_liquidity = self.market_liquidity.entry(market_id).read();
            self.market_liquidity.entry(market_id).write(current_liquidity - winnings);
            self.total_value_locked.write(self.total_value_locked.read() - winnings);

            // Mark as claimed
            user_bet.stake.claimed = true;

            // Update the bet in storage
            self.user_bets.entry(bet_key).write(user_bet);

            self
                .emit(
                    WinningsCollected {
                        market_id, user: caller, amount: winnings, wager_index: bet_idx,
                    },
                );

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
                                let (is_resolved, winning_choice, total_pool, winning_pool) = self
                                    ._get_market_resolution_info(market_id, market_type);

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
                }
                market_id += 1;
            }

            total_claimable
        }

        // ================ User Queries ================

        fn get_user_predictions(
            self: @ContractState, user: ContractAddress,
        ) -> Array<PredictionMarket> {
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
            }

            user_markets
        }

        fn get_user_crypto_predictions(
            self: @ContractState, user: ContractAddress,
        ) -> Array<CryptoPrediction> {
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
            }

            user_markets
        }

        fn get_user_sports_predictions(
            self: @ContractState, user: ContractAddress,
        ) -> Array<SportsPrediction> {
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
            }

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

            self.emit(ModeratorAdded { moderator, added_by: get_caller_address() });
        }

        fn remove_all_predictions(ref self: ContractState) {
            self.assert_only_admin();
            self.prediction_count.write(0);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.assert_only_admin();
            assert(impl_hash.is_non_zero(), 'Class hash cannot be zero');
            starknet::syscalls::replace_class_syscall(impl_hash).unwrap();
        }

        // ================ Enhanced Betting Functions ================

        fn get_betting_token(self: @ContractState) -> ContractAddress {
            self.betting_token.read()
        }

        fn get_market_fees(self: @ContractState, market_id: u256) -> u256 {
            self.collected_fees.entry(market_id).read()
        }

        fn get_total_fees_collected(self: @ContractState) -> u256 {
            self.total_fees_collected.read()
        }

        fn get_betting_restrictions(self: @ContractState) -> (u256, u256) {
            let min_bet = self.min_bet_amount.read();
            let max_bet = self.max_bet_amount.read();
            (min_bet, max_bet)
        }

        fn get_market_liquidity(self: @ContractState, market_id: u256) -> u256 {
            self.market_liquidity.entry(market_id).read()
        }

        fn get_total_value_locked(self: @ContractState) -> u256 {
            self.total_value_locked.read()
        }

        // ================ Multi-Token Support Functions ================

        fn get_supported_token(self: @ContractState, token_name: felt252) -> ContractAddress {
            self.get_asset_address(token_name)
        }

        fn get_market_token(self: @ContractState, market_id: u256) -> ContractAddress {
            let market_token = self.market_token.entry(market_id).read();
            if market_token.is_zero() {
                self.betting_token.read() // Return default token if no specific token set
            } else {
                market_token
            }
        }

        fn is_token_supported(self: @ContractState, token_name: felt252) -> bool {
            !self.get_asset_address(token_name).is_zero()
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

            self.emit(ModeratorRemoved { moderator, removed_by: get_caller_address() });
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

            self.emit(EmergencyPaused { paused_by: get_caller_address(), reason });
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
            ref self: ContractState, min_duration: u64, max_duration: u64, resolution_window: u64,
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

        fn is_market_creation_paused(self: @ContractState) -> bool {
            self.market_creation_paused.read()
        }

        fn is_betting_paused(self: @ContractState) -> bool {
            self.betting_paused.read()
        }

        fn is_resolution_paused(self: @ContractState) -> bool {
            self.resolution_paused.read()
        }

        fn set_oracle_address(ref self: ContractState, oracle: ContractAddress) {
            self.assert_only_admin();
            self.pragma_oracle.write(oracle);
        }

        fn get_oracle_address(self: @ContractState) -> ContractAddress {
            self.pragma_oracle.read()
        }

        fn get_market_stats(self: @ContractState) -> (u256, u256, u256) {
            let total_markets = self.prediction_count.read();
            let mut active_markets = 0;
            let mut resolved_markets = 0;
            let mut i = 1;

            while i <= total_markets {
                // Check all market types
                let mut market_type: u8 = 0;
                while market_type < 3_u8 {
                    println!("resolved_markets------2-: {}", resolved_markets);
                    if market_type == 0 {
                        let market = self.predictions.entry(i).read();
                        if market.market_id != 0 {
                            if market.is_resolved {
                                resolved_markets += 1;
                                println!("resolved_markets-------: {}", resolved_markets);
                            } else if market.is_open {
                                active_markets += 1;
                            }
                        }
                    } else if market_type == 1 {
                        let market = self.crypto_predictions.entry(i).read();
                        if market.market_id != 0 {
                            if market.is_resolved {
                                resolved_markets += 1;
                            } else if market.is_open {
                                active_markets += 1;
                            }
                        }
                    } else if market_type == 2 {
                        let market = self.sports_predictions.entry(i).read();
                        if market.market_id != 0 {
                            if market.is_resolved {
                                resolved_markets += 1;
                            } else if market.is_open {
                                active_markets += 1;
                            }
                        }
                    }
                    market_type += 1;
                }
                i += 1;
            }

            (total_markets, active_markets, resolved_markets)
        }

        fn emergency_close_market(ref self: ContractState, market_id: u256, market_type: u8) {
            self.assert_only_admin();
            self.assert_market_exists(market_id, market_type);

            if market_type == 0 {
                let mut market = self.predictions.entry(market_id).read();
                market.is_open = false;
                self.predictions.entry(market_id).write(market);
            } else if market_type == 1 {
                let mut market = self.crypto_predictions.entry(market_id).read();
                market.is_open = false;
                self.crypto_predictions.entry(market_id).write(market);
            } else if market_type == 2 {
                let mut market = self.sports_predictions.entry(market_id).read();
                market.is_open = false;
                self.sports_predictions.entry(market_id).write(market);
            } else {
                let mut market = self.business_predictions.entry(market_id).read();
                market.is_open = false;
                self.business_predictions.entry(market_id).write(market);
            }
        }

        fn emergency_close_multiple_markets(
            ref self: ContractState, market_ids: Array<u256>, market_types: Array<u8>,
        ) {
            self.assert_only_admin();
            assert(market_ids.len() == market_types.len(), 'Arrays length mismatch');

            let mut i = 0;
            while i < market_ids.len() {
                let market_id = *market_ids.at(i);
                let market_type = *market_types.at(i);
                self.emergency_close_market(market_id, market_type);
                i += 1;
            };
        }

        fn set_betting_token(ref self: ContractState, token_address: ContractAddress) {
            self.assert_only_admin();
            self.betting_token.write(token_address);
        }

        fn set_betting_restrictions(ref self: ContractState, min_amount: u256, max_amount: u256) {
            self.assert_only_admin();
            assert(min_amount > 0, 'Min amount must be positive');
            assert(max_amount > min_amount, 'Max must be greater than min');

            self.min_bet_amount.write(min_amount);
            self.max_bet_amount.write(max_amount);
        }

        fn emergency_withdraw_tokens(
            ref self: ContractState, amount: u256, recipient: ContractAddress,
        ) {
            self.assert_only_admin();
            assert(amount > 0, 'Amount must be positive');

            let token = IERC20Dispatcher { contract_address: self.betting_token.read() };
            let success = token.transfer(recipient, amount);
            assert(success, 'Emergency withdrawal failed');
        }

        fn emergency_withdraw_specific_token(
            ref self: ContractState, token_name: felt252, amount: u256, recipient: ContractAddress,
        ) {
            self.assert_only_admin();
            assert(amount > 0, 'Amount must be positive');

            let token_address = self.get_asset_address(token_name);
            assert(!token_address.is_zero(), 'Unsupported token');

            let token = IERC20Dispatcher { contract_address: token_address };
            let success = token.transfer(recipient, amount);
            assert(success, 'Emergency withdrawal failed');
        }

        fn add_supported_token(
            ref self: ContractState, token_name: felt252, token_address: ContractAddress,
        ) {
            self.assert_only_admin();
            assert(!token_address.is_zero(), 'Invalid token address');
            self.supported_tokens.entry(token_name).write(token_address);
        }

        fn remove_supported_token(ref self: ContractState, token_name: felt252) {
            self.assert_only_admin();
            self.supported_tokens.entry(token_name).write(0.try_into().unwrap());
        }
    }

    // ================ Helper Functions ================

    #[generate_trait]
    impl HelperImpl of HelperTrait {
        fn _update_market_totals(
            ref self: ContractState, market_id: u256, market_type: u8, choice_idx: u8, amount: u256,
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
            self: @ContractState, market_id: u256, market_type: u8,
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

        fn _get_choice_struct(
            self: @ContractState, market_id: u256, market_type: u8, choice_idx: u8,
        ) -> Choice {
            if choice_idx == 0 {
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
            }
        }

        fn _generate_market_id(ref self: ContractState) -> u256 {
            let caller = get_caller_address();
            let timestamp = get_block_timestamp();
            let nonce = self.user_nonces.entry(caller).read();

            // Increment Nonce for the next market
            self.user_nonces.entry(caller).write(nonce + 1);

            // Generate market ID using sequential counter
            let timestamp_part: u256 = (timestamp.into()) * 0x1000000000000000000000000;
            let caller_felt: felt252 = caller.into();
            let address_part: u256 = (caller_felt.into() & 0xFFFFFFFFFFFFFFFF);
            let nonce_part: u256 = nonce & 0xFFFF;

            timestamp_part | address_part | nonce_part
        }

        fn get_asset_address(self: @ContractState, token_name: felt252) -> ContractAddress {
            // Return the token address from supported tokens mapping
            // Admin must explicitly add tokens for security
            self.supported_tokens.entry(token_name).read()
        }

        fn _initialize_supported_tokens(
            ref self: ContractState,
        ) { // Initialize supported tokens storage
        // Admin must explicitly add tokens using add_supported_token()
        // This ensures no hardcoded mainnet addresses in tests
        }

        fn assert_sufficient_token_balance_for_token(
            self: @ContractState,
            user: ContractAddress,
            amount: u256,
            token_address: ContractAddress,
        ) {
            let token = IERC20Dispatcher { contract_address: token_address };
            let balance = token.balance_of(user);
            assert(balance >= amount, 'Insufficient token balance');
        }

        fn assert_sufficient_allowance_for_token(
            self: @ContractState,
            user: ContractAddress,
            amount: u256,
            token_address: ContractAddress,
        ) {
            let token = IERC20Dispatcher { contract_address: token_address };
            let allowance = token.allowance(user, starknet::get_contract_address());
            assert(allowance >= amount, 'Insufficient token allowance');
        }
    }
}
