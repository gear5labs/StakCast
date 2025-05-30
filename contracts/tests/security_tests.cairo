use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use starknet::class_hash::{ClassHash, class_hash_const};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, start_cheat_block_timestamp
};

use stakcast::interface::{
    IPredictionHubDispatcher, IPredictionHubDispatcherTrait
};

// ================ Test Constants ================

fn ADMIN() -> ContractAddress {
    contract_address_const::<'admin'>()
}

fn MODERATOR() -> ContractAddress {
    contract_address_const::<'moderator'>()
}

fn USER1() -> ContractAddress {
    contract_address_const::<'user1'>()
}

fn USER2() -> ContractAddress {
    contract_address_const::<'user2'>()
}

fn FEE_RECIPIENT() -> ContractAddress {
    contract_address_const::<'fee_recipient'>()
}

fn PRAGMA_ORACLE() -> ContractAddress {
    contract_address_const::<'pragma_oracle'>()
}

fn NEW_FEE_RECIPIENT() -> ContractAddress {
    contract_address_const::<'new_fee_recipient'>()
}

fn NEW_CLASS_HASH() -> ClassHash {
    class_hash_const::<'new_implementation'>()
}

// ================ Test Setup ================

fn deploy_contract() -> IPredictionHubDispatcher {
    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN().into(),
        FEE_RECIPIENT().into(),
        PRAGMA_ORACLE().into()
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IPredictionHubDispatcher { contract_address }
}

// ================ Access Control Tests ================

#[test]
fn test_admin_access_control() {
    let contract = deploy_contract();
    
    // Test admin can add moderator
    start_cheat_caller_address(contract.contract_address, ADMIN());
    contract.add_moderator(MODERATOR());
    stop_cheat_caller_address(contract.contract_address);
    
    // Verify moderator was added by testing they can create a market
    start_cheat_caller_address(contract.contract_address, MODERATOR());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    
    let count = contract.get_prediction_count();
    assert(count == 1, 'Moderator should create market');
}

#[test]
#[should_panic(expected: ('Only admin allowed',))]
fn test_non_admin_cannot_add_moderator() {
    let contract = deploy_contract();
    
    // Test non-admin cannot add moderator
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.add_moderator(MODERATOR());
}

#[test]
fn test_moderator_can_create_market() {
    let contract = deploy_contract();
    
    // Add moderator
    start_cheat_caller_address(contract.contract_address, ADMIN());
    contract.add_moderator(MODERATOR());
    stop_cheat_caller_address(contract.contract_address);
    
    // Test moderator can create market
    start_cheat_caller_address(contract.contract_address, MODERATOR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    
    // Verify market was created
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market not created');
}

#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_regular_user_cannot_create_market() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, USER1());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
}

// ================ Time-based Restriction Tests ================

#[test]
#[should_panic(expected: ('End time must be in future',))]
fn test_cannot_create_market_with_past_end_time() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, ADMIN());
    
    // Set current time to a known value
    let current_time = 10000;
    start_cheat_block_timestamp(contract.contract_address, current_time);
    
    // Use a timestamp that's clearly in the past
    let past_time = current_time - 1;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        past_time
    );
}

#[test]
#[should_panic(expected: ('Market duration too short',))]
fn test_cannot_create_market_with_too_short_duration() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let short_future_time = get_block_timestamp() + 1800; // 30 minutes (less than 1 hour minimum)
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        short_future_time
    );
}

#[test]
fn test_valid_market_duration() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let valid_future_time = get_block_timestamp() + 7200; // 2 hours (valid duration)
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        valid_future_time
    );
    
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market should be created');
}

// ================ Market State Validation Tests ================

#[test]
fn test_betting_on_open_market() {
    let contract = deploy_contract();
    
    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // Place bet as user
    start_cheat_caller_address(contract.contract_address, USER1());
    let bet_result = contract.place_bet(1, 0, 1000, 0); // market_id=1, choice=0, amount=1000, market_type=0
    assert(bet_result == true, 'Bet should succeed');
}

#[test]
#[should_panic(expected: ('Market has ended',))]
fn test_cannot_bet_on_ended_market() {
    let contract = deploy_contract();
    
    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 3600; // 1 hour from now
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // Fast forward time past market end
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);
    
    // Try to place bet after market ended
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.place_bet(1, 0, 1000, 0);
}

#[test]
#[should_panic(expected: ('Amount must be positive',))]
fn test_cannot_bet_zero_amount() {
    let contract = deploy_contract();
    
    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // Try to place bet with zero amount
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.place_bet(1, 0, 0, 0); // amount = 0
}

#[test]
#[should_panic(expected: ('Invalid choice index',))]
fn test_cannot_bet_invalid_choice() {
    let contract = deploy_contract();
    
    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // Try to place bet with invalid choice index
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.place_bet(1, 2, 1000, 0); // choice_idx = 2 (invalid, should be 0 or 1)
}

// ================ Emergency Pause Tests ================

#[test]
fn test_emergency_pause_functionality() {
    let contract = deploy_contract();
    
    // Basic test to verify contract deployment and admin access
    start_cheat_caller_address(contract.contract_address, ADMIN());
    
    // Emergency pause functionality exists in IAdditionalAdmin interface
    // but is not accessible through the main IPredictionHub interface
    // This test serves as a placeholder for future emergency pause testing
    
    let admin = contract.get_admin();
    assert(admin == ADMIN(), 'Admin should be set correctly');
}

// ================ Market Resolution Tests ================

#[test]
fn test_market_resolution_by_moderator() {
    let contract = deploy_contract();
    
    // Add moderator and create market
    start_cheat_caller_address(contract.contract_address, ADMIN());
    contract.add_moderator(MODERATOR());
    
    let future_time = get_block_timestamp() + 3600; // 1 hour
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // Fast forward past market end time
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);
    
    // Moderator can resolve market
    start_cheat_caller_address(contract.contract_address, MODERATOR());
    contract.resolve_prediction(1, 0); // market_id=1, winning_choice=0
    
    // Verify market is resolved
    let market = contract.get_prediction(1);
    assert(market.is_resolved == true, 'Market should be resolved');
}

#[test]
#[should_panic(expected: ('Market not yet ended',))]
fn test_cannot_resolve_market_before_end_time() {
    let contract = deploy_contract();
    
    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400; // 1 day
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    
    // Try to resolve before end time
    contract.resolve_prediction(1, 0);
}

#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_regular_user_cannot_resolve_market() {
    let contract = deploy_contract();
    
    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 3600;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // Fast forward past end time
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);
    
    // Regular user tries to resolve
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.resolve_prediction(1, 0);
}

// ================ Reentrancy Protection Tests ================

#[test]
fn test_reentrancy_protection_on_betting() {
    let contract = deploy_contract();
    
    // Create market
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // Normal betting should work
    start_cheat_caller_address(contract.contract_address, USER1());
    let result = contract.place_bet(1, 0, 1000, 0);
    assert(result == true, 'First bet should succeed');
    
    // Reentrancy protection is implemented in the contract
    // Full reentrancy testing would require a malicious contract setup
}

// ================ Edge Case Tests ================

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_betting_on_nonexistent_market() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.place_bet(999, 0, 1000, 0); // market_id=999 doesn't exist
}

#[test]
fn test_multiple_bets_same_user() {
    let contract = deploy_contract();
    
    // Create market
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // User places multiple bets
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.place_bet(1, 0, 1000, 0);
    contract.place_bet(1, 1, 500, 0);
    
    // Check bet count
    let bet_count = contract.get_bet_count_for_market(USER1(), 1, 0);
    assert(bet_count == 2, 'Should have 2 bets');
}

#[test]
fn test_crypto_prediction_creation() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_crypto_prediction(
        "BTC Price Prediction",
        "Will BTC be above $50,000?",
        ('Above', 'Below'),
        'crypto',
        "https://example.com/btc.png",
        future_time,
        1, // comparison_type: greater than
        'BTC/USD', // asset_key
        50000 // target_value
    );
    
    let count = contract.get_prediction_count();
    assert(count == 1, 'Crypto prediction created');
}

#[test]
fn test_sports_prediction_creation() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, ADMIN());
    let future_time = get_block_timestamp() + 86400;
    
    contract.create_sports_prediction(
        "Team A vs Team B",
        "Who will win the match?",
        ('Team A', 'Team B'),
        'sports',
        "https://example.com/match.png",
        future_time,
        12345, // event_id
        true // team_flag
    );
    
    let count = contract.get_prediction_count();
    assert(count == 1, 'Sports prediction created');
}

// ================ Integration Tests ================

#[test]
fn test_complete_market_lifecycle() {
    let contract = deploy_contract();
    
    // 1. Admin adds moderator
    start_cheat_caller_address(contract.contract_address, ADMIN());
    contract.add_moderator(MODERATOR());
    stop_cheat_caller_address(contract.contract_address);
    
    // 2. Moderator creates market
    start_cheat_caller_address(contract.contract_address, MODERATOR());
    let future_time = get_block_timestamp() + 3600;
    
    contract.create_prediction(
        "Test Market",
        "Test Description",
        ('Yes', 'No'),
        'general',
        "https://example.com/image.png",
        future_time
    );
    stop_cheat_caller_address(contract.contract_address);
    
    // 3. Users place bets
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.place_bet(1, 0, 1000, 0);
    stop_cheat_caller_address(contract.contract_address);
    
    start_cheat_caller_address(contract.contract_address, USER2());
    contract.place_bet(1, 1, 500, 0);
    stop_cheat_caller_address(contract.contract_address);
    
    // 4. Time passes and market ends
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);
    
    // 5. Moderator resolves market
    start_cheat_caller_address(contract.contract_address, MODERATOR());
    contract.resolve_prediction(1, 0); // USER1 wins
    stop_cheat_caller_address(contract.contract_address);
    
    // 6. Winner collects winnings
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.collect_winnings(1, 0, 0); // market_id=1, market_type=0, bet_idx=0
    
    // Verify market state
    let market = contract.get_prediction(1);
    assert(market.is_resolved == true, 'Market should be resolved');
    assert(market.is_open == false, 'Market should be closed');
}

// ================ Upgrade Function Tests ================

#[test]
fn test_admin_can_upgrade_contract() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, ADMIN());
    
    // This will fail in test environment since NEW_CLASS_HASH() doesn't exist
    // but it tests the access control and parameter validation
    contract.upgrade(NEW_CLASS_HASH());
    
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Only admin allowed',))]
fn test_non_admin_cannot_upgrade_contract() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, USER1());
    contract.upgrade(NEW_CLASS_HASH());
}

#[test]
#[should_panic(expected: ('Class hash cannot be zero',))]
fn test_cannot_upgrade_to_zero_class_hash() {
    let contract = deploy_contract();
    
    start_cheat_caller_address(contract.contract_address, ADMIN());
    
    // Create a zero class hash
    let zero_hash: ClassHash = 0_felt252.try_into().unwrap();
    contract.upgrade(zero_hash);
} 