use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_block_timestamp,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ClassHash, ContractAddress, get_block_timestamp};

// ================ Test Constants ================

const ADMIN: felt252 = 123;
const MODERATOR: felt252 = 456;
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

fn NEW_FEE_RECIPIENT() -> ContractAddress {
    123456.try_into().unwrap()
}

fn NEW_CLASS_HASH() -> ClassHash {
    789012.try_into().unwrap()
}

// ================ Test Setup ================

fn deploy_contract() -> (IPredictionHubDispatcher, IERC20Dispatcher) {
    // Deploy mock ERC20 token
    let token_contract = declare("strktoken").unwrap().contract_class();
    let token_calldata = array![USER1_ADDR().into(), ADMIN_ADDR().into(), 18];
    let (token_address, _) = token_contract.deploy(@token_calldata).unwrap();
    let token = IERC20Dispatcher { contract_address: token_address };

    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    (IPredictionHubDispatcher { contract_address }, token)
}

// ================ Access Control Tests ================

#[test]
fn test_admin_access_control() {
    let (contract, _) = deploy_contract();

    // Test admin can add moderator
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify moderator was added by testing they can create a market
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );

    let count = contract.get_prediction_count();
    assert(count == 1, 'Moderator should create market');
}

#[test]
#[should_panic(expected: ('Only admin allowed',))]
fn test_non_admin_cannot_add_moderator() {
    let (contract, _) = deploy_contract();

    // Test non-admin cannot add moderator
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
}

#[test]
fn test_moderator_can_create_market() {
    let (contract, _) = deploy_contract();

    // Add moderator
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Test moderator can create market
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );

    // Verify market was created
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market not created');
}

#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_regular_user_cannot_create_market() {
    let (contract, _) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
}

// ================ Time-based Restriction Tests ================

#[test]
#[should_panic(expected: ('End time must be in future',))]
fn test_cannot_create_market_with_past_end_time() {
    let (contract, _) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

    // Set current time to a known value
    let current_time = 10000;
    start_cheat_block_timestamp(contract.contract_address, current_time);

    // Use a timestamp that's clearly in the past
    let past_time = current_time - 1;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            past_time,
        );
}

#[test]
#[should_panic(expected: ('Market duration too short',))]
fn test_cannot_create_market_with_too_short_duration() {
    let (contract, _) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let short_future_time = get_block_timestamp() + 1800; // 30 minutes (less than 1 hour minimum)

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            short_future_time,
        );
}

#[test]
fn test_valid_market_duration() {
    let (contract, _) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let valid_future_time = get_block_timestamp() + 7200; // 2 hours (valid duration)

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            valid_future_time,
        );

    let count = contract.get_prediction_count();
    assert(count == 1, 'Market should be created');
}

// ================ Market State Validation Tests ================
//function place bet already tested in diffrent other places
// #[test]
// fn test_betting_on_open_market() {
//     let (contract, token) = deploy_contract();

//     // Create market as admin
//     start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
//     let future_time = get_block_timestamp() + 86400;

//     contract
//         .create_prediction(
//             "Test Market",
//             "Test Description",
//             ('Yes', 'No'),
//             'general',
//             "https://example.com/image.png",
//             future_time,
//         );
//     stop_cheat_caller_address(contract.contract_address);

//     // Place bet as user
//     start_cheat_caller_address(token.contract_address, USER1_ADDR());
//     token.approve(contract.contract_address, 900000000000000000000); // Approve enough tokens

//     let bet_result = contract
//         .place_bet(
//             1, 0, 1000000000000000000, 0,
//         ); // market_id=1, choice=0, amount=1000, market_type=0
//     assert(bet_result == true, 'Bet should succeed');
// }

#[test]
#[should_panic(expected: ('Market has ended',))]
fn test_cannot_bet_on_ended_market() {
    let (contract, _) = deploy_contract();

    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 3600; // 1 hour from now

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Fast forward time past market end
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);

    // Try to place bet after market ended
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.place_bet(1, 0, 1000, 0);
}

#[test]
#[should_panic(expected: ('Amount must be positive',))]
fn test_cannot_bet_zero_amount() {
    let (contract, _) = deploy_contract();

    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Try to place bet with zero amount
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.place_bet(1, 0, 0, 0); // amount = 0
}

#[test]
#[should_panic(expected: ('Invalid choice index',))]
fn test_cannot_bet_invalid_choice() {
    let (contract, _) = deploy_contract();

    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Try to place bet with invalid choice index
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.place_bet(1, 2, 1000, 0); // choice_idx = 2 (invalid, should be 0 or 1)
}

// ================ Emergency Pause Tests ================

#[test]
fn test_emergency_pause_functionality() {
    let (contract, _) = deploy_contract();

    // Basic test to verify contract deployment and admin access
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());

    // Emergency pause functionality exists in IAdditionalAdmin interface
    // but is not accessible through the main IPredictionHub interface
    // This test serves as a placeholder for future emergency pause testing

    let admin = contract.get_admin();
    assert(admin == ADMIN_ADDR(), 'Admin should be set correctly');
}

// ================ Market Resolution Tests ================

#[test]
fn test_market_resolution_by_moderator() {
    let (contract, _) = deploy_contract();

    // Add moderator and create market
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR());

    let future_time = get_block_timestamp() + 3600; // 1 hour
    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Fast forward past market end time
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);

    // Moderator can resolve market
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract.resolve_prediction(1, 0); // market_id=1, winning_choice=0

    // Verify market is resolved
    let market = contract.get_prediction(1);
    assert(market.is_resolved == true, 'Market should be resolved');
}

#[test]
#[should_panic(expected: ('Market not yet ended',))]
fn test_cannot_resolve_market_before_end_time() {
    let (contract, _) = deploy_contract();

    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );

    // Try to resolve before end time
    contract.resolve_prediction(1, 0);
}

#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_regular_user_cannot_resolve_market() {
    let (contract, _) = deploy_contract();

    // Create market as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 3600;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Fast forward past end time
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);

    // Regular user tries to resolve
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.resolve_prediction(1, 0);
}

// ================ Reentrancy Protection Tests ================

#[test]
#[ignore] // This test is ignored because it requires a more complex setup to simulate reentrancy
fn test_reentrancy_protection_on_betting() {
    let (contract, token) = deploy_contract();

    // Create market
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Normal betting should work
    start_cheat_caller_address(token.contract_address, USER1_ADDR());
    token.approve(contract.contract_address, 900000000000000000000); // Only 100 tokens
    let result = contract.place_bet(1, 0, 1000000000000000000, 0);
    assert(result == true, 'First bet should succeed');
    // Reentrancy protection is implemented in the contract
// Full reentrancy testing would require a malicious contract setup
}

// ================ Edge Case Tests ================

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_betting_on_nonexistent_market() {
    let (contract, _) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.place_bet(999, 0, 1000, 0); // market_id=999 doesn't exist
}

#[test]
fn test_crypto_prediction_creation() {
    let (contract, _) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_crypto_prediction(
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
    let (contract, _) = deploy_contract();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_sports_prediction(
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
    let (contract, token) = deploy_contract();

    // 1. Admin adds moderator
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // 2. Moderator creates market
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 3600;

    contract
        .create_prediction(
            "Test Market",
            "Test Description",
            ('Yes', 'No'),
            'general',
            "https://example.com/image.png",
            future_time,
        );
    stop_cheat_caller_address(contract.contract_address);

    // 3. Distribute tokens to USER2
    start_cheat_caller_address(token.contract_address, USER1_ADDR());
    token.transfer(USER2_ADDR(), 500000000000000000000); // 500 tokens to USER2
    stop_cheat_caller_address(token.contract_address);

    // 4. Users approve and place bets
    start_cheat_caller_address(token.contract_address, USER1_ADDR());
    token.approve(contract.contract_address, 900000000000000000000); // Approve for USER1
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(token.contract_address, USER2_ADDR());
    token.approve(contract.contract_address, 900000000000000000000); // Approve for USER2
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.place_bet(1, 0, 1000000000000000000, 0);
    stop_cheat_caller_address(contract.contract_address);

    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    contract.place_bet(1, 1, 1000000000000000000, 0);
    stop_cheat_caller_address(contract.contract_address);

    // 5. Time passes and market ends
    start_cheat_block_timestamp(contract.contract_address, future_time + 1);

    // 6. Moderator resolves market
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract.resolve_prediction(1, 0); // USER1 wins
    stop_cheat_caller_address(contract.contract_address);

    // 7. Winner collects winnings
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.collect_winnings(1, 0, 0); // market_id=1, market_type=0, bet_idx=0

    // Verify market state
    let market = contract.get_prediction(1);
    assert(market.is_resolved == true, 'Market should be resolved');
    assert(market.is_open == false, 'Market should be closed');
}

// ================ Upgrade Function Tests ================

#[test]
fn test_upgradability() {
    let token_contract = declare("strktoken").unwrap().contract_class();
    let token_calldata = array![USER1_ADDR().into(), ADMIN_ADDR().into(), 18];
    let (token_address, _) = token_contract.deploy(@token_calldata).unwrap();

    // first declaration of predictionhub contract
    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into(),
    ];

    // deployment of the contract
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let instance = IPredictionHubDispatcher { contract_address };
    // declaring for a new class hash
    let new_class_hash = declare("PredictionHub").unwrap().contract_class().class_hash;
    start_cheat_caller_address(contract_address, ADMIN_ADDR());
    instance.upgrade(*new_class_hash);
}


#[test]
#[should_panic]
fn test_upgradability_should_fail_if_not_owner_tries_to_update() {
    let token_contract = declare("strktoken").unwrap().contract_class();
    let token_calldata = array![USER1_ADDR().into(), ADMIN_ADDR().into(), 18];
    let (token_address, _) = token_contract.deploy(@token_calldata).unwrap();

    // first declaration of predictionhub contract
    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into(),
    ];

    // deployment of the contract
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let instance = IPredictionHubDispatcher { contract_address };
    // declaring for a new class hash
    let new_class_hash = declare("PredictionHub").unwrap().contract_class().class_hash;

    // change caller to another person
    start_cheat_caller_address(contract_address, USER1_ADDR());
    instance.upgrade(*new_class_hash);
}
