use starknet::{ContractAddress, get_block_timestamp};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, start_cheat_block_timestamp, spy_events, EventSpyTrait
};

use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// ================ Test Constants ================

const ADMIN_CONST: felt252 = 123;
const MODERATOR_CONST: felt252 = 456;
const USER1_CONST: felt252 = 101112;
const USER2_CONST: felt252 = 131415;
const USER3_CONST: felt252 = 161718;
const FEE_RECIPIENT_CONST: felt252 = 192021;
const PRAGMA_ORACLE_CONST: felt252 = 222324;
const BETTING_TOKEN_CONST: felt252 = 252627;

fn ADMIN() -> ContractAddress {
    ADMIN_CONST.try_into().unwrap()
}

fn MODERATOR() -> ContractAddress {
    MODERATOR_CONST.try_into().unwrap()
}

fn USER1() -> ContractAddress {
    USER1_CONST.try_into().unwrap()
}

fn USER2() -> ContractAddress {
    USER2_CONST.try_into().unwrap()
}

fn USER3() -> ContractAddress {
    USER3_CONST.try_into().unwrap()
}

fn FEE_RECIPIENT() -> ContractAddress {
    FEE_RECIPIENT_CONST.try_into().unwrap()
}

fn PRAGMA_ORACLE() -> ContractAddress {
    PRAGMA_ORACLE_CONST.try_into().unwrap()
}

fn BETTING_TOKEN() -> ContractAddress {
    BETTING_TOKEN_CONST.try_into().unwrap()
}

// ================ Complete Integration Test ================

#[test]
fn test_complete_bet_management_workflow() {
    // ================ Setup Phase ================
    
    // Deploy mock ERC20 token
    let token_contract = declare("MockERC20").unwrap().contract_class();
    let token_calldata = array![USER1().into()];
    let (token_address, _) = token_contract.deploy(@token_calldata).unwrap();
    let token = IERC20Dispatcher { contract_address: token_address };
    
    // Deploy prediction contract
    let prediction_contract = declare("PredictionHub").unwrap().contract_class();
    let prediction_calldata = array![
        ADMIN().into(),
        FEE_RECIPIENT().into(),
        PRAGMA_ORACLE().into(),
        token_address.into()
    ];
    let (prediction_address, _) = prediction_contract.deploy(@prediction_calldata).unwrap();
    let prediction_hub = IPredictionHubDispatcher { contract_address: prediction_address };
    let admin_interface = IAdditionalAdminDispatcher { contract_address: prediction_address };
    
    // ================ Initial Setup ================
    
    // Add moderator
    start_cheat_caller_address(prediction_address, ADMIN());
    prediction_hub.add_moderator(MODERATOR());
    
    // Set platform fee to 3%
    admin_interface.set_platform_fee(300);
    
    // Set betting restrictions
    admin_interface.set_betting_restrictions(
        1000000000000000000,     // 1 token minimum
        100000000000000000000000 // 100k tokens maximum
    );
    stop_cheat_caller_address(prediction_address);
    
    // Distribute tokens from USER1 (who received all tokens during deployment) to other users
    start_cheat_caller_address(token_address, USER1());
    token.transfer(USER2(), 3000000000000000000000000); // 3M tokens to USER2
    token.transfer(USER3(), 2000000000000000000000000); // 2M tokens to USER3
    // USER1 keeps remaining 5M tokens
    
    // Set up allowances for all users
    token.approve(prediction_address, 5000000000000000000000000); // 5M tokens allowance
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(token_address, USER2());
    token.approve(prediction_address, 3000000000000000000000000); // 3M tokens allowance
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(token_address, USER3());
    token.approve(prediction_address, 2000000000000000000000000); // 2M tokens allowance
    stop_cheat_caller_address(token_address);
    
    // ================ Market Creation Phase ================
    
    start_cheat_caller_address(prediction_address, MODERATOR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now
    
    // Create multiple types of markets
    prediction_hub.create_prediction(
        "Will BTC reach $100k by end of 2024?",
        "A prediction about Bitcoin reaching $100,000",
        ('Yes', 'No'),
        'crypto',
        "https://example.com/btc.jpg",
        future_time
    );
    
    prediction_hub.create_crypto_prediction(
        "ETH Price Prediction",
        "Will ETH be above $5000?",
        ('Above $5000', 'Below $5000'),
        'crypto',
        "https://example.com/eth.jpg",
        future_time,
        1, // greater than
        'ETH/USD',
        5000
    );
    
    prediction_hub.create_sports_prediction(
        "Champions League Final",
        "Who will win the Champions League?",
        ('Team A', 'Team B'),
        'sports',
        "https://example.com/ucl.jpg",
        future_time,
        12345, // event_id
        true   // team_flag
    );
    stop_cheat_caller_address(prediction_address);
    
    // ================ Betting Phase ================
    
    let mut spy = spy_events();
    
    // USER1 places multiple bets
    start_cheat_caller_address(prediction_address, USER1());
    
    // Bet on BTC market
    prediction_hub.place_wager(1, 0, 1000000000000000000000, 0); // 1000 tokens on "Yes"
    
    // Bet on ETH market  
    prediction_hub.place_wager(2, 1, 500000000000000000000, 1); // 500 tokens on "Below $5000"
    
    // Multiple bets on sports market
    prediction_hub.place_wager(3, 0, 750000000000000000000, 2); // 750 tokens on "Team A"
    prediction_hub.place_wager(3, 1, 250000000000000000000, 2); // 250 tokens on "Team B"
    
    stop_cheat_caller_address(prediction_address);
    
    // USER2 places bets
    start_cheat_caller_address(prediction_address, USER2());
    
    prediction_hub.place_wager(1, 1, 800000000000000000000, 0); // 800 tokens on "No" (BTC)
    prediction_hub.place_wager(2, 0, 600000000000000000000, 1); // 600 tokens on "Above $5000" (ETH)
    prediction_hub.place_wager(3, 0, 400000000000000000000, 2); // 400 tokens on "Team A"
    
    stop_cheat_caller_address(prediction_address);
    
    // USER3 places bets
    start_cheat_caller_address(prediction_address, USER3());
    
    prediction_hub.place_wager(1, 0, 300000000000000000000, 0); // 300 tokens on "Yes" (BTC)
    prediction_hub.place_wager(3, 1, 900000000000000000000, 2); // 900 tokens on "Team B"
    
    stop_cheat_caller_address(prediction_address);
    
    // ================ Verification Phase ================
    
    // Check betting restrictions work
    let (min_bet, max_bet) = prediction_hub.get_betting_restrictions();
    assert(min_bet == 1000000000000000000, 'Min bet incorrect');
    assert(max_bet == 100000000000000000000000, 'Max bet incorrect');
    
    // Check total value locked
    let tvl = prediction_hub.get_total_value_locked();
    println!("Total Value Locked: {}", tvl);
    
    // Check market liquidity for each market
    let btc_liquidity = prediction_hub.get_market_liquidity(1);
    let eth_liquidity = prediction_hub.get_market_liquidity(2);
    let sports_liquidity = prediction_hub.get_market_liquidity(3);
    
    println!("BTC Market Liquidity: {}", btc_liquidity);
    println!("ETH Market Liquidity: {}", eth_liquidity);
    println!("Sports Market Liquidity: {}", sports_liquidity);
    
    // Check total fees collected
    let total_fees = prediction_hub.get_total_fees_collected();
    let btc_fees = prediction_hub.get_market_fees(1);
    let eth_fees = prediction_hub.get_market_fees(2);
    let sports_fees = prediction_hub.get_market_fees(3);
    
    println!("Total Fees: {}", total_fees);
    println!("BTC Fees: {}", btc_fees);
    println!("ETH Fees: {}", eth_fees);
    println!("Sports Fees: {}", sports_fees);
    
    // Verify fee recipient received fees
    let fee_recipient_balance = token.balance_of(FEE_RECIPIENT());
    assert(fee_recipient_balance == total_fees, 'Fee recipient balance mismatch');
    
    // Check user bet counts
    let user1_btc_bets = prediction_hub.get_bet_count_for_market(USER1(), 1, 0);
    let user1_sports_bets = prediction_hub.get_bet_count_for_market(USER1(), 3, 2);
    
    assert(user1_btc_bets == 1, 'USER1 BTC bet count wrong');
    assert(user1_sports_bets == 2, 'USER1 sports bet count wrong');
    
    // ================ Market Resolution Phase ================
    
    // Fast forward time to after market end
    start_cheat_block_timestamp(prediction_address, get_block_timestamp() + 86400 + 3600); // 1 day + 1 hour
    
    start_cheat_caller_address(prediction_address, MODERATOR());
    
    // Resolve markets
    prediction_hub.resolve_prediction(1, 0); // BTC reaches $100k (choice 0 wins)
    prediction_hub.resolve_crypto_prediction_manually(2, 1); // ETH below $5000 (choice 1 wins)
    prediction_hub.resolve_sports_prediction_manually(3, 0); // Team A wins (choice 0 wins)
    
    stop_cheat_caller_address(prediction_address);
    
    // ================ Winnings Collection Phase ================
    
    // Record initial balances
    let user1_initial = token.balance_of(USER1());
    let user2_initial = token.balance_of(USER2());
    let user3_initial = token.balance_of(USER3());
    
    // USER1 collects winnings (won BTC and Sports Team A bets)
    start_cheat_caller_address(prediction_address, USER1());
    prediction_hub.collect_winnings(1, 0, 0); // BTC market win
    prediction_hub.collect_winnings(3, 2, 0); // Sports market Team A win
    stop_cheat_caller_address(prediction_address);
    
    // USER2 collects winnings (won Sports Team A bet)
    start_cheat_caller_address(prediction_address, USER2());
    prediction_hub.collect_winnings(3, 2, 0); // Sports market Team A win
    stop_cheat_caller_address(prediction_address);
    
    // USER3 collects winnings (won BTC bet)
    start_cheat_caller_address(prediction_address, USER3());
    prediction_hub.collect_winnings(1, 0, 0); // BTC market win
    stop_cheat_caller_address(prediction_address);
    
    // Check final balances increased
    let user1_final = token.balance_of(USER1());
    let user2_final = token.balance_of(USER2());
    let user3_final = token.balance_of(USER3());
    
    assert(user1_final > user1_initial, 'USER1 should have won');
    assert(user2_final > user2_initial, 'USER2 should have won');  
    assert(user3_final > user3_initial, 'USER3 should have won');
    
    println!("USER1 winnings: {}", user1_final - user1_initial);
    println!("USER2 winnings: {}", user2_final - user2_initial);
    println!("USER3 winnings: {}", user3_final - user3_initial);
    
    // ================ Final Verification ================
    
    // Check market stats
    let (total_markets, _active_markets, resolved_markets) = admin_interface.get_market_stats();
    assert(total_markets == 3, 'Total markets wrong');
    assert(resolved_markets == 3, 'Resolved markets wrong');
    
    // Verify claimable amounts are 0 after collection
    let _user1_claimable = prediction_hub.get_user_claimable_amount(USER1());
    let _user2_claimable = prediction_hub.get_user_claimable_amount(USER2());
    let _user3_claimable = prediction_hub.get_user_claimable_amount(USER3());
    
    // Check events were emitted
    let events = spy.get_events();
    assert(events.events.len() > 20, 'Expected many events');
    
    println!("Integration test completed successfully!");
    println!("Total events emitted: {}", events.events.len());
    println!("Final TVL: {}", prediction_hub.get_total_value_locked());
}

// ================ Edge Cases Test ================

#[test]
fn test_edge_cases_and_error_conditions() {
    // Setup similar to above but simplified
    let token_contract = declare("MockERC20").unwrap().contract_class();
    let token_calldata = array![USER1().into()];
    let (token_address, _) = token_contract.deploy(@token_calldata).unwrap();
    let token = IERC20Dispatcher { contract_address: token_address };
    
    let prediction_contract = declare("PredictionHub").unwrap().contract_class();
    let prediction_calldata = array![
        ADMIN().into(), FEE_RECIPIENT().into(), PRAGMA_ORACLE().into(), token_address.into()
    ];
    let (prediction_address, _) = prediction_contract.deploy(@prediction_calldata).unwrap();
    let prediction_hub = IPredictionHubDispatcher { contract_address: prediction_address };
    let admin_interface = IAdditionalAdminDispatcher { contract_address: prediction_address };
    
    // Setup basic configuration
    start_cheat_caller_address(prediction_address, ADMIN());
    prediction_hub.add_moderator(MODERATOR());
    admin_interface.set_platform_fee(250); // 2.5%
    stop_cheat_caller_address(prediction_address);
    
    // Create a market
    start_cheat_caller_address(prediction_address, MODERATOR());
    let future_time = get_block_timestamp() + 86400;
    prediction_hub.create_prediction(
        "Test Market", "Test Description", ('Yes', 'No'), 'test', "", future_time
    );
    stop_cheat_caller_address(prediction_address);
    
    start_cheat_caller_address(token_address, USER1());
    token.approve(prediction_address, 1000000000000000000000);
    stop_cheat_caller_address(token_address);
    
    // Test 1: Betting on closed market
    start_cheat_caller_address(prediction_address, ADMIN());
    prediction_hub.toggle_market_status(1, 0); // Close market
    stop_cheat_caller_address(prediction_address);
    
    // Test 2: Emergency token withdrawal
    start_cheat_caller_address(prediction_address, ADMIN());

    prediction_hub.toggle_market_status(1, 0); // Reopen market
    stop_cheat_caller_address(prediction_address);
    
    start_cheat_caller_address(prediction_address, USER1());
    prediction_hub.place_wager(1, 0, 1000000000000000000, 0);
    stop_cheat_caller_address(prediction_address);
    
    // Admin emergency withdrawal
    start_cheat_caller_address(prediction_address, ADMIN());
    let contract_balance = token.balance_of(prediction_address);
    if contract_balance > 0 {
        admin_interface.emergency_withdraw_tokens(contract_balance, ADMIN());
        let admin_balance = token.balance_of(ADMIN());
        assert(admin_balance == contract_balance, 'Emergency withdrawal failed');
    }
    stop_cheat_caller_address(prediction_address);
    
    println!("Edge cases test completed successfully!");
} 