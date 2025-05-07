use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare,
    start_cheat_caller_address, test_address
};
use stakcast::interface::{
    IMarketValidatorDispatcher, IMarketValidatorDispatcherTrait,
    IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait
};
use starknet::ContractAddress;
use starknet::testing::set_block_timestamp;

// Helper to deploy MarketValidator
fn deploy_market_validator(
    prediction_market: ContractAddress,
    min_stake: u256,
    resolution_timeout: u64,
    slash_percentage: u64,
    owner: ContractAddress,
) -> IMarketValidatorDispatcher {
    let declare_result = declare("MarketValidator").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        prediction_market.into(),
        min_stake.low.into(),
        min_stake.high.into(),
        resolution_timeout.into(),
        slash_percentage.into(),
        owner.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IMarketValidatorDispatcher { contract_address: address }
}

// Helper to deploy PredictionMarket
fn deploy_prediction_market(
    fee_collector: ContractAddress, platform_fee: u256, market_validator: ContractAddress,
) -> IPredictionMarketDispatcher {
    let declare_result = declare("PredictionMarket").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        fee_collector.into(),
        platform_fee.low.into(),
        platform_fee.high.into(),
        market_validator.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IPredictionMarketDispatcher { contract_address: address }
}

// Test get_validator_by_index function
#[test]
fn test_get_validator_by_index_valid() {
    // Setup
    let owner = test_address();
    let validator1 = test_address();
    let validator2 = test_address();
    
    // Create validator contract first with a temporary prediction market address
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    
    // Now create the prediction market with the real validator address
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    
    // Update validator contract with the real prediction market address
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // 1. Register validators
    start_cheat_caller_address(mv_contract.contract_address, validator1);
    mv_contract.register_validator(100_u256);
    
    start_cheat_caller_address(mv_contract.contract_address, validator2);
    mv_contract.register_validator(100_u256);
    
    // 2. Get validators by index
    let retrieved_validator1 = mv_contract.get_validator_by_index(0);
    let retrieved_validator2 = mv_contract.get_validator_by_index(1);
    
    // 3. Assert correct validators are retrieved
    assert_eq!(retrieved_validator1, validator1, "First validator should be at index 0");
    assert_eq!(retrieved_validator2, validator2, "Second validator should be at index 1");
}

#[test]
#[should_panic(expected: ('Invalid validator index',))]
fn test_get_validator_by_index_invalid() {
    // Setup
    let owner = test_address();
    let validator = test_address();
    
    // Create validator contract first with a temporary prediction market address
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    
    // Now create the prediction market with the real validator address
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    
    // Update validator contract with the real prediction market address
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // 1. Register one validator
    start_cheat_caller_address(mv_contract.contract_address, validator);
    mv_contract.register_validator(100_u256);
    
    // 2. Try to get validator with invalid index (should panic)
    mv_contract.get_validator_by_index(1); // This should panic as we only have one validator at index 0
}

#[test]
#[should_panic(expected: ('Invalid validator index',))]
fn test_get_validator_by_index_no_validators() {
    // Setup
    let owner = test_address();
    
    // Create validator contract first with a temporary prediction market address
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    
    // Now create the prediction market with the real validator address
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    
    // Update validator contract with the real prediction market address
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Try to get validator with no validators registered (should panic)
    mv_contract.get_validator_by_index(0);
}

// --- register_validator Tests ---

#[test]
fn test_register_validator_success() {
    // Setup
    let owner = test_address();
    let validator_addr = test_address();
    let min_stake = 100_u256;
    
    let mv_contract = deploy_market_validator(test_address(), min_stake, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Execute: Register validator
    start_cheat_caller_address(mv_contract.contract_address, validator_addr);
    mv_contract.register_validator(min_stake);
    
    // Assert: Validator info is stored correctly
    let validator_info = mv_contract.get_validator_info(validator_addr);
    assert_eq!(validator_info.stake, min_stake, "Stake mismatch");
    assert!(validator_info.active, "Validator should be active");
    assert_eq!(mv_contract.get_validator_count(), 1, "Validator count incorrect");
    assert_eq!(mv_contract.get_validator_by_index(0), validator_addr, "Validator index mismatch");
}

#[test]
fn test_register_validator_update_stake() {
    // Setup
    let owner = test_address();
    let validator_addr = test_address();
    let initial_stake = 100_u256;
    let updated_stake = 200_u256;
    
    let mv_contract = deploy_market_validator(test_address(), initial_stake, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Execute: Register validator initially
    start_cheat_caller_address(mv_contract.contract_address, validator_addr);
    mv_contract.register_validator(initial_stake);
    
    // Assert: Initial registration
    let initial_info = mv_contract.get_validator_info(validator_addr);
    assert_eq!(initial_info.stake, initial_stake, "Initial stake mismatch");
    assert_eq!(mv_contract.get_validator_count(), 1, "Initial count incorrect");
    
    // Execute: Register again with higher stake (should update)
    mv_contract.register_validator(updated_stake);
    
    // Assert: Validator info is updated
    let updated_info = mv_contract.get_validator_info(validator_addr);
    assert_eq!(updated_info.stake, updated_stake, "Updated stake mismatch");
    assert!(updated_info.active, "Validator should remain active");
    assert_eq!(mv_contract.get_validator_count(), 1, "Validator count should not change"); // Still only one validator
}


#[test]
#[should_panic(expected: ('Insufficient stake',))]
fn test_register_validator_insufficient_stake() {
    // Setup
    let owner = test_address();
    let validator_addr = test_address();
    let min_stake = 100_u256;
    let insufficient_stake = 50_u256;
    
    let mv_contract = deploy_market_validator(test_address(), min_stake, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Execute: Attempt to register with insufficient stake (should panic)
    start_cheat_caller_address(mv_contract.contract_address, validator_addr);
    mv_contract.register_validator(insufficient_stake); 
}


// --- slash_validator Tests ---

#[test]
fn test_slash_validator_success_fixed_amount() {
    // Setup
    let owner = test_address(); // Admin and prediction market deployer
    let validator_addr = test_address();
    let initial_stake = 200_u256;
    let min_stake = 100_u256;
    let slash_amount = 50_u256;
    let slash_reason: felt252 = 'misbehavior';
    
    let mv_contract = deploy_market_validator(test_address(), min_stake, 86400, 10, owner); // Temp PM addr
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner); // Set PM address as owner
    mv_contract.set_prediction_market(pm_contract.contract_address); // Set the actual PM address
    
    // Register validator
    start_cheat_caller_address(mv_contract.contract_address, validator_addr);
    mv_contract.register_validator(initial_stake);
    
    // Execute: Slash validator (called by Prediction Market contract)
    start_cheat_caller_address(mv_contract.contract_address, pm_contract.contract_address); 
    mv_contract.slash_validator(validator_addr, slash_amount, slash_reason);
    
    // Assert: Stake reduced, still active
    let validator_info = mv_contract.get_validator_info(validator_addr);
    assert_eq!(validator_info.stake, initial_stake - slash_amount, "Stake not reduced correctly");
    assert!(validator_info.active, "Validator should still be active");
    assert_eq!(validator_info.disputed_resolutions, 1, "Dispute count mismatch");
}

#[test]
fn test_slash_validator_success_percentage() {
    // Setup
    let owner = test_address();
    let validator_addr = test_address();
    let initial_stake = 200_u256;
    let min_stake = 100_u256;
    let slash_percentage: u64 = 10; // 10%
    let expected_slash = (initial_stake * slash_percentage.into()) / 100_u256;
    let slash_reason: felt252 = 'inactivity';
    
    let mv_contract = deploy_market_validator(test_address(), min_stake, 86400, slash_percentage, owner);
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Register validator
    start_cheat_caller_address(mv_contract.contract_address, validator_addr);
    mv_contract.register_validator(initial_stake);
    
    // Execute: Slash validator with 0 amount (triggers percentage slash)
    start_cheat_caller_address(mv_contract.contract_address, pm_contract.contract_address);
    mv_contract.slash_validator(validator_addr, 0_u256, slash_reason); 
    
    // Assert: Stake reduced by percentage
    let validator_info = mv_contract.get_validator_info(validator_addr);
    assert_eq!(validator_info.stake, initial_stake - expected_slash, "Stake not reduced by percentage");
    assert!(validator_info.active, "Validator should still be active");
    assert_eq!(validator_info.disputed_resolutions, 1, "Dispute count mismatch");
}

#[test]
fn test_slash_validator_deactivation() {
    // Setup
    let owner = test_address();
    let validator_addr = test_address();
    let initial_stake = 150_u256;
    let min_stake = 100_u256;
    let slash_amount = 60_u256; // Will bring stake below min_stake
    let slash_reason: felt252 = 'critical failure';
    
    let mv_contract = deploy_market_validator(test_address(), min_stake, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Register validator
    start_cheat_caller_address(mv_contract.contract_address, validator_addr);
    mv_contract.register_validator(initial_stake);
    
    // Execute: Slash validator
    start_cheat_caller_address(mv_contract.contract_address, pm_contract.contract_address);
    mv_contract.slash_validator(validator_addr, slash_amount, slash_reason);
    
    // Assert: Stake reduced, validator deactivated
    let validator_info = mv_contract.get_validator_info(validator_addr);
    assert_eq!(validator_info.stake, initial_stake - slash_amount, "Stake mismatch after slash");
    assert!(!validator_info.active, "Validator should be deactivated");
}


#[test]
#[should_panic(expected: ('Validator not found or inactive',))]
fn test_slash_validator_non_existent() {
    // Setup
    let owner = test_address();
    let non_existent_validator = test_address();
    let min_stake = 100_u256;
    
    let mv_contract = deploy_market_validator(test_address(), min_stake, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Execute: Attempt to slash non-existent validator (should panic)
    start_cheat_caller_address(mv_contract.contract_address, pm_contract.contract_address);
    mv_contract.slash_validator(non_existent_validator, 50_u256, 'fake reason');
}

#[test]
#[should_panic(expected: ('Unauthorized slashing',))]
fn test_slash_validator_unauthorized_caller() {
    // Setup
    let owner = test_address();
    let validator_addr = test_address();
    let unauthorized_caller = test_address();
    let initial_stake = 200_u256;
    let min_stake = 100_u256;
    
    let mv_contract = deploy_market_validator(test_address(), min_stake, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address
    );
    start_cheat_caller_address(mv_contract.contract_address, owner);
    mv_contract.set_prediction_market(pm_contract.contract_address);
    
    // Register validator
    start_cheat_caller_address(mv_contract.contract_address, validator_addr);
    mv_contract.register_validator(initial_stake);
    
    // Execute: Attempt to slash from unauthorized address (should panic)
    start_cheat_caller_address(mv_contract.contract_address, unauthorized_caller); 
    mv_contract.slash_validator(validator_addr, 50_u256, 'unauthorized attempt');
}
