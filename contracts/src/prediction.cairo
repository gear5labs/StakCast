use core::num::traits::Zero;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
use pragma_lib::types::DataType;
use stakcast::admin_interface::IAdditionalAdmin;
use stakcast::errors;
use stakcast::events::{
    BetPlaced, EmergencyPaused, Event, FeesCollected, MarketCreated, MarketResolved, ModeratorAdded,
    ModeratorRemoved, WagerPlaced, WinningsCollected,
};
use stakcast::interface::IPredictionHub;
use stakcast::types::{BetActivity, Choice, MarketStatus, Outcome, PredictionMarket, UserStake};
use starknet::storage::{Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};
use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};


// ================ Contract Storage ================

#[starknet::contract]
pub mod PredictionHub {
    use starknet::storage::{MutableVecTrait, Vec, VecTrait};
    use crate::types::{MarketStats, num_to_market_category};
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

        user_predictions: Map<ContractAddress, Vec<u256>>, // user to a list of market ids
        claimed: Map<(u256, ContractAddress), bool>,
        market_analytics: Map<u256, Vec<BetActivity>> // market to a list of BetActivity structs
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
            assert(!self.is_paused.read(), errors::CONTRACT_IS_PAUSED);
        }


        fn assert_only_admin(self: @ContractState) {
            let caller = get_caller_address();

            assert(self.admin.read() == caller, errors::ONLY_ADMIN_ALLOWED);
        }


        fn assert_only_moderator_or_admin(self: @ContractState) {
            let caller = get_caller_address();

            let is_admin = self.admin.read() == caller;

            let is_moderator = self.moderators.entry(caller).read();

            assert(is_admin || is_moderator, errors::ONLY_ADMIN_OR_MODERATOR);
        }


        fn assert_market_creation_not_paused(self: @ContractState) {
            assert(!self.market_creation_paused.read(), errors::MARKET_CREATION_PAUSED);
        }


        fn assert_betting_not_paused(self: @ContractState) {
            assert(!self.betting_paused.read(), errors::BETTING_PAUSED);
        }


        fn assert_resolution_not_paused(self: @ContractState) {
            assert(!self.resolution_paused.read(), errors::RESOLUTION_PAUSED);
        }


        fn assert_valid_market_timing(self: @ContractState, end_time: u64) {
            let current_time = get_block_timestamp();

            let min_duration = self.min_market_duration.read();

            let max_duration = self.max_market_duration.read();

            // Check that end_time is in the future first to avoid overflow in subtraction

            assert(end_time > current_time, errors::END_TIME_MUST_BE_IN_FUTURE);

            let duration = end_time - current_time;

            assert(duration >= min_duration, errors::MARKET_DURATION_TOO_SHORT);

            assert(duration <= max_duration, errors::MARKET_DURATION_TOO_LONG);
        }


        /// @notice Asserts that the market is open, not resolved, and has not ended

        fn assert_market_open(self: @ContractState, market_id: u256) {
            let market = self.all_predictions.entry(market_id).read();

            assert(market.is_open, errors::MARKET_IS_CLOSED);

            assert(!market.is_resolved, errors::MARKET_ALREADY_RESOLVED);

            assert(get_block_timestamp() < market.end_time, errors::MARKET_HAS_ENDED);
        }


        fn assert_market_exists(self: @ContractState, market_id: u256) {
            let market = self.all_predictions.entry(market_id).read();

            assert(market.market_id == market_id, errors::MARKET_DOES_NOT_EXIST);
        }


        /// @notice Asserts that the provided choice is valid (1 or 2)

        fn assert_valid_choice(self: @ContractState, choice: u8) {
            assert(choice < 2, errors::INVALID_CHOICE_SELECTED);
        }


        fn assert_valid_amount(self: @ContractState, amount: u256) {
            assert(amount > 0, errors::AMOUNT_MUST_BE_POSITIVE);

            let min_bet = self.min_bet_amount.read();

            let max_bet = self.max_bet_amount.read();

            assert(amount >= min_bet, errors::AMOUNT_BELOW_MINIMUM);

            assert(amount <= max_bet, errors::AMOUNT_ABOVE_MAXIMUM);
        }


        fn assert_sufficient_token_balance(
            self: @ContractState, user: ContractAddress, amount: u256,
        ) {
            let token = IERC20Dispatcher { contract_address: self.protocol_token.read() };

            let balance = token.balance_of(user);

            assert(balance >= amount, errors::INSUFFICIENT_TOKEN_BALANCE);
        }


        fn assert_sufficient_allowance(self: @ContractState, user: ContractAddress, amount: u256) {
            let token = IERC20Dispatcher { contract_address: self.protocol_token.read() };

            let allowance = token.allowance(user, starknet::get_contract_address());

            assert(allowance >= amount, errors::INSUFFICIENT_TOKEN_ALLOWANCE);
        }


        fn assert_market_resolved(self: @ContractState, market_id: u256) {
            let market = self.all_predictions.entry(market_id).read();

            assert(market.is_resolved, errors::MARKET_IS_NOT_RESOLVED);

            assert(market.winning_choice.is_some(), errors::MARKET_RESOLVED);
        }


        fn start_reentrancy_guard(ref self: ContractState) {
            assert(!self.reentrancy_guard.read(), errors::REENTRANT_CALL);

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
            category: u8,
            end_time: u64,
            prediction_market_type: u8,
            crypto_prediction: Option<(felt252, u128)>,
        ) {
            self.assert_not_paused();

            self.assert_market_creation_not_paused();

            self.assert_only_moderator_or_admin();

            self.assert_valid_market_timing(end_time);

            assert(prediction_market_type <= 2, errors::INVALID_MARKET_TYPE);

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
                choices: (Outcome::Option1(choice_0_label), Outcome::Option2(choice_1_label)),
                category: num_to_market_category(category),
                is_resolved: false,
                is_open: true,
                end_time,
                status: MarketStatus::Active,
                winning_choice: Option::None,
                total_shares_option_one: HALF,
                total_shares_option_two: HALF,
                total_pool: PRECISION,
                crypto_prediction: if prediction_market_type == 1 {
                    crypto_prediction
                } else {
                    Option::None
                },
            };

            self.all_predictions.entry(market_id).write(market.clone());

            self.market_stats.entry(market_id).write(market_stats);

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


        fn get_prediction(self: @ContractState, market_id: u256) -> PredictionMarket {
            self.assert_market_exists(market_id);

            self.all_predictions.entry(market_id).read()
        }


        fn get_all_predictions_by_market_category(
            self: @ContractState, category: u8,
        ) -> Array<PredictionMarket> {
            assert(category <= 7, errors::INVALID_MARKET_CATEGORY);

            let mut predictions = ArrayTrait::new();

            let count = self.prediction_count.read();

            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();

                let market = self.all_predictions.entry(market_id).read();

                let category = num_to_market_category(category);

                if market_id != 0 && market.category == category {
                    predictions.append(market);
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

        fn get_market_status(self: @ContractState, market_id: u256) -> (bool, bool) {
            self.assert_market_exists(market_id);

            let market = self.all_predictions.entry(market_id).read();

            (market.is_open, market.is_resolved)
        }


        fn calculate_share_prices(self: @ContractState, market_id: u256) -> (u256, u256) {
            let market = self.all_predictions.entry(market_id).read();

            let total_shares: u256 = market.total_shares_option_one
                + market.total_shares_option_two;

            let price_a = self.divide(market.total_shares_option_one, total_shares);
            let price_b = self.divide(market.total_shares_option_two, total_shares);

            if price_a + price_b != PRECISION {
                let adjusted_price_b = PRECISION - price_a;
                (price_a, adjusted_price_b)
            } else {
                (price_a, price_b)
            }
        }

        fn buy_shares(ref self: ContractState, market_id: u256, choice: u8, amount: u256) {
            let caller = get_caller_address();

            let token_contract_address = self.protocol_token.read();

            self.assert_not_paused();

            self.assert_betting_not_paused();

            self.assert_resolution_not_paused();

            self.assert_valid_choice(choice);

            self.assert_valid_amount(amount);

            self.assert_sufficient_token_balance_for_token(caller, amount, token_contract_address);

            self.assert_sufficient_allowance_for_token(caller, amount, token_contract_address);

            let token_dispatcher = IERC20Dispatcher { contract_address: token_contract_address };

            let success = token_dispatcher
                .transfer_from(caller, starknet::get_contract_address(), amount);

            assert(success, errors::TOKEN_TRANSFER_FAILED);

            self.assert_market_open(market_id);

            self.start_reentrancy_guard();

            let (price_a, price_b) = self.calculate_share_prices(market_id);

            let user_choice = self.choice_num_to_outcome(market_id, choice);

            let mut market = self.all_predictions.entry(market_id).read();

            let mut user_stake: UserStake = self.bet_details.entry((market_id, caller)).read();

            // Check if user has traded on this market before
            let user_traded = self.user_traded_status.entry((market_id, caller)).read();

            let mut market_stats = self.market_stats.entry(market_id).read();

            if !user_traded {
                market_stats.total_trades += 1;
                self.user_traded_status.entry((market_id, caller)).write(true);

                // Add market_id to user's list of predictions
                // add bet to user bet collection
                self.user_predictions.entry(caller).push(market_id);
            }

            // Update market stats
            match user_choice {
                Outcome::Option1 => {
                    let shares = self.divide(amount, price_a);

                    market.total_shares_option_one += shares;

                    user_stake.shares_a = user_stake.shares_a + shares;

                    market_stats.traders_option_a += 1;

                    market_stats.amount_staked_option_a += amount;
                },
                Outcome::Option2 => {
                    let shares = self.divide(amount, price_b);

                    market.total_shares_option_two += shares;

                    user_stake.shares_b = user_stake.shares_b + shares;

                    market_stats.traders_option_b += 1;

                    market_stats.amount_staked_option_b += amount;
                },
                _ => panic!("{}", errors::INVALID_CHOICE_SELECTED),
            }

            user_stake.total_invested = user_stake.total_invested + amount;

            market.total_pool = market.total_pool + amount;

            market_stats.total_trades += 1;

            self.bet_details.entry((market_id, caller)).write(user_stake);

            self.market_stats.entry(market_id).write(market_stats);

            // update market analytics
            self.market_analytics.entry(market_id).push(BetActivity { choice, amount });

            // Update market state
            self.all_predictions.entry(market_id).write(market);

            // End reentrancy guard
            self.end_reentrancy_guard();
        }


        fn claim(ref self: ContractState, market_id: u256) {
            self.assert_not_paused();

            self.assert_resolution_not_paused();

            self.assert_market_exists(market_id);

            self.assert_market_open(market_id);

            self.assert_market_resolved(market_id);

            // check if the user has claimed before

            let user_addr: ContractAddress = get_caller_address();

            assert(!self.claimed.entry((market_id, user_addr)).read(), errors::ALREADY_CLAIMED);

            let market: PredictionMarket = self.all_predictions.entry(market_id).read();

            let user_stake: UserStake = self.bet_details.entry((market_id, user_addr)).read();

            self.claimed.entry((market_id, user_addr)).write(true);

            let winning_choice: u8 = market.winning_choice.unwrap();

            let user_amount_on_option_winning: u256 = if winning_choice == 0 {
                user_stake.shares_a
            } else {
                user_stake.shares_b
            };

            assert(user_amount_on_option_winning > 0, errors::NO_WINNING_STAKE_FOR_USER);

            let user_reward: u256 = self.calculate_user_winnings(market_id, user_addr);

            // Transfer ERC20 reward to the user

            let token_contract_address = self.protocol_token.read();

            let token_dispatcher = IERC20Dispatcher { contract_address: token_contract_address };

            let success = token_dispatcher.transfer(user_addr, user_reward);

            assert(success, errors::ERC20_TRANSFER_FAILED);
        }


        fn get_market_activity(self: @ContractState, market_id: u256) -> Array<BetActivity> {
            let mut market_activity_array = ArrayTrait::new();

            let market_activity = self.market_analytics.entry(market_id);

            for i in 0..market_activity.len() {
                let analytics = market_activity.at(i).read();

                market_activity_array.append(analytics);
            }

            market_activity_array
        }


        fn get_all_open_markets(self: @ContractState) -> Array<PredictionMarket> {
            let mut markets = ArrayTrait::new();

            let count = self.prediction_count.read();

            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();

                let market = self.all_predictions.entry(market_id).read();

                if market_id != 0 && market.status == MarketStatus::Active {
                    markets.append(market);
                }

                i += 1;
            }

            markets
        }

        fn get_all_locked_markets(self: @ContractState) -> Array<PredictionMarket> {
            let mut markets = ArrayTrait::new();

            let count = self.prediction_count.read();

            let mut i: u256 = 1;

            while i <= count {
                let market_id = self.market_ids.entry(i).read();

                let market = self.all_predictions.entry(market_id).read();

                if market_id != 0 && market.status == MarketStatus::Locked {
                    markets.append(market);
                }

                i += 1;
            }

            markets
        }

        fn get_all_resolved_markets(self: @ContractState) -> Array<PredictionMarket> {
            let mut markets = ArrayTrait::new();
            let count = self.prediction_count.read();
            let mut i: u256 = 1;
            while i <= count {
                let market_id = self.market_ids.entry(i).read();
                let market = self.all_predictions.entry(market_id).read();

                if market_id != 0_u256 && market.winning_choice.is_some() {
                    markets.append(market);
                }

                i += 1;
            }
            markets
        }


        fn get_all_closed_bets_for_user(
            self: @ContractState, user: ContractAddress,
        ) -> Array<PredictionMarket> {
            let mut user_markets = ArrayTrait::new();

            let user_market_ids = self.user_predictions.entry(user);

            let user_market_ids_len = user_market_ids.len();

            for i in 0..user_market_ids_len {
                let market_id: u256 = user_market_ids.at(i).read();

                let market = self.all_predictions.entry(market_id).read();

                // Check if market is resolved (closed)
                match market.status {
                    MarketStatus::Resolved(_) => { user_markets.append(market); },
                    _ => {},
                }
            }

            user_markets
        }


        fn get_all_open_bets_for_user(
            self: @ContractState, user: ContractAddress,
        ) -> Array<PredictionMarket> {
            let mut user_markets = ArrayTrait::new();

            let user_market_ids = self.user_predictions.entry(user);

            let user_market_ids_len = user_market_ids.len();

            for i in 0..user_market_ids_len {
                let market_id: u256 = user_market_ids.at(i).read();

                let market = self.all_predictions.entry(market_id).read();

                if market.status == MarketStatus::Active {
                    user_markets.append(market);
                }
            }

            user_markets
        }

        fn get_all_locked_bets_for_user(
            self: @ContractState, user: ContractAddress,
        ) -> Array<PredictionMarket> {
            let mut user_markets = ArrayTrait::new();

            let user_market_ids = self.user_predictions.entry(user);

            let user_market_ids_len = user_market_ids.len();

            for i in 0..user_market_ids_len {
                let market_id: u256 = user_market_ids.at(i).read();

                let market = self.all_predictions.entry(market_id).read();

                if market.status == MarketStatus::Locked {
                    user_markets.append(market);
                }
            }

            user_markets
        }


        fn get_all_bets_for_user(
            self: @ContractState, user: ContractAddress,
        ) -> Array<PredictionMarket> {
            let mut user_markets = ArrayTrait::new();

            let user_market_ids = self.user_predictions.entry(user);

            let user_market_ids_len = user_market_ids.len();
            for i in 0..user_market_ids_len {
                let market_id: u256 = user_market_ids.at(i).read();
                let market = self.all_predictions.entry(market_id).read();
                user_markets.append(market);
            }

            user_markets
        }

        fn get_user_market_ids(self: @ContractState, user: ContractAddress) -> Array<u256> {
            let mut market_ids = ArrayTrait::new();

            let user_market_ids = self.user_predictions.entry(user);

            let user_market_ids_len = user_market_ids.len();

            for i in 0..user_market_ids_len {
                let market_id: u256 = user_market_ids.at(i).read();
                market_ids.append(market_id);
            }

            market_ids
        }


        fn get_user_stake_details(
            self: @ContractState, market_id: u256, user: ContractAddress,
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

        /// @dev depreciated

        // fn get_active_general_prediction_markets(self: @ContractState) -> Array<PredictionMarket>
        // {
        //     let mut predictions = ArrayTrait::new();

        //     let count = self.prediction_count.read();

        //     for i in 0..=count {
        //         let market_id = self.market_ids.entry(i).read();

        //         if market_id != 0 {
        //             let market = self.predictions.entry(market_id).read();

        //             if market.market_id != 0 && market.is_open {
        //                 predictions.append(market);
        //             }
        //         }
        //     }

        //     predictions
        // }

        // fn get_active_sport_markets(self: @ContractState) -> Array<PredictionMarket> {
        //     let mut predictions = ArrayTrait::new();

        //     let count = self.prediction_count.read();

        //     for i in 0..=count {
        //         let market_id = self.market_ids.entry(i).read();

        //         if market_id != 0 {
        //             let market = self.sports_predictions.entry(market_id).read();

        //             if market.market_id != 0 && market.is_open {
        //                 predictions.append(market);
        //             }
        //         }
        //     }

        //     predictions
        // }

        // fn get_active_crypto_markets(self: @ContractState) -> Array<PredictionMarket> {
        //     let mut predictions = ArrayTrait::new();

        //     let count = self.prediction_count.read();

        //     for i in 0..=count {
        //         let market_id = self.market_ids.entry(i).read();

        //         if market_id != 0 {
        //             let market = self.crypto_predictions.entry(market_id).read();

        //             if market.market_id != 0 && market.is_open {
        //                 predictions.append(market);
        //             }
        //         }
        //     }

        //     predictions
        // }

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


        fn resolve_prediction(ref self: ContractState, market_id: u256, winning_choice: u8) {
            self.assert_not_paused();

            self.assert_resolution_not_paused();

            self.assert_only_moderator_or_admin();

            self.assert_market_exists(market_id);

            self.assert_valid_choice(winning_choice);

            self.start_reentrancy_guard();

            let mut market = self.all_predictions.entry(market_id).read();

            assert(!market.is_resolved, errors::MARKET_ALREADY_RESOLVED);

            let current_time = get_block_timestamp();

            assert(current_time >= market.end_time, errors::MARKET_NOT_YET_ENDED);

            let resolution_deadline = market.end_time + self.resolution_window.read();

            assert(current_time <= resolution_deadline, errors::RESOLUTION_WINDOW_EXPIRED);

            market.is_resolved = true;

            market.is_open = false;

            let winning_choice_outcome: Outcome = self
                .choice_num_to_outcome(market_id, winning_choice);

            market.winning_choice = Option::Some(winning_choice);

            market.status = MarketStatus::Resolved(winning_choice_outcome);

            self.all_predictions.entry(market_id).write(market);

            self.emit(MarketResolved { market_id, resolver: get_caller_address(), winning_choice });

            self.end_reentrancy_guard();
        }

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
        }


        fn add_moderator(ref self: ContractState, moderator: ContractAddress) {
            self.assert_only_admin();

            assert(!self.moderators.entry(moderator).read(), errors::ALREADY_A_MODERATOR);

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

            assert(impl_hash.is_non_zero(), errors::CLASS_HASH_CANNOT_BE_ZERO);

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

            assert(self.moderators.entry(moderator).read(), errors::NOT_A_MODERATOR);

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

            assert(min_duration > 0, errors::MIN_DURATION_MUST_BE_POSITIVE);

            assert(max_duration > min_duration, errors::MAX_MUST_BE_GREATER_THAN_MIN);

            assert(resolution_window > 0, errors::RESOLUTION_WINDOW_POSITIVE);

            self.min_market_duration.write(min_duration);

            self.max_market_duration.write(max_duration);

            self.resolution_window.write(resolution_window);
        }


        fn set_platform_fee(ref self: ContractState, fee_percentage: u256) {
            self.assert_only_admin();

            assert(fee_percentage <= 1000, errors::FEE_CANNOT_EXCEED_10_PERCENT); // 1000 basis points = 10%

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

            // while i <= total_markets {
            //     // Check all market types

            //     let mut market_type: u8 = 0;

            //     while market_type < 3_u8 {
            //         if market_type == 0 {
            //             let market = self.predictions.entry(i).read();

            //             if market.market_id != 0 {
            //                 if market.is_resolved {
            //                     resolved_markets += 1;
            //                 } else if market.is_open {
            //                     active_markets += 1;
            //                 }
            //             }
            //         } else if market_type == 1 {
            //             let market = self.crypto_predictions.entry(i).read();

            //             if market.market_id != 0 {
            //                 if market.is_resolved {
            //                     resolved_markets += 1;
            //                 } else if market.is_open {
            //                     active_markets += 1;
            //                 }
            //             }
            //         } else if market_type == 2 {
            //             let market = self.sports_predictions.entry(i).read();

            //             if market.market_id != 0 {
            //                 if market.is_resolved {
            //                     resolved_markets += 1;
            //                 } else if market.is_open {
            //                     active_markets += 1;
            //                 }
            //             }
            //         }

            //         market_type += 1;
            //     }

            //     i += 1;
            // }

            (total_markets, active_markets, resolved_markets)
        }


        fn emergency_close_market(ref self: ContractState, market_id: u256, market_type: u8) {}


        fn emergency_close_multiple_markets(
            ref self: ContractState, market_ids: Array<u256>, market_types: Array<u8>,
        ) {
            self.assert_only_admin();

            assert(market_ids.len() == market_types.len(), errors::ARRAYS_LENGTH_MISMATCH);

            let mut i = 0;

            while i < market_ids.len() {
                let market_id = *market_ids.at(i);

                let market_type = *market_types.at(i);

                self.emergency_close_market(market_id, market_type);

                i += 1;
            };
        }


        fn emergency_resolve_multiple_markets(
            ref self: ContractState,
            market_ids: Array<u256>,
            market_types: Array<u8>,
            winning_choices: Array<u8>,
        ) {}


        fn set_protocol_token(ref self: ContractState, token_address: ContractAddress) {
            self.assert_only_admin();

            self.protocol_token.write(token_address);
        }


        fn set_protocol_restrictions(ref self: ContractState, min_amount: u256, max_amount: u256) {
            self.assert_only_admin();

            assert(min_amount > 0, errors::MIN_AMOUNT_MUST_BE_POSITIVE);

            assert(max_amount > min_amount, errors::MAX_MUST_BE_GREATER_THAN_MIN);

            self.min_bet_amount.write(min_amount);

            self.max_bet_amount.write(max_amount);
        }


        fn emergency_withdraw_tokens(
            ref self: ContractState, amount: u256, recipient: ContractAddress,
        ) {
            self.assert_only_admin();

            assert(amount > 0, errors::AMOUNT_MUST_BE_POSITIVE);

            let token = IERC20Dispatcher { contract_address: self.protocol_token.read() };

            let success = token.transfer(recipient, amount);

            assert(success, errors::EMERGENCY_WITHDRAWAL_FAILED);
        }
    }


    // ================ Helper Functions ================

    #[generate_trait]
    impl HelperImpl of HelperTrait {
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

            assert(balance >= amount, errors::INSUFFICIENT_TOKEN_BALANCE);
        }


        fn assert_sufficient_allowance_for_token(
            self: @ContractState,
            user: ContractAddress,
            amount: u256,
            token_address: ContractAddress,
        ) {
            let token = IERC20Dispatcher { contract_address: token_address };

            let allowance = token.allowance(user, starknet::get_contract_address());

            assert(allowance >= amount, errors::INSUFFICIENT_TOKEN_ALLOWANCE);
        }


        fn choice_num_to_outcome(self: @ContractState, market_id: u256, choice: u8) -> Outcome {
            let market = self.all_predictions.entry(market_id).read();

            assert(choice <= 1, errors::INVALID_CHOICE);

            let (outcome1, outcome2) = market.choices;

            match choice {
                0 => outcome1,
                1 => outcome2,
                _ => panic!("{}", errors::INVALID_CHOICE_PANIC),
            }
        }


        fn calculate_user_winnings(
            self: @ContractState, market_id: u256, user: ContractAddress,
        ) -> u256 {
            // Calculate the user's winnings for a resolved market.

            // 1. Get the market and user stake.

            let market = self.all_predictions.entry(market_id).read();

            let user_stake = self.bet_details.entry((market_id, user)).read();

            // 2. Ensure the market is resolved and has a winning choice.

            assert(market.is_resolved, errors::MARKET_NOT_RESOLVED);

            let winning_choice = market.winning_choice.unwrap();

            // 3. Determine user's shares on the winning side.

            let user_shares = if winning_choice == 0 {
                user_stake.shares_a
            } else {
                user_stake.shares_b
            };

            // 4. If user has no shares on the winning side, return 0.

            if user_shares == 0 {
                return 0;
            }

            // 5. Calculate total shares on the winning side.

            let total_winning_shares = if winning_choice == 0 {
                market.total_shares_option_one
            } else {
                market.total_shares_option_two
            };

            // 6. Calculate platform fee.

            let platform_fee_bps = self.platform_fee_percentage.read(); // e.g., 250 = 2.5%

            let _fee_amount = (market.total_pool * platform_fee_bps) / 10000_u256;

            let distributable_pool = market.total_pool;

            // 7. User's reward = (user_shares / total_winning_shares) * distributable_pool

            // To avoid precision loss, multiply first, then divide.

            let user_reward = (user_shares * distributable_pool) / total_winning_shares;

            user_reward
        }
    }
}
