use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_block_timestamp,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};

// ================ Test Constants ================

const ADMIN: felt252 = 123;
const MODERATOR: felt252 = 456;
const MODERATOR2: felt252 = 789;
const USER1: felt252 = 101112;
const USER2: felt252 = 131415;
const FEE_RECIPIENT: felt252 = 161718;
const PRAGMA_ORACLE: felt252 = 192021;

fn ADMIN_ADDR() -> ContractAddress {
    ADMIN.try_into().unwrap()
}

fn MODERATOR_ADDR() -> ContractAddress {
    MODERATOR.try_into().unwrap()
}

fn MODERATOR2_ADDR() -> ContractAddress {
    MODERATOR2.try_into().unwrap()
}

fn USER1_ADDR() -> ContractAddress {
    USER1.try_into().unwrap()
}

fn USER2_ADDR() -> ContractAddress {
    USER2.try_into().unwrap()
}

fn FEE_RECIPIENT_ADDR() -> ContractAddress {
    FEE_RECIPIENT.try_into().unwrap()
}

fn PRAGMA_ORACLE_ADDR() -> ContractAddress {
    PRAGMA_ORACLE.try_into().unwrap()
}

// ================ Test Setup ================

fn deploy_contract() -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher) {
    // Deploy mock ERC20 token
    let token_contract = declare("MockERC20").unwrap().contract_class();
    let token_calldata = array![USER1_ADDR().into()];
    let (token_address, _) = token_contract.deploy(@token_calldata).unwrap();

    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    let prediction_hub = IPredictionHubDispatcher { contract_address };
    let admin_contract = IAdditionalAdminDispatcher { contract_address };
    (prediction_hub, admin_contract)
}

fn setup_with_moderator() -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher) {
    let (contract, admin_contract) = deploy_contract();

    // Add moderator
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    (contract, admin_contract)
}

// ================ General Prediction Market Tests ================

#[test]
fn test_create_prediction_market_success() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2024?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2024",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );

    // Verify market count increased
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify market data
    let market = contract.get_prediction(1);
    assert(market.market_id == 1, 'Market ID should be 1');
    assert(market.title == "Will Bitcoin reach $100,000 by end of 2024?", 'Title mismatch');
    assert(market.is_open, 'Market should be open');
    assert(market.is_resolved == false, 'Market not resolved');
    assert(market.total_pool == 0, 'Initial pool 0');
    assert(market.end_time == future_time, 'End time mismatch');

    // Verify choices
    let (choice_0, choice_1) = market.choices;
    assert(choice_0.label == 'Yes', 'Choice 0 label mismatch');
    assert(choice_1.label == 'No', 'Choice 1 label mismatch');
}

#[test]
fn test_create_multiple_prediction_markets() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    // Create first market
    contract
        .create_prediction(
            "Market 1",
            "Description 1",
            ('Yes', 'No'),
            'category1',
            "https://example.com/1.png",
            future_time,
        );

    // Create second market
    contract
        .create_prediction(
            "Market 2",
            "Description 2",
            ('True', 'False'),
            'category2',
            "https://example.com/2.png",
            future_time + 3600,
        );

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 2 markets');

    // Verify both markets exist and have unique IDs
    let market1 = contract.get_prediction(1);
    let market2 = contract.get_prediction(2);

    assert(market1.market_id == 1, 'Market 1 ID should be 1');
    assert(market2.market_id == 2, 'Market 2 ID should be 2');
    assert(market1.title == "Market 1", 'Market 1 title mismatch');
    assert(market2.title == "Market 2", 'Market 2 title mismatch');

    // Test get_all_predictions
    let all_markets = contract.get_all_predictions();
    assert(all_markets.len() == 2, 'Should return 2 markets');
}

#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_create_prediction_access_control_failure() {
    let (contract, _admin_contract) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Unauthorized Market",
            "This should fail",
            ('Yes', 'No'),
            'test',
            "https://example.com/test.png",
            future_time,
        );
}

#[test]
#[should_panic(expected: ('End time must be in future',))]
fn test_create_prediction_invalid_end_time() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    let current_time = 10000;
    start_cheat_block_timestamp(contract.contract_address, current_time);

    let past_time = current_time - 1;

    contract
        .create_prediction(
            "Invalid Time Market",
            "This should fail due to past end time",
            ('Yes', 'No'),
            'test',
            "https://example.com/test.png",
            past_time,
        );
}

#[test]
#[should_panic(expected: ('Market duration too short',))]
fn test_create_prediction_too_short_duration() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let short_future_time = get_block_timestamp() + 1800; // 30 minutes (less than 1 hour minimum)

    contract
        .create_prediction(
            "Short Duration Market",
            "This should fail due to short duration",
            ('Yes', 'No'),
            'test',
            "https://example.com/test.png",
            short_future_time,
        );
}

// ================ Crypto Prediction Market Tests ================

#[test]
fn test_create_crypto_prediction_success() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify crypto market data
    let crypto_market = contract.get_crypto_prediction(1);
    assert(crypto_market.market_id == 1, 'Market ID should be 1');
    assert(crypto_market.title == "ETH Price Prediction", 'Title mismatch');
    assert(crypto_market.comparison_type == 1, 'Comparison type 1');
    assert(crypto_market.asset_key == 'ETH', 'Asset key ETH');
    assert(crypto_market.target_value == 3000, 'Target value 3000');
    assert(crypto_market.is_open, 'Market should be open');
    assert(crypto_market.is_resolved == false, 'Market not resolved');

    // Verify choices
    let (choice_0, choice_1) = crypto_market.choices;
    assert(choice_0.label == 'Above $3000', 'Choice 0 label');
    assert(choice_1.label == 'Below $3000', 'Choice 1 label');
}

#[test]
#[should_panic(expected: ('Invalid comparison type',))]
fn test_create_crypto_prediction_invalid_comparison_type() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_crypto_prediction(
            "Invalid Comparison",
            "This should fail",
            ('Up', 'Down'),
            'test',
            "https://example.com/test.png",
            future_time,
            2, // Invalid comparison type (should be 0 or 1)
            'BTC',
            50000,
        );
}

#[test]
fn test_create_crypto_prediction_both_comparison_types() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    // Test comparison type 0 (less than)
    contract
        .create_crypto_prediction(
            "BTC Below 40k",
            "Will BTC be below $40,000?",
            ('Below', 'Above'),
            'btc_below',
            "https://example.com/btc.png",
            future_time,
            0, // Less than comparison
            'BTC',
            40000,
        );

    // Test comparison type 1 (greater than)
    contract
        .create_crypto_prediction(
            "BTC Above 60k",
            "Will BTC be above $60,000?",
            ('Above', 'Below'),
            'btc_above',
            "https://example.com/btc2.png",
            future_time + 3600,
            1, // Greater than comparison
            'BTC',
            60000,
        );

    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 2 markets');

    let market1 = contract.get_crypto_prediction(1);
    let market2 = contract.get_crypto_prediction(2);

    assert(market1.comparison_type == 0, 'Market 1 less than');
    assert(market2.comparison_type == 1, 'Market 2 greater than');
    assert(market1.target_value == 40000, 'Market 1 target 40000');
    assert(market2.target_value == 60000, 'Market 2 target 60000');
}

// ================ Sports Prediction Market Tests ================

#[test]
fn test_create_sports_prediction_success() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify sports market data
    let sports_market = contract.get_sports_prediction(1);
    assert(sports_market.market_id == 1, 'Market ID should be 1');
    assert(sports_market.title == "Lakers vs Warriors", 'Title mismatch');
    assert(sports_market.event_id == 123456, 'Event ID 123456');
    assert(sports_market.team_flag, 'Team flag true');
    assert(sports_market.is_open, 'Market should be open');
    assert(sports_market.is_resolved == false, 'Market not resolved');

    // Verify choices
    let (choice_0, choice_1) = sports_market.choices;
    assert(choice_0.label == 'Lakers', 'Choice 0 Lakers');
    assert(choice_1.label == 'Warriors', 'Choice 1 Warriors');
}

#[test]
fn test_create_sports_prediction_non_team_event() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_sports_prediction(
            "Super Bowl Outcome",
            "Will the Super Bowl go to overtime?",
            ('Yes', 'No'),
            'nfl_overtime',
            "https://example.com/superbowl.png",
            future_time,
            789012, // Event ID
            false // Not team-based
        );

    let sports_market = contract.get_sports_prediction(1);
    assert(!sports_market.team_flag, 'Team flag should be false');
    assert(sports_market.event_id == 789012, 'Event ID 789012');

    let (choice_0, choice_1) = sports_market.choices;
    assert(choice_0.label == 'Yes', 'Choice 0 Yes');
    assert(choice_1.label == 'No', 'Choice 1 No');
}

// ================ Mixed Market Type Tests ================

#[test]
fn test_create_all_market_types() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    // Create general prediction
    contract
        .create_prediction(
            "General Market",
            "General prediction description",
            ('Option A', 'Option B'),
            'general',
            "https://example.com/general.png",
            future_time,
        );

    // Create crypto prediction
    contract
        .create_crypto_prediction(
            "Crypto Market",
            "Crypto prediction description",
            ('Up', 'Down'),
            'crypto',
            "https://example.com/crypto.png",
            future_time + 3600,
            1,
            'BTC',
            50000,
        );

    // Create sports prediction
    contract
        .create_sports_prediction(
            "Sports Market",
            "Sports prediction description",
            ('Team A', 'Team B'),
            'sports',
            "https://example.com/sports.png",
            future_time + 7200,
            555,
            true,
        );

    // Verify total count
    let count = contract.get_prediction_count();
    assert(count == 3, 'Should have 3 markets');

    // Verify each market type exists
    let general_market = contract.get_prediction(1);
    let crypto_market = contract.get_crypto_prediction(2);
    let sports_market = contract.get_sports_prediction(3);

    assert(general_market.market_id == 1, 'General market ID 1');
    assert(crypto_market.market_id == 2, 'Crypto market ID 2');
    assert(sports_market.market_id == 3, 'Sports market ID 3');

    // Test get_all functions
    let all_general = contract.get_all_predictions();
    let all_crypto = contract.get_all_crypto_predictions();
    let all_sports = contract.get_all_sports_predictions();

    assert(all_general.len() == 1, '1 general market');
    assert(all_crypto.len() == 1, '1 crypto market');
    assert(all_sports.len() == 1, '1 sports market');
}

// ================ Admin and Moderator Management Tests ================

#[test]
fn test_admin_can_create_market() {
    let (contract, _admin_contract) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Admin Market",
            "Market created by admin",
            ('Yes', 'No'),
            'admin_test',
            "https://example.com/admin.png",
            future_time,
        );

    let count = contract.get_prediction_count();
    assert(count == 1, 'Admin can create market');

    let market = contract.get_prediction(1);
    assert(market.title == "Admin Market", 'Admin market title');
}

#[test]
fn test_multiple_moderators_can_create_markets() {
    let (contract, _admin_contract) = deploy_contract();

    // Add two moderators
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
    contract.add_moderator(MODERATOR2_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    let future_time = get_block_timestamp() + 86400;

    // First moderator creates a market
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract
        .create_prediction(
            "Moderator 1 Market",
            "Market by moderator 1",
            ('Yes', 'No'),
            'mod1',
            "https://example.com/mod1.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Second moderator creates a market
    start_cheat_caller_address(contract.contract_address, MODERATOR2_ADDR());
    contract
        .create_prediction(
            "Moderator 2 Market",
            "Market by moderator 2",
            ('True', 'False'),
            'mod2',
            "https://example.com/mod2.png",
            future_time + 3600,
        );
    stop_cheat_caller_address(contract.contract_address);

    let count = contract.get_prediction_count();
    assert(count == 2, '2 moderator markets');

    let market1 = contract.get_prediction(1);
    let market2 = contract.get_prediction(2);

    assert(market1.title == "Moderator 1 Market", 'Market 1 title');
    assert(market2.title == "Moderator 2 Market", 'Market 2 title');
}

// ================ Edge Case and Error Handling Tests ================

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_get_nonexistent_market() {
    let (contract, _admin_contract) = deploy_contract();

    // Try to get a market that doesn't exist
    contract.get_prediction(999);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_get_nonexistent_crypto_market() {
    let (contract, _admin_contract) = deploy_contract();

    // Try to get a crypto market that doesn't exist
    contract.get_crypto_prediction(999);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_get_nonexistent_sports_market() {
    let (contract, _admin_contract) = deploy_contract();

    // Try to get a sports market that doesn't exist
    contract.get_sports_prediction(999);
}

#[test]
fn test_empty_arrays_when_no_markets() {
    let (contract, _admin_contract) = deploy_contract();

    // Test that get_all functions return empty arrays when no markets exist
    let all_general = contract.get_all_predictions();
    let all_crypto = contract.get_all_crypto_predictions();
    let all_sports = contract.get_all_sports_predictions();

    assert(all_general.len() == 0, 'Empty general array');
    assert(all_crypto.len() == 0, 'Empty crypto array');
    assert(all_sports.len() == 0, 'Empty sports array');

    // Prediction count should be 0
    let count = contract.get_prediction_count();
    assert(count == 0, 'Initial count 0');
}

// ================ Gas Optimization Tests ================

#[test]
fn test_sequential_market_id_generation() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    // Create 5 markets and verify IDs are sequential
    let mut i: u32 = 1;
    while i <= 5 {
        contract
            .create_prediction(
                "Market",
                "Description",
                ('Yes', 'No'),
                'test',
                "https://example.com/test.png",
                future_time,
            );

        let count = contract.get_prediction_count();
        assert(count == i.into(), 'Count matches iteration');

        let market = contract.get_prediction(i.into());
        assert(market.market_id == i.into(), 'Sequential market ID');

        i += 1;
    }

    let final_count = contract.get_prediction_count();
    assert(final_count == 5, 'Final count 5');
}

#[test]
fn test_market_data_integrity() {
    let (contract, _admin_contract) = setup_with_moderator();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    // Create a market with specific data
    let title = "Data Integrity Test Market";
    let description = "This market tests data integrity across storage and retrieval";
    let category = 'integrity_test';
    let image_url = "https://example.com/integrity-test.png";

    contract
        .create_prediction(
            title.clone(),
            description.clone(),
            ('Option Alpha', 'Option Beta'),
            category,
            image_url.clone(),
            future_time,
        );

    // Retrieve and verify all data matches exactly
    let market = contract.get_prediction(1);

    assert(market.title == title, 'Title match');
    assert(market.description == description, 'Description match');
    assert(market.category == category, 'Category match');
    assert(market.image_url == image_url, 'Image URL match');
    assert(market.end_time == future_time, 'End time match');
    assert(market.market_id == 1, 'Market ID 1');
    assert(market.is_open, 'Market open initially');
    assert(market.is_resolved == false, 'Market not resolved');
    assert(market.total_pool == 0, 'Total pool 0 initially');

    let (choice_0, choice_1) = market.choices;
    assert(choice_0.label == 'Option Alpha', 'Choice 0 label');
    assert(choice_1.label == 'Option Beta', 'Choice 1 label');
    assert(choice_0.staked_amount == 0, 'Choice 0 stake 0');
    assert(choice_1.staked_amount == 0, 'Choice 1 stake 0');
}

// ================ Pause/Unpause Tests ================

#[test]
#[should_panic(expected: ('Contract is paused',))]
fn test_cannot_create_market_when_emergency_paused() {
    let (contract, admin_contract) = setup_with_moderator();

    // Emergency pause the contract
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    admin_contract.emergency_pause("Emergency maintenance");
    stop_cheat_caller_address(contract.contract_address);

    // Try to create market while paused
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Should Fail",
            "This should fail due to pause",
            ('Yes', 'No'),
            'fail_test',
            "https://example.com/fail.png",
            future_time,
        );
}

#[test]
#[should_panic(expected: ('Market creation paused',))]
fn test_cannot_create_market_when_market_creation_paused() {
    let (contract, admin_contract) = setup_with_moderator();

    // Pause market creation specifically
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    admin_contract.pause_market_creation();
    stop_cheat_caller_address(contract.contract_address);

    // Try to create market while market creation is paused
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Should Fail",
            "This should fail due to market creation pause",
            ('Yes', 'No'),
            'fail_test',
            "https://example.com/fail.png",
            future_time,
        );
}

#[test]
fn test_can_create_market_after_unpause() {
    let (contract, admin_contract) = setup_with_moderator();

    // Emergency pause the contract
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    admin_contract.emergency_pause("Testing pause/unpause");

    // Verify contract is paused
    assert(admin_contract.is_paused(), 'Contract paused');

    // Unpause the contract
    admin_contract.emergency_unpause();

    // Verify contract is unpaused
    assert(!admin_contract.is_paused(), 'Contract unpaused');
    stop_cheat_caller_address(contract.contract_address);

    // Now create market should work
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Post Unpause Market",
            "This should work after unpause",
            ('Yes', 'No'),
            'unpause_test',
            "https://example.com/unpause.png",
            future_time,
        );

    let count = contract.get_prediction_count();
    assert(count == 1, 'Market created after unpause');
}

#[test]
fn test_can_create_market_after_market_creation_unpause() {
    let (contract, admin_contract) = setup_with_moderator();

    // Pause market creation
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    admin_contract.pause_market_creation();

    // Unpause market creation
    admin_contract.unpause_market_creation();
    stop_cheat_caller_address(contract.contract_address);

    // Now create market should work
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Post Market Creation Unpause",
            "This should work after unpause",
            ('Yes', 'No'),
            'mc_unpause_test',
            "https://example.com/mc_unpause.png",
            future_time,
        );

    let count = contract.get_prediction_count();
    assert(count == 1, 'Market created after unpause');
}

#[test]
fn test_emergency_pause_functionality() {
    let (_contract, admin_contract) = deploy_contract();

    start_cheat_caller_address(admin_contract.contract_address, ADMIN_ADDR());

    admin_contract.emergency_pause("Test emergency pause");

    // Verify pause was successful (functional test)
    assert(admin_contract.is_paused(), 'Contract should be paused');
    let reason = admin_contract.get_emergency_pause_reason();
    assert(reason == "Test emergency pause", 'Pause reason should match');
}
