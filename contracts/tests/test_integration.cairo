use core::array::ArrayTrait;
use core::felt252;
use core::traits::{Into, TryInto};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, EventSpyTrait, declare,
    spy_events, start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_block_timestamp,
    stop_cheat_caller_address,
};
use stakcast::admin_interface::{
    IAdditionalAdmin, IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait,
};
use stakcast::events;
use stakcast::events::{
    BetPlaced, EmergencyPaused, FeesCollected, MarketCreated, MarketEmergencyClosed, MarketExtended,
    MarketForceClosed, MarketModified, MarketResolved, ModeratorAdded, ModeratorRemoved,
    WagerPlaced, WinningsCollected,
};
use stakcast::interface::{IPredictionHub, IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::prediction::PredictionHub;
use stakcast::types::{
    BetActivity, Choice, MarketCategory, MarketStats, MarketStatus, Outcome, PredictionMarket,
    StakingActivity, UserDashboard, UserStake, num_to_market_category,
};
use starknet::{ContractAddress, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR, deploy_prediction_contract,
    deploy_test_token, setup_test_environment, turn_number_to_precision_point,
};

#[test]
fn test_pool_creation_staking_resolution_claim_flow() {
    let (prediction_hub, admin_interface, token) = setup_test_environment();
    let mut spy_events = spy_events();

    let now = get_block_timestamp();
    start_cheat_block_timestamp(prediction_hub.contract_address, now);
    // create a prediction market
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub
        .create_predictions(
            "Will Arsenal win the premier league this season?",
            "A market bringing options weather arsenal win the premier league this season",
            "https://imgs.search.brave.com/Bkq4xMzdpvbCQ5mUhA42_uq8z8IGE3PcohDc5FPY-Ys/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9sb2dv/cy13b3JsZC5uZXQv/d3AtY29udGVudC91/cGxvYWRzLzIwMjAv/MDUvQXJzZW5hbC1M/b25kb24tTG9nby03/MDB4Mzk0LnBuZw",
            ('yes', 'no'),
            0,
            now + 172800, // end time of 2 days
            1,
            None,
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    let mut market_id = 0;

    if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
        market_id = (*event.data.at(0)).into();
    }

    // verify we have an open market
    let open_markets = prediction_hub.get_all_open_markets();
    assert(open_markets.len() == 1, 'should have 1 open market');

    let expected_stake_event = events::Event::MarketCreated(
        MarketCreated { market_id, creator: MODERATOR_ADDR(), market_type: 1 },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_stake_event)]);

    // user 1 stakes on the prediction market
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // verify total value held
    let total_value_held = prediction_hub.get_total_value_held();
    assert(total_value_held == turn_number_to_precision_point(10), 'total value held should be 10');

    // verify staking event
    let expected_stake_event = events::Event::WagerPlaced(
        WagerPlaced {
            market_id, user: USER1_ADDR(), choice: 0, amount: turn_number_to_precision_point(10),
        },
    );

    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_stake_event)]);

    // user 2 stakes on the prediction market
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.buy_shares(market_id, 1, turn_number_to_precision_point(20));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // verify total value held
    let total_value_held = prediction_hub.get_total_value_held();
    assert(total_value_held == turn_number_to_precision_point(30), 'total value held should be 30');

    // verify staking event
    let expected_stake_event = events::Event::WagerPlaced(
        WagerPlaced {
            market_id, user: USER2_ADDR(), choice: 1, amount: turn_number_to_precision_point(20),
        },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_stake_event)]);

    // fast forward to end of market
    start_cheat_block_timestamp(prediction_hub.contract_address, now + 172801);
    // resolve the market
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    prediction_hub.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // verify resolved event
    let expected_stake_event = events::Event::MarketResolved(
        MarketResolved { market_id, resolver: ADMIN_ADDR(), winning_choice: 0 },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_stake_event)]);

    // verify we have a resolved market
    let resolved_markets = prediction_hub.get_all_resolved_markets();
    assert(resolved_markets.len() == 1, 'should have 1 resolved market');

    // verify we have a winner
    let prediction = prediction_hub.get_prediction(market_id);
    let (choice1, _) = prediction.choices;
    assert(prediction.status == MarketStatus::Resolved(choice1), 'should have a winner');

    // claim for user 1
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.claim(market_id);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // get event

    let mut claimed_amount = 0;

    if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
        claimed_amount = (*event.data.at(0)).into();
    }

    println!("claimed_amount: {:?}", claimed_amount);

    // verify claim event
    let expected_stake_event = events::Event::WinningsCollected(
        WinningsCollected { market_id, user: USER1_ADDR(), amount: claimed_amount },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_stake_event)]);
}


#[test]
fn test_overall_lifecycle_with_get_functions() {
    let (prediction_hub, admin_interface, token) = setup_test_environment();
    let mut spy_events = spy_events();

    // Set up base time for the test
    let base_time: u64 = 1000000;
    let pool_duration: u64 = 172800; // 2 days in seconds
    let pool_extension: u64 = 900000; // extension duration
    let after_extension = base_time + pool_extension; // new end time after extension

    // Set the block timestamp to base_time before creating the pool
    start_cheat_block_timestamp(prediction_hub.contract_address, base_time);

    // create a prediction market
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub
        .create_predictions(
            "Will Arsenal win the premier league this season?",
            "A market bringing options weather arsenal win the premier league this season",
            "https://imgs.search.brave.com/Bkq4xMzdpvbCQ5mUhA42_uq8z8IGE3PcohDc5FPY-Ys/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9sb2dv/cy13b3JsZC5uZXQv/d3AtY29udGVudC91/cGxvYWRzLzIwMjAv/MDUvQXJzZW5hbC1M/b25kb24tTG9nby03/MDB4Mzk0LnBuZw",
            ('yes', 'no'),
            0,
            base_time + pool_duration, // end time of 2 days from base_time
            1,
            None,
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    let mut market_id = 0;

    // The first event should be MarketCreated
    if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
        market_id = (*event.data.at(0)).into();
    }

    // verify we have an open market
    let open_markets = prediction_hub.get_all_open_markets();
    assert(open_markets.len() == 1, 'should have 1 open market');

    // Check MarketCreated event
    let expected_event = events::Event::MarketCreated(
        MarketCreated { market_id, creator: MODERATOR_ADDR(), market_type: 1 },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // user 1 stakes on the prediction market
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check WagerPlaced event for USER1
    let expected_event = events::Event::WagerPlaced(
        WagerPlaced {
            market_id, user: USER1_ADDR(), choice: 0, amount: turn_number_to_precision_point(10),
        },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // Fast forward to just before the original end time to extend the pool
    start_cheat_block_timestamp(prediction_hub.contract_address, base_time + pool_duration - 1);
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub.extend_market_duration(market_id, after_extension);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check MarketExtended event
    let expected_event = events::Event::MarketExtended(
        MarketExtended { market_id, new_end_time: after_extension },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // Fast forward to just after the original end time, but before the new end time
    let after_original_end = base_time + pool_duration + 3500;
    start_cheat_block_timestamp(prediction_hub.contract_address, after_original_end);
    // another person buys shares
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.buy_shares(market_id, 1, turn_number_to_precision_point(20));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check WagerPlaced event for USER2
    let expected_event = events::Event::WagerPlaced(
        WagerPlaced {
            market_id, user: USER2_ADDR(), choice: 1, amount: turn_number_to_precision_point(20),
        },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // change the description of the market
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub
        .modify_market_details(
            market_id,
            "A market bringing options weather arsenal win the premier league this season",
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check MarketModified event
    let expected_event = events::Event::MarketModified(MarketModified { market_id });
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // Fast forward to just before the new end time, allow another buy
    start_cheat_block_timestamp(prediction_hub.contract_address, after_original_end + 1000);
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.buy_shares(market_id, 1, turn_number_to_precision_point(20));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check WagerPlaced event for USER2 again
    let expected_event = events::Event::WagerPlaced(
        WagerPlaced {
            market_id, user: USER2_ADDR(), choice: 1, amount: turn_number_to_precision_point(20),
        },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // Fast forward to after the extended end time to resolve the pool
    let after_final_end = after_extension + 1;
    start_cheat_block_timestamp(prediction_hub.contract_address, after_final_end);
    // resolve the market
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    prediction_hub.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check MarketResolved event
    let expected_event = events::Event::MarketResolved(
        MarketResolved { market_id, resolver: ADMIN_ADDR(), winning_choice: 0 },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // get claim status
    let claim_status = prediction_hub.get_user_claim_status(market_id, USER1_ADDR());
    assert(!claim_status, 'user should not have claim');

    // claim for user 1
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.claim(market_id);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // get claim status
    let claim_status = prediction_hub.get_user_claim_status(market_id, USER1_ADDR());
    assert(claim_status, 'user should have claim');

    // get event
    let mut claimed_amount = 0;

    // The last event should be WinningsCollected for USER1
    if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
        claimed_amount = (*event.data.at(0)).into();
    }

    // Check WinningsCollected event for USER1
    let expected_event = events::Event::WinningsCollected(
        WinningsCollected { market_id, user: USER1_ADDR(), amount: claimed_amount },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // create another prediction market, set time forward for new pool
    let new_pool_time = after_final_end + 1000;
    start_cheat_block_timestamp(prediction_hub.contract_address, new_pool_time);
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub
        .create_predictions(
            "Will  Real Madrid win the premier league this season?",
            "A market bringing options weather real madrid win the premier league this season",
            "https://imgs.search.brave.com/Bkq4xMzdpvbCQ5mUhA42_uq8z8IGE3PcohDc5FPY-Ys/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9sb2dv/cy13b3JsZC5uZXQv/d3AtY29udGVudC91/cGxvYWRzLzIwMjAv/MDUvQXJzZW5hbC1M/b25kb24tTG9nby03/MDB4Mzk0LnBuZw",
            ('yes', 'no'),
            0,
            new_pool_time + pool_duration, // end time of 2 days from new_pool_time
            1,
            None,
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    let mut market_id_2 = 0;

    // The last event should be MarketCreated for market_id_2
    if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
        market_id_2 = (*event.data.at(0)).into();
    }

    // Check MarketCreated event for market_id_2
    let expected_event = events::Event::MarketCreated(
        MarketCreated { market_id: market_id_2, creator: MODERATOR_ADDR(), market_type: 1 },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);

    // verify we have an open market
    let open_markets = prediction_hub.get_all_open_markets();
    assert(open_markets.len() == 1, 'should have 1 open markets');

    let details: Array<ByteArray> = array![
        "Will Arsenal win the premier league this season?",
        "Will Real Madrid win the premier league this season?",
        "Will Barcelona win the premier league this season?",
        "Will Manchester United win the premier league this season?",
        "Will Chelsea win the premier league this season?",
    ];

    // create 5 prediction markets, increment time for each to avoid timestamp collision
    let mut create_time = new_pool_time + 1000;
    let mut created_market_ids = array![];
    for i in 0..details.len() {
        start_cheat_block_timestamp(prediction_hub.contract_address, create_time);
        prediction_hub
            .create_predictions(
                details.at(i).clone(),
                "this is a market for sports prediction for the premier leaugue",
                "https://imgs.search.brave.com/Bkq4xMzdpvbCQ5mUhA42_uq8z8IGE3PcohDc5FPY-Ys/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9sb2dv/cy13b3JsZC5uZXQv/d3AtY29udGVudC91/cGxvYWRzLzIwMjAv/MDUvQXJzZW5hbC1M/b25kb24tTG9nby03/MDB4Mzk0LnBuZw",
                ('yes', 'no'),
                0,
                create_time + 345600, // end time of 4 days from create_time
                1,
                None,
            );
        // The last event should be MarketCreated for each new market
        if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
            let new_market_id = (*event.data.at(0)).into();
            created_market_ids.append(new_market_id);
            let expected_event = events::Event::MarketCreated(
                MarketCreated {
                    market_id: new_market_id, creator: MODERATOR_ADDR(), market_type: 1,
                },
            );
            spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_event)]);
        }
        create_time += 1000; // increment time for next market
    }

    // check that the number of open markets is 7
    let open_markets = prediction_hub.get_all_open_markets();
    assert(open_markets.len() == 7, 'should have 7 open markets');

    // check that the number of resolved markets is 1
    let resolved_markets = prediction_hub.get_all_resolved_markets();
    assert(resolved_markets.len() == 1, 'should have 1 resolved markets');

    // get all predictions created
    let predictions = prediction_hub.get_all_predictions();
    assert(predictions.len() == 8, 'should have 8 predictions');

    // assert all prediction count is 8
    let prediction_count = prediction_hub.get_prediction_count();
    assert(prediction_count == 8, 'should have 8 predictions');
}

fn create_stake(prediction_hub: IPredictionHubDispatcher) -> u256 {
    let mut spy_events = spy_events();
    let now = get_block_timestamp();
    start_cheat_block_timestamp(prediction_hub.contract_address, now);
    // create a prediction market
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub
        .create_predictions(
            "Will Arsenal win the premier league this season?",
            "A market bringing options weather arsenal win the premier league this season",
            "https://imgs.search.brave.com/Bkq4xMzdpvbCQ5mUhA42_uq8z8IGE3PcohDc5FPY-Ys/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9sb2dv/cy13b3JsZC5uZXQv/d3AtY29udGVudC91/cGxvYWRzLzIwMjAv/MDUvQXJzZW5hbC1M/b25kb24tTG9nby03/MDB4Mzk0LnBuZw",
            ('yes', 'no'),
            0,
            now + 172800, // end time of 2 days
            1,
            None,
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    let mut market_id = 0;

    if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
        market_id = (*event.data.at(0)).into();
    }

    // user 1 stakes on the prediction market
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(prediction_hub.contract_address);

    return market_id;
}

#[test]
fn test_market_status_functionality_integrated() {
    let (prediction_hub, admin_interface, token) = setup_test_environment();
    let mut spy_events = spy_events();

    let now = get_block_timestamp();
    start_cheat_block_timestamp(prediction_hub.contract_address, now);

    let market_id = create_stake(prediction_hub);
    // test get market status
    let (is_open, is_resolved) = prediction_hub.get_market_status(market_id);
    assert(is_open, 'market should be open');
    assert(!is_resolved, 'market should not be locked');

    // get all open markets
    let open_markets = prediction_hub.get_all_open_markets();
    assert(open_markets.len() == 1, 'should have 1 open market');

    // get_all_users_in_market
    let users = prediction_hub.get_all_users_in_market(market_id);
    assert(users.len() == 1, 'should have 1 user in market');

    // user 2 stakes in the market
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.buy_shares(market_id, 1, turn_number_to_precision_point(20));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // get all users after
    let users = prediction_hub.get_all_users_in_market(market_id);
    assert(users.len() == 2, 'should have 2 users in market');

    // fast forward to end of market
    start_cheat_block_timestamp(prediction_hub.contract_address, now + 172801);

    // check a prediction market open for betting
    let (is_open, is_resolved) = prediction_hub.get_market_status(market_id);
    assert(is_open, 'market should be open');

    // resolve the market
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    prediction_hub.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // check a prediction market open for betting
    let (is_open, is_resolved) = prediction_hub.get_market_status(market_id);
    assert(!is_open, 'market should not be open');

    // get all resolved markets
    let resolved_markets = prediction_hub.get_all_resolved_markets();
    assert(resolved_markets.len() == 1, 'should have 1 resolved market');
}

#[test]
fn test_user_details_integration() {
    let (prediction_hub, admin_interface, token) = setup_test_environment();
    let mut spy_events = spy_events();

    let now = get_block_timestamp();
    start_cheat_block_timestamp(prediction_hub.contract_address, now);

    let market_id = create_stake(prediction_hub);

    // get all closed bets for user 1
    let closed_bets = prediction_hub.get_all_closed_bets_for_user(USER1_ADDR());
    assert(closed_bets.len() == 0, 'should have 0 closed bet');

    // get all open bets for user 1
    let open_bets = prediction_hub.get_all_open_bets_for_user(USER1_ADDR());
    assert(open_bets.len() == 1, 'should have 1 open bet');

    // moderator resolves
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub.resolve_prediction(market_id, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // get all closed bets for user 1
    let closed_bets = prediction_hub.get_all_closed_bets_for_user(USER1_ADDR());
    assert(closed_bets.len() == 1, 'should have 1 closed bet');

    // get all open bets for user 1
    let open_bets = prediction_hub.get_all_open_bets_for_user(USER1_ADDR());
    assert(open_bets.len() == 0, 'should have 0 open bet');

    // get all bets for user 1
    let all_bets = prediction_hub.get_all_bets_for_user(USER1_ADDR());
    assert(all_bets.len() == 1, 'should have 1 bet');

    // get all bets for user 2
    let all_bets = prediction_hub.get_all_bets_for_user(USER2_ADDR());
    assert(all_bets.len() == 0, 'should have 0 bet');

    // create another market
    start_cheat_block_timestamp(prediction_hub.contract_address, now);
    // create a prediction market
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    prediction_hub
        .create_predictions(
            "Will Arsenal win the premier league this season?",
            "A market bringing options weather arsenal win the premier league this season",
            "https://imgs.search.brave.com/Bkq4xMzdpvbCQ5mUhA42_uq8z8IGE3PcohDc5FPY-Ys/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9sb2dv/cy13b3JsZC5uZXQv/d3AtY29udGVudC91/cGxvYWRzLzIwMjAv/MDUvQXJzZW5hbC1M/b25kb24tTG9nby03/MDB4Mzk0LnBuZw",
            ('yes', 'no'),
            0,
            now + 172800, // end time of 2 days
            1,
            None,
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    // user 1 buys shares
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // get all bets for user 1
    let all_bets = prediction_hub.get_all_bets_for_user(USER1_ADDR());
    assert(all_bets.len() == 2, 'should have 2 bet');

    // user 1 buys shares again
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.buy_shares(market_id, 1, turn_number_to_precision_point(10));
    stop_cheat_caller_address(prediction_hub.contract_address);

    // get all bets for user 1
    let all_bets = prediction_hub.get_all_bets_for_user(USER1_ADDR());
    assert(all_bets.len() == 2, 'should have 2 bet');
}
