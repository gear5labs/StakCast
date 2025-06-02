use starknet::{ContractAddress, get_block_timestamp};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyTrait
};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// ================ Test Constants ================

const ADMIN_CONST: felt252 = 123;
const MODERATOR_CONST: felt252 = 456;
const USER1_CONST: felt252 = 101112;
const USER2_CONST: felt252 = 131415;
const FEE_RECIPIENT_CONST: felt252 = 161718;
const PRAGMA_ORACLE_CONST: felt252 = 192021;

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

fn FEE_RECIPIENT_ADDR() -> ContractAddress {
    FEE_RECIPIENT_CONST.try_into().unwrap()
}

fn PRAGMA_ORACLE_ADDR() -> ContractAddress {
    PRAGMA_ORACLE_CONST.try_into().unwrap()
}

// ================ Test Setup ================

fn deploy_test_token() -> IERC20Dispatcher {
    let contract = declare("MockERC20").unwrap().contract_class();
    let constructor_calldata = array![USER1_ADDR().into()];
    
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IERC20Dispatcher { contract_address }
}

fn deploy_prediction_contract(token_address: ContractAddress) -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher) {
    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into()
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    
    let prediction_hub = IPredictionHubDispatcher { contract_address };
    let admin_interface = IAdditionalAdminDispatcher { contract_address };
    
    (prediction_hub, admin_interface)
}

fn setup_test_environment() -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher, IERC20Dispatcher) {
    let token = deploy_test_token();
    let (prediction_hub, admin_interface) = deploy_prediction_contract(token.contract_address);
    
    // Add moderator
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    prediction_hub.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // Setup token balances and allowances
    start_cheat_caller_address(token.contract_address, USER1_ADDR());
    token.transfer(USER2_ADDR(), 500000000000000000000000); // 500k tokens to USER2
    
    token.approve(prediction_hub.contract_address, 1000000000000000000000000); // 1M approval
    stop_cheat_caller_address(token.contract_address);
    
    start_cheat_caller_address(token.contract_address, USER2_ADDR());
    token.approve(prediction_hub.contract_address, 500000000000000000000000); // 500k approval
    stop_cheat_caller_address(token.contract_address);
    
    (prediction_hub, admin_interface, token)
}

fn create_test_market(prediction_hub: IPredictionHubDispatcher) -> u256 {
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    
    let future_time = get_block_timestamp() + 86400; // 1 day from now
    prediction_hub.create_prediction(
        "Will BTC reach $100k?",
        "A prediction about Bitcoin price",
        ('Yes', 'No'),
        'crypto',
        "https://example.com/btc.jpg",
        future_time
    );
    
    stop_cheat_caller_address(prediction_hub.contract_address);
    1
}

// ================ Basic Wager Placement Tests ================

#[test]
fn test_place_wager_success() {
    let (prediction_hub, _admin_interface, token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    let mut spy = spy_events();
    
    // Place wager
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let result = prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    assert(result, 'Wager placement failed');
    
    // Check events were emitted
    let events = spy.get_events();
    assert(events.events.len() >= 3, 'Expected multiple events'); // FeesCollected, WagerPlaced, BetPlaced
    
    // Verify user bet was recorded
    let bet_count = prediction_hub.get_bet_count_for_market(USER1_ADDR(), market_id, 0);
    assert(bet_count == 1, 'Bet count incorrect');
    
    // Verify token balances changed
    let user_balance = token.balance_of(USER1_ADDR());

    let expected_balance = 9500000000000000000000000 - 1000000000000000000000; // 9.5M - 1k
    assert(user_balance == expected_balance, 'User balance incorrect');
}

#[test]
fn test_place_wager_with_custom_fees() {
    let (prediction_hub, admin_interface, token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    // Set platform fee to 5% (500 basis points)
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    admin_interface.set_platform_fee(500);
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // Place wager
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let result = prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    assert(result, 'Wager placement failed');
    
    // Check fee calculation
    let market_fees = prediction_hub.get_market_fees(market_id);
    let expected_fee = 1000000000000000000000 * 500 / 10000; // 50 tokens (5%)
    assert(market_fees == expected_fee, 'Market fees incorrect');
    
    // Check fee recipient balance
    let fee_recipient_balance = token.balance_of(FEE_RECIPIENT_ADDR());
    assert(fee_recipient_balance == expected_fee, 'Fee recipient balance incorrect');
}

#[test]
fn test_multiple_wagers_same_user() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    // Place first wager
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens on choice 0
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // Place second wager by same user
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_wager(market_id, 1, 500000000000000000000, 0); // 500 tokens on choice 1
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // Verify bet counts
    let bet_count = prediction_hub.get_bet_count_for_market(USER1_ADDR(), market_id, 0);
    assert(bet_count == 2, 'Bet count incorrect');
    
    // Verify both bets are recorded
    let bet1 = prediction_hub.get_choice_and_bet(USER1_ADDR(), market_id, 0, 0);
    let bet2 = prediction_hub.get_choice_and_bet(USER1_ADDR(), market_id, 0, 1);
    
    // Verify bet amounts (accounting for 2.5% default fee)
    let expected_net1 = 1000000000000000000000 - (1000000000000000000000 * 250 / 10000);
    let expected_net2 = 500000000000000000000 - (500000000000000000000 * 250 / 10000);
    
    assert(bet1.stake.amount == expected_net1, 'First bet amount incorrect');
    assert(bet2.stake.amount == expected_net2, 'Second bet amount incorrect');
}

#[test]
fn test_multiple_users_wagers() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    // USER1 places wager
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // USER2 places wager
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.place_wager(market_id, 1, 800000000000000000000, 0); // 800 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // Verify market liquidity
    let market_liquidity = prediction_hub.get_market_liquidity(market_id);
    
    // Calculate expected liquidity (net of fees)
    let net1 = 1000000000000000000000 - (1000000000000000000000 * 250 / 10000);
    let net2 = 800000000000000000000 - (800000000000000000000 * 250 / 10000);
    let expected_liquidity = net1 + net2;
    
    assert(market_liquidity == expected_liquidity, 'Market liquidity incorrect');
    
    // Verify total value locked
    let tvl = prediction_hub.get_total_value_locked();
    assert(tvl == expected_liquidity, 'TVL incorrect');
}

// ================ Error Condition Tests ================

#[test]
#[should_panic(expected: ('Insufficient token balance',))]
fn test_insufficient_balance() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    // USER2 has 500k tokens, trying to bet 600k
    prediction_hub.place_wager(market_id, 0, 600000000000000000000000, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);
}

#[test]
#[should_panic(expected: ('Insufficient token allowance',))]
fn test_insufficient_allowance() {
    let (prediction_hub, _admin_interface, token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    // Reduce allowance for USER2
    start_cheat_caller_address(token.contract_address, USER2_ADDR());
    token.approve(prediction_hub.contract_address, 100000000000000000000); // Only 100 tokens
    stop_cheat_caller_address(token.contract_address);
    
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    // Trying to bet 1000 tokens but only 100 approved
    prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);
}

#[test]
#[should_panic(expected: ('Amount below minimum',))]
fn test_bet_below_minimum() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    // Trying to bet below minimum (1 token)
    prediction_hub.place_wager(market_id, 0, 500000000000000000, 0); // 0.5 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
}

// ================ Pool Management Tests ================

#[test]
fn test_pool_updates_correctly() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    // Place wagers on both choices
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens on choice 0
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.place_wager(market_id, 1, 800000000000000000000, 0); // 800 tokens on choice 1
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // Check market state
    let market = prediction_hub.get_prediction(market_id);
    
    // Calculate expected net amounts (after 2.5% fee)
    let net1 = 1000000000000000000000 - (1000000000000000000000 * 250 / 10000);
    let net2 = 800000000000000000000 - (800000000000000000000 * 250 / 10000);
    
    let (choice_0, choice_1) = market.choices;
    assert(choice_0.staked_amount == net1, 'Choice 0 stake incorrect');
    assert(choice_1.staked_amount == net2, 'Choice 1 stake incorrect');
    assert(market.total_pool == net1 + net2, 'Total pool incorrect');
}

// ================ Administrative Functions Tests ================

#[test]
fn test_set_betting_restrictions() {
    let (prediction_hub, admin_interface, _token) = setup_test_environment();
    
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    admin_interface.set_betting_restrictions(5000000000000000000, 50000000000000000000); // 5-50 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    let (min_bet, max_bet) = prediction_hub.get_betting_restrictions();
    assert(min_bet == 5000000000000000000, 'Min bet incorrect');
    assert(max_bet == 50000000000000000000, 'Max bet incorrect');
}

#[test]
fn test_fee_tracking() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    // Place multiple wagers
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.place_wager(market_id, 1, 800000000000000000000, 0); // 800 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    // Check fee tracking
    let market_fees = prediction_hub.get_market_fees(market_id);
    let total_fees = prediction_hub.get_total_fees_collected();
    
    let expected_fees = (1000000000000000000000 * 250 / 10000) + (800000000000000000000 * 250 / 10000);
    assert(market_fees == expected_fees, 'Market fees incorrect');
    assert(total_fees == expected_fees, 'Total fees incorrect');
}

// ================ Backward Compatibility Tests ================

#[test]
fn test_place_bet_backward_compatibility() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);
    
    // Test that place_bet still works (calls place_wager internally)
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let result = prediction_hub.place_bet(market_id, 0, 1000000000000000000000, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);
    
    assert(result, 'place_bet failed');
    
    let bet_count = prediction_hub.get_bet_count_for_market(USER1_ADDR(), market_id, 0);
    assert(bet_count == 1, 'Bet not recorded');
} 