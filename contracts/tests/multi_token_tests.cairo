use core::num::traits::Zero;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};


// ================ Test Constants ================

const ADMIN_CONST: felt252 = 123;
const MODERATOR_CONST: felt252 = 456;
const USER1_CONST: felt252 = 101112;
const USER2_CONST: felt252 = 131415;
const USER3_CONST: felt252 = 161718;
const FEE_RECIPIENT_CONST: felt252 = 192021;
const PRAGMA_ORACLE_CONST: felt252 = 222324;

fn ADMIN_ADDR() -> ContractAddress {
    ADMIN_CONST.try_into().unwrap()
}

fn MODERATOR_ADDR() -> ContractAddress {
    MODERATOR_CONST.try_into().unwrap()
}

fn USER1_ADDR() -> ContractAddress {
    USER1_CONST.try_into().unwrap()
}

fn USER2_ADDR() -> ContractAddress {
    USER2_CONST.try_into().unwrap()
}

fn USER3_ADDR() -> ContractAddress {
    USER3_CONST.try_into().unwrap()
}

fn FEE_RECIPIENT_ADDR() -> ContractAddress {
    FEE_RECIPIENT_CONST.try_into().unwrap()
}

fn PRAGMA_ORACLE_ADDR() -> ContractAddress {
    PRAGMA_ORACLE_CONST.try_into().unwrap()
}

// ================ Mock Token Setup ================

fn deploy_mock_token(recipient: ContractAddress, symbol: ByteArray) -> IERC20Dispatcher {
    let contract = declare("MockERC20").unwrap().contract_class();
    let constructor_calldata = array![recipient.into()];

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IERC20Dispatcher { contract_address }
}

fn deploy_prediction_contract(
    token_address: ContractAddress,
) -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher) {
    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let prediction_hub = IPredictionHubDispatcher { contract_address };
    let admin_interface = IAdditionalAdminDispatcher { contract_address };

    (prediction_hub, admin_interface)
}

fn setup_multi_token_environment() -> (
    IPredictionHubDispatcher,
    IAdditionalAdminDispatcher,
    IERC20Dispatcher, // USDC Mock
    IERC20Dispatcher, // STRK Mock
    IERC20Dispatcher, // ETH Mock
    IERC20Dispatcher // Custom Token
) {
    // Deploy multiple mock tokens
    let usdc_token = deploy_mock_token(USER1_ADDR(), "USDC");
    let strk_token = deploy_mock_token(USER1_ADDR(), "STRK");
    let eth_token = deploy_mock_token(USER1_ADDR(), "ETH");
    let custom_token = deploy_mock_token(USER1_ADDR(), "CUSTOM");

    let (prediction_hub, admin_interface) = deploy_prediction_contract(usdc_token.contract_address);

    // Add moderator
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    prediction_hub.add_moderator(MODERATOR_ADDR());

    // Add all tokens as supported (using mock token addresses in tests)
    admin_interface.add_supported_token('USDC', usdc_token.contract_address);
    admin_interface.add_supported_token('usdc', usdc_token.contract_address);
    admin_interface.add_supported_token('STRK', strk_token.contract_address);
    admin_interface.add_supported_token('strk', strk_token.contract_address);
    admin_interface.add_supported_token('ETH', eth_token.contract_address);
    admin_interface.add_supported_token('eth', eth_token.contract_address);
    admin_interface.add_supported_token('CUSTOM', custom_token.contract_address);
    admin_interface.add_supported_token('custom', custom_token.contract_address);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Setup token balances and allowances for multiple users and multiple tokens
    let tokens = array![usdc_token, strk_token, eth_token, custom_token];
    let users = array![USER1_ADDR(), USER2_ADDR(), USER3_ADDR()];

    let mut token_idx = 0;
    while token_idx < tokens.len() {
        let token = *tokens.at(token_idx);

        let mut user_idx = 0;
        while user_idx < users.len() {
            let user = *users.at(user_idx);

            // Transfer tokens from USER1 to other users if not USER1
            if user != USER1_ADDR() {
                start_cheat_caller_address(token.contract_address, USER1_ADDR());
                token.transfer(user, 500000000000000000000000); // 500k tokens
                stop_cheat_caller_address(token.contract_address);
            }

            // Set up allowances for all users
            start_cheat_caller_address(token.contract_address, user);
            token
                .approve(prediction_hub.contract_address, 1000000000000000000000000); // 1M approval
            stop_cheat_caller_address(token.contract_address);

            user_idx += 1;
        }
        token_idx += 1;
    }

    (prediction_hub, admin_interface, usdc_token, strk_token, eth_token, custom_token)
}

fn create_test_market(prediction_hub: IPredictionHubDispatcher) -> u256 {
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    let future_time = get_block_timestamp() + 86400; // 1 day from now
    prediction_hub
        .create_prediction(
            "Will BTC reach $100k?",
            "A prediction about Bitcoin price",
            ('Yes', 'No'),
            'crypto',
            "https://example.com/btc.jpg",
            future_time,
        );

    stop_cheat_caller_address(prediction_hub.contract_address);
    1
}

// ================ Multi-Token Support Tests ================

#[test]
fn test_supported_token_addresses() {
    let (prediction_hub, _admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();

    // Test token support (tokens added in setup)
    let usdc_addr = prediction_hub.get_supported_token('USDC');
    let strk_addr = prediction_hub.get_supported_token('STRK');
    let eth_addr = prediction_hub.get_supported_token('ETH');
    let custom_addr = prediction_hub.get_supported_token('CUSTOM');

    // Check that addresses are not zero (indicating they are supported)
    assert(!usdc_addr.is_zero(), 'USDC should be supported');
    assert(!strk_addr.is_zero(), 'STRK should be supported');
    assert(!eth_addr.is_zero(), 'ETH should be supported');
    assert(!custom_addr.is_zero(), 'CUSTOM should be supported');

    // Test case sensitivity
    let usdc_lower = prediction_hub.get_supported_token('usdc');
    let strk_lower = prediction_hub.get_supported_token('strk');
    assert(!usdc_lower.is_zero(), 'usdc should be supported');
    assert(!strk_lower.is_zero(), 'strk should be supported');
}

#[test]
fn test_is_token_supported() {
    let (prediction_hub, _admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();

    // Test supported tokens
    assert(prediction_hub.is_token_supported('USDC'), 'USDC should be supported');
    assert(prediction_hub.is_token_supported('STRK'), 'STRK should be supported');
    assert(prediction_hub.is_token_supported('ETH'), 'ETH should be supported');
    assert(prediction_hub.is_token_supported('CUSTOM'), 'CUSTOM should be supported');

    // Test unsupported token
    assert(!prediction_hub.is_token_supported('UNKNOWN'), 'UNKNOWN should not be supported');
}

#[test]
fn test_place_bet_with_usdc() {
    let (prediction_hub, _admin_interface, usdc_token, _strk, _eth, _custom) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    let mut spy = spy_events();

    // Place bet with USDC
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let result = prediction_hub
        .place_bet_with_token(market_id, 0, 1000000000000000000000, 0, 'USDC'); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);

    assert(result, 'USDC bet placement failed');

    // Verify market token is set to USDC
    let market_token = prediction_hub.get_market_token(market_id);
    let expected_usdc_addr = prediction_hub.get_supported_token('USDC');
    assert(market_token == expected_usdc_addr, 'Market token should be USDC');

    // Verify bet was recorded
    let bet_count = prediction_hub.get_bet_count_for_market(USER1_ADDR(), market_id, 0);
    assert(bet_count == 1, 'Bet count incorrect');

    // Check events were emitted
    let events = spy.get_events();
    assert(events.events.len() >= 2, 'Expected multiple events');
}

#[test]
fn test_place_bet_with_strk() {
    let (prediction_hub, _admin_interface, _usdc, strk_token, _eth, _custom) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    // Place bet with STRK
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    let result = prediction_hub
        .place_wager_with_token(market_id, 1, 500000000000000000000, 0, 'STRK'); // 500 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);

    assert(result, 'STRK bet placement failed');

    // Verify market token is set to STRK
    let market_token = prediction_hub.get_market_token(market_id);
    let expected_strk_addr = prediction_hub.get_supported_token('STRK');
    assert(market_token == expected_strk_addr, 'Market token should be STRK');

    // Verify bet was recorded
    let bet_count = prediction_hub.get_bet_count_for_market(USER2_ADDR(), market_id, 0);
    assert(bet_count == 1, 'Bet count incorrect');
}

#[test]
fn test_place_bet_with_custom_token() {
    let (prediction_hub, _admin_interface, _usdc, _strk, _eth, custom_token) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    // Place bet with custom token
    start_cheat_caller_address(prediction_hub.contract_address, USER3_ADDR());
    let result = prediction_hub
        .place_bet_with_token(market_id, 0, 200000000000000000000, 0, 'CUSTOM'); // 200 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);

    assert(result, 'Custom token bet failed');

    // Verify market token is set to custom token
    let market_token = prediction_hub.get_market_token(market_id);
    let expected_custom_addr = prediction_hub.get_supported_token('CUSTOM');
    assert(market_token == expected_custom_addr, 'Market token should be CUSTOM');

    // Verify bet was recorded
    let bet_count = prediction_hub.get_bet_count_for_market(USER3_ADDR(), market_id, 0);
    assert(bet_count == 1, 'Bet count incorrect');
}

#[test]
#[should_panic(expected: ('Unsupported token',))]
fn test_bet_with_unsupported_token() {
    let (prediction_hub, _admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_bet_with_token(market_id, 0, 1000000000000000000000, 0, 'UNKNOWN');
    stop_cheat_caller_address(prediction_hub.contract_address);
}

#[test]
#[should_panic(expected: ('Market token mismatch',))]
fn test_bet_with_different_token_same_market() {
    let (prediction_hub, _admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    // First bet with USDC
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_bet_with_token(market_id, 0, 1000000000000000000000, 0, 'USDC');
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Second bet with STRK on same market should fail
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.place_bet_with_token(market_id, 1, 500000000000000000000, 0, 'STRK');
    stop_cheat_caller_address(prediction_hub.contract_address);
}

#[test]
fn test_multiple_markets_different_tokens() {
    let (prediction_hub, _admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();

    // Create first market
    let market_id_1 = create_test_market(prediction_hub);

    // Create second market
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;
    prediction_hub
        .create_prediction(
            "Will ETH reach $5k?",
            "A prediction about Ethereum price",
            ('Yes', 'No'),
            'crypto',
            "https://example.com/eth.jpg",
            future_time,
        );
    stop_cheat_caller_address(prediction_hub.contract_address);
    let market_id_2 = 2;

    // Bet on first market with USDC
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_bet_with_token(market_id_1, 0, 1000000000000000000000, 0, 'USDC');
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Bet on second market with STRK
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.place_bet_with_token(market_id_2, 1, 500000000000000000000, 0, 'STRK');
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Verify each market has the correct token
    let market_1_token = prediction_hub.get_market_token(market_id_1);
    let market_2_token = prediction_hub.get_market_token(market_id_2);

    let expected_usdc_addr = prediction_hub.get_supported_token('USDC');
    let expected_strk_addr = prediction_hub.get_supported_token('STRK');

    assert(market_1_token == expected_usdc_addr, 'Market 1 should use USDC');
    assert(market_2_token == expected_strk_addr, 'Market 2 should use STRK');
}

// ================ Token Management Tests ================

#[test]
fn test_add_custom_token() {
    let (prediction_hub, admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();

    let new_token_addr: ContractAddress = 0x123456789.try_into().unwrap();

    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    admin_interface.add_supported_token('NEWTOKEN', new_token_addr);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Verify token was added
    let retrieved_addr = prediction_hub.get_supported_token('NEWTOKEN');
    assert(retrieved_addr == new_token_addr, 'New token not added correctly');
    assert(prediction_hub.is_token_supported('NEWTOKEN'), 'New token should be supported');
}

#[test]
fn test_remove_custom_token() {
    let (prediction_hub, admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();

    // Remove the custom token
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    admin_interface.remove_supported_token('CUSTOM');
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Verify token was removed
    assert(!prediction_hub.is_token_supported('CUSTOM'), 'CUSTOM token should be removed');
    let retrieved_addr = prediction_hub.get_supported_token('CUSTOM');
    assert(retrieved_addr.is_zero(), 'CUSTOM token should be zero');
}

#[test]
#[should_panic(expected: ('Only admin allowed',))]
fn test_non_admin_cannot_add_token() {
    let (prediction_hub, admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();

    let new_token_addr: ContractAddress = 0x123456789.try_into().unwrap();

    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    admin_interface.add_supported_token('NEWTOKEN', new_token_addr);
    stop_cheat_caller_address(prediction_hub.contract_address);
}

// ================ Emergency Withdrawal Tests ================

#[test]
fn test_emergency_withdraw_specific_token() {
    let (prediction_hub, admin_interface, usdc_token, _strk, _eth, _custom) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    // Place bet to add tokens to contract
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_bet_with_token(market_id, 0, 1000000000000000000000, 0, 'USDC');
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check contract balance before withdrawal
    let contract_balance_before = usdc_token.balance_of(prediction_hub.contract_address);
    assert(contract_balance_before > 0, 'should have USDC balance');

    // Emergency withdraw
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    admin_interface
        .emergency_withdraw_specific_token(
            'USDC', 500000000000000000000, ADMIN_ADDR(),
        ); // 500 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check balances after withdrawal
    let admin_balance = usdc_token.balance_of(ADMIN_ADDR());
    assert(admin_balance == 500000000000000000000, 'Admin receive tokens');
}

#[test]
#[should_panic(expected: ('Unsupported token',))]
fn test_emergency_withdraw_unsupported_token() {
    let (prediction_hub, admin_interface, _usdc, _strk, _eth, _custom) =
        setup_multi_token_environment();

    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    admin_interface
        .emergency_withdraw_specific_token('UNKNOWN', 100000000000000000000, ADMIN_ADDR());
    stop_cheat_caller_address(prediction_hub.contract_address);
}

// ================ Backward Compatibility Tests ================

#[test]
fn test_backward_compatibility_default_token() {
    let (prediction_hub, _admin_interface, usdc_token, _strk, _eth, _custom) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    // Use old place_bet function (should use default token)
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let result = prediction_hub.place_bet(market_id, 0, 1000000000000000000000, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);

    assert(result, 'Backward compatible bet failed');

    // Verify market uses default token (the one passed to constructor)
    let market_token = prediction_hub.get_market_token(market_id);
    let default_token = prediction_hub.get_betting_token();
    assert(market_token == default_token, 'Should use default token');
}

#[test]
fn test_market_token_fallback() {
    let (prediction_hub, _admin_interface, usdc_token, _strk, _eth, _custom) =
        setup_multi_token_environment();
    let market_id = create_test_market(prediction_hub);

    // Before any bets, market token should return default token
    let market_token = prediction_hub.get_market_token(market_id);
    let default_token = prediction_hub.get_betting_token();
    assert(market_token == default_token, 'fallback to default token');
}

// ================ Integration Tests ================

#[test]
fn test_multi_token_fee_collection() {
    let (prediction_hub, admin_interface, usdc_token, strk_token, _eth, _custom) =
        setup_multi_token_environment();

    // Create two markets
    let market_id_1 = create_test_market(prediction_hub);

    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;
    prediction_hub
        .create_prediction(
            "Will STRK reach $10?",
            "A prediction about STRK price",
            ('Yes', 'No'),
            'crypto',
            "https://example.com/strk.jpg",
            future_time,
        );
    stop_cheat_caller_address(prediction_hub.contract_address);
    let market_id_2 = 2;

    // Bet on first market with USDC
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_bet_with_token(market_id_1, 0, 1000000000000000000000, 0, 'USDC');
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Bet on second market with STRK
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.place_bet_with_token(market_id_2, 1, 800000000000000000000, 0, 'STRK');
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check fee recipient received fees in both tokens
    let usdc_fee_expected = 1000000000000000000000 * 250 / 10000; // 2.5% of 1000
    let strk_fee_expected = 800000000000000000000 * 250 / 10000; // 2.5% of 800

    let fee_recipient_usdc_balance = usdc_token.balance_of(FEE_RECIPIENT_ADDR());
    let fee_recipient_strk_balance = strk_token.balance_of(FEE_RECIPIENT_ADDR());

    assert(fee_recipient_usdc_balance == usdc_fee_expected, 'USDC fees incorrect');
    assert(fee_recipient_strk_balance == strk_fee_expected, 'STRK fees incorrect');
}
