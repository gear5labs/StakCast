use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::types::{MarketStatus, Outcome, UserStake};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, HALF_PRECISION, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR,
    USER3_ADDR, create_test_market, default_create_crypto_prediction, default_create_predictions,
    setup_test_environment, turn_number_to_precision_point,
};

// ================ General Prediction Market Tests ================
// ================ Buy share ========================
#[test]
fn test_admin_functions() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // asset that adin addres is the expected address
    assert!(contract.get_admin() == ADMIN_ADDR(), "addres not admin");
    assert!(contract.get_fee_recipient() == FEE_RECIPIENT_ADDR(), "address not recipient address");

    // change fee recipient
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.set_fee_recipient(USER3_ADDR());
    stop_cheat_caller_address(contract.contract_address);
    assert!(contract.get_fee_recipient() == USER3_ADDR(), "address not recipient address");

    // add moderator
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(USER1_ADDR());
    contract.set_fee_recipient(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // add prediction
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    default_create_predictions(contract);
    stop_cheat_caller_address(contract.contract_address);
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // add moderator
    assert!(contract.get_fee_recipient() == MODERATOR_ADDR(), "address not recipient address");
}

#[test]
#[should_panic(expected: 'Insufficient role privileges')]
fn test_non_admin_function_should_panic() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    // set fee recipent with non admin call should panic
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.set_fee_recipient(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Only admin allowed')]
fn test_non_admin_add_moderator_should_panic() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    // set fee recipent with non admin call should panic
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_emergency_close_market() {
    let (contract, admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let user1 = USER1_ADDR();
    // User 1 bets on markets 1 and 2
    start_cheat_caller_address(contract.contract_address, user1);
    contract.buy_shares(market_id_1, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);
    // market closed with emergency close
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_close_market(market_id_1);
    stop_cheat_caller_address(admin_interface.contract_address);

    let market = contract.get_prediction(market_id_1);
    assert(market.status == MarketStatus::Closed, 'Market should be closed');
    assert(!market.is_open, 'Market should be closed');
}

#[test]
#[should_panic(expected: ('Market is closed',))]
fn test_emergency_close_market_panics_on_bet_after_close() {
    let (contract, admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let user1 = USER1_ADDR();
    // User 1 bets on market 1
    start_cheat_caller_address(contract.contract_address, user1);
    contract.buy_shares(market_id_1, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    // Emergency close the market
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_close_market(market_id_1);
    stop_cheat_caller_address(admin_interface.contract_address);

    // User 2 tries to bet after market is closed - should panic
    let user2 = USER2_ADDR();
    start_cheat_caller_address(contract.contract_address, user2);
    contract.buy_shares(market_id_1, 1, turn_number_to_precision_point(5));
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_emergency_close_market_panics_if_not_admin() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // Create a market as moderator
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Try to close the market as a non-admin (user1)
    let user1 = USER1_ADDR();
    start_cheat_caller_address(admin_interface.contract_address, user1);
    admin_interface.emergency_close_market(market_id_1);
    stop_cheat_caller_address(admin_interface.contract_address);
}


#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_emergency_close_market_panics_if_non_existing_market() {
    let (_, admin_interface, _token) = setup_test_environment();

    let market_id_1 = 234;

    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_close_market(market_id_1);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
fn test_emergency_close_multiple_markets_succcess() {
    let (contract, admin_interface, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    let market_id_2 = create_test_market(contract);
    let market_id_3 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Emergency close all markets at once
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    let market_ids = array![market_id_1, market_id_2, market_id_3];
    admin_interface.emergency_close_multiple_markets(market_ids);
    stop_cheat_caller_address(admin_interface.contract_address);

    // Assert all markets are closed
    let market1 = contract.get_prediction(market_id_1);
    let market2 = contract.get_prediction(market_id_2);
    let market3 = contract.get_prediction(market_id_3);

    assert(market1.status == MarketStatus::Closed, 'Market 1 should be closed');
    assert(!market1.is_open, 'Market 1 should be closed');
    assert(market2.status == MarketStatus::Closed, 'Market 2 should be closed');
    assert(!market2.is_open, 'Market 2 should be closed');
    assert(market3.status == MarketStatus::Closed, 'Market 3 should be closed');
    assert(!market3.is_open, 'Market 3 should be closed');
}

#[test]
fn test_force_close_market() {
    let (contract, admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let user1 = USER1_ADDR();
    // User 1 bets on market
    start_cheat_caller_address(contract.contract_address, user1);
    contract.buy_shares(market_id_1, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    // Force close the market with a reason
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    let reason = "Emergency situation";
    admin_interface.force_close_market(market_id_1, reason);
    stop_cheat_caller_address(admin_interface.contract_address);

    let market = contract.get_prediction(market_id_1);
    assert(market.status == MarketStatus::Closed, 'Market should be closed');
    assert(!market.is_open, 'Market should be closed');
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_force_close_market_panics_if_not_admin() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // Create a market as moderator
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Try to force close the market as a non-admin (user1)
    let user1 = USER1_ADDR();
    start_cheat_caller_address(admin_interface.contract_address, user1);
    let reason = "Emergency situation";
    admin_interface.force_close_market(market_id_1, reason);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_force_close_market_panics_if_non_existing_market() {
    let (_, admin_interface, _token) = setup_test_environment();

    let market_id_1 = 234;
    let reason = "Emergency situation";

    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.force_close_market(market_id_1, reason);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
fn test_emergency_resolve_market() {
    let (contract, admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let user1 = USER1_ADDR();
    // User 1 bets on market
    start_cheat_caller_address(contract.contract_address, user1);
    contract.buy_shares(market_id_1, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    // Emergency resolve the market with winning choice 0
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_resolve_market(market_id_1, 0);
    stop_cheat_caller_address(admin_interface.contract_address);

    let market = contract.get_prediction(market_id_1);
    assert(market.is_resolved, 'Market resolved');
    assert(!market.is_open, 'Market closed');
    assert(market.winning_choice.is_some(), 'Has winning choice');
    assert(market.winning_choice.unwrap() == 0, 'Choice is 0');
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_emergency_resolve_market_panics_if_not_admin() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // Create a market as moderator
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Try to emergency resolve the market as a non-admin (user1)
    let user1 = USER1_ADDR();
    start_cheat_caller_address(admin_interface.contract_address, user1);
    admin_interface.emergency_resolve_market(market_id_1, 0);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_emergency_resolve_market_panics_if_non_existing_market() {
    let (_, admin_interface, _token) = setup_test_environment();

    let market_id_1 = 234;

    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_resolve_market(market_id_1, 0);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
#[should_panic(expected: ('Invalid choice selected',))]
fn test_emergency_resolve_market_panics_if_invalid_choice() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // Create a market as moderator
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Try to emergency resolve with invalid choice (2)
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_resolve_market(market_id_1, 2);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
fn test_emergency_resolve_multiple_markets() {
    let (contract, admin_interface, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    let market_id_2 = create_test_market(contract);
    let market_id_3 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Emergency resolve all markets at once
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    let market_ids = array![market_id_1, market_id_2, market_id_3];
    let market_types = array![0, 0, 0]; // Not used in current implementation
    let winning_choices = array![0, 1, 0];
    admin_interface.emergency_resolve_multiple_markets(market_ids, market_types, winning_choices);
    stop_cheat_caller_address(admin_interface.contract_address);

    // Assert all markets are resolved
    let market1 = contract.get_prediction(market_id_1);
    let market2 = contract.get_prediction(market_id_2);
    let market3 = contract.get_prediction(market_id_3);

    assert(market1.is_resolved, 'Market 1 resolved');
    assert(market1.winning_choice.unwrap() == 0, 'Market 1 choice 0');
    assert(market2.is_resolved, 'Market 2 resolved');
    assert(market2.winning_choice.unwrap() == 1, 'Market 2 choice 1');
    assert(market3.is_resolved, 'Market 3 resolved');
    assert(market3.winning_choice.unwrap() == 0, 'Market 3 choice 0');
}

#[test]
#[should_panic(expected: ('Arrays must have same length',))]
fn test_emergency_resolve_multiple_markets_panics_if_arrays_mismatch() {
    let (contract, admin_interface, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id_1 = create_test_market(contract);
    let market_id_2 = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Try to resolve with mismatched array lengths
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    let market_ids = array![market_id_1, market_id_2];
    let market_types = array![0, 0, 0]; // Extra element
    let winning_choices = array![0, 1];
    admin_interface.emergency_resolve_multiple_markets(market_ids, market_types, winning_choices);
    stop_cheat_caller_address(admin_interface.contract_address);
}
