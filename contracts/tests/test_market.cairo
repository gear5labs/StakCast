use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR, create_test_market,
    default_create_crypto_prediction, default_create_predictions, default_create_sports_prediction,
    setup_test_environment,
};

// ================ General Prediction Market Tests ================

#[test]
fn test_create_prediction_market_success() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    default_create_predictions(contract);
    stop_cheat_caller_address(contract.contract_address);
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');
}

#[test]
fn test_create_multiple_prediction_markets() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400;
    // Create first market
    default_create_predictions(contract);

    // Fetch market_id for first market
    let market1_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };
    // spy.clear_events(); // Clear events to avoid confusion

    // Create second market
    contract
        .create_predictions(
            "Market 2",
            "Description 2",
            ('True', 'False'),
            'category2',
            future_time + 3600,
            0, // Normal general prediction market
            None,
            None,
        );

    // Fetch market_id for second market
    let market2_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 2 markets');

    // Verify both markets exist and have correct IDs
    let market1 = contract.get_prediction(market1_id, 0);
    let market2 = contract.get_prediction(market2_id, 0);

    assert(market1.market_id == market1_id, 'Market 1 ID mismatch');
    assert(market2.market_id == market2_id, 'Market 2 ID mismatch');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Contract is paused')]
fn test_create_market_should_panic_if_contract_is_pasued() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let admin_dispatcher = IAdditionalAdminDispatcher {
        contract_address: contract.contract_address,
    };

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    admin_dispatcher.emergency_pause();
    stop_cheat_caller_address(contract.contract_address);

    // try creating a new market
    default_create_predictions(contract);
}

#[test]
fn test_create_market_should_work_after_contract_unpasued() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let admin_dispatcher = IAdditionalAdminDispatcher {
        contract_address: contract.contract_address,
    };

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());

    admin_dispatcher.emergency_pause();

    admin_dispatcher.emergency_unpause();

    default_create_predictions(contract);
}

#[test]
#[should_panic(expected: 'Market creation paused')]
fn test_create_market_should_panic_if_market_creation_is_pasued() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let admin_dispatcher = IAdditionalAdminDispatcher {
        contract_address: contract.contract_address,
    };
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    admin_dispatcher.pause_market_creation();
    stop_cheat_caller_address(contract.contract_address);
    default_create_predictions(contract);
}

#[test]
fn test_create_market_should_work_after_market_creation_unpasued() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let admin_dispatcher = IAdditionalAdminDispatcher {
        contract_address: contract.contract_address,
    };
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());

    admin_dispatcher.pause_market_creation();

    admin_dispatcher.unpause_market_creation();

    default_create_predictions(contract);
}

#[test]
#[should_panic(expected: 'Only admin or moderator')]
fn test_create_market_should_panic_if_non_admin_tries_to_create() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, USER2_ADDR().into());
    default_create_predictions(contract);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'End time must be in future')]
fn test_create_market_should_panic_if_end_time_not_in_future() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let current_time = 10000;
    start_cheat_block_timestamp(contract.contract_address, current_time);

    let past_time = current_time - 1;

    contract
        .create_predictions(
            "Invalid Time Market",
            "This should fail due to past end time",
            ('Yes', 'No'),
            'test',
            past_time,
            0, // Normal general prediction market
            None,
            None,
        );
}

#[test]
#[should_panic(expected: 'Market duration too short')]
fn test_create_market_should_panic_if_end_time_is_too_short() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let small_time = get_block_timestamp() + 10;
    contract
        .create_predictions(
            "Market 2", "Description 2", ('True', 'False'), 'category2', small_time, 0, None, None,
        );
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market duration too long')]
fn test_create_market_should_panic_if_end_time_is_too_long() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let large_time = get_block_timestamp() + 1000000000;
    contract
        .create_predictions(
            "Market 2", "Description 2", ('True', 'False'), 'category2', large_time, 0, None, None,
        );
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_create_market_create_crypto_market() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    default_create_crypto_prediction(contract);
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');
}


#[test]
fn test_create_market_create_multiple_market_types() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let mut spy = spy_events();

    let all_general = contract.get_all_predictions();
    let all_crypto = contract.get_all_crypto_predictions();
    let all_sports = contract.get_all_sports_predictions();

    assert(all_general.len() == 0, 'Empty general array');
    assert(all_crypto.len() == 0, 'Empty crypto array');
    assert(all_sports.len() == 0, 'Empty sports array');

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_predictions(
            "General Market",
            "General prediction description",
            ('Option A', 'Option B'),
            'general',
            future_time,
            0,
            None,
            None,
        );

    let mut general_market_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        general_market_id = (*event.data.at(0)).into();
    }

    contract
        .create_predictions(
            "Crypto Market",
            "Crypto prediction description",
            ('Up', 'Down'),
            'crypto',
            future_time + 3600,
            1,
            Some(('BTC', 50000)),
            None,
        );

    let mut crypto_market_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        crypto_market_id = (*event.data.at(0)).into();
    }

    contract
        .create_predictions(
            "Sports Market",
            "Sports prediction description",
            ('Team A', 'Team B'),
            'sports',
            future_time + 7200,
            2,
            None,
            Some((555, true)),
        );

    let mut sports_market_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        sports_market_id = (*event.data.at(0)).into();
    }

    let count = contract.get_prediction_count();
    assert(count == 3, 'Should have 4 markets');

    let general_market = contract.get_prediction(general_market_id, 0);
    let crypto_market = contract.get_prediction(crypto_market_id, 1);
    let sports_market = contract.get_prediction(sports_market_id, 2);

    assert(general_market.market_id == general_market_id, 'General market ID mismatch');
    assert(crypto_market.market_id == crypto_market_id, 'Crypto market ID mismatch');
    assert(sports_market.market_id == sports_market_id, 'Sports market ID mismatch');
    assert(general_market.title == "General Market", 'General market title mismatch');
    assert(crypto_market.title == "Crypto Market", 'Crypto market title mismatch');
    assert(sports_market.title == "Sports Market", 'Sports market title mismatch');

    let all_general = contract.get_all_general_predictions();
    let all_crypto = contract.get_all_crypto_predictions();
    let all_sports = contract.get_all_sports_predictions();
    assert(all_general.len() == 1, 'general market should be 1');
    assert(all_crypto.len() == 1, 'crypto market should be 1');
    assert(all_sports.len() == 1, 'sport market should be 1');
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_creat_market_multiple_moderators_can_create_markets() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let mut spy = spy_events();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(contract_address_const::<0x02>());
    stop_cheat_caller_address(contract.contract_address);

    let future_time = get_block_timestamp() + 86400;

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract
        .create_predictions(
            "Moderator 1 Market",
            "Market by moderator 1",
            ('Yes', 'No'),
            'mod1',
            future_time,
            0,
            None,
            None,
        );

    let mut market1_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        market1_id = (*event.data.at(0)).into();
    }

    stop_cheat_caller_address(contract.contract_address);

    // Second moderator creates a market
    start_cheat_caller_address(contract.contract_address, contract_address_const::<0x02>());
    contract
        .create_predictions(
            "Moderator 2 Market",
            "Market by moderator 2",
            ('True', 'False'),
            'mod2',
            future_time + 3600,
            0, // Normal general prediction market
            None,
            None,
        );

    // Fetch market_id for second market
    let mut market2_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        market2_id = (*event.data.at(0)).into();
    }

    stop_cheat_caller_address(contract.contract_address);

    let count = contract.get_prediction_count();
    assert(count == 2, '2 moderator markets');

    let market1 = contract.get_prediction(market1_id, 0);
    let market2 = contract.get_prediction(market2_id, 0);

    assert(market1.title == "Moderator 1 Market", 'Market 1 title');
    assert(market2.title == "Moderator 2 Market", 'Market 2 title');
}


#[test]
fn test_get_market_status() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let (is_open, is_resolved) = contract.get_market_status(market_id, 0);
    assert(is_open, 'Market should be open');
    assert(!is_resolved, 'Should not be resolved');
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_get_market_should_panic_if_non_existent_market() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    contract.get_prediction(999, 0);
}


#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_get_market_should_panic_if_non_existent_crypto_market() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    contract.get_prediction(999, 1);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_get_market_should_panic_if_non_existent_sports_market() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    contract.get_prediction(999, 2);
}

