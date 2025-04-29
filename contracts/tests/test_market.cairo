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
