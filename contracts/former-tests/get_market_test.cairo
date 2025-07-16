use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR,
    create_business_prediction, create_crypto_prediction, create_sports_prediction,
    create_test_market, setup_test_environment,
};

// ================ General Prediction Market Tests ================
// test get active prediction markets
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

// test prediction market is open
#[test]
fn test_is_prediction_market_open() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

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

    // Verify market count increased
    let count = prediction_hub.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify market is open
    let market = prediction_hub.is_prediction_market_open_for_betting(market_id);
    assert(market, 'Market should be open');
}

// ================ Crypto Prediction Market Tests ================
// test get active crypto prediction markets
#[test]
fn test_get_active_crypto_prediction_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    // Verify market count
    let count = prediction_hub.get_prediction_count();
    assert(count == 0, 'Should have 0 markets');

    let market = prediction_hub.get_active_crypto_markets();
    assert(market.len() == 0, 'Market count should be 0');

    create_crypto_prediction(prediction_hub);
    create_crypto_prediction(prediction_hub);
    create_crypto_prediction(prediction_hub);

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
    prediction_hub.resolve_crypto_prediction_manually(market_id, 1);

    stop_cheat_caller_address(prediction_hub.contract_address);

    let market = prediction_hub.get_active_crypto_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
// test get resolved crypto prediction marketss
#[test]
fn test_get_resolved_crypto_prediction_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    // Verify market count
    let count = prediction_hub.get_prediction_count();
    assert(count == 0, 'Should have 0 markets');

    let market = prediction_hub.get_resolved_crypto_markets();
    assert(market.len() == 0, 'Market count should be 0');

    create_crypto_prediction(prediction_hub);
    create_crypto_prediction(prediction_hub);

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
    assert(count == 2, 'Should have 1 markets');

    start_cheat_block_timestamp(
        prediction_hub.contract_address, get_block_timestamp() + 86400 + 3600,
    );

    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    // Resolve market
    prediction_hub.resolve_crypto_prediction_manually(market_id, 1);

    stop_cheat_caller_address(prediction_hub.contract_address);

    let market = prediction_hub.get_resolved_crypto_markets();
    assert(market.len() == 1, 'resolve count should be 1');
}

// test crypto prediction market is open
#[test]
fn test_is_crypto_prediction_market_open() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();

    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    create_crypto_prediction(prediction_hub);

    // Fetch market_id from MarketCreated event
    let market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };

    stop_cheat_caller_address(prediction_hub.contract_address);

    // Verify market count
    let count = prediction_hub.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify crypto market data
    let crypto_market = prediction_hub.is_crypto_market_open_for_betting(market_id);
    assert(crypto_market, 'Market should be open');
}

// ================ Sports Prediction Market Tests ================
// test get active sport prediction markets
#[test]
fn test_get_active_sport_prediction_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = prediction_hub.get_active_sport_markets();
    assert(market.len() == 0, 'Market count should be 3');

    create_sports_prediction(prediction_hub);
    create_sports_prediction(prediction_hub);
    create_sports_prediction(prediction_hub);

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
    prediction_hub.resolve_sports_prediction(market_id, 1);

    stop_cheat_caller_address(prediction_hub.contract_address);

    let market = prediction_hub.get_active_sport_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
// test get resolved sport prediction markets
#[test]
fn test_get_resolved_sport_prediction_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = prediction_hub.get_resolved_sport_markets();
    assert(market.len() == 0, 'Market count should be 3');

    create_sports_prediction(prediction_hub);
    create_sports_prediction(prediction_hub);

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
    assert(count == 2, 'Should have 2 markets');

    start_cheat_block_timestamp(
        prediction_hub.contract_address, get_block_timestamp() + 86400 + 3600,
    );

    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    // Resolve market
    prediction_hub.resolve_sports_prediction(market_id, 1);

    stop_cheat_caller_address(prediction_hub.contract_address);

    let market = prediction_hub.get_resolved_sport_markets();
    assert(market.len() == 1, 'resolve count should be 1');
}
// test sport prediction market is open
#[test]
fn test_is_sport_prediction_market_open() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    create_sports_prediction(prediction_hub);

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

    // Verify market count increased
    let count = prediction_hub.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify market is open
    let market = prediction_hub.is_sport_market_open_for_betting(market_id);
    assert(market, 'Market should be open');
}

// ================ Business Prediction Market Tests ================
// test get resolved  business prediction markets
#[test]
fn test_get_active_business_prediction_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = prediction_hub.get_active_business_markets();
    assert(market.len() == 0, 'Market count should be 3');

    create_business_prediction(prediction_hub);
    create_business_prediction(prediction_hub);
    create_business_prediction(prediction_hub);

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
    prediction_hub.resolve_business_prediction_manually(market_id, 1);

    stop_cheat_caller_address(prediction_hub.contract_address);

    let market = prediction_hub.get_active_business_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
// test get resolved business prediction markets
#[test]
fn test_get_resolved_business_prediction_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = prediction_hub.get_resolved_business_markets();
    assert(market.len() == 0, 'Market count should be 3');

    create_business_prediction(prediction_hub);
    create_business_prediction(prediction_hub);

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
    assert(count == 2, 'Should have 2 markets');

    start_cheat_block_timestamp(
        prediction_hub.contract_address, get_block_timestamp() + 86400 + 3600,
    );

    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    // Resolve market
    prediction_hub.resolve_business_prediction_manually(market_id, 1);

    stop_cheat_caller_address(prediction_hub.contract_address);

    let market = prediction_hub.get_resolved_business_markets();
    assert(market.len() == 1, 'resolve count should be 1');
}
// test business prediction market is open
#[test]
fn test_is_business_prediction_market_open() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    create_business_prediction(prediction_hub);

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

    // Verify market count increased
    let count = prediction_hub.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify market is open
    let market = prediction_hub.is_business_market_open_for_betting(market_id);
    assert(market, 'Market should be open');
}


//test if emergency close market is working. And a closed market does not show up in the
//get_active_prediction_markets()
#[test]
fn test_emergencyclose_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    create_test_market(prediction_hub);
    let market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };
    let market = prediction_hub.get_active_prediction_markets();
    assert(market.len() == 1, 'active Market count should be 1');

    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    _admin_interface.emergency_close_market(market_id, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);
    let market = prediction_hub.get_active_prediction_markets();
    assert(market.len() == 0, 'active Market count should be 0');
}
//test if emergency resolve market is working. Admin can resolve market before it ends
#[test]
fn test_emergency_resolve_market() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    create_test_market(prediction_hub);
    let market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    // Verify market is active and not resolved
    let market = prediction_hub.get_active_prediction_markets();
    assert(market.len() == 1, 'active Market count should be 1');

    let prediction = prediction_hub.get_prediction(market_id);
    assert(!prediction.is_resolved, 'Dont resolved yet');

    // Admin emergency resolves the market before it ends
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    _admin_interface
        .emergency_resolve_market(market_id, 0, 0); // Resolve with choice 0 (Yes) as winner
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Verify market is now resolved and moved to resolved markets
    let active_markets = prediction_hub.get_active_prediction_markets();
    assert(active_markets.len() == 0, 'active Market count should be 0');

    let resolved_markets = prediction_hub.get_resolved_prediction_markets();
    assert(resolved_markets.len() == 1, 'resolved count should be 1');

    let resolved_prediction = prediction_hub.get_prediction(market_id);
    assert(resolved_prediction.is_resolved, 'Market should be resolved');
    assert(!resolved_prediction.is_open, 'Market should be closed');

    // Verify winning choice is set correctly
    let winning_choice = resolved_prediction.winning_choice.unwrap();
    assert(winning_choice.label == 'Yes', 'Winning choice should be Yes');
}

//test if batch emergency resolve market is working. Admin can resolve multiple markets before they
//end
#[test]
fn test_emergency_resolve_multiple_markets() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    // Create multiple markets
    create_test_market(prediction_hub);
    let market_id1 = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    create_test_market(prediction_hub);

    let market_id2 = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    // Verify markets are active and not resolved
    let active_markets = prediction_hub.get_active_prediction_markets();
    assert(active_markets.len() == 2, 'active Market count should be 2');

    let prediction1 = prediction_hub.get_prediction(market_id1);
    let prediction2 = prediction_hub.get_prediction(market_id2);
    assert(!prediction1.is_resolved, 'Market 1 is not resolved yet');
    assert(!prediction2.is_resolved, 'Market 2 is not resolved yet');

    // Admin emergency resolves multiple markets before they end
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    let market_ids = array![market_id1, market_id2];
    let market_types = array![0, 0]; // Both are general prediction markets
    let winning_choices = array![0, 1]; // First market: choice 0 wins, Second market: choice 1 wins
    _admin_interface.emergency_resolve_multiple_markets(market_ids, market_types, winning_choices);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Verify markets are now resolved and moved to resolved markets
    let active_markets = prediction_hub.get_active_prediction_markets();
    assert(active_markets.len() == 0, 'active Market count should be 0');

    let resolved_markets = prediction_hub.get_resolved_prediction_markets();
    assert(resolved_markets.len() == 2, 'Market count should be 2');

    let resolved_prediction1 = prediction_hub.get_prediction(market_id1);
    let resolved_prediction2 = prediction_hub.get_prediction(market_id2);
    assert(resolved_prediction1.is_resolved, 'Market 1 should be resolved');
    assert(resolved_prediction2.is_resolved, 'Market 2 should be resolved');
    assert(!resolved_prediction1.is_open, 'Market 1 should be closed');
    assert(!resolved_prediction2.is_open, 'Market 2 should be closed');

    // Verify winning choices are set correctly
    let winning_choice1 = resolved_prediction1.winning_choice.unwrap();
    let winning_choice2 = resolved_prediction2.winning_choice.unwrap();
    assert(winning_choice1.label == 'Yes', 'Market 1 winning is Yes');
    assert(winning_choice2.label == 'No', 'Market 2 winning is No');
}


#[test]
fn test_resolve_multiple_predictions() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_active_business_markets();
    assert(market.len() == 0, 'Market count should be 0');
    // create general prediction market
    create_test_market(contract);
    // Fetch market_id from MarketCreated event
    let market_id1 = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };
    // create crypto prediction market
    create_crypto_prediction(contract);
    // Fetch market_id from MarketCreated event
    let market_id2 = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };
    // create sport prediction market
    create_sports_prediction(contract);
    // Fetch market_id from MarketCreated event
    let market_id3 = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };
    // create business prediction market
    create_business_prediction(contract);

    // Fetch market_id from MarketCreated event
    let market_id4 = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    let market = contract
        .get_active_prediction_markets(); // get general prediction active market count
    assert(market.len() == 1, 'active Market count should be 1');
    let market = contract.get_active_crypto_markets(); // get crypto active market count
    assert(market.len() == 1, 'active Market count should be 1');
    let market = contract.get_active_sport_markets(); // get sport active market count
    assert(market.len() == 1, 'active Market count should be 1');
    let market = contract.get_active_business_markets(); // get business active market count
    assert(market.len() == 1, 'active Market count should be 1');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_prediction(market_id1, 0); // BTC reaches $100k (choice 0 wins)
    contract.resolve_crypto_prediction_manually(market_id2, 1);
    contract.resolve_sports_prediction(market_id3, 1);
    contract.resolve_business_prediction_manually(market_id4, 1);

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_resolved_crypto_markets(); // get crypto resolve market count
    assert(market.len() == 1, 'resolve count should be 1');
    let market = contract
        .get_resolved_prediction_markets(); // get general prediction resolve market count
    assert(market.len() == 1, 'resolve count should be 1');

    let market = contract.get_resolved_sport_markets(); // get sport resolve market count
    assert(market.len() == 1, 'resolve count should be 1');
    let market = contract.get_resolved_business_markets(); // get business resolve market count
    assert(market.len() == 1, 'resolve count should be 1');
}
