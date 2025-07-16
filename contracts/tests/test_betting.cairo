use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::types::{Outcome, UserStake};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, HALF_PRECISION, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR,
    USER3_ADDR, create_test_market, default_create_crypto_prediction, default_create_predictions,
    setup_test_environment, turn_number_to_precision_point,
};

// ================ General Prediction Market Tests ================

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
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, 10, contract_address_const::<'hi'>());
    stop_cheat_caller_address(contract.contract_address);

    // user 2 buys 20 shares of option 2
    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    contract.buy_shares(market_id, 0, 20, contract_address_const::<'hi'>());
    stop_cheat_caller_address(contract.contract_address);

    // user 3 buys 40 shares of option 2
    start_cheat_caller_address(contract.contract_address, USER3_ADDR());
    contract.buy_shares(market_id, 1, 40, contract_address_const::<'hi'>());
    stop_cheat_caller_address(contract.contract_address);

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
fn test_get_market_activity() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // assert that the initial market activity is 0
    let mut market_activity: Array<(ContractAddress, u256)> = contract
        .get_market_activity(market_id);
    assert(market_activity.len() == 0, 'should not have anything');

    // place bet to trigger market activity
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 0, 10, contract_address_const::<'hi'>());
    stop_cheat_caller_address(contract.contract_address);

    market_activity = contract.get_market_activity(market_id);

    assert(market_activity.len() == 1, 'should not have 1 activity');
    assert(
        *market_activity.at(0) == (USER1_ADDR(), turn_number_to_precision_point(10)),
        'didnt update as expected',
    );
}
