use openzeppelin::access::accesscontrol::AccessControlComponent;
use openzeppelin::access::ownable::OwnableComponent;
use openzeppelin::introspection::src5::SRC5Component;
use stakcast::interface::{
    IMarketValidator, IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait, ValidatorInfo,
};
use starknet::storage::{Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};
use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

#[starknet::contract]
pub mod MarketValidator {
    use super::*;


    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;

    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;


    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;


    impl InternalImplOwnable = OwnableComponent::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    // Storage: Removed the array and introduced a mapping for index-based lookup.
    #[storage]
    struct Storage {
        prediction_market: ContractAddress,
        validators: Map<ContractAddress, LocalValidatorInfo>,
        validators_by_index: Map<u32, ContractAddress>, // mapping from index to validator address
        validator_count: u32,
        stake_token: ContractAddress,
        min_stake: u256,
        resolution_timeout: u64,
        slash_percentage: u64,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
    }

    // Data Structures
    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct LocalValidatorInfo {
        stake: u256,
        markets_resolved: u32,
        disputed_resolutions: u32,
        accuracy_score: u32,
        active: bool,
        last_resolution_time: u64,
        validator_index: u32,
    }

    // Events
    #[derive(Drop, starknet::Event)]
    pub struct ValidatorRegistered {
        pub validator: ContractAddress,
        pub stake: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MarketResolved {
        pub market_id: u32,
        pub resolver: ContractAddress,
        pub resolution_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ValidatorSlashed {
        pub validator: ContractAddress,
        pub amount: u256,
        pub reason: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorActivated {
        validator: ContractAddress,
        activation_time: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ValidatorRegistered: ValidatorRegistered,
        MarketResolved: MarketResolved,
        ValidatorSlashed: ValidatorSlashed,
        ValidatorActivated: ValidatorActivated,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
    }


    // Constructor
    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        prediction_market: ContractAddress,
        stake_token_address: ContractAddress,
        min_stake: u128,
        resolution_timeout: u64,
        slash_percentage: u64,
        owner: ContractAddress,
    ) {
        self.prediction_market.write(prediction_market);
        self.stake_token.write(stake_token_address);
        self.min_stake.write(min_stake.into());
        self.resolution_timeout.write(resolution_timeout);
        self.slash_percentage.write(slash_percentage);
        self.validator_count.write(0);
        self.ownable.initializer(owner);
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
    }

    // External Implementation
    #[external(v0)]
    #[abi(embed_v0)]
    impl MarketValidatorImp of IMarketValidator<ContractState> {
        fn register_validator(ref self: ContractState, stake: u256) {
            let caller = get_caller_address();

            // Ensure the provided stake meets the minimum.
            assert!(stake >= self.min_stake.read(), "Insufficient stake");

            let mut validator_info = self.validators.entry(caller).read();
            if !validator_info.active {
                // Initialize the validator info if not already active.
                validator_info =
                    LocalValidatorInfo {
                        stake: 0.into(),
                        markets_resolved: 0,
                        disputed_resolutions: 0,
                        accuracy_score: 0,
                        active: false,
                        last_resolution_time: 0,
                        validator_index: 0,
                    };
            }

            if !validator_info.active {
                // Instead of appending to an array, we store the caller address in a mapping.
                let validator_count = self.validator_count.read();
                self.validators_by_index.entry(validator_count).write(caller);
                validator_info.validator_index = validator_count;
                self.validator_count.write(validator_count + 1);
            }

            // Update the validator's info.
            validator_info.stake = stake;
            validator_info.active = true;
            validator_info.markets_resolved = 0;
            validator_info.disputed_resolutions = 0;
            validator_info.accuracy_score = 0;

            self.validators.entry(caller).write(validator_info);

            self.emit(ValidatorRegistered { validator: caller, stake });
        }

        fn resolve_market(
            ref self: ContractState,
            market_id: u32,
            winning_outcome: u32,
            resolution_details: felt252,
        ) {
            // this function can only be called by the admin
            self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            let mut validator_info = self.validators.entry(caller).read();

            if !validator_info.active {
                panic!("Validator not found or inactive");
            }

            // Ensure sufficient time has passed since the last resolution.
            assert!(
                current_time > validator_info.last_resolution_time + self.resolution_timeout.read(),
                "Too frequent resolutions",
            );

            validator_info.markets_resolved += 1;
            validator_info.last_resolution_time = current_time;

            self.validators.entry(caller).write(validator_info);

            let pm = IPredictionMarketDispatcher {
                contract_address: self.prediction_market.read(),
            };
            pm.resolve_market(market_id, winning_outcome, resolution_details);

            self
                .emit(
                    MarketResolved { market_id, resolver: caller, resolution_time: current_time },
                );
        }

        fn slash_validator(
            ref self: ContractState, validator: ContractAddress, amount: u256, reason: felt252,
        ) {
            // this function can only be called by the admin
            self.accesscontrol.assert_only_role(ADMIN_ROLE);

            // Only the prediction market contract can perform slashing.
            assert!(get_caller_address() == self.prediction_market.read(), "Unauthorized slashing");

            let mut validator_info = self.validators.entry(validator).read();

            if !validator_info.active {
                panic!("Validator not found or inactive");
            }

            let min_stake: u256 = self.min_stake.read().into();
            let slash_percentage: u256 = self.slash_percentage.read().into();

            let slash_amount = if amount == 0.into() {
                (validator_info.stake * slash_percentage) / 100.into()
            } else {
                core::cmp::min(amount, validator_info.stake)
            };

            validator_info.stake -= slash_amount;
            validator_info.disputed_resolutions += 1;

            if validator_info.stake < min_stake {
                validator_info.active = false;
            }

            self.validators.entry(validator).write(validator_info);

            self.emit(ValidatorSlashed { validator, amount: slash_amount, reason });
        }

        fn get_validator_info(self: @ContractState, validator: ContractAddress) -> ValidatorInfo {
            let local_info = self.validators.entry(validator).read();
            ValidatorInfo {
                stake: local_info.stake,
                markets_resolved: local_info.markets_resolved,
                disputed_resolutions: local_info.disputed_resolutions,
                accuracy_score: local_info.accuracy_score,
                active: local_info.active,
                last_resolution_time: local_info.last_resolution_time,
                validator_index: local_info.validator_index,
            }
        }

        fn is_active_validator(self: @ContractState, validator: ContractAddress) -> bool {
            self.validators.entry(validator).read().active
        }

        // Implement missing trait items:
        fn get_validator_by_index(self: @ContractState, index: u32) -> ContractAddress {
            let validator_count = self.validator_count.read();
            assert!(index < validator_count, "Invalid validator index");
            self.validators_by_index.entry(index).read()
        }

        fn get_validator_count(self: @ContractState) -> u32 {
            self.validator_count.read()
        }

        fn set_role(
            ref self: ContractState, recipient: ContractAddress, role: felt252, is_enable: bool,
        ) {
            self._set_role(recipient, role, is_enable);
        }

        fn is_admin(self: @ContractState, role: felt252, address: ContractAddress) -> bool {
            self.accesscontrol.has_role(role, address)
        }

        fn set_prediction_market(ref self: ContractState, prediction_market: ContractAddress) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.prediction_market.write(prediction_market);
        }

        fn get_prediction_market(self: @ContractState) -> ContractAddress {
            self.prediction_market.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        // Retrieve a validator's address by its index from the new mapping.
        fn get_validator_by_index(self: @ContractState, index: u32) -> ContractAddress {
            let validator_count = self.validator_count.read();
            assert!(index < validator_count, "Invalid validator index");
            self.validators_by_index.entry(index).read()
        }

        fn calculate_accuracy(self: @ContractState, validator: ContractAddress) -> u32 {
            let validator_info = self.validators.entry(validator).read();
            if !validator_info.active {
                panic!("Validator not found or inactive");
            }
            let total = validator_info.markets_resolved;
            if total == 0 {
                return 0;
            }
            ((total - validator_info.disputed_resolutions) * 100) / total
        }

        fn _set_role(
            ref self: ContractState, recipient: ContractAddress, role: felt252, is_enable: bool,
        ) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            assert!(role == ADMIN_ROLE, "role not enable");
            if is_enable {
                self.accesscontrol._grant_role(role, recipient);
            } else {
                self.accesscontrol._revoke_role(role, recipient);
            }
        }
    }
}
