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
    USER3_ADDR, USER4_ADDR, create_test_market, default_create_crypto_prediction,
    default_create_predictions, setup_test_environment, turn_number_to_precision_point,
};

// =============== Util ======================
fn create_and_stake_on_general_prediction_util() -> (
    u256, IPredictionHubDispatcher, IAdditionalAdminDispatcher, IERC20Dispatcher,
) {
    let (contract, admin_interface, _token) = setup_test_environment();

    // create a prediction
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');
    // get share prices
    let mut market_shares = contract.calculate_share_prices(market_id);
    let (ppua, ppub) = market_shares;
    assert(ppua == HALF_PRECISION() && ppub == HALF_PRECISION(), 'Share prices should be 500000');

    // user 1 buys 10 shares of option 1
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.buy_shares(market_id, 1, turn_number_to_precision_point(10));
    contract.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(contract.contract_address);

    // user 2 buys 20 shares of option 2
    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    contract.buy_shares(market_id, 1, turn_number_to_precision_point(20));
    stop_cheat_caller_address(contract.contract_address);

    // user 3 buys 40 shares of option 2
    start_cheat_caller_address(contract.contract_address, USER3_ADDR());
    contract.buy_shares(market_id, 1, turn_number_to_precision_point(20));
    contract.buy_shares(market_id, 0, turn_number_to_precision_point(20));
    stop_cheat_caller_address(contract.contract_address);

    // let market_shares_after = contract.calculate_share_prices(market_id);
    contract.get_user_stake_details(market_id, USER1_ADDR());
    contract.get_user_stake_details(market_id, USER2_ADDR());
    contract.get_user_stake_details(market_id, USER3_ADDR());

    (market_id, contract, admin_interface, _token)
}


// ================ General Prediction Market Tests ================
// ================ Resolve General Market ========================
#[test]
fn test_resolve_market_success() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();
    let mut spy = spy_events();
    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    let event = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketResolved event emitted"),
    };
    assert!(event == 456, "market not resolved");
    stop_cheat_caller_address(contract.contract_address);

    // get market details
    let market = contract.get_prediction(market_id);
    assert(market.is_resolved, 'market should be resolved');
    assert(!market.is_open, 'market should be closed');
    let (choice1, _) = market.choices;
    assert(market.status == MarketStatus::Resolved(choice1), 'resolved not correct');

    // het all user dashboards and assert they were updated successfully
    let user_one_dashboard = contract.get_user_dashboard(USER1_ADDR());
    // this user bet on the two
    assert(user_one_dashboard.total_wins == 1, 'user 1 should have 1 win');
    assert(user_one_dashboard.total_losses == 1, 'user 1 should have 1 losses');
    // his total gained should be more than 10 since he bet 10 on the correct option
    assert(
        user_one_dashboard.total_gained > turn_number_to_precision_point(10),
        'gain should be more than 10',
    );

    let user_two_dashboard = contract.get_user_dashboard(USER2_ADDR());
    // this user bet on the wrong option
    assert(user_two_dashboard.total_wins == 0, 'user 2 should have 0 win');
    assert(user_two_dashboard.total_losses == 1, 'user 2 should have 1 losses');
    // he bet 20 on the wrong option so he should have lost 20
    assert(user_two_dashboard.total_gained == 0, 'user 2 should have 0 gained');

    let user_three_dashboard = contract.get_user_dashboard(USER3_ADDR());
    // this user bet on the two options
    assert(user_three_dashboard.total_wins == 1, 'user 3 should have 0 win');
    assert(user_three_dashboard.total_losses == 1, 'user 3 should have 1 losses');
    println!("user 3 dashboard: {:?}", user_three_dashboard);
    // he bet 20 on the correct option so he should have gained 20
    assert(
        user_three_dashboard.total_gained > turn_number_to_precision_point(20),
        'user 3 should have 20 gained',
    );
}

#[test]
#[should_panic(expected: ('Contract is paused',))]
fn test_resolve_when_contract_is_pause_should_panic() {
    let (market_id, contract, admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.emergency_pause();
    stop_cheat_caller_address(admin_interface.contract_address);
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Resolution paused',))]
fn test_resolve_when_resolution_is_pause_should_panic() {
    let (market_id, contract, admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour
    start_cheat_caller_address(admin_interface.contract_address, ADMIN_ADDR());
    admin_interface.pause_resolution();
    stop_cheat_caller_address(admin_interface.contract_address);
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_resolve_whith_non_moderator_or_admin_should_panic() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_resolve_invalid_market_should_panic() {
    let (_market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(12, 0);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expected: ('Invalid choice selected',))]
fn test_resolve_invalid_choice_should_panic() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 4);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Market already resolved',))]
fn test_resolve_market_should_panic_if_market_already_resolved() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();
    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 1);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Market not yet ended',))]
fn test_resolve_market_should_panic_if_market_not_ended() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Resolution window expired',))]
fn test_resolve_market_should_panic_if_resolution_window_expired() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();
    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 * 14 + 3600,
    ); // 2 weeks + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_claim_success() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);

    // get contract balance and user 1 balance before user 1 claims
    let contract_balance_before = _token.balance_of(contract.contract_address);
    let user_1_balance_before = _token.balance_of(USER1_ADDR());

    // user 1 claims
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.claim(market_id);
    stop_cheat_caller_address(contract.contract_address);

    let contract_balance_after = _token.balance_of(contract.contract_address);
    let user_1_balance_after = _token.balance_of(USER1_ADDR());

    // been precalculated
    assert(contract_balance_after < contract_balance_before, 'incorrect contract balance');
    assert(user_1_balance_after > user_1_balance_before, 'incorrect user 1 balance');

    let claim_status = contract.get_user_claim_status(market_id, USER1_ADDR());
    assert(claim_status, 'User 1 should have claimed');
}


#[test]
#[should_panic(expected: ('Contract is paused',))]
fn test_claim_should_panic_if_paused() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);

    start_cheat_caller_address(_admin_interface.contract_address, ADMIN_ADDR());
    _admin_interface.emergency_pause();
    stop_cheat_caller_address(_admin_interface.contract_address);

    // user 1 claims
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.claim(market_id);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Claim paused',))]
fn test_claim_should_panic_if_claim_paused() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);

    start_cheat_caller_address(_admin_interface.contract_address, ADMIN_ADDR());
    _admin_interface.pause_claim();
    stop_cheat_caller_address(_admin_interface.contract_address);

    // user 1 claims
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.claim(market_id);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_claim_should_panic_if_market_doesnt_exist() {
    let (_, contract, _admin_interface, _token) = create_and_stake_on_general_prediction_util();

    // user 1 claims
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.claim(44);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expected: ('Market not resolved',))]
fn test_claim_should_panic_if_market_not_resolved() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    // user 1 claims
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.claim(market_id);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expected: ('Already claimed',))]
fn test_claim_should_panic_if_already_claimed() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);

    // user 1 claims
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.claim(market_id);
    stop_cheat_caller_address(contract.contract_address);

    // user 1 claims again
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.claim(market_id);
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
#[should_panic(expected: ('No winning stake for user',))]
fn test_claim_should_panic_if_no_winning_stake_for_user() {
    let (market_id, contract, _admin_interface, _token) =
        create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);

    // user 1 claims
    start_cheat_caller_address(contract.contract_address, USER4_ADDR());
    contract.claim(market_id);
    stop_cheat_caller_address(contract.contract_address);
}
