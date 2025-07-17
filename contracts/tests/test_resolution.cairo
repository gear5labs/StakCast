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

// =============== Util ======================
fn create_and_stake_on_general_prediction_util() -> (
    u256, IPredictionHubDispatcher, IAdditionalAdminDispatcher,
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
    contract.buy_shares(market_id, 1, 10, contract_address_const::<'hi'>());
    stop_cheat_caller_address(contract.contract_address);

    // user 2 buys 20 shares of option 2
    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    contract.buy_shares(market_id, 1, 20, contract_address_const::<'hi'>());
    stop_cheat_caller_address(contract.contract_address);

    // user 3 buys 40 shares of option 2
    start_cheat_caller_address(contract.contract_address, USER3_ADDR());
    contract.buy_shares(market_id, 1, 40, contract_address_const::<'hi'>());
    stop_cheat_caller_address(contract.contract_address);

    // let market_shares_after = contract.calculate_share_prices(market_id);
    contract.get_user_stake_details(market_id, USER1_ADDR());
    contract.get_user_stake_details(market_id, USER2_ADDR());
    contract.get_user_stake_details(market_id, USER3_ADDR());

    (market_id, contract, admin_interface)
}


// ================ General Prediction Market Tests ================
// ================ Resolve General Market ========================
#[test]
fn test_resolve_market_success() {
    let (market_id, contract, _admin_interface) = create_and_stake_on_general_prediction_util();
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
}

#[test]
#[should_panic(expected: ('Contract is paused',))]
fn test_resolve_when_contract_is_pause_should_panic() {
    let (market_id, contract, admin_interface) = create_and_stake_on_general_prediction_util();

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
    let (market_id, contract, admin_interface) = create_and_stake_on_general_prediction_util();

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
    let (market_id, contract, _admin_interface) = create_and_stake_on_general_prediction_util();

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
    let (_market_id, contract, _admin_interface) = create_and_stake_on_general_prediction_util();

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
    let (market_id, contract, _admin_interface) = create_and_stake_on_general_prediction_util();

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        contract.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 4);
    stop_cheat_caller_address(contract.contract_address);
}

