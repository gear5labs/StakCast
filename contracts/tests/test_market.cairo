use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR, create_test_market, create_test_market_as,
    default_create_crypto_prediction, default_create_predictions, setup_test_environment,
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
        .create_predictions("Market 2", "Description 2", ('True', 'False'), 1, small_time, 0, None);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market duration too long')]
fn test_create_market_should_panic_if_end_time_is_too_long() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let large_time = get_block_timestamp() + 1000000000;
    contract
        .create_predictions("Market 2", "Description 2", ('True', 'False'), 0, large_time, 0, None);
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
    contract.add_moderator(contract_address_const::<0x02>());
    stop_cheat_caller_address(contract.contract_address);

    let future_time = get_block_timestamp() + 86400;

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract
        .create_predictions(
            "Moderator 1 Market", "Market by moderator 1", ('Yes', 'No'), 3, future_time, 0, None,
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
#[should_panic(expected: 'Only admin or moderator')]
fn test_extend_market_duration_should_panic_if_not_admin_nor_moderator() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    contract.extend_market_duration(999, 1000);
}

#[test]
fn test_extend_market_duration_success_by_admin() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let original_market = contract.get_prediction(market_id);
    let new_end_time = original_market.end_time + 3600;
    
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, new_end_time);
    stop_cheat_caller_address(contract.contract_address);
    
    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.end_time == new_end_time, 'End time not updated');
    
    // Verify that an event was emitted from the correct contract
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Should emit exactly 1 event');
    
    let (event_from, event_data) = events.events.at(0);
    assert(*event_from == contract.contract_address, 'Event from wrong contract');
    
    assert((*event_data.data.at(0)).into() == market_id, 'Wrong market_id in event');
    assert(*event_data.data.at(1) == 0, 'Wrong updated_by in event');
    assert(*event_data.data.at(2) == ADMIN_ADDR().into(), 'Wrong updated_by in event');
    assert(*event_data.data.at(3) == new_end_time.into(), 'Wrong new_end_time in event');
}

#[test]
fn test_extend_market_duration_success_by_moderator() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let original_market = contract.get_prediction(market_id);
    let new_end_time = original_market.end_time + 7200;
    
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract.extend_market_duration(market_id, new_end_time);
    stop_cheat_caller_address(contract.contract_address);
    
    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.end_time == new_end_time, 'End time not updated');

    let events = spy.get_events();
    assert(events.events.len() == 1, 'Should emit exactly 1 event');
    
    let (event_from, event_data) = events.events.at(0);
    assert(*event_from == contract.contract_address, 'Event from wrong contract');
    
    assert((*event_data.data.at(0)).into() == market_id, 'Wrong market_id in event');
    assert(*event_data.data.at(1) == 0, 'Wrong updated_by in event');
    assert(*event_data.data.at(2) == MODERATOR_ADDR().into(), 'Wrong updated_by in event');
    assert(*event_data.data.at(3) == new_end_time.into(), 'Wrong new_end_time in event');
}

#[test]
#[should_panic(expected: 'Market does not exist')]
fn test_extend_market_duration_should_panic_if_market_does_not_exist() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let future_time = get_block_timestamp() + 86400;
    contract.extend_market_duration(999, future_time); // Non-existent market
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market is closed')]
fn test_extend_market_duration_should_panic_if_market_is_closed() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    
    // Resolve the market to close it
    let market = contract.get_prediction(market_id);
    start_cheat_block_timestamp(contract.contract_address, market.end_time + 1);
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
    
    let new_end_time = market.end_time + 3600;
 
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, new_end_time);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market has ended')]
fn test_extend_market_duration_should_panic_if_market_has_ended() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    
    let market = contract.get_prediction(market_id);
    start_cheat_block_timestamp(contract.contract_address, market.end_time + 1);
    
    let new_end_time = market.end_time + 3600;
 
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, new_end_time);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'End time must be in future')]
fn test_extend_market_duration_should_panic_if_new_end_time_is_in_past() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let block_timestamp = 3600;
    
    start_cheat_block_timestamp(contract.contract_address, block_timestamp);
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, block_timestamp - 1000);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market duration too short')]
fn test_extend_market_duration_should_panic_if_new_duration_too_short() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    
    let short_time = get_block_timestamp() + 1800; // 30 minutes (less than 1 hour minimum)
 
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, short_time);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market duration too long')]
fn test_extend_market_duration_should_panic_if_new_duration_too_long() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let market_id = create_test_market_as(contract, ADMIN_ADDR());

    let long_time = get_block_timestamp() + 40000000; // More than 1 year maximum
    
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, long_time);
    stop_cheat_caller_address(contract.contract_address);
    
}

#[test]
fn test_extend_market_duration_multiple_extensions() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    
    let original_market = contract.get_prediction(market_id);
    let first_extension = original_market.end_time + 3600;
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, first_extension);
    stop_cheat_caller_address(contract.contract_address);
    
    let market_after_first = contract.get_prediction(market_id);
    assert(market_after_first.end_time == first_extension, 'First extension failed');
    
    let second_extension = first_extension + 7200;
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.extend_market_duration(market_id, second_extension);
    stop_cheat_caller_address(contract.contract_address);
    
    let market_after_second = contract.get_prediction(market_id);
    assert(market_after_second.end_time == second_extension, 'Second extension failed');
}

#[test]
fn test_modify_market_details_success_by_admin() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let original_market = contract.get_prediction(market_id);
    let new_description = "Updated market description by admin";
    
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.modify_market_details(market_id, new_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.description == new_description, 'Description not updated');
    assert(updated_market.title == original_market.title, 'Title should not change');
    assert(updated_market.market_id == original_market.market_id, 'Market ID should not change');
    
    // Verify that an event was emitted
    let events = spy.get_events();
    assert(events.events.len() == 1, 'Should emit exactly 1 event');
    
    let (event_from, event_data) = events.events.at(0);
    assert(*event_from == contract.contract_address, 'Event from wrong contract');
    
    assert((*event_data.data.at(0)).into() == market_id, 'Wrong market_id in event');
    assert(*event_data.data.at(1) == 0, 'Wrong updated_by in event');
    assert(*event_data.data.at(2) == ADMIN_ADDR().into(), 'Wrong updated_by in event');
}

#[test]
fn test_modify_market_details_success_by_moderator() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let original_market = contract.get_prediction(market_id);
    let new_description = "Updated market description by moderator";
    
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract.modify_market_details(market_id, new_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.description == new_description, 'Description not updated');
    assert(updated_market.title == original_market.title, 'Title should not change');
    assert(updated_market.market_id == original_market.market_id, 'Market ID should not change');

    let events = spy.get_events();
    assert(events.events.len() == 1, 'Should emit exactly 1 event');
    
    let (event_from, event_data) = events.events.at(0);
    assert(*event_from == contract.contract_address, 'Event from wrong contract');
    
    assert((*event_data.data.at(0)).into() == market_id, 'Wrong market_id in event');
    assert(*event_data.data.at(1) == 0, 'Wrong updated_by in event');
    assert(*event_data.data.at(2) == MODERATOR_ADDR().into(), 'Wrong updated_by in event');
}

#[test]
#[should_panic(expected: 'Only admin or moderator')]
fn test_modify_market_details_should_panic_if_not_admin_nor_moderator() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let new_description = "This should fail";

    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    contract.modify_market_details(market_id, new_description);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market does not exist')]
fn test_modify_market_details_should_panic_if_market_does_not_exist() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.modify_market_details(999, "This should fail"); // Non-existent market
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_modify_market_details_multiple_updates() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let first_description = "First updated description";
    let second_description = "Second updated description";
    
    // First update by admin
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.modify_market_details(market_id, first_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let market_after_first = contract.get_prediction(market_id);
    assert(market_after_first.description == first_description, 'First update failed');
    
    // Second update by moderator
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    contract.modify_market_details(market_id, second_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let market_after_second = contract.get_prediction(market_id);
    assert(market_after_second.description == second_description, 'Second update failed');
}

#[test]
fn test_modify_market_details_empty_description() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let empty_description = "";
    
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.modify_market_details(market_id, empty_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.description == empty_description, 'Empty description not set');
}

#[test]
fn test_modify_market_details_very_long_description() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let long_description = "This is a very long description that contains many characters to test if the function can handle longer text inputs without any issues. It should work fine as ByteArray can handle large strings.";
    
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.modify_market_details(market_id, long_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let updated_market = contract.get_prediction(market_id);
    assert(updated_market.description == long_description, 'Long description not set');
}

#[test]
fn test_modify_market_details_preserves_other_fields() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let original_market = contract.get_prediction(market_id);
    let new_description = "New description to test field preservation";
    
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.modify_market_details(market_id, new_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let updated_market = contract.get_prediction(market_id);
    
    // Check that only description changed
    assert(updated_market.description == new_description, 'Description not updated');
    assert(updated_market.title == original_market.title, 'Title should not change');
    assert(updated_market.market_id == original_market.market_id, 'Market ID should not change');
    assert(updated_market.is_open == original_market.is_open, 'is_open should not change');
    assert(updated_market.is_resolved == original_market.is_resolved, 'is_resolved should not change');
    assert(updated_market.end_time == original_market.end_time, 'end_time should not change');
    assert(updated_market.status == original_market.status, 'status should not change');
    assert(updated_market.choices == original_market.choices, 'choices should not change');
    assert(updated_market.category == original_market.category, 'category should not change');
    assert(updated_market.total_pool == original_market.total_pool, 'total_pool should not change');
}

#[test]
fn test_modify_market_details_no_update_when_description_unchanged() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    
    let market_id = create_test_market_as(contract, ADMIN_ADDR());
    let original_market = contract.get_prediction(market_id);
    let same_description = original_market.description.clone();
    
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.modify_market_details(market_id, same_description.clone());
    stop_cheat_caller_address(contract.contract_address);
    
    let market_after_call = contract.get_prediction(market_id);
    
    // Verify that no event was emitted since description didn't change
    let events = spy.get_events();
    assert(events.events.len() == 0, 'Should not emit event');
    
    // Verify that the market description is still the same
    assert(market_after_call.description == original_market.description, 'Description should not change');
    
    // Verify that all other fields remain exactly the same
    assert(market_after_call.title == original_market.title, 'Title should not change');
    assert(market_after_call.market_id == original_market.market_id, 'Market ID should not change');
    assert(market_after_call.is_open == original_market.is_open, 'is_open should not change');
    assert(market_after_call.is_resolved == original_market.is_resolved, 'is_resolved should not change');
    assert(market_after_call.end_time == original_market.end_time, 'end_time should not change');
    assert(market_after_call.status == original_market.status, 'status should not change');
    assert(market_after_call.choices == original_market.choices, 'choices should not change');
    assert(market_after_call.category == original_market.category, 'category should not change');
    assert(market_after_call.total_pool == original_market.total_pool, 'total_pool should not change');
}
