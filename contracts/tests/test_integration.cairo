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
    MODERATOR_ADDR, USER1_ADDR, deploy_prediction_contract, deploy_test_token,
    setup_test_environment, turn_number_to_precision_point,
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

    let expected_stake_event = events::Event::MarketCreated(
        MarketCreated { market_id: 0, creator: MODERATOR_ADDR(), market_type: 1 },
    );
    spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_stake_event)]);

    let mut market_id = 0;

    if let Some((_, event)) = spy_events.get_events().events.into_iter().last() {
        market_id = (*event.data.at(0)).into();
    }
    // user 1 stakes on the prediction market
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.buy_shares(market_id, 0, turn_number_to_precision_point(10));
    stop_cheat_caller_address(prediction_hub.contract_address);
    // let expected_stake_event = events::Event::WagerPlaced(
//     WagerPlaced { market_id: 0, user: USER1_ADDR(), choice: 0, amount: 1000000000000000000 },
// );
// spy_events.assert_emitted(@array![(prediction_hub.contract_address, expected_stake_event)]);
}
