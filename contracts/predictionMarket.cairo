// prediction_market.cairo

// Declare the main contract module.
#[starknet::contract]
mod PredictionMarket {
    // Import necessary libraries and types.
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::info::get_block_timestamp;
    use starknet::storage_access::MapTrait;
    use openzeppelin::token::erc20::interface::IERC20;

    // Import our interface.
    use super::IPredictionMarket;

    // --- Data Structure Definitions ---
    // Moved from utils.cairo

    // Struct representing an outcome within a prediction market.
    #[derive(Drop, starknet::Store, Clone)]
    struct Outcome {
        id: u32, // Unique ID within the market
        description: felt252, // Felt representation of the outcome description
    }

    // Enum representing the possible states of a prediction market.
    #[derive(Drop, starknet::Store)]
    enum MarketStatus {
        Open, // Market is accepting unit purchases
        Resolved, // Market outcome has been set, claims are possible
        Cancelled, // Market was cancelled (out of MVP scope)
    }

    // Struct representing a single prediction market.
    #[derive(Drop, starknet::Store)]
    struct Market {
        creator: ContractAddress, // Address that created the market
        question: felt252, // Felt representation of the market question
        outcomes: Array<Outcome>, // List of possible outcomes for this market
        status: MarketStatus, // Current status of the market
        total_market_volume: u128, // Total number of units purchased across all outcomes
        resolved_outcome_id: u32, // The ID of the winning outcome once resolved (0 if not resolved)
        // Add timestamps later if needed (creation_time, resolution_time)
    }


    // --- Contract State Variables ---
    // Defined using the #[storage] attribute.
    #[storage]
    struct Storage {
        // maps market_id to Market struct
        markets: Map<u64, Market>,
        // maps user_wallet -> market_id -> outcome_id -> units held
        balances: Map<ContractAddress, Map<u64, Map<u32, u128>>>,
        // maps market_id -> outcome_id -> total units purchased for that outcome
        total_units: Map<u64, Map<u32, u128>>,
        // maps validator_address -> is_validator (bool)
        validators: Map<ContractAddress, bool>,
        // Store the address of the ERC20 token used for unit purchases and payouts.
        erc20_token_address: ContractAddress,
        // Simple counter for generating unique market IDs.
        market_count: u64,
    }

    // --- Constructor / Initializer ---
    // Called once upon contract deployment to set initial state.
    #[constructor]
    fn constructor(ref self: Storage, initial_validator: ContractAddress, erc20_token_address: ContractAddress) {
        // Set the initial validator (can be multisig later).
        self.validators.write(initial_validator, true);
        // Store the ERC20 token address that the contract will interact with.
        self.erc20_token_address.write(erc20_token_address);
        // Initialize market count to 0.
        self.market_count.write(0);
    }

    // --- External Functions (Implementing IPredictionMarket) ---

    // Implementation of the IPredictionMarket trait.
    #[external(v0)]
    impl PredictionMarketImpl of IPredictionMarket<Storage> {
        // See interface for function signatures and descriptions.

        // Function to create a new prediction market.
        fn create_market(ref self: Storage, question: felt252, outcomes: Array<felt252>) -> u64 {
            // @logic:
            // 1. Get the next unique market ID using market_count.
            let market_id = self.market_count.read();

            // 2. Increment the market count for the next market.
            self.market_count.write(market_id + 1);

            // 3. Validate outcomes: Ensure there's at least one outcome. Maybe add max outcomes limit.
            // TODO: Add outcome validation logic (e.g., outcomes.len() > 0)

            // 4. Convert felt252 outcomes to Outcome structs with unique IDs.
            let mut outcome_structs = Array::<Outcome>::new();
            let mut outcome_id_counter = 1; // Start outcome IDs from 1 (0 could mean unresolved/invalid)
            let mut outcomes_iter = outcomes.span();
            loop {
                if outcomes_iter.is_empty() {
                    break;
                }
                let outcome_description = *outcomes_iter.pop_front().unwrap();
                outcome_structs.append(Outcome {
                    id: outcome_id_counter,
                    description: outcome_description,
                });
                outcome_id_counter += 1;
            };

            // 5. Create the Market struct.
            let new_market = Market {
                creator: get_caller_address(), // The market creator is the caller
                question,
                outcomes: outcome_structs.clone(), // Clone is needed here to use the Array
                status: MarketStatus::Open, // New markets are always open
                total_market_volume: 0, // No units purchased yet
                resolved_outcome_id: 0, // Not resolved yet
            };

            // 6. Store the new market struct using the market_id.
            self.markets.write(market_id, new_market);

            // 7. Initialize mappings for this new market (total_units per outcome).
            // Iterate through outcomes and initialize their total units to 0.
             let mut outcomes_iter = outcome_structs.span(); // Use the cloned array
             loop {
                if outcomes_iter.is_empty() {
                    break;
                }
                let outcome = *outcomes_iter.pop_front().unwrap();
                // Initialize total units for this outcome ID for this market ID
                self.total_units.write(market_id, outcome.id, 0);
            };

            // 8. Return the new market ID.
            market_id
        }

        // Function for users to purchase units for a specific outcome.
        fn purchase_units(ref self: Storage, market_id: u64, outcome_id: u32, amount: u128) {
            // @logic:
            // 1. Get the caller's address.
            let caller = get_caller_address();

            // 2. Check if the market exists and is Open.
            // TODO: Read market and check status. If not found or not open, panic or revert.

            // 3. Check if the outcome_id is valid for this market.
            // TODO: Read market, iterate outcomes to find outcome_id. If not found, panic.

            // 4. Calculate the required token amount (amount_of_units * price_per_unit).
            let price_per_unit: u128 = 1000; // 1000 SK per unit
            // TODO: Calculate required_token_amount = amount * price_per_unit. Handle potential overflow (use u256 for calculation?).

            // 5. Get the ERC20 token contract address.
            let erc20_address = self.erc20_token_address.read();
            let erc20 = IERC20Dispatcher { contract_address: erc20_address };

            // 6. **Transfer tokens** from the caller to this contract using transferFrom.
            // Requires user approval beforehand.
            // TODO: Call `erc20.transfer_from(caller, get_contract_address(), required_token_amount)`. Handle transfer failure.

            // 7. Update user's balance for this market and outcome.
            // TODO: Read current balance, add amount, write new balance: self.balances.write(caller, market_id, outcome_id, current_balance + amount);

            // 8. Update total units for this outcome.
            // TODO: Read current total units, add amount, write new total: self.total_units.write(market_id, outcome_id, current_total + amount);

            // 9. Update market's total volume.
            // TODO: Read market struct, add amount to total_market_volume, write updated market struct.
        }

        // Function for a Validator to resolve a market.
        fn resolve_market(ref self: Storage, market_id: u64, winning_outcome_id: u32) {
            // @logic:
            // 1. Get the caller's address.
            let caller = get_caller_address();

            // 2. Check if the caller is a validator.
            // TODO: Read from `self.validators`. If not true, panic (Unauthorized).

            // 3. Check if the market exists and is Open.
            // TODO: Read market struct. If not found or not Open, panic.

            // 4. Check if the winning_outcome_id is valid for this market.
            // TODO: Read market, iterate outcomes to find winning_outcome_id. If not found, panic.

            // 5. Update the market status to Resolved and set resolved_outcome_id.
            // TODO: Read market struct, update status and resolved_outcome_id. Write back updated market struct.

            // Note: Rewards are NOT transferred here. They are claimed later by winners.
        }

        // Function for winning users to claim their rewards.
        fn claim_rewards(ref self: Storage, market_id: u64) {
            // @logic:
            // 1. Get the caller's address.
            let caller = get_caller_address();

            // 2. Check if the market exists and is Resolved.
            // TODO: Read market struct. If not found or not Resolved, panic.

            // 3. Get the resolved_outcome_id.
            // TODO: Read `resolved_outcome_id` from the market struct. Panic if 0.

            // 4. Get the user's units for the winning outcome.
            // TODO: Read `user_units` from `self.balances.read(caller, market_id, resolved_outcome_id)`.

            // 5. If user_units is 0, they didn't bet on the winner or already claimed. Panic or return.
            // TODO: Check if user_units > 0. If not, panic (Nothing to claim).

            // 6. Get the total units for the winning outcome.
            // TODO: Read `total_winning_units` from `self.total_units.read(market_id, resolved_outcome_id)`.

            // 7. Get the total market volume (in units).
            // TODO: Read `total_market_volume` from the market struct.

            // 8. Calculate the reward amount (in tokens).
            // Formula: (user_units / total_winning_units) * total_market_volume * price_per_unit
            // Use u256 for intermediate calculation to minimize overflow risk.
            // TODO: Implement safe calculation: `reward = (user_units as u256 * total_market_volume as u256 * price_per_unit as u256) / (total_winning_units as u256)`.
            // TODO: Convert the result back to u128 or appropriate token type. Handle potential division by zero if total_winning_units is 0 (shouldn't happen if user_units > 0, but defensive).

            // 9. Zero out the user's balance for this market/outcome to prevent double claiming.
            // TODO: Write 0 to `self.balances.write(caller, market_id, resolved_outcome_id, 0);`

            // 10. Get the ERC20 token address.
            let erc20_address = self.erc20_token_address.read();
            let erc20 = IERC20Dispatcher { contract_address: erc20_address };

            // 11. **Transfer tokens** (the calculated reward) from this contract to the caller.
            // TODO: Call `erc20.transfer(caller, reward);`. Handle transfer failure.
        }

        // --- Getter Implementations ---
        // These functions read from storage and return data.

        fn get_market(self: @Storage, market_id: u64) -> Market {
            // TODO: Read and return the Market struct. Consider adding existence check and panic if market_id is invalid.
             self.markets.read(market_id)
        }

        fn get_user_position(self: @Storage, user: ContractAddress, market_id: u64, outcome_id: u32) -> u128 {
            // TODO: Read and return the user's units.
            self.balances.read(user, market_id, outcome_id) // Returns 0 if no position
        }

        fn get_total_outcome_units(self: @Storage, market_id: u64, outcome_id: u32) -> u128 {
            // TODO: Read and return the total units for the given outcome.
             self.total_units.read(market_id, outcome_id) // Returns 0 if no units
        }

         fn get_market_total_volume(self: @Storage, market_id: u64) -> u128 {
            // TODO: Read and return the total volume from the Market struct. Consider adding existence check.
             self.markets.read(market_id).total_market_volume // Returns 0 if market doesn't exist or volume is 0
         }


        fn get_resolved_outcome_id(self: @Storage, market_id: u64) -> u32 {
             // TODO: Read and return the resolved outcome ID from the Market struct. Consider adding existence check.
             self.markets.read(market_id).resolved_outcome_id // Returns 0 if not resolved
         }

        fn get_market_count(self: @Storage) -> u64 {
            // TODO: Read and return the market count.
            self.market_count.read()
        }

        fn get_erc20_token_address(self: @Storage) -> ContractAddress {
            // TODO: Read and return the stored ERC20 token address.
             self.erc20_token_address.read()
        }

        fn is_validator(self: @Storage, address: ContractAddress) -> bool {
            // TODO: Read and return if the address is marked as a validator.
            self.validators.read(address) // Returns false if not set
        }
    }
}