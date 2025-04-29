use stakcast::custom_errors::Errors::{
    ERR_ABOVE_MAX_STAKE, ERR_BELOW_MIN_STAKE, ERR_CANCELLATION_ONLY_BY_MARKET_CREATOR,
    ERR_INACTIVE_MARKET, ERR_INSUFFICIENT_BALANCE, ERR_INVALID_END_TIME, ERR_INVALID_OUTCOME,
    ERR_INVALID_START_TIME, ERR_INVALID_WINNING_OUTCOME, ERR_MARKET_ENDED, ERR_MARKET_NOT_ENDED,
    ERR_MARKET_NOT_STARTED, ERR_MAX_STAKE_LESS_THAN_MIN, ERR_MIN_OUTCOMES_REQUIRED,
    ERR_MIN_STAKE_ABOVE_ZERO, ERR_NO_CLAIMING_POSITION, ERR_POSITION_CLAIMED,
    ERR_RESOLUTION_PERIOD_EXP, ERR_RESOLVABLE_BY_ASSIGNED_VALIDATORS, ERR_UNRESOLVED_MARKET,
};

#[starknet::contract]
pub mod PredictionMarket {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    // Additional interface imports
    use stakcast::interface::{
        IMarketValidatorDispatcher, IMarketValidatorDispatcherTrait, IPredictionMarket,
        Market as IMarket, MarketDetails as IMarketDetails, MarketOutcome as IMarketOutcome,
        MarketStatus as IMarketStatus, Position as IPosition,
    };
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    // Local Data Structures
    #[derive(Drop, Serde, starknet::Store)]
    struct Market {
        creator: ContractAddress,
        title: ByteArray,
        description: ByteArray,
        category: ByteArray,
        start_time: u64,
        end_time: u64,
        resolution_time: u64,
        total_stake: u256,
        min_stake: u256,
        max_stake: u256,
        num_outcomes: u32,
        validator: ContractAddress,
    }

    #[derive(Copy, Drop, Destruct, Serde, starknet::Store)]
    struct Position {
        amount: u256,
        outcome_index: u32,
        claimed: bool,
    }

    #[derive(Drop, Copy, Serde, starknet::Store, PartialEq)]
    #[allow(starknet::store_no_default_variant)]
    pub enum MarketStatus {
        Active,
        Closed,
        Resolved,
        Disputed,
        Cancelled,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct MarketOutcome {
        winning_outcome: u32,
        resolution_details: felt252,
    }

    #[derive(Drop, Serde, starknet::Store)]
    struct MarketDetails {
        market: Market,
        status: MarketStatus,
        outcome: Option<MarketOutcome>,
    }

    // Conversion functions to adapt internal structures to interface types.
    fn to_interface_market(m: Market) -> IMarket {
        IMarket {
            creator: m.creator,
            title: m.title,
            description: m.description,
            category: m.category,
            start_time: m.start_time,
            end_time: m.end_time,
            resolution_time: m.resolution_time,
            total_stake: m.total_stake,
            min_stake: m.min_stake,
            max_stake: m.max_stake,
            num_outcomes: m.num_outcomes,
            validator: m.validator,
        }
    }

    fn to_interface_market_outcome(o: MarketOutcome) -> IMarketOutcome {
        IMarketOutcome {
            winning_outcome: o.winning_outcome, resolution_details: o.resolution_details,
        }
    }

    fn to_interface_market_details(md: MarketDetails) -> IMarketDetails {
        IMarketDetails {
            market: to_interface_market(md.market),
            status: match md.status {
                MarketStatus::Active => IMarketStatus::Active,
                MarketStatus::Closed => IMarketStatus::Closed,
                MarketStatus::Resolved => IMarketStatus::Resolved,
                MarketStatus::Disputed => IMarketStatus::Disputed,
                MarketStatus::Cancelled => IMarketStatus::Cancelled,
            },
            outcome: (match md.outcome {
                Option::Some(o) => Option::Some(to_interface_market_outcome(o)),
                Option::None => Option::None,
            }),
        }
    }

    fn to_interface_position(p: Position) -> IPosition {
        IPosition { amount: p.amount, outcome_index: p.outcome_index, claimed: p.claimed }
    }

    // Storage
    #[storage]
    struct Storage {
        balances: Map<ContractAddress, u256>,
        markets: Map<u32, Market>,
        market_count: u32,
        positions: Map<(u32, ContractAddress), Position>,
        market_outcomes: Map<u32, MarketOutcome>,
        stakes_per_outcome: Map<(u32, u32), u256>,
        platform_fee: u256,
        fee_collector: ContractAddress,
        stake_token: ContractAddress,
        market_validator: ContractAddress,
        // Now stored as a primitive.
        validator_index: u32,
        market_status: Map<u32, MarketStatus>,
    }

    // Events
    #[derive(Drop, starknet::Event)]
    pub struct MarketCreated {
        market_id: u32,
        creator: ContractAddress,
        title: ByteArray,
        start_time: u64,
        end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PositionTaken {
        market_id: u32,
        user: ContractAddress,
        outcome_index: u32,
        amount: u256,
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
        market_id: u32,
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MarketDisputed {
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

    // Constructor
    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        stake_token_address: ContractAddress,
        fee_collector: ContractAddress,
        platform_fee: u256,
        market_validator_address: ContractAddress,
    ) {
        self.stake_token.write(stake_token_address);
        self.fee_collector.write(fee_collector);
        self.platform_fee.write(platform_fee);
        self.market_validator.write(market_validator_address);
        self.validator_index.write(0);
    }

    // External Implementation
    #[external(v0)]
    #[abi(embed_v0)]
    impl PredictionMarketImp of IPredictionMarket<ContractState> {
        fn deposit(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let current_balance = self.balances.entry(caller).read();
            assert!(current_balance >= amount, "Insufficient balance");
            self.balances.entry(caller).write(current_balance - amount);
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let current_balance = self.balances.entry(caller).read();
            assert!(current_balance >= amount, "Insufficient balance");
            self.balances.entry(caller).write(current_balance - amount);
        }

        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            return self.balances.entry(user).read();
        }

        fn get_market_details(self: @ContractState, market_id: u32) -> IMarketDetails {
            let market = self.markets.entry(market_id).read();
            let status = self.market_status.entry(market_id).read();
            let outcome = if status == MarketStatus::Resolved {
                Option::Some(self.market_outcomes.entry(market_id).read())
            } else {
                Option::None
            };
            let details = MarketDetails { market, status, outcome };
            to_interface_market_details(details)
        }

        fn get_user_position(
            self: @ContractState, user: ContractAddress, market_id: u32,
        ) -> IPosition {
            let pos = self.positions.entry((market_id, user)).read();
            to_interface_position(pos)
        }

        fn create_market(
            ref self: ContractState,
            title: ByteArray,
            description: ByteArray,
            category: ByteArray,
            start_time: u64,
            end_time: u64,
            outcomes: Array<felt252>,
            min_stake: u256,
            max_stake: u256,
        ) -> u32 {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            assert!(start_time > current_time, "Invalid start time");
            assert!(end_time > start_time, "Invalid end time");
            let outcomes_len: usize = ArrayTrait::len(@outcomes);
            assert!(outcomes_len >= 2, "Minimum 2 outcomes required");
            assert!(min_stake > 0, "Min stake must be > 0");
            assert!(max_stake >= min_stake, "Max stake < min stake");

            let market_id = self.market_count.read() + 1;
            self.market_count.write(market_id);

            let market = Market {
                creator: caller,
                title: title.clone(),
                description: description,
                category: category,
                start_time: start_time,
                end_time: end_time,
                resolution_time: end_time + 86400,
                total_stake: 0,
                min_stake: min_stake,
                max_stake: max_stake,
                num_outcomes: outcomes_len.try_into().unwrap(),
                validator: get_contract_address() // default placeholder
            };

            self.markets.entry(market_id).write(market);
            self.market_status.entry(market_id).write(MarketStatus::Active);

            self.assign_validator(market_id);

            self
                .emit(
                    MarketCreated {
                        market_id: market_id,
                        creator: caller,
                        title: title,
                        start_time: start_time,
                        end_time: end_time,
                    },
                );

            market_id
        }

        fn take_position(
            ref self: ContractState, market_id: u32, outcome_index: u32, amount: u256,
        ) {
            let caller = get_caller_address();
            let market = self.markets.entry(market_id).read();
            let current_time = get_block_timestamp();
            assert!(amount >= market.min_stake, "Below min stake");
            assert!(amount <= market.max_stake, "Above max stake");
            assert!(outcome_index < market.num_outcomes, "Invalid outcome");
            assert!(
                self.market_status.entry(market_id).read() == MarketStatus::Active,
                "Market not active",
            );
            assert!(current_time >= market.start_time, "Market not started");
            assert!(current_time < market.end_time, "Market ended");

            // Deduct from user's internal balance
            let user_balance = self.balances.entry(caller).read();
            assert!(user_balance >= amount, "Insufficient balance");
            self.balances.entry(caller).write(user_balance - amount);

            let old_pos = self.positions.entry((market_id, caller)).read();
            let new_pos = Position {
                amount: old_pos.amount + amount,
                outcome_index: outcome_index,
                claimed: old_pos.claimed,
            };
            self.positions.entry((market_id, caller)).write(new_pos);

            let new_total = market.total_stake + amount;
            let new_market = Market { total_stake: new_total, ..market };
            self.markets.entry(market_id).write(new_market);

            let curr_stake = self.stakes_per_outcome.entry((market_id, outcome_index)).read();
            self.stakes_per_outcome.entry((market_id, outcome_index)).write(curr_stake + amount);

            self
                .emit(
                    PositionTaken {
                        market_id: market_id,
                        user: caller,
                        outcome_index: outcome_index,
                        amount: amount,
                    },
                );
        }

        fn claim_winnings(ref self: ContractState, market_id: u32) {
            let caller = get_caller_address();
            let market = self.markets.entry(market_id).read();
            let status = self.market_status.entry(market_id).read();
            let outcome_opt = if status == MarketStatus::Resolved {
                Option::Some(self.market_outcomes.entry(market_id).read())
            } else {
                Option::None
            };
            let outcome = OptionTrait::unwrap(outcome_opt);
            let old_pos = self.positions.entry((market_id, caller)).read();
            assert!(old_pos.amount > 0, "No position to claim");
            assert!(!old_pos.claimed, "Already claimed");

            let winning_outcome = outcome.winning_outcome;
            let mut winnings = 0;
            if old_pos.outcome_index == winning_outcome {
                let tot_win_stake = self
                    .stakes_per_outcome
                    .entry((market_id, winning_outcome))
                    .read();
                winnings = (old_pos.amount * market.total_stake) / tot_win_stake;
                let fee = (winnings * self.platform_fee.read()) / 10000;
                if winnings > fee {
                    // Add winnings to user's internal balance
                    let user_balance = self.balances.entry(caller).read();
                    self.balances.entry(caller).write(user_balance + (winnings - fee));
                    // Add fee to fee collector's balance
                    let fee_collector_balance = self
                        .balances
                        .entry(self.fee_collector.read())
                        .read();
                    self
                        .balances
                        .entry(self.fee_collector.read())
                        .write(fee_collector_balance + fee);
                }
            }
        }

        fn resolve_market(
            ref self: ContractState,
            market_id: u32,
            winning_outcome: u32,
            resolution_details: felt252,
        ) {
            let caller = get_caller_address();
            let market = self.markets.entry(market_id).read();
            let current_time = get_block_timestamp();
            assert!(caller == market.validator, "Only assigned validator");
            assert!(current_time >= market.end_time, "Market not yet ended");
            assert!(current_time <= market.resolution_time, "Resolution period expired");
            assert!(winning_outcome < market.num_outcomes, "Invalid winning outcome");
            self
                .market_outcomes
                .entry(market_id)
                .write(
                    MarketOutcome {
                        winning_outcome: winning_outcome, resolution_details: resolution_details,
                    },
                );
            self.market_status.entry(market_id).write(MarketStatus::Resolved);
            self
                .emit(
                    MarketResolved {
                        market_id: market_id,
                        outcome: winning_outcome,
                        resolver: caller,
                        resolution_details: resolution_details,
                    },
                );
        }

        // Get market stats
        fn get_market_stats(self: @ContractState, market_id: u32) -> (u256, Array<u256>) {
            let market = self.markets.entry(market_id).read();
            let mut stakes: Array<u256> = ArrayTrait::new();
            let outcomes_count = market.num_outcomes;
            let mut i = 0;
            while i != outcomes_count {
                let stake_i = self.stakes_per_outcome.entry((market_id, i)).read();
                stakes.append(stake_i);
                i += 1;
            }
            (market.total_stake, stakes)
        }

        fn dispute_market(ref self: ContractState, market_id: u32, reason: felt252) {
            let caller = get_caller_address();
            assert!(
                self.market_status.entry(market_id).read() == MarketStatus::Resolved,
                "Market not resolved",
            );
            self.market_status.entry(market_id).write(MarketStatus::Disputed);
            self.emit(MarketDisputed { market_id: market_id, disputer: caller, reason: reason });
        }

        fn cancel_market(ref self: ContractState, market_id: u32, reason: felt252) {
            let caller = get_caller_address();
            let market = self.markets.entry(market_id).read();
            assert!(caller == market.creator, "Only creator can cancel");
            assert!(
                self.market_status.entry(market_id).read() == MarketStatus::Active,
                "Market not active",
            );
            self.market_status.entry(market_id).write(MarketStatus::Cancelled);
        }

        // Internal helper: assign a validator to the market.
        fn assign_validator(ref self: ContractState, market_id: u32) {
            let validator = self.get_random_validator();
            let market = self.markets.entry(market_id).read();
            let new_market = Market { validator: validator, ..market };
            self.markets.entry(market_id).write(new_market);
        }
        fn set_market_validator(ref self: ContractState, market_validator: ContractAddress) {
            // self.accesscontrol.assert_only_role(ADMIN_ROLE); // Ensure only admin can call this
            self.market_validator.write(market_validator);
        }
    }

    // Note: get_random_validator needs to update storage, so we use a mutable reference.
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_random_validator(ref self: ContractState) -> ContractAddress {
            let validator_contract = IMarketValidatorDispatcher {
                contract_address: self.market_validator.read(),
            };
            let validator_count = validator_contract.get_validator_count();
            if validator_count == 0 {
                return self.fee_collector.read();
            }
            let current_index = self.validator_index.read();
            let index = current_index % validator_count;
            self.validator_index.write(current_index + 1);
            validator_contract.get_validator_by_index(index)
        }
    }
}
