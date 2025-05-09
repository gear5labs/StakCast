#[starknet::contract]
mod PredictionMarket {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use starknet::contract_address::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use contracts::interface::IPredictionMarket;

    // OpenZeppelin imports
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;

    // ====== TYPES & STRUCTS ======
    #[derive(Drop, starknet::Store)]
    pub struct Market {
        question: felt252,
        outcomes: Array<felt252>,
        start_time: u64,
        end_time: u64,
        is_resolved: bool,
        winning_outcome_id: u32,
    }

    
    // ====== STORAGE ======
       #[storage]
    struct Storage {
        markets: Map<u64, Market>,
        market_count: u64,
        user_positions: Map<(u64, ContractAddress, u32), u128>,
        outcome_totals: Map<(u64, u32), u128>,
        validators: Map<ContractAddress, bool>,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    // ====== EVENTS ======
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        MarketCreated: MarketCreated,
        UnitsPurchased: UnitsPurchased,
        MarketResolved: MarketResolved,
        RewardsClaimed: RewardsClaimed,
        ValidatorAdded: ValidatorAdded,
        ValidatorRemoved: ValidatorRemoved,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketCreated {
        market_id: u64,
        question: felt252,
        end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct UnitsPurchased {
        user: ContractAddress,
        market_id: u64,
        outcome_id: u32,
        amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketResolved {
        market_id: u64,
        winning_outcome_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardsClaimed {
        user: ContractAddress,
        amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorAdded {
        account: ContractAddress,
        caller: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorRemoved {
        account: ContractAddress,
        caller: ContractAddress,
    }

    // ====== COMPONENTS ======
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // AccessControl impl
    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;

    // SRC5 impl
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ====== CONSTRUCTOR ======
    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, admin);
        self.validators.write(admin, true); // Admin is default validator
    }

    // ====== CONTRACT IMPLEMENTATION ======
    #[abi(embed_v0)]
    impl PredicitionMarketImpl of IPredictionMarket<ContractState> {
        fn create_market(
            ref self: TContractState,
            question: felt252,
            mut outcomes: Array<felt252>,
            start_time: u64,
            end_time: u64,
        ) -> u64 {
            let caller = get_caller_address();
           

            let current_time = get_block_timestamp();
            assert(end_time > current_time, 'End time must be in future');

            let market_id = self.market_count.read();

            let market = Market {
                question,
                outcomes: outcomes.clone(),
                start_time: current_time,
                end_time,
                is_resolved: false,
                winning_outcome_id: 0_u32,
            };

            self.markets.write(market_id, market);
            self.market_count.write(market_id + 1);

            emit(Event::MarketCreated(MarketCreated { market_id, question, end_time }));

            return market_id;
        }

        fn purchase_units(
            ref self: ContractState,
            market_id: u64,
            outcome_id: u32,
            amount: u128,
        ) {
            let user = get_caller_address();

            let market = self.markets.read(market_id);
            assert(!market.is_resolved, 'Market resolved');
            let now = get_block_timestamp();
            assert(now <= market.end_time, 'Market closed');

            assert(outcome_id < market.outcomes.len().try_into().unwrap(), 'Invalid outcome');

            let key = (market_id, user, outcome_id);
            self.user_positions.write(key, amount);

            let total_key = (market_id, outcome_id);
            self.outcome_totals.write(total_key, self.outcome_totals.read(total_key) + amount);

            emit(Event::UnitsPurchased(UnitsPurchased { user, market_id, outcome_id, amount }));
        }

        fn resolve_market(
            ref self: ContractState,
            market_id: u64,
            winning_outcome_id: u32,
        ) {
            let caller = get_caller_address();
            assert(self.is_validator(caller), 'Caller not authorized');

            let mut market = self.markets.read(market_id);
            let now = get_block_timestamp();
            assert(now > market.end_time, 'Market not ended');
            assert(!market.is_resolved, 'Already resolved');

            assert(winning_outcome_id < market.outcomes.len().try_into().unwrap(), 'Invalid outcome');

            market.is_resolved = true;
            market.winning_outcome_id = winning_outcome_id;
            self.markets.write(market_id, market);

            emit(Event::MarketResolved(MarketResolved { market_id, winning_outcome_id }));
        }

        fn claim_rewards(ref self: ContractState, market_id: u64) {
            let user = get_caller_address();

            let market = self.markets.read(market_id);
            assert(market.is_resolved, 'Market not resolved');

            let winning_outcome_id = market.winning_outcome_id;
            let user_key = (market_id, user, winning_outcome_id);
            let user_amount = self.user_positions.read(user_key);
            assert(user_amount > 0_u128, 'No units to claim');

            let total_key = (market_id, winning_outcome_id);
            let total_pool = self.get_market_total_volume(market_id);
            let total_winning_pool = self.outcome_totals.read(total_key);
            let reward = (user_amount * total_pool) / total_winning_pool;

            self.user_positions.write(user_key, 0_u128);
            emit(Event::RewardsClaimed(RewardsClaimed { user, amount: reward }));
        }

        fn get_market(self: @ContractState, market_id: u64) -> Market {
            self.markets.read(market_id)
        }

        fn get_user_position(
            self: @ContractState,
            user: ContractAddress,
            market_id: u64,
            outcome_id: u32,
        ) -> u128 {
            self.user_positions.read((market_id, user, outcome_id))
        }

        fn get_total_outcome_units(
            self: @ContractState,
            market_id: u64,
            outcome_id: u32,
        ) -> u128 {
            self.outcome_totals.read((market_id, outcome_id))
        }

        fn get_market_total_volume(self: @ContractState, market_id: u64) -> u128 {
            let market = self.markets.read(market_id);
            let mut i = 0_u32;
            let mut total = 0_u128;
            let len = market.outcomes.len().try_into().unwrap();

            while i < len {
                total += self.get_total_outcome_units(market_id, i);
                i += 1;
            }

            total
        }

        fn get_resolved_outcome_id(self: @ContractState, market_id: u64) -> u32 {
            let market = self.markets.read(market_id);
            market.winning_outcome_id
        }

        fn get_market_count(self: @ContractState) -> u64 {
            self.market_count.read()
        }

        fn is_validator(self: @ContractState, address: ContractAddress) -> bool {
            self.validators.read(address)
        }
    }

    // ====== PRIVATE HELPERS ======
    #[generate_trait]
    impl Private of PrivateTrait {
        fn contains_outcome(self: @ContractState, outcomes: Array<felt252>, target: felt252) -> bool {
            let mut i = 0;
            while i < outcomes.len() {
                if outcomes.at(i) == target {
                    return true;
                }
                i += 1;
            }
            false
        }
    }
}