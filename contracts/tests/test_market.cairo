use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, MODERATOR_ADDR_2, USER1_ADDR, USER2_ADDR,
    create_test_market, default_create_crypto_prediction, default_create_predictions,
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
            "https://pinata.com/image.png",
            ('True', 'False'),
            0,
            future_time + 3600,
            0, // Normal general prediction market
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
    let market1 = contract.get_prediction(market1_id);
    let market2 = contract.get_prediction(market2_id);

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
            "https://pinata.com/image.png",
            ('Yes', 'No'),
            0,
            past_time,
            0, // Normal general prediction market
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
            "Market 2",
            "Description 2",
            "https://pinata.com/image.png",
            ('True', 'False'),
            1,
            small_time,
            0,
            None,
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
            "Market 2",
            "Description 2",
            "https://pinata.com/image.png",
            ('True', 'False'),
            0,
            large_time,
            0,
            None,
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

    let all_prediction = contract.get_all_predictions();
    let all_crypto = contract.get_all_predictions_by_market_category(3);
    let all_sports = contract.get_all_predictions_by_market_category(2);

    assert(all_prediction.len() == 0, 'Empty general array');
    assert(all_crypto.len() == 0, 'Empty crypto array');
    assert(all_sports.len() == 0, 'Empty sports array');

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_predictions(
            "General Market",
            "General prediction description",
            "https://pinata.com/image.png",
            ('Option A', 'Option B'),
            0,
            future_time,
            0,
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
            "https://pinata.com/image.png",
            ('Up', 'Down'),
            3,
            future_time + 3600,
            1,
            Some(('BTC', 50000)),
        );

    let mut crypto_market_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        crypto_market_id = (*event.data.at(0)).into();
    }

    contract
        .create_predictions(
            "Sports Market",
            "Sports prediction description",
            "https://pinata.com/image.png",
            ('Team A', 'Team B'),
            2,
            future_time + 7200,
            2,
            None,
        );

    let mut sports_market_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        sports_market_id = (*event.data.at(0)).into();
    }

    let count = contract.get_prediction_count();
    assert(count == 3, 'Should have 4 markets');

    let general_market = contract.get_prediction(general_market_id);
    let crypto_market = contract.get_prediction(crypto_market_id);
    let sports_market = contract.get_prediction(sports_market_id);

    assert(general_market.market_id == general_market_id, 'General market ID mismatch');
    assert(crypto_market.market_id == crypto_market_id, 'Crypto market ID mismatch');
    assert(sports_market.market_id == sports_market_id, 'Sports market ID mismatch');
    assert(general_market.title == "General Market", 'General market title mismatch');
    assert(crypto_market.title == "Crypto Market", 'Crypto market title mismatch');
    assert(sports_market.title == "Sports Market", 'Sports market title mismatch');

    let all_general = contract.get_all_predictions_by_market_category(0);
    let all_crypto = contract.get_all_predictions_by_market_category(3);
    let all_sports = contract.get_all_predictions_by_market_category(2);
    let all_prediction = contract.get_all_predictions();

    assert(all_general.len() == 1, 'general market should be 1');
    assert(all_crypto.len() == 1, 'crypto market should be 1');
    assert(all_sports.len() == 1, 'sport market should be 1');
    println!("len is : {:?}", all_prediction.len());
    assert(all_prediction.len() == 3, 'Empty market array');
    stop_cheat_caller_address(contract.contract_address);
}


#[test]
fn test_creat_market_multiple_moderators_can_create_markets() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let mut spy = spy_events();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR_2());
    stop_cheat_caller_address(contract.contract_address);

    let future_time = get_block_timestamp() + 86400;

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract
        .create_predictions(
            "Moderator 1 Market",
            "Market by moderator 1",
            "https://pinata.com/image.png",
            ('Yes', 'No'),
            3,
            future_time,
            0,
            None,
        );

    let mut market1_id = 0;

    if let Some((_, event)) = spy.get_events().events.into_iter().last() {
        market1_id = (*event.data.at(0)).into();
    }

    stop_cheat_caller_address(contract.contract_address);

    // Second moderator creates a market
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR_2());
    contract
        .create_predictions(
            "Moderator 2 Market",
            "Market by moderator 2",
            "https://pinata.com/image.png",
            ('True', 'False'),
            4,
            future_time + 3600,
            0, // Normal general prediction market
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

    let market1 = contract.get_prediction(market1_id);
    let market2 = contract.get_prediction(market2_id);
    let all_crypto = contract.get_all_predictions_by_market_category(3);
    let all_business = contract.get_all_predictions_by_market_category(4);
    println!("len is : {:?}", all_crypto.len());

    assert(all_crypto.len() == 1, 'Should have 1 crypto market');
    assert(all_business.len() == 1, 'Should have 1 business market');
    assert(market1.title == "Moderator 1 Market", 'Market 1 title');
    assert(market2.title == "Moderator 2 Market", 'Market 2 title');
}


#[test]
fn test_get_market_status() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    let (is_open, is_resolved) = contract.get_market_status(market_id);
    assert(is_open, 'Market should be open');
    assert(!is_resolved, 'Should not be resolved');
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_get_market_should_panic_if_non_existent_market() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    contract.get_prediction(999);
}

#[test]
fn test_extend_market_duration_success() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    // Create a market (create_test_market handles its own caller address)
    let market_id = create_test_market(contract);

    // Get original market details
    let original_market = contract.get_prediction(market_id);
    let original_end_time = original_market.end_time;

    // Extend the market duration by 1 day (86400 seconds) as moderator
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let new_end_time = original_end_time + 86400;

    let mut spy = spy_events();
    contract.extend_market_duration(market_id, new_end_time);

    // Verify the market was updated
    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.end_time == new_end_time, 'End time not updated');

    // Verify event was emitted
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Should emit 1 event');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_extend_market_duration_admin_access() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    // Create a market (create_test_market handles its own caller address)
    let market_id = create_test_market(contract);

    // Extend as admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let original_market = contract.get_prediction(market_id);
    let new_end_time = original_market.end_time + 86400;

    contract.extend_market_duration(market_id, new_end_time);

    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.end_time == new_end_time, 'Admin should be able to extend');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_extend_market_duration_unauthorized() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    // Create a market (create_test_market handles its own caller address)
    let market_id = create_test_market(contract);

    // Try to extend as regular user (should fail)
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    let market = contract.get_prediction(market_id);
    let new_end_time = market.end_time + 86400;

    contract.extend_market_duration(market_id, new_end_time);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_extend_market_duration_nonexistent_market() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;
    contract.extend_market_duration(999, future_time);
}

#[test]
#[should_panic(expected: ('New end time must be later',))]
fn test_extend_market_duration_earlier_time() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market(contract);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market = contract.get_prediction(market_id);
    let earlier_time = market.end_time - 3600; // 1 hour earlier

    contract.extend_market_duration(market_id, earlier_time);
}

#[test]
#[should_panic(expected: ('End time must be in future',))]
fn test_extend_market_duration_past_time() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market(contract);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market = contract.get_prediction(market_id);

    start_cheat_block_timestamp(
        contract.contract_address, market.end_time + 86400,
    ); // Move 1 day forward
    let past_time = market.end_time
        + 3600; // 1 hour after market end, but still in the past from current time

    contract.extend_market_duration(market_id, past_time);
}

#[test]
fn test_modify_market_details_success() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market(contract);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let new_description = "Updated market description";

    let mut spy = spy_events();
    contract.modify_market_details(market_id, new_description);

    let _updated_market = contract.get_prediction(market_id);

    let events = spy.get_events();
    assert(events.events.len() == 1, 'Should emit 1 event');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_modify_market_details_admin_access() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market(contract);

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let new_description = "Admin updated description";

    contract.modify_market_details(market_id, new_description);

    let _updated_market = contract.get_prediction(market_id);

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Only admin or moderator',))]
fn test_modify_market_details_unauthorized() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market(contract);

    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    let new_description = "Unauthorized modification";

    contract.modify_market_details(market_id, new_description);
}

#[test]
#[should_panic(expected: ('Market does not exist',))]
fn test_modify_market_details_nonexistent_market() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let new_description = "Some description";
    contract.modify_market_details(999, new_description);
}

#[test]
#[should_panic(expected: ('Market already resolved',))]
fn test_extend_market_duration_resolved_market() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    let market_id = create_test_market(contract);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market = contract.get_prediction(market_id);
    start_cheat_block_timestamp(contract.contract_address, market.end_time + 1);

    contract.resolve_prediction(market_id, 0);

    let new_end_time = market.end_time + 86400;
    contract.extend_market_duration(market_id, new_end_time);
}

#[test]
#[should_panic(expected: ('Market already resolved',))]
fn test_modify_market_details_resolved_market() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    let market_id = create_test_market(contract);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market = contract.get_prediction(market_id);
    start_cheat_block_timestamp(contract.contract_address, market.end_time + 1);

    contract.resolve_prediction(market_id, 0);

    let new_description = "Should not work";
    contract.modify_market_details(market_id, new_description);
}
