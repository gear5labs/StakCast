use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::get_block_timestamp;
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR, create_test_market,
    setup_test_environment,
};

#[test]
fn test_place_wager_success() {
    let (prediction_hub, _admin_interface, token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);

    let mut spy = spy_events();

    // Place wager
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let user_balance_before = token.balance_of(USER1_ADDR());

    let result = prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);

    assert(result, 'Wager placement failed');

    // Check events were emitted
    let events = spy.get_events();
    assert(
        events.events.len() >= 3, 'Expected multiple events',
    ); // FeesCollected, WagerPlaced, BetPlaced

    // Verify user bet was recorded
    let bet_count = prediction_hub.get_bet_count_for_market(USER1_ADDR(), market_id, 0);
    assert(bet_count == 1, 'Bet count incorrect');

    // Verify token balances changed
    let user_balance = token.balance_of(USER1_ADDR());
    let expected_balance = user_balance_before - 1000000000000000000000; // 9.5M - 1k
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
fn test_multiple_bets_same_user() {
    let (prediction_hub, _admin_interface, token) = setup_test_environment();
    let market_id = create_test_market(prediction_hub);

    let mut spy = spy_events();

    // Place wager
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let user_balance_before = token.balance_of(USER1_ADDR());
    let result = prediction_hub.place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    assert(result, 'Wager placement failed');

    // Check events were emitted
    let events = spy.get_events();
    assert(
        events.events.len() >= 3, 'Expected multiple events',
    ); // FeesCollected, WagerPlaced, BetPlaced

    let _expected_balance = 9500000000000000000000000 - 1000000000000000000000; // 9.5M - 1k
    // Verify user bet was recorded
    let bet_count = prediction_hub.get_bet_count_for_market(USER1_ADDR(), market_id, 0);
    assert(bet_count == 1, 'Bet count incorrect');

    // Verify token balances changed
    let user_balance = token.balance_of(USER1_ADDR());
    let expected_balance = user_balance_before - 1000000000000000000000; // 9.5M - 1k
    assert(user_balance == expected_balance, 'User balance incorrect');

    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    let result2 = prediction_hub
        .place_wager(market_id, 0, 1000000000000000000000, 0); // 1000 tokens
    stop_cheat_caller_address(prediction_hub.contract_address);
    assert(result2, 'Wager placement failed');
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
    admin_interface
        .set_betting_restrictions(5000000000000000000, 50000000000000000000); // 5-50 tokens
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

    let expected_fees = (1000000000000000000000 * 250 / 10000)
        + (800000000000000000000 * 250 / 10000);
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

#[test]
fn test_get_active_prediction_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = prediction_hub.get_active_prediction_markets();
    assert(market.len() == 0, 'Market count should be 0');

    create_test_market(prediction_hub);
    create_test_market(prediction_hub);
    create_test_market(prediction_hub);

    // Fetch market_id from MarketCreated event
    let market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };
    // Verify market count
    let count = prediction_hub.get_prediction_count();
    assert(count == 3, 'Should have 3 markets');

    start_cheat_block_timestamp(
        prediction_hub.contract_address, get_block_timestamp() + 86400 + 3600,
    );

    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    // Resolve market
    prediction_hub.resolve_prediction(market_id, 0); // BTC reaches $100k (choice 0 wins)

    stop_cheat_caller_address(prediction_hub.contract_address);

    let market = prediction_hub.get_active_prediction_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
