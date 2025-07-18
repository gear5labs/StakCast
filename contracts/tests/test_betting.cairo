use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::types::{BetActivity, UserStake};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, HALF_PRECISION, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR,
    USER3_ADDR, create_test_market, default_create_crypto_prediction, default_create_predictions,
    setup_test_environment, turn_number_to_precision_point,
};

// ================ General Prediction Market Tests ================
// ================ Buy share ========================
#[test]
fn test_buy_share_success() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');
    println!("Market created with ID: {}", market_id);
    // get share prices
    let mut market_shares = contract.calculate_share_prices(market_id);
    let (ppua, ppub) = market_shares;
    assert(ppua == HALF_PRECISION() && ppub == HALF_PRECISION(), 'Share prices should be 500000');
    println!("Share prices for market {}: {:?}", market_id, market_shares);

    // user 1 buys 10 shares of option 1
    let user1_amount = turn_number_to_precision_point(10);
    let user2_amount = turn_number_to_precision_point(20);
    let user3_amount = turn_number_to_precision_point(40);

    let user1_balance_before = _token.balance_of(USER1_ADDR());
    let contract_balance_before = _token.balance_of(contract.contract_address);
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, user1_amount);
    stop_cheat_caller_address(contract.contract_address);
    let user1_balance_after = _token.balance_of(USER1_ADDR());
    let contract_balance_after = _token.balance_of(contract.contract_address);
    assert(user1_balance_after == user1_balance_before - user1_amount, 'u1 debit');
    assert(contract_balance_after == contract_balance_before + user1_amount, 'u1 credit');

    // user 2 buys 20 shares of option 2
    let user2_balance_before = _token.balance_of(USER2_ADDR());
    let contract_balance_before2 = _token.balance_of(contract.contract_address);
    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    contract.buy_shares(market_id, 0, user2_amount);
    stop_cheat_caller_address(contract.contract_address);
    let user2_balance_after = _token.balance_of(USER2_ADDR());
    let contract_balance_after2 = _token.balance_of(contract.contract_address);
    assert(user2_balance_after == user2_balance_before - user2_amount, 'u2 debit');
    assert(contract_balance_after2 == contract_balance_before2 + user2_amount, 'u2 credit');

    // user 3 buys 40 shares of option 2
    let user3_balance_before = _token.balance_of(USER3_ADDR());
    let contract_balance_before3 = _token.balance_of(contract.contract_address);
    start_cheat_caller_address(contract.contract_address, USER3_ADDR());
    contract.buy_shares(market_id, 1, user3_amount);
    stop_cheat_caller_address(contract.contract_address);
    let user3_balance_after = _token.balance_of(USER3_ADDR());
    let contract_balance_after3 = _token.balance_of(contract.contract_address);
    assert(user3_balance_after == user3_balance_before - user3_amount, 'u3 debit');
    assert(contract_balance_after3 == contract_balance_before3 + user3_amount, 'u3 credit');

    let market_shares_after = contract.calculate_share_prices(market_id);
    let bet_details_user_1: UserStake = contract.get_user_stake_details(market_id, USER1_ADDR());
    let bet_details_user_2: UserStake = contract.get_user_stake_details(market_id, USER2_ADDR());
    let bet_details_user_3: UserStake = contract.get_user_stake_details(market_id, USER3_ADDR());

    println!(
        "user 1 Bet details after buying shares: shares A: {}, shares B: {}, total invested: {}",
        bet_details_user_1.shares_a,
        bet_details_user_1.shares_b,
        bet_details_user_1.total_invested,
    );
    println!(
        "user 2 Bet details after buying shares: shares A: {}, shares B: {}, total invested: {}",
        bet_details_user_2.shares_a,
        bet_details_user_2.shares_b,
        bet_details_user_2.total_invested,
    );
    println!(
        "user 3 Bet details after buying shares: shares A: {}, shares B: {}, total invested: {}",
        bet_details_user_3.shares_a,
        bet_details_user_3.shares_b,
        bet_details_user_3.total_invested,
    );

    let prediction_details_after_bet_placed = contract.get_prediction(market_id);
    println!(
        "Prediction details after bet placed: total share option 1 {} total share option 2: {}, total pool {}",
        prediction_details_after_bet_placed.total_shares_option_one,
        prediction_details_after_bet_placed.total_shares_option_two,
        prediction_details_after_bet_placed.total_pool,
    );

    println!("Share prices for market after is {}: {:?}", market_id, market_shares_after);
}

#[test]
#[should_panic(expected: ('Contract is paused',))]
fn test_buy_when_contract_is_pause_should_panic() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_pause();
    stop_cheat_caller_address(admin_interface.contract_address);

    // user 1 try to buys 10 shares of option 1 should panic
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Betting paused',))]
fn test_buy_when_market_is_pause_should_panic() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.pause_betting();
    stop_cheat_caller_address(admin_interface.contract_address);

    // user 1 try to buys 10 shares of option 1 should panic
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 1, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Resolution paused',))]
fn test_buy_when_resolution_is_pause_should_panic() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.pause_resolution();
    stop_cheat_caller_address(admin_interface.contract_address);

    // user 1 try to buys 10 shares of option 1 should panic
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 1, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Market is closed',))]
fn test_buy_when_market_is_not_open_should_panic() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);
    // start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    // admin_interface.emergency_close_market(market_id, 0);
    // stop_cheat_caller_address(admin_interface.contract_address);
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
    // user 1 try to buys 10 shares of option 1 should panic
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_get_market_activity() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // assert that the initial market activity is 0
    let mut market_activity: Array<BetActivity> = contract.get_market_activity(market_id);
    assert(market_activity.len() == 0, 'should not have anything');

    // place bet to trigger market activity
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    market_activity = contract.get_market_activity(market_id);

    assert(market_activity.len() == 1, 'should not have 1 activity');
    let bet = *market_activity.at(0);
    assert(bet.choice == 0, 'choice should be 0');
    assert(bet.amount == turn_number_to_precision_point(10), 'amount should be 10');
}

#[test]
fn test_get_market_activity_multiple_bets() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // place bet to trigger market activity
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    contract.buy_shares(market_id, 1, turn_number_to_precision_point(25));
    stop_cheat_caller_address(contract.contract_address);

    let market_activity = contract.get_market_activity(market_id);
    assert(market_activity.len() == 2, 'should have 2 activities');

    let bet1 = *market_activity.at(0);
    let bet2 = *market_activity.at(1);

    assert(bet1.choice == 0, 'choice should be 0');
    assert(bet1.amount == turn_number_to_precision_point(10), 'amount should be 10');
    assert(bet2.choice == 1, 'choice should be 1');
    assert(bet2.amount == turn_number_to_precision_point(25), 'amount should be 25');
}
