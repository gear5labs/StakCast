use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::types::{
    BetActivity, MarketStatus, PredictionMarket, StakingActivity, UserDashboard, UserStake,
};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, HALF_PRECISION, MODERATOR_ADDR, MODERATOR_ADDR_2, USER1_ADDR,
    USER2_ADDR, USER3_ADDR, create_test_market, default_create_crypto_prediction,
    default_create_predictions, setup_test_environment, turn_number_to_precision_point,
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
    let (price_per_unit_a, price_per_unit_b) = market_shares;
    assert(
        price_per_unit_a == HALF_PRECISION() && price_per_unit_b == HALF_PRECISION(),
        'Share prices should be 500000',
    );
    println!("Share prices for market {}: {:?}", market_id, market_shares);

    // user 1 buys 10 shares of option 1
    let user1_amount = turn_number_to_precision_point(10);
    let user2_amount = turn_number_to_precision_point(20);
    let user3_amount = turn_number_to_precision_point(5);
    let user3_amount_second = turn_number_to_precision_point(5);

    let user1_balance_before = _token.balance_of(USER1_ADDR());
    let contract_balance_before = _token.balance_of(contract.contract_address);
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, user1_amount);
    stop_cheat_caller_address(contract.contract_address);
    let user1_balance_after = _token.balance_of(USER1_ADDR());
    let contract_balance_after = _token.balance_of(contract.contract_address);
    assert(user1_balance_after == user1_balance_before - user1_amount, 'u1 debit');
    assert(contract_balance_after == contract_balance_before + user1_amount, 'u1 credit');

    // assert userstake details were updates as expected
    let bet_details_user_1: UserStake = contract.get_user_stake_details(market_id, USER1_ADDR());
    assert(bet_details_user_1.total_amount_a == user1_amount, 'u1 total amount should be 10');
    assert(bet_details_user_1.shares_a > 0, 'u1 shares a should be 10');
    assert(bet_details_user_1.total_amount_b == 0, 'u1 total amount b should be 0');
    assert(bet_details_user_1.total_invested == user1_amount, 'u1 total invested should be 10');

    // assert user dashboard details were updates as expected
    let user_dashboard_user_1: UserDashboard = contract.get_user_dashboard(USER1_ADDR());
    assert(user_dashboard_user_1.total_markets_participated == 1, 'total markets should be 1');
    assert(user_dashboard_user_1.total_wins == 0, 'u1 total wins should be 0');
    assert(user_dashboard_user_1.total_losses == 0, 'u1 total losses should be 0');
    assert(user_dashboard_user_1.total_trades == 1, 'u1 total trades should be 1');

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

    // assert userstake details were updates as expected
    let bet_details_user_2: UserStake = contract.get_user_stake_details(market_id, USER2_ADDR());
    assert(bet_details_user_2.total_amount_a == user2_amount, 'u2 total amount a should be 20');
    assert(bet_details_user_2.shares_b == 0, 'u2 shares b should be 20');
    assert(bet_details_user_2.total_amount_b == 0, 'u2 total amount b should be 20');
    assert(bet_details_user_2.total_invested == user2_amount, 'u2 total invested should be 20');

    // assert user dashboard details were updates as expected
    let user_dashboard_user_2: UserDashboard = contract.get_user_dashboard(USER2_ADDR());
    assert(user_dashboard_user_2.total_markets_participated == 1, 'total markets should be 1');
    assert(user_dashboard_user_2.total_wins == 0, 'u2 total wins should be 0');
    assert(user_dashboard_user_2.total_losses == 0, 'u2 total losses should be 0');
    assert(user_dashboard_user_2.total_trades == 1, 'u2 total trades should be 1');

    // user 3 buys 40 shares of option 2
    let user3_balance_before = _token.balance_of(USER3_ADDR());
    println!("user 3 balance before: {}", user3_balance_before);
    let contract_balance_before3 = _token.balance_of(contract.contract_address);
    start_cheat_caller_address(contract.contract_address, USER3_ADDR());
    contract.buy_shares(market_id, 1, user3_amount);

    // assert user dashboard details were updates as expected
    let user_dashboard_user_3: UserDashboard = contract.get_user_dashboard(USER3_ADDR());
    assert(user_dashboard_user_3.total_markets_participated == 1, 'total markets should be 1');
    assert(user_dashboard_user_3.total_wins == 0, 'u3 total wins should be 0');
    assert(user_dashboard_user_3.total_losses == 0, 'u3 total losses should be 0');
    assert(user_dashboard_user_3.total_trades == 1, 'u3 total trades should be 1');

    contract.buy_shares(market_id, 1, user3_amount_second);

    // assert user dashboard details were updates as expected
    let user_dashboard_user_3_after: UserDashboard = contract.get_user_dashboard(USER3_ADDR());
    assert(
        user_dashboard_user_3_after.total_markets_participated == 1, 'total markets should be 1',
    );
    assert(user_dashboard_user_3_after.total_wins == 0, 'u3 total wins should be 0');
    assert(user_dashboard_user_3_after.total_losses == 0, 'u3 total losses should be 0');
    assert(user_dashboard_user_3_after.total_trades == 2, 'u3 total trades should be 2');

    stop_cheat_caller_address(contract.contract_address);

    let user3_balance_after = _token.balance_of(USER3_ADDR());
    let contract_balance_after3 = _token.balance_of(contract.contract_address);
    assert(
        user3_balance_after == user3_balance_before - user3_amount - user3_amount_second,
        'u3 debit',
    );
    assert(
        contract_balance_after3 == contract_balance_before3 + user3_amount + user3_amount_second,
        'u3 credit',
    );

    // assert userstake details were updates as expected
    let bet_details_user_3: UserStake = contract.get_user_stake_details(market_id, USER3_ADDR());
    assert(bet_details_user_3.total_amount_a == 0, 'u3 total amount a should be 0');
    assert(bet_details_user_3.shares_b > 0, 'u3 shares b should be 40');
    assert(
        bet_details_user_3.total_amount_b == user3_amount + user3_amount_second,
        'u3 total amount b should be 40',
    );
    assert(
        bet_details_user_3.total_invested == user3_amount + user3_amount_second,
        'u3 total invested should be 40',
    );

    let market_shares_after = contract.calculate_share_prices(market_id);
    let bet_details_user_1: UserStake = contract.get_user_stake_details(market_id, USER1_ADDR());
    let bet_details_user_2: UserStake = contract.get_user_stake_details(market_id, USER2_ADDR());
    let bet_details_user_3: UserStake = contract.get_user_stake_details(market_id, USER3_ADDR());

    // test all user in market
    let all_users_in_market: Array<ContractAddress> = contract.get_all_users_in_market(market_id);
    assert(all_users_in_market.len() == 3, 'all users in market should be 3');
    let user_1: ContractAddress = *all_users_in_market.at(0);
    let user_2: ContractAddress = *all_users_in_market.at(1);
    let user_3: ContractAddress = *all_users_in_market.at(2);
    assert(user_1 == USER1_ADDR(), 'user 1 should be in market');
    assert(user_2 == USER2_ADDR(), 'user 2 should be in market');
    assert(user_3 == USER3_ADDR(), 'user 3 should be in market');

    // test staking activity
    let staking_activity: Array<StakingActivity> = contract.get_staking_activity(USER3_ADDR());
    assert(staking_activity.len() == 2, 'staking activity should be 2');
    let staking_activity_1: StakingActivity = *staking_activity.at(0);
    assert(staking_activity_1.market_id == market_id, 'should be 1');
    assert(staking_activity_1.amount == user3_amount, 'should be 5');
    let staking_activity_2: StakingActivity = *staking_activity.at(1);
    assert(staking_activity_2.market_id == market_id, 'should be 1');
    assert(staking_activity_2.amount == user3_amount_second, 'should be 5');

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
    let user: Array<PredictionMarket> = contract.get_all_bets_for_user(USER2_ADDR());
    assert!(user.len() == 1, "user stake  len should be 1");
    let user_bet: @PredictionMarket = user.at(0);
    assert!(user_bet.market_id == @market_id, "incorrect market id");
    println!("user bet id: {}", user_bet.market_id);

    // test get choice stakers
    let choice_stakers: Array<ContractAddress> = contract.get_choice_stakers(market_id, 0);
    println!("choice stakers: {:?}", choice_stakers);
    assert(choice_stakers.len() == 2, 'choice stakers should be 1');
    let choice_staker: ContractAddress = *choice_stakers.at(0);
    assert(choice_staker == USER1_ADDR(), 'choice staker should be user 1');
}

#[test]
fn test_get_all_bets_for_user() {
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
    let (ppua, price_per_unit_b) = market_shares;
    assert(
        ppua == HALF_PRECISION() && price_per_unit_b == HALF_PRECISION(),
        'Share prices should be 500000',
    );
    println!("Share prices for market {}: {:?}", market_id, market_shares);

    // user 1 buys 10 shares of option 1
    let user1_amount = turn_number_to_precision_point(10);

    let user1_balance_before = _token.balance_of(USER1_ADDR());
    let contract_balance_before = _token.balance_of(contract.contract_address);
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, user1_amount);
    stop_cheat_caller_address(contract.contract_address);
    let user1_balance_after = _token.balance_of(USER1_ADDR());
    let contract_balance_after = _token.balance_of(contract.contract_address);
    assert(user1_balance_after == user1_balance_before - user1_amount, 'u1 debit');
    assert(contract_balance_after == contract_balance_before + user1_amount, 'u1 credit');

    // get all bets for user 1 let user: Array<PredictionMarket> =
    // contract.get_all_bets_for_user(USER2_ADDR());
    let user_1: Array<PredictionMarket> = contract.get_all_bets_for_user(USER1_ADDR());
    assert!(user_1.len() == 1, "user stake len should be 1");

    // user 1 bets again on same pool
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 1, turn_number_to_precision_point(5));
    stop_cheat_caller_address(contract.contract_address);

    let user_1_after: Array<PredictionMarket> = contract.get_all_bets_for_user(USER1_ADDR());
    assert!(user_1_after.len() == 1, "user stake len should be 2");
    let user_1_after_bet: @PredictionMarket = user_1_after.at(0);
    assert!(user_1_after_bet.market_id == @market_id, "incorrect market id");
    println!("user bet id: {}", user_1_after_bet.market_id);

    // creating another market and the user betting on it
    let market_id_2 = create_test_market(contract);
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id_2, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    let user_1_after_2: Array<PredictionMarket> = contract.get_all_bets_for_user(USER1_ADDR());
    assert!(user_1_after_2.len() == 2, "user stake len should be 2");
    let user_1_after_2_bet: @PredictionMarket = user_1_after_2.at(1);
    assert!(user_1_after_2_bet.market_id == @market_id_2, "incorrect market id");
    println!("totoal pool now is: {}", contract.get_prediction(market_id_2).total_pool);
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

#[test]
fn test_get_user_market_ids() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // Create multiple markets
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    let market_id_2 = create_test_market(contract);
    let market_id_3 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    println!("Created markets: {}, {}, {}", market_id_1, market_id_2, market_id_3);

    let user1 = USER1_ADDR();
    let user2 = USER2_ADDR();

    // User 1 bets on markets 1 and 2
    start_cheat_caller_address(contract.contract_address, user1);
    contract.buy_shares(market_id_1, 0, turn_number_to_precision_point(10));
    contract.buy_shares(market_id_2, 1, turn_number_to_precision_point(15));
    stop_cheat_caller_address(contract.contract_address);

    // User 2 bets on markets 2 and 3
    start_cheat_caller_address(contract.contract_address, user2);
    contract.buy_shares(market_id_2, 0, turn_number_to_precision_point(20));
    contract.buy_shares(market_id_3, 1, turn_number_to_precision_point(25));
    stop_cheat_caller_address(contract.contract_address);

    // Test get_user_market_ids
    let user1_market_ids = contract.get_user_market_ids(user1);
    let user2_market_ids = contract.get_user_market_ids(user2);

    println!("\nUser 1 market IDs (should be 2): {}", user1_market_ids.len());
    println!("User 2 market IDs (should be 2): {}", user2_market_ids.len());

    // Verify the results
    assert(user1_market_ids.len() == 2, 'User 1 should have 2 market IDs');
    assert(user2_market_ids.len() == 2, 'User 2 should have 2 market IDs');

    // Test that the market IDs are correct
    let user1_all_bets = contract.get_all_bets_for_user(user1);
    let user2_all_bets = contract.get_all_bets_for_user(user2);

    println!("User 1 all bets count: {}", user1_all_bets.len());
    println!("User 2 all bets count: {}", user2_all_bets.len());

    assert(user1_all_bets.len() == 2, 'User 1 should have 2 bets');
    assert(user2_all_bets.len() == 2, 'User 2 should have 2 bets');

    println!("get_user_market_ids function works correctly!");
    println!("It returns the same count as get_all_bets_for_user!");
}
// #[test]
// fn test_user_bet_functions_with_arrays() {
//     let (contract, _admin_interface, _token) = setup_test_environment();

//     // Create a prediction market
//     start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
//     let market_id = create_test_market(contract);
//     stop_cheat_caller_address(contract.contract_address);

//     println!("Testing User Bet Functions");
//     println!("==============================");
//     println!("Created market with ID: {}", market_id);

//     // Test user addresses
//     let user1 = USER1_ADDR();
//     let user2 = USER2_ADDR();
//     let user3 = USER3_ADDR();

//     println!("\nBefore any bets are placed:");
//     println!("User 1 closed bets: {}", contract.get_all_closed_bets_for_user(user1).len());
//     println!("User 1 open bets: {}", contract.get_all_open_bets_for_user(user1).len());
//     println!("User 1 locked bets: {}", contract.get_all_locked_bets_for_user(user1).len());
//     println!("User 1 all bets: {}", contract.get_all_bets_for_user(user1).len());
//     println!("User 1 market IDs: {}", contract.get_user_market_ids(user1).len());

//     // User 1 places a bet
//     let user1_amount = turn_number_to_precision_point(10);
//     start_cheat_caller_address(contract.contract_address, user1);
//     contract.buy_shares(market_id, 0, user1_amount);
//     stop_cheat_caller_address(contract.contract_address);

//     println!("\nAfter User 1 places a bet:");
//     println!("User 1 closed bets: {}", contract.get_all_closed_bets_for_user(user1).len());
//     println!("User 1 open bets: {}", contract.get_all_open_bets_for_user(user1).len());
//     println!("User 1 locked bets: {}", contract.get_all_locked_bets_for_user(user1).len());
//     println!("User 1 all bets: {}", contract.get_all_bets_for_user(user1).len());
//     println!("User 1 market IDs: {}", contract.get_user_market_ids(user1).len());

//     // User 2 places a bet
//     let user2_amount = turn_number_to_precision_point(20);
//     start_cheat_caller_address(contract.contract_address, user2);
//     contract.buy_shares(market_id, 1, user2_amount);
//     stop_cheat_caller_address(contract.contract_address);

//     println!("\nAfter User 2 places a bet:");
//     println!("User 2 closed bets: {}", contract.get_all_closed_bets_for_user(user2).len());
//     println!("User 2 open bets: {}", contract.get_all_open_bets_for_user(user2).len());
//     println!("User 2 locked bets: {}", contract.get_all_locked_bets_for_user(user2).len());
//     println!("User 2 all bets: {}", contract.get_all_bets_for_user(user2).len());
//     println!("User 2 market IDs: {}", contract.get_user_market_ids(user2).len());

//     // User 3 places a bet
//     let user3_amount = turn_number_to_precision_point(15);
//     start_cheat_caller_address(contract.contract_address, user3);
//     contract.buy_shares(market_id, 0, user3_amount);
//     stop_cheat_caller_address(contract.contract_address);

//     println!("\nAfter User 3 places a bet:");
//     println!("User 3 closed bets: {}", contract.get_all_closed_bets_for_user(user3).len());
//     println!("User 3 open bets: {}", contract.get_all_open_bets_for_user(user3).len());
//     println!("User 3 locked bets: {}", contract.get_all_locked_bets_for_user(user3).len());
//     println!("User 3 all bets: {}", contract.get_all_bets_for_user(user3).len());
//     println!("User 3 market IDs: {}", contract.get_user_market_ids(user3).len());

//     // Test market status functions
//     println!("\nMarket Status Functions:");
//     println!("All markets: {}", contract.get_all_predictions().len());
//     println!("Open markets: {}", contract.get_all_open_markets().len());
//     println!("Resolved markets: {}", contract.get_all_resolved_markets().len());

//     // Verify the functions work correctly
//     assert(contract.get_all_open_bets_for_user(user1).len() == 1, 'User 1 should have 1 open
//     bet');
//     assert(contract.get_all_open_bets_for_user(user2).len() == 1, 'User 2 should have 1 open
//     bet');
//     assert(contract.get_all_open_bets_for_user(user3).len() == 1, 'User 3 should have 1 open
//     bet');
//     assert(contract.get_all_bets_for_user(user1).len() == 1, 'User 1 should have 1 total bet');
//     assert(contract.get_user_market_ids(user1).len() == 1, 'User 1 should have 1 market ID');

//     println!("\nAll user bet functions are working correctly!");
//     println!("Arrays are being returned and populated properly!");
// }

// Helper function to create a market with a specific category
fn create_test_market_with_category(contract: IPredictionHubDispatcher, category: u8) -> u256 {
    let title = "Test Market";
    let description = "Test Description";
    let image_url = "https://example.com/image.jpg";
    let choices = ('Yes', 'No');
    let end_time = get_block_timestamp() + 86400; // 24 hours from now
    let prediction_market_type = 0; // Regular market
    let crypto_prediction = Option::None;

    let mut spy = spy_events();

    contract
        .create_predictions(
            title,
            description,
            image_url,
            choices,
            category,
            end_time,
            prediction_market_type,
            crypto_prediction,
        );

    let events = spy.get_events();
    let mut market_id: u256 = 0;
    if let Some((_, event)) = events.events.into_iter().last() {
        let market_id_felt = *event.data.at(0);
        market_id = market_id_felt.into();
    }
    market_id
}

#[test]
fn test_get_user_markets_by_status_multiple_users_same_status() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // Create multiple markets
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    let market1_id = create_test_market_with_category(contract, 0);
    let market2_id = create_test_market_with_category(contract, 1);
    let market3_id = create_test_market_with_category(contract, 2);

    stop_cheat_caller_address(contract.contract_address);

    // User1 bets on market1 and market2
    let user1 = USER1_ADDR();
    start_cheat_caller_address(contract.contract_address, user1);
    contract.buy_shares(market1_id, 0, turn_number_to_precision_point(10));
    contract.buy_shares(market2_id, 1, turn_number_to_precision_point(15));
    stop_cheat_caller_address(contract.contract_address);

    // User2 bets on market2 and market3
    let user2 = USER2_ADDR();
    start_cheat_caller_address(contract.contract_address, user2);
    contract.buy_shares(market2_id, 0, turn_number_to_precision_point(20));
    contract.buy_shares(market3_id, 1, turn_number_to_precision_point(25));
    stop_cheat_caller_address(contract.contract_address);

    // User3 bets on all three markets
    let user3 = USER3_ADDR();
    start_cheat_caller_address(contract.contract_address, user3);
    contract.buy_shares(market1_id, 1, turn_number_to_precision_point(30));
    contract.buy_shares(market2_id, 0, turn_number_to_precision_point(35));
    contract.buy_shares(market3_id, 0, turn_number_to_precision_point(40));
    stop_cheat_caller_address(contract.contract_address);

    // All markets should be active initially - test same status for different users
    let user1_active = contract.get_user_markets_by_status(user1, 0); // Active
    let user2_active = contract.get_user_markets_by_status(user2, 0); // Active
    let user3_active = contract.get_user_markets_by_status(user3, 0); // Active

    // Verify each user has the correct number of active markets
    assert(user1_active.len() == 2, 'User1 should have 2 active');
    assert(user2_active.len() == 2, 'User2 should have 2 active');
    assert(user3_active.len() == 3, 'User3 should have 3 active');

    // Test that users don't get markets they didn't participate in
    // User1 didn't bet on market3
    let user1_has_market3 = user1_active.len() > 0
        && (user1_active.at(0).market_id == @market3_id
            || (user1_active.len() > 1 && user1_active.at(1).market_id == @market3_id));
    assert(!user1_has_market3, 'User1 should not have market3');

    // Verify all users get empty arrays for non-existent statuses
    let user1_resolved = contract.get_user_markets_by_status(user1, 2); // Resolved
    let user2_resolved = contract.get_user_markets_by_status(user2, 2); // Resolved
    let user3_resolved = contract.get_user_markets_by_status(user3, 2); // Resolved

    assert(user1_resolved.len() == 0, 'No resolved markets yet');
    assert(user2_resolved.len() == 0, 'No resolved markets yet');
    assert(user3_resolved.len() == 0, 'No resolved markets yet');
}

#[test]
fn test_get_user_markets_by_status_mixed_statuses_single_user() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // Create 5 different markets
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    let market1_id = create_test_market_with_category(contract, 0);
    let market2_id = create_test_market_with_category(contract, 1);
    let market3_id = create_test_market_with_category(contract, 2);
    let market4_id = create_test_market_with_category(contract, 3);
    let market5_id = create_test_market_with_category(contract, 4);

    stop_cheat_caller_address(contract.contract_address);

    // Single user bets on all markets
    let user = USER1_ADDR();
    start_cheat_caller_address(contract.contract_address, user);

    contract.buy_shares(market1_id, 0, turn_number_to_precision_point(10));
    contract.buy_shares(market2_id, 1, turn_number_to_precision_point(15));
    contract.buy_shares(market3_id, 0, turn_number_to_precision_point(20));
    contract.buy_shares(market4_id, 1, turn_number_to_precision_point(25));
    contract.buy_shares(market5_id, 0, turn_number_to_precision_point(30));

    stop_cheat_caller_address(contract.contract_address);

    // Initially all should be active
    let active_markets = contract.get_user_markets_by_status(user, 0);
    let locked_markets = contract.get_user_markets_by_status(user, 1);
    let resolved_markets = contract.get_user_markets_by_status(user, 2);
    let closed_markets = contract.get_user_markets_by_status(user, 3);

    // Verify initial state - all markets should be active
    assert(active_markets.len() == 5, 'Should have 5 active markets');
    assert(locked_markets.len() == 0, 'Should have 0 locked markets');
    assert(resolved_markets.len() == 0, 'Should have 0 resolved markets');
    assert(closed_markets.len() == 0, 'Should have 0 closed markets');

    // Verify that all market IDs are present in active markets
    let mut found_markets = 0;
    let mut i = 0;
    while i < active_markets.len() {
        let market = active_markets.at(i);
        if market.market_id == @market1_id
            || market.market_id == @market2_id
            || market.market_id == @market3_id
            || market.market_id == @market4_id
            || market.market_id == @market5_id {
            found_markets += 1;
        }
        i += 1;
    }
    assert(found_markets == 5, 'All 5 markets should be found');

    // Test consistency - same user should get same results on repeated calls
    let active_markets_2 = contract.get_user_markets_by_status(user, 0);
    assert(active_markets.len() == active_markets_2.len(), 'Results should be consistent');
}

#[test]
fn test_get_user_markets_by_status_boundary_and_edge_cases() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // Test with user who has no markets at all
    let empty_user = USER3_ADDR();

    // Test all valid status values for empty user
    let empty_active = contract.get_user_markets_by_status(empty_user, 0);
    let empty_locked = contract.get_user_markets_by_status(empty_user, 1);
    let empty_resolved = contract.get_user_markets_by_status(empty_user, 2);
    let empty_closed = contract.get_user_markets_by_status(empty_user, 3);

    assert(empty_active.len() == 0, 'Empty user active should be 0');
    assert(empty_locked.len() == 0, 'Empty user locked should be 0');
    assert(empty_resolved.len() == 0, 'Empty user resolved should be 0');
    assert(empty_closed.len() == 0, 'Empty user closed should be 0');

    // Create a single market and test boundary behavior
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let single_market_id = create_test_market_with_category(contract, 0);
    stop_cheat_caller_address(contract.contract_address);

    // User bets on single market
    let user = USER1_ADDR();
    start_cheat_caller_address(contract.contract_address, user);
    contract.buy_shares(single_market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    // Test boundary values for status parameter (valid range: 0-3)
    let status_0_result = contract.get_user_markets_by_status(user, 0);
    let status_3_result = contract.get_user_markets_by_status(user, 3);

    assert(status_0_result.len() == 1, 'Status 0 returns 1 market');
    assert(status_3_result.len() == 0, 'Status 3 returns 0 markets');

    // Verify the returned market is correct
    let returned_market = status_0_result.at(0);
    assert(returned_market.market_id == @single_market_id, 'Should return correct market');

    // Test with same user calling multiple times - should be idempotent
    let first_call = contract.get_user_markets_by_status(user, 0);
    let second_call = contract.get_user_markets_by_status(user, 0);
    let third_call = contract.get_user_markets_by_status(user, 0);

    assert(first_call.len() == second_call.len(), 'Calls should be consistent');
    assert(second_call.len() == third_call.len(), 'Calls should be consistent');

    // Verify market ID consistency across calls
    assert(first_call.at(0).market_id == second_call.at(0).market_id, 'Market ID consistent');
    assert(second_call.at(0).market_id == third_call.at(0).market_id, 'Market ID consistent');
}

#[test]
fn test_get_user_markets_by_status() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // Create markets
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Create markets that will have different statuses
    let active_market_id = create_test_market_with_category(contract, 0);
    let resolved_market_id = create_test_market_with_category(contract, 1);
    let closed_market_id = create_test_market_with_category(contract, 2);

    stop_cheat_caller_address(contract.contract_address);

    // User 1 bets on active and resolved markets
    let user1 = USER1_ADDR();
    start_cheat_caller_address(contract.contract_address, user1);
    contract.buy_shares(active_market_id, 0, turn_number_to_precision_point(10));
    contract.buy_shares(resolved_market_id, 0, turn_number_to_precision_point(15));
    stop_cheat_caller_address(contract.contract_address);

    // User 2 bets on resolved and closed markets
    let user2 = USER2_ADDR();
    start_cheat_caller_address(contract.contract_address, user2);
    contract.buy_shares(resolved_market_id, 1, turn_number_to_precision_point(20));
    contract.buy_shares(closed_market_id, 0, turn_number_to_precision_point(25));
    stop_cheat_caller_address(contract.contract_address);

    // Test filtering by status - all should be active initially
    let user1_active_markets = contract.get_user_markets_by_status(user1, 0); // Active
    let user1_resolved_markets = contract.get_user_markets_by_status(user1, 2); // Resolved
    let user1_closed_markets = contract.get_user_markets_by_status(user1, 3); // Closed

    let user2_active_markets = contract.get_user_markets_by_status(user2, 0); // Active
    let user2_resolved_markets = contract.get_user_markets_by_status(user2, 2); // Resolved
    let user2_closed_markets = contract.get_user_markets_by_status(user2, 3); // Closed

    // Assertions - all markets should be active initially
    assert(user1_active_markets.len() == 2, 'User1 active');
    assert(user1_resolved_markets.len() == 0, 'User1 resolved');
    assert(user1_closed_markets.len() == 0, 'User1 closed');

    assert(user2_active_markets.len() == 2, 'User2 active');
    assert(user2_resolved_markets.len() == 0, 'User2 resolved');
    assert(user2_closed_markets.len() == 0, 'User2 closed');

    // Verify market IDs match
    let user1_active_market1 = user1_active_markets.at(0);
    let user1_active_market2 = user1_active_markets.at(1);
    let user2_active_market1 = user2_active_markets.at(0);
    let user2_active_market2 = user2_active_markets.at(1);

    // Check that we have the correct markets (order might vary)
    let user1_has_active = user1_active_market1.market_id == @active_market_id
        || user1_active_market2.market_id == @active_market_id;
    let user1_has_resolved = user1_active_market1.market_id == @resolved_market_id
        || user1_active_market2.market_id == @resolved_market_id;
    let user2_has_resolved = user2_active_market1.market_id == @resolved_market_id
        || user2_active_market2.market_id == @resolved_market_id;
    let user2_has_closed = user2_active_market1.market_id == @closed_market_id
        || user2_active_market2.market_id == @closed_market_id;

    assert(user1_has_active, 'User1 has active market');
    assert(user1_has_resolved, 'User1 has resolved market');
    assert(user2_has_resolved, 'User2 has resolved market');
    assert(user2_has_closed, 'User2 has closed market');
}

#[test]
#[should_panic(expected: ('Invalid status: must be 0-3',))]
fn test_get_user_markets_by_status_invalid_status() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // Try to get markets with invalid status (4)
    contract.get_user_markets_by_status(USER1_ADDR(), 4);
}

#[test]
fn test_get_user_markets_by_status_empty_result() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // User who hasn't participated in any markets
    let user = USER3_ADDR();

    // Try to get markets by status for user with no participation
    let active_markets = contract.get_user_markets_by_status(user, 0); // Active

    // Should return empty array
    assert(active_markets.len() == 0, 'Empty array');
}

#[test]
fn test_get_user_markets_by_status_all_statuses() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // Create markets
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    let active_market_id = create_test_market_with_category(contract, 0);
    let resolved_market_id = create_test_market_with_category(contract, 1);
    let closed_market_id = create_test_market_with_category(contract, 2);

    stop_cheat_caller_address(contract.contract_address);

    // User participates in all markets
    let user = USER1_ADDR();
    start_cheat_caller_address(contract.contract_address, user);

    contract.buy_shares(active_market_id, 0, turn_number_to_precision_point(10));
    contract.buy_shares(resolved_market_id, 0, turn_number_to_precision_point(10));
    contract.buy_shares(closed_market_id, 0, turn_number_to_precision_point(10));

    stop_cheat_caller_address(contract.contract_address);

    // Test all statuses - all should be active initially
    let active_markets = contract.get_user_markets_by_status(user, 0);
    let locked_markets = contract.get_user_markets_by_status(user, 1);
    let resolved_markets = contract.get_user_markets_by_status(user, 2);
    let closed_markets = contract.get_user_markets_by_status(user, 3);

    // Should have exactly 3 active markets initially
    assert(active_markets.len() == 3, 'Active markets');
    assert(locked_markets.len() == 0, 'Locked market'); // No locked markets in this test
    assert(resolved_markets.len() == 0, 'Resolved market'); // No resolved markets initially
    assert(closed_markets.len() == 0, 'Closed market'); // No closed markets initially
}
