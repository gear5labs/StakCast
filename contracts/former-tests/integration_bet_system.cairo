use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR, USER3_ADDR,
    create_business_prediction, create_crypto_prediction, create_sports_prediction,
    create_test_market, setup_test_environment,
};

// Helper function for general prediction market with customizable parameters
fn create_market_and_get_id(
    contract: IPredictionHubDispatcher,
    caller: ContractAddress,
    future_time: u64,
    title: ByteArray,
    description: ByteArray,
    category: felt252,
    image_url: ByteArray,
) -> u256 {
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, caller);
    contract.create_prediction(title, description, ('Yes', 'No'), category, image_url, future_time);
    let market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };
    stop_cheat_caller_address(contract.contract_address);
    market_id
}

// ================ Complete Integration Test ================

#[test]
fn test_complete_bet_management_workflow() {
    let (prediction_hub, admin_interface, token) = setup_test_environment();
    let mut spy = spy_events();
    // ================ Initial Setup ================

    // Add moderator
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());

    // Set platform fee to 3%
    admin_interface.set_platform_fee(300);

    // Set betting restrictions
    admin_interface
        .set_betting_restrictions(
            1000000000000000000, // 1 token minimum
            100000000000000000000000 // 100k tokens maximum
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Distribute tokens from USER1 (who received all tokens during deployment) to other users
    start_cheat_caller_address(token.contract_address, USER1_ADDR());
    token.transfer(USER2_ADDR(), 3000000000000000000000000); // 3M tokens to USER2
    token.transfer(USER3_ADDR(), 2000000000000000000000000); // 2M tokens to USER3
    // USER1 keeps remaining 5M tokens

    // Set up allowances for all users
    token
        .approve(prediction_hub.contract_address, 5000000000000000000000000); // 5M tokens allowance
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(token.contract_address, USER2_ADDR());
    token
        .approve(prediction_hub.contract_address, 3000000000000000000000000); // 3M tokens allowance
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(token.contract_address, USER3_ADDR());
    token
        .approve(prediction_hub.contract_address, 2000000000000000000000000); // 2M tokens allowance
    stop_cheat_caller_address(token.contract_address);

    // ================ Market Creation Phase ================

    // start_cheat_caller_address(prediction_address, MODERATOR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    // Create one market (BTC) and get the ID from the event
    create_test_market(prediction_hub);
    let btc_market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };
    println!("BTC Market ID: {}", btc_market_id);

    // Verify market exists
    let btc_liquidity = prediction_hub.get_market_liquidity(btc_market_id);
    println!("BTC Market Liquidity after creation: {}", btc_liquidity);
    assert(btc_liquidity == 0, 'Liquidity must be 0 before bets');

    // ================ Betting Phase ================

    let mut spy = spy_events();

    // USER1 places multiple bets
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_wager(btc_market_id, 0, 1000000000000000000000, 0); // 1000 tokens on "Yes"
    stop_cheat_caller_address(prediction_hub.contract_address);

    // USER2 places bets
    start_cheat_caller_address(prediction_hub.contract_address, USER2_ADDR());
    prediction_hub.place_wager(btc_market_id, 1, 800000000000000000000, 0); // 800 tokens on "No"
    stop_cheat_caller_address(prediction_hub.contract_address);

    // USER3 places bets
    start_cheat_caller_address(prediction_hub.contract_address, USER3_ADDR());
    prediction_hub.place_wager(btc_market_id, 0, 300000000000000000000, 0); // 300 tokens on "Yes"
    stop_cheat_caller_address(prediction_hub.contract_address);

    // ================ Verification Phase ================

    // Check betting restrictions work
    let (min_bet, max_bet) = prediction_hub.get_betting_restrictions();
    assert(min_bet == 1000000000000000000, 'Min bet incorrect');
    assert(max_bet == 100000000000000000000000, 'Max bet incorrect');

    // Check total value locked
    let tvl = prediction_hub.get_total_value_locked();
    println!("Total Value Locked: {}", tvl);

    // Check market liquidity for each market
    // let btc_liquidity = prediction_hub.get_market_liquidity(1);
    // let eth_liquidity = prediction_hub.get_market_liquidity(2);
    // let sports_liquidity = prediction_hub.get_market_liquidity(3);

    // Check market liquidity
    let btc_liquidity = prediction_hub.get_market_liquidity(btc_market_id);
    println!("BTC Market Liquidity: {}", btc_liquidity);

    // Check total fees collected
    let total_fees = prediction_hub.get_total_fees_collected();
    let btc_fees = prediction_hub.get_market_fees(btc_market_id);
    // let eth_fees = prediction_hub.get_market_fees(2);
    // let sports_fees = prediction_hub.get_market_fees(3);

    println!("Total Fees: {}", total_fees);
    println!("BTC Fees: {}", btc_fees);
    // println!("ETH Fees: {}", eth_fees);
    // println!("Sports Fees: {}", sports_fees);

    // Verify fee recipient received fees
    let fee_recipient_balance = token.balance_of(FEE_RECIPIENT_ADDR());
    assert(fee_recipient_balance == total_fees, 'Fee recipient balance mismatch');

    // Check user bet counts
    let user1_btc_bets = prediction_hub.get_bet_count_for_market(USER1_ADDR(), btc_market_id, 0);
    // let user1_sports_bets = prediction_hub.get_bet_count_for_market(USER1(), 3, 2);

    assert(user1_btc_bets == 1, 'USER1 BTC bet count wrong');

    // ================ Market Resolution Phase ================

    // Fast forward time to after market end
    start_cheat_block_timestamp(
        prediction_hub.contract_address, get_block_timestamp() + 86400 + 3600,
    ); // 1 day + 1 hour

    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());

    // Resolve market
    prediction_hub.resolve_prediction(btc_market_id, 0); // BTC reaches $100k (choice 0 wins)
    // prediction_hub.resolve_crypto_prediction_manually(2, 1); // ETH below $5000 (choice 1 wins)
    // prediction_hub.resolve_sports_prediction_manually(3, 0); // Team A wins (choice 0 wins)

    stop_cheat_caller_address(prediction_hub.contract_address);

    // ================ Winnings Collection Phase ================

    // Check claimable amounts before collection
    let user1_claimable = prediction_hub.get_user_claimable_amount(USER1_ADDR());
    println!("USER1 claimable: {}", user1_claimable);

    // Record initial balances
    let user1_initial = token.balance_of(USER1_ADDR());
    let user2_initial = token.balance_of(USER2_ADDR());
    let user3_initial = token.balance_of(USER3_ADDR());
    println!("USER1 initial balance: {}", user1_initial);

    // USER1 collects winnings
    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.collect_winnings(btc_market_id, 0, 0); // BTC market win
    // prediction_hub.collect_winnings(3, 2, 0); // Sports market Team A win
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Check final balances increased
    let user1_final = token.balance_of(USER1_ADDR());
    let user2_final = token.balance_of(USER2_ADDR());
    let user3_final = token.balance_of(USER3_ADDR());
    println!("USER1 final balance: {}", user1_final);
    println!("USER2 final balance: {}", user2_final);
    println!("USER3 final balance: {}", user3_final);

    assert(user1_final > user1_initial, 'USER1 should have won');
    assert(user2_final == user2_initial, 'USER2 should have no winnings');

    println!("USER1 winnings: {}", user1_final - user1_initial);
    println!("USER2 winnings: {}", user2_final - user2_initial);
    println!("USER3 winnings: {}", user3_final - user3_initial);

    // ================ Final Verification ================

    // Check market stats
    let (total_markets, _active_markets, resolved_markets) = admin_interface.get_market_stats();
    // assert(total_markets == 3, 'Total markets wrong');
    // assert(resolved_markets == 3, 'Resolved markets wrong');

    // Verify claimable amounts are 0 after collection
    // let _user1_claimable = prediction_hub.get_user_claimable_amount(USER1());
    // let _user2_claimable = prediction_hub.get_user_claimable_amount(USER2());
    // let _user3_claimable = prediction_hub.get_user_claimable_amount(USER3());

    println!("Total markets: {}, Resolved markets: {}", total_markets, resolved_markets);
    println!("Total markets: {}, Resolved markets: {}", total_markets, resolved_markets);
    // assert(total_markets == 1, 'Total markets wrong');
    // assert(resolved_markets == 1, 'Resolved markets wrong');

    // Check events were emitted
    let events = spy.get_events();
    assert(events.events.len() > 5, 'Expected multiple events');

    println!("Integration test completed successfully!");
    println!("Total events emitted: {}", events.events.len());
    println!("Final TVL: {}", prediction_hub.get_total_value_locked());
}


// ================ Edge Cases Test ================

#[test]
fn test_edge_cases_and_error_conditions() {
    let (prediction_hub, _admin_interface, _token) = setup_test_environment();
    let mut spy = spy_events();
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
    stop_cheat_caller_address(prediction_hub.contract_address);

    start_cheat_caller_address(_token.contract_address, USER1_ADDR());
    _token.approve(prediction_hub.contract_address, 1000000000000000000000);
    stop_cheat_caller_address(_token.contract_address);

    // Test 1: Betting on closed market
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    prediction_hub.toggle_market_status(market_id, 0); // Close market
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Test 2: Emergency token withdrawal
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());

    prediction_hub.toggle_market_status(market_id, 0); // Reopen market
    stop_cheat_caller_address(prediction_hub.contract_address);

    start_cheat_caller_address(prediction_hub.contract_address, USER1_ADDR());
    prediction_hub.place_wager(market_id, 0, 1000000000000000000, 0);
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Admin emergency withdrawal
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    let contract_balance = _token.balance_of(prediction_hub.contract_address);
    if contract_balance > 0 {
        _admin_interface.emergency_withdraw_tokens(contract_balance, ADMIN_ADDR());
        let admin_balance = _token.balance_of(ADMIN_ADDR());
        assert(admin_balance == contract_balance, 'Emergency withdrawal failed');
    }
    stop_cheat_caller_address(prediction_hub.contract_address);
}
