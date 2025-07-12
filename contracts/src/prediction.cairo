use core::num::traits::Zero;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
use pragma_lib::types::DataType;
use stakcast::admin_interface::IAdditionalAdmin;
use stakcast::events::{
    BetPlaced, EmergencyPaused, Event, FeesCollected, MarketCreated, MarketResolved, ModeratorAdded,
    ModeratorRemoved, WagerPlaced, WinningsCollected,
};
use stakcast::interface::IPredictionHub;
use stakcast::types::{Choice, MarketStatus, Outcome, PredictionMarket, UserStake};
use starknet::storage::{Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};
use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};

// ================ Contract Storage ================

#[starknet::contract]
pub mod PredictionHub {
    use starknet::storage::{MutableVecTrait, Vec};
    use crate::types::MarketStats;
    use super::{*, StoragePathEntry, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        // Access control
        admin: ContractAddress,
        moderators: Map<ContractAddress, bool>,
        moderator_count: u32,
        // Market data
        prediction_count: u256,
        predictions: Map<u256, PredictionMarket>,
        all_predictions: Map<u256, PredictionMarket>,
        crypto_predictions: Map<u256, PredictionMarket>,
        sports_predictions: Map<u256, PredictionMarket>,
        // bets placed
        bet_details: Map<(u256, ContractAddress), UserStake>,
        fee_recipient: ContractAddress,
        platform_fee_percentage: u256,
        // Token integration - Multi-token support
        protocol_token: ContractAddress,
        supported_tokens: Vec<ContractAddress>,
        // Oracle integration
        pragma_oracle: ContractAddress,
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
        market_liquidity: Map<u256, u256>,
        total_value_locked: u256,
        // Reentrancy protection
        reentrancy_guard: bool,
        user_nonces: Map<ContractAddress, u256>, // Tracks nonce for each user
        market_ids: Map<u256, u256>,
        market_stats: Map<u256, MarketStats>,
        // user traded status
        user_traded_status: Map<
            (u256, ContractAddress), bool,
        >, // Tracks if user has traded on a market
        // more market analytics
        market_analytics: Map<
            u256, Vec<(ContractAddress, u256)>,
        > // market to a list of (user, amount) tuples
    }

    const PRECISION: u256 = 1000000000000000000; // 18 decimals now
    const HALF: u256 = 500000000000000000;
    #[event]
    use stakcast::events::Event;

    // ================ Constructor ================

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        fee_recipient: ContractAddress,
        pragma_oracle: ContractAddress,
        protocol_token: ContractAddress,
    ) {
        self.admin.write(admin);
        self.fee_recipient.write(fee_recipient);
        self.platform_fee_percentage.write(250); // 2.5% default fee
        self.pragma_oracle.write(pragma_oracle);

        self.protocol_token.write(protocol_token);

        // Set default time restrictions
        self.min_market_duration.write(3600); // 1 hour minimum
        self.max_market_duration.write(31536000); // 1 year maximum
        self.resolution_window.write(604800); // 1 week resolution window

        // Set default betting restrictions
        self.min_bet_amount.write(1000000000000000000); // 1 token (18 decimals)
        self.max_bet_amount.write(1000000000000000000000000); // 1M tokens

        // Initialize tracking
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

        /// @notice Asserts that the market is open, not resolved, and has not ended
        fn assert_market_open(self: @ContractState, market_id: u256, market_type: u8) {
            let market = match market_type {
                0 => self.predictions.entry(market_id).read(),
                1 => self.crypto_predictions.entry(market_id).read(),
                2 => self.sports_predictions.entry(market_id).read(),
                _ => panic!("Invalid market type"),
            };

            assert(market.is_open, 'Market is closed');
            assert(!market.is_resolved, 'Market already resolved');
            assert(get_block_timestamp() < market.end_time, 'Market has ended');
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

        /// @notice Asserts that the provided choice is valid (1 or 2)
        fn assert_valid_choice(self: @ContractState, choice: u8) {
            assert(choice < 2, 'Invalid choice selected');
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
            let token = IERC20Dispatcher { contract_address: self.protocol_token.read() };
            let balance = token.balance_of(user);
            assert(balance >= amount, 'Insufficient token balance');
        }

        fn assert_sufficient_allowance(self: @ContractState, user: ContractAddress, amount: u256) {
            let token = IERC20Dispatcher { contract_address: self.protocol_token.read() };
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

    #[generate_trait]
    impl PrecisionImpl of PrecisionTrait {
        fn multiply(self: @ContractState, a: u256, b: u256) -> u256 {
            (a * b) / PRECISION
        }

        fn divide(self: @ContractState, a: u256, b: u256) -> u256 {
            if b == 0 {
                return 0;
            }
            (a * PRECISION) / b
        }

        fn add(self: @ContractState, a: u256, b: u256) -> u256 {
            a + b
        }

        fn subtract(self: @ContractState, a: u256, b: u256) -> u256 {
            if a >= b {
                a - b
            } else {
                0
            }
        }
    }

    // ================ IPredictionHub Implementation ================

    #[abi(embed_v0)]
    impl PredictionHubImpl of IPredictionHub<ContractState> {
        // ================ Market Creation ================

        fn create_predictions(
            ref self: ContractState,
            title: ByteArray,
            description: ByteArray,
            choices: (felt252, felt252),
            category: felt252,
            end_time: u64,
            prediction_market_type: u8,
            crypto_prediction: Option<(felt252, u128)>,
            sports_prediction: Option<(u64, bool)>,
        ) {
            self.assert_not_paused();
            self.assert_market_creation_not_paused();
            self.assert_only_moderator_or_admin();
            self.assert_valid_market_timing(end_time);
            assert(prediction_market_type <= 2, 'Invalid market type');

            self.start_reentrancy_guard();

            let market_id = self._generate_market_id();
            let count = self.prediction_count.read() + 1;
            self.prediction_count.write(count);
            self.market_ids.entry(count).write(market_id);

            let (choice_0_label, choice_1_label) = choices;

            let market_stats = MarketStats {
                total_traders: 0,
                traders_option_a: 0,
                traders_option_b: 0,
                amount_staked_option_a: 0,
                amount_staked_option_b: 0,
                total_trades: 0,
            };
            let mut market = PredictionMarket {
                title,
                market_id,
                description,
                choices: (
                    Choice { label: choice_0_label, staked_amount: 0 },
                    Choice { label: choice_1_label, staked_amount: 0 },
                ),
                category,
                is_resolved: false,
                is_open: true,
                end_time,
                status: MarketStatus::Active,
                winning_choice: Option::None,
                total_shares_option_one: HALF,
                total_shares_option_two: HALF,
                total_pool: PRECISION,
                prediction_market_type,
                crypto_prediction: if prediction_market_type == 1 {
                    crypto_prediction
                } else {
                    Option::None
                },
                sports_prediction: if prediction_market_type == 2 {
                    sports_prediction
                } else {
                    Option::None
                },
            };

            self.all_predictions.entry(market_id).write(market.clone());

            self.market_stats.entry(market_id).write(market_stats);

            // Type-specific storage
            match prediction_market_type {
                0 => self.predictions.entry(market_id).write(market),
                1 => self.crypto_predictions.entry(market_id).write(market),
                2 => self.sports_predictions.entry(market_id).write(market),
                _ => {},
            }

            self
                .emit(
                    MarketCreated {
                        market_id,
                        creator: get_caller_address(),
                        market_type: prediction_market_type,
                    },
                );

            self.end_reentrancy_guard();
        }

        // ================ Market Queries ================

        fn get_prediction_count(self: @ContractState) -> u256 {
            self.prediction_count.read()
        }

        fn get_prediction(
            self: @ContractState, market_id: u256, market_type: u8,
        ) -> PredictionMarket {
            self.assert_market_exists(market_id, market_type);
            self.all_predictions.entry(market_id).read()
        }


        fn get_all_predictions_by_market_type(
            self: @ContractState, market_type: u8,
        ) -> Array<PredictionMarket> {
            assert(market_type <= 2, 'Invalid market type!');

            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = match market_type {
                        0 => self.predictions.entry(market_id).read(),
                        1 => self.crypto_predictions.entry(market_id).read(),
                        2 => self.sports_predictions.entry(market_id).read(),
                        _ => panic!("Invalid market type!"),
                    };

                    if market.market_id != 0 {
                        predictions.append(market);
                    }
                }
                i += 1;
            }

            predictions
        }

        fn get_all_predictions(self: @ContractState) -> Array<PredictionMarket> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.all_predictions.entry(market_id).read();
                    if market.market_id != 0 {
                        predictions.append(market);
                    }
                }
                i += 1;
            }

            predictions
        }


        /// @dev depriciated
        fn get_all_general_predictions(self: @ContractState) -> Array<PredictionMarket> {
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
        /// @dev depriciated
        fn get_all_crypto_predictions(self: @ContractState) -> Array<PredictionMarket> {
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
        /// @dev depriciated
        fn get_all_sports_predictions(self: @ContractState) -> Array<PredictionMarket> {
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

        fn get_market_status(
            self: @ContractState, market_id: u256, market_type: u8,
        ) -> (bool, bool) {
            if market_type == 0 {
                let market = self.predictions.entry(market_id).read();
                (market.is_open, market.is_resolved)
            } else if market_type == 1 {
                let market = self.sports_predictions.entry(market_id).read();
                (market.is_open, market.is_resolved)
            } else if market_type == 2 {
                let market = self.crypto_predictions.entry(market_id).read();
                (market.is_open, market.is_resolved)
            } else {
                panic!("Market not found")
            }
        }

        fn calculate_share_prices(ref self: ContractState, market_id: u256) -> (u256, u256) {
            let market = self.all_predictions.entry(market_id).read();
            let total_shares: u256 = market.total_pool; // 11000000 tso1 20500000 ts02 500000
            let price_a = self.divide(market.total_shares_option_one, total_shares); // 1863636
            let price_b = self.divide(market.total_shares_option_two, total_shares); // 45454

            let total_price = price_a + price_b; // 1909090

            // if total_price > 0 {
            let normalized_a = self.divide(self.multiply(price_a, PRECISION), total_price);
            let normalized_b = PRECISION - normalized_a; // Ensure sum = 1.0
            (normalized_a, normalized_b)
            // } else {
        //     (HALF, HALF)
        // }
        }

        fn buy_shares(
            ref self: ContractState,
            market_id: u256,
            choice: Outcome,
            amount: u256,
            token: ContractAddress,
        ) {
            self.assert_not_paused();
            self.assert_betting_not_paused();
            self.assert_resolution_not_paused();
            // self.assert_valid_choice(choice);
            // self.assert_valid_amount(amount);

            let fixed_point_amount_format = amount * PRECISION;

            self.assert_market_open(market_id, 0);

            self.start_reentrancy_guard();

            let (price_a, price_b) = self.calculate_share_prices(market_id);

            let mut market = self.all_predictions.entry(market_id).read();
            let mut choice_details: (u256, u256) = (0, 0);
            let mut user_stake: UserStake = self
                .bet_details
                .entry((market_id, get_caller_address()))
                .read();

            // Check if user has traded on this market before
            let user_traded = self
                .user_traded_status
                .entry((market_id, get_caller_address()))
                .read();
            let mut market_stats = self.market_stats.entry(market_id).read();

            if !user_traded {
                market_stats.total_trades += 1;
                self.user_traded_status.entry((market_id, get_caller_address())).write(true);
            }

            // Update market stats

            match choice {
                Outcome::Option1 => {
                    let shares = self.divide(fixed_point_amount_format, price_a);
                    market.total_shares_option_one += shares;
                    user_stake.shares_a = user_stake.shares_a + shares;
                    market_stats.traders_option_a += 1;
                    market_stats.amount_staked_option_a += fixed_point_amount_format;
                },
                Outcome::Option2 => {
                    let shares = self.divide(fixed_point_amount_format, price_b);
                    market.total_shares_option_two += shares;
                    user_stake.shares_b = user_stake.shares_b + shares;
                    market_stats.traders_option_b += 1;
                    market_stats.amount_staked_option_b += fixed_point_amount_format;
                },
                _ => panic!("Invalid choice selected"),
            }

            user_stake.total_invested = user_stake.total_invested + fixed_point_amount_format;
            market.total_pool = market.total_pool + fixed_point_amount_format;
            market_stats.total_trades += 1;
            self.bet_details.entry((market_id, get_caller_address())).write(user_stake);

            // update market analytics
            let mut analytics = self
                .market_analytics
                .entry(market_id)
                .append()
                .write((get_caller_address(), fixed_point_amount_format));
            // Update market state
            self.all_predictions.entry(market_id).write(market);
            // End reentrancy guard
            self.end_reentrancy_guard();
        }

        fn get_market_activity(
            ref self: ContractState, market_id: u256,
        ) -> Array<(ContractAddress, u256)> {
            let mut market_activity_array = ArrayTrait::new();
            let market_activity = self.market_analytics.entry(market_id);
            for i in 0..market_activity.len() {
                let analytics = market_activity.at(i).read();
                market_activity_array.append(analytics);
            }
            market_activity_array
        }


        fn get_user_stake_details(
            ref self: ContractState, market_id: u256, user: ContractAddress,
        ) -> UserStake {
            self.bet_details.entry((market_id, user)).read()
        }

        fn get_active_prediction_markets(self: @ContractState) -> Array<PredictionMarket> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.all_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_open {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_active_general_prediction_markets(self: @ContractState) -> Array<PredictionMarket> {
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

        fn get_active_sport_markets(self: @ContractState) -> Array<PredictionMarket> {
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

        fn get_active_crypto_markets(self: @ContractState) -> Array<PredictionMarket> {
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

        fn get_all_resolved_prediction_markets(self: @ContractState) -> Array<PredictionMarket> {
            let mut predictions = ArrayTrait::new();
            let count = self.prediction_count.read();

            for i in 0..=count {
                let market_id = self.market_ids.entry(i).read();
                if market_id != 0 {
                    let market = self.all_predictions.entry(market_id).read();
                    if market.market_id != 0 && market.is_resolved {
                        predictions.append(market);
                    }
                }
            }

            predictions
        }

        fn get_resolved_general_prediction_markets(
            self: @ContractState,
        ) -> Array<PredictionMarket> {
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

        fn get_resolved_sport_markets(self: @ContractState) -> Array<PredictionMarket> {
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

        fn get_resolved_crypto_markets(self: @ContractState) -> Array<PredictionMarket> {
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

        fn is_prediction_market_open_for_betting(ref self: ContractState, market_id: u256) -> bool {
            self.assert_not_paused();
            self.assert_resolution_not_paused();

            let market = self.all_predictions.entry(market_id).read();
            if market.is_open {
                return true;
            } else {
                return false;
            }
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
            let (asset_key, target_value) = market.crypto_prediction.unwrap();
            // Get price from Pragma Oracle
            let oracle = IPragmaABIDispatcher { contract_address: self.pragma_oracle.read() };
            let price_response = oracle.get_data_median(DataType::SpotEntry(asset_key));
            let current_price = price_response.price;

            // // Determine winning choice based on comparison
            // let winning_choice = if comparison_type == 0 {
            //     // Less than target
            //     if current_price < target_value.into() {
            //         0
            //     } else {
            //         1
            //     }
            // } else {
            //     // Greater than target
            //     if current_price > target_value.into() {
            //         0
            //     } else {
            //         1
            //     }
            // };

            market.is_resolved = true;
            market.is_open = false;

            // let winning_choice_struct = if winning_choice == 0 {
            //     let (choice_0, _choice_1) = market.choices;
            //     choice_0
            // } else {
            //     let (_choice_0, choice_1) = market.choices;
            //     choice_1
            // };

            // market.winning_choice = Option::Some(winning_choice_struct);
            self.crypto_predictions.entry(market_id).write(market);

            // self.emit(MarketResolved { market_id, resolver: get_caller_address(), winning_choice
            // });

            self.end_reentrancy_guard();
        }

        fn resolve_sports_prediction(ref self: ContractState, market_id: u256, winning_choice: u8) {
            // This would integrate with sports data API in production
            self.resolve_sports_prediction_manually(market_id, winning_choice);
        }

        // ================ Winnings Management ================

        // ================ User Queries ================

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

        fn get_protocol_token(self: @ContractState) -> ContractAddress {
            self.protocol_token.read()
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

        fn emergency_pause(ref self: ContractState) {
            self.assert_only_admin();
            self.is_paused.write(true);
        }

        fn emergency_unpause(ref self: ContractState) {
            self.assert_only_admin();
            self.is_paused.write(false);
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
                panic!("Invalid market type");
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

        fn emergency_resolve_market(
            ref self: ContractState, market_id: u256, market_type: u8, winning_choice: u8,
        ) {
            self.assert_only_admin();
            self.assert_market_exists(market_id, market_type);
            assert(winning_choice <= 1, 'Invalid winning choice');

            if market_type == 0 {
                let mut market = self.predictions.entry(market_id).read();
                assert(!market.is_resolved, 'Market already resolved');

                let (choice_0, choice_1) = market.choices;
                let winning_choice_struct = if winning_choice == 0 {
                    choice_0
                } else {
                    choice_1
                };
                market.winning_choice = Option::Some(winning_choice_struct);
                market.is_resolved = true;
                market.is_open = false;

                self.predictions.entry(market_id).write(market);
            } else if market_type == 1 {
                let mut market = self.crypto_predictions.entry(market_id).read();
                assert(!market.is_resolved, 'Market already resolved');

                let (choice_0, choice_1) = market.choices;
                let winning_choice_struct = if winning_choice == 0 {
                    choice_0
                } else {
                    choice_1
                };
                market.winning_choice = Option::Some(winning_choice_struct);
                market.is_resolved = true;
                market.is_open = false;

                self.crypto_predictions.entry(market_id).write(market);
            } else if market_type == 2 {
                let mut market = self.sports_predictions.entry(market_id).read();
                assert(!market.is_resolved, 'Market already resolved');

                let (choice_0, choice_1) = market.choices;
                let winning_choice_struct = if winning_choice == 0 {
                    choice_0
                } else {
                    choice_1
                };
                market.winning_choice = Option::Some(winning_choice_struct);
                market.is_resolved = true;
                market.is_open = false;

                self.sports_predictions.entry(market_id).write(market);
            } else {
                panic!("Invalid market type");
            }
        }

        fn emergency_resolve_multiple_markets(
            ref self: ContractState,
            market_ids: Array<u256>,
            market_types: Array<u8>,
            winning_choices: Array<u8>,
        ) {
            self.assert_only_admin();
            assert(market_ids.len() == market_types.len(), 'Arrays length mismatch');
            assert(market_ids.len() == winning_choices.len(), 'Arrays length mismatch');

            let mut i = 0;
            while i < market_ids.len() {
                let market_id = *market_ids.at(i);
                let market_type = *market_types.at(i);
                let winning_choice = *winning_choices.at(i);
                self.emergency_resolve_market(market_id, market_type, winning_choice);
                i += 1;
            };
        }

        fn set_protocol_token(ref self: ContractState, token_address: ContractAddress) {
            self.assert_only_admin();
            self.protocol_token.write(token_address);
        }

        fn set_protocol_restrictions(ref self: ContractState, min_amount: u256, max_amount: u256) {
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

            let token = IERC20Dispatcher { contract_address: self.protocol_token.read() };
            let success = token.transfer(recipient, amount);
            assert(success, 'Emergency withdrawal failed');
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
