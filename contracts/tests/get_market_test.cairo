use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};

// ================ Test Constants ================

const ADMIN: felt252 = 123;
const MODERATOR: felt252 = 456;
const MODERATOR2: felt252 = 789;
const USER1: felt252 = 101112;
const USER2: felt252 = 131415;
const FEE_RECIPIENT: felt252 = 161718;
const PRAGMA_ORACLE: felt252 = 192021;

fn ADMIN_ADDR() -> ContractAddress {
    ADMIN.try_into().unwrap()
}

fn MODERATOR_ADDR() -> ContractAddress {
    MODERATOR.try_into().unwrap()
}

fn MODERATOR2_ADDR() -> ContractAddress {
    MODERATOR2.try_into().unwrap()
}

fn USER1_ADDR() -> ContractAddress {
    USER1.try_into().unwrap()
}

fn USER2_ADDR() -> ContractAddress {
    USER2.try_into().unwrap()
}

fn FEE_RECIPIENT_ADDR() -> ContractAddress {
    FEE_RECIPIENT.try_into().unwrap()
}

fn PRAGMA_ORACLE_ADDR() -> ContractAddress {
    PRAGMA_ORACLE.try_into().unwrap()
}

// ================ Test Setup ================

fn deploy_contract() -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher) {
    // Deploy mock ERC20 token
    let token_contract = declare("strktoken").unwrap().contract_class();
    let token_calldata = array![USER1_ADDR().into(), ADMIN_ADDR().into(), 18];
    let (token_address, _) = token_contract.deploy(@token_calldata).unwrap();

    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    let prediction_hub = IPredictionHubDispatcher { contract_address };
    let admin_contract = IAdditionalAdminDispatcher { contract_address };
    (prediction_hub, admin_contract)
}

fn setup_with_moderator() -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher) {
    let (contract, admin_contract) = deploy_contract();

    // Add moderator
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    contract.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    (contract, admin_contract)
}

// ================ General Prediction Market Tests ================
// test get active prediction markets
#[test]
fn test_get_active_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_active_prediction_markets();
    assert(market.len() == 0, 'Market count should be 0');

    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2026?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2026",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );

    contract
        .create_prediction(
            "Will Bitcoin reach $2000,000 by end of 2025?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2025",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );

    contract
        .create_prediction(
            "Will Solana reach $2000,000 by end of 2025?",
            "Prediction market for Solana price reaching $100,000 USD by December 31, 2025",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );
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
    let count = contract.get_prediction_count();
    assert(count == 3, 'Should have 3 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_prediction(market_id, 0); // BTC reaches $100k (choice 0 wins)

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_active_prediction_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
// test get resolved prediction markets
#[test]
fn test_get_resolved_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_active_business_markets();
    assert(market.len() == 0, 'Market count should be 0');

    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2026?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2026",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );

    contract
        .create_prediction(
            "Will Solana reach $2000,000 by end of 2025?",
            "Prediction market for Solana price reaching $100,000 USD by December 31, 2025",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );
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
    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 2 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_prediction(market_id, 0); // BTC reaches $100k (choice 0 wins)

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_resolved_prediction_markets();
    assert(market.len() == 1, 'resolve count should be 1');
}
// test prediction market is open
#[test]
fn test_is_prediction_market_open() {
    let (contract, _admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2024?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2024",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );

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
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify market is open
    let market = contract.is_prediction_market_open_for_betting(market_id);
    assert(market, 'Market should be open');
}

// ================ Crypto Prediction Market Tests ================
// test get active crypto prediction markets
#[test]
fn test_get_active_crypto_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 0, 'Should have 0 markets');

    let market = contract.get_active_crypto_markets();
    assert(market.len() == 0, 'Market count should be 0');

    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );

    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );

    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );
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
    let count = contract.get_prediction_count();
    assert(count == 3, 'Should have 3 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_crypto_prediction_manually(market_id, 1);

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_active_crypto_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
// test get resolved crypto prediction marketss
#[test]
fn test_get_resolved_crypto_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 0, 'Should have 0 markets');

    let market = contract.get_resolved_crypto_markets();
    assert(market.len() == 0, 'Market count should be 0');

    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );

    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );
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
    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 1 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_crypto_prediction_manually(market_id, 1);

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_resolved_crypto_markets();
    assert(market.len() == 1, 'resolve count should be 1');
}
// test crypto prediction market is open
#[test]
fn test_is_crypto_prediction_market_open() {
    let (contract, _admin_contract) = setup_with_moderator();
    let mut spy = spy_events();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400;

    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );

    // Fetch market_id from MarketCreated event
    let market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };

    stop_cheat_caller_address(contract.contract_address);

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify crypto market data
    let crypto_market = contract.is_crypto_market_open_for_betting(market_id);
    assert(crypto_market, 'Market should be open');
}

// ================ Sports Prediction Market Tests ================
// test get active sport prediction markets
#[test]
fn test_get_active_sport_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_active_sport_markets();
    assert(market.len() == 0, 'Market count should be 3');

    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );

    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );

    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );
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
    let count = contract.get_prediction_count();
    assert(count == 3, 'Should have 3 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_sports_prediction(market_id, 1);

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_active_sport_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
// test get resolved sport prediction markets
#[test]
fn test_get_resolved_sport_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_resolved_sport_markets();
    assert(market.len() == 0, 'Market count should be 3');

    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );

    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );
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
    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 2 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_sports_prediction(market_id, 1);

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_resolved_sport_markets();
    assert(market.len() == 1, 'resolve count should be 1');
}
// test sport prediction market is open
#[test]
fn test_is_sport_prediction_market_open() {
    let (contract, _admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );

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
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify market is open
    let market = contract.is_sport_market_open_for_betting(market_id);
    assert(market, 'Market should be open');
}

// ================ Business Prediction Market Tests ================
// test get resolved  business prediction markets
#[test]
fn test_get_active_business_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_active_business_markets();
    assert(market.len() == 0, 'Market count should be 3');

    contract
        .create_business_prediction(
            "Will Microsoft acquire a gaming company by June 2025?",
            "business Predictions for Microsoft to acquire a specific gaming company by June 2025?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            45337 // Event ID
        );

    contract
        .create_business_prediction(
            "Will Microsoft acquire a gaming company by June 2027?",
            "business Predictions for Microsoft to acquire a specific gaming company by June 2027?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            4537 // Event ID
        );

    contract
        .create_business_prediction(
            "Will Apple acquire a gaming company by June 2025?",
            "business Predictions for Apple to acquire a specific gaming company by June 2025?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            35637 // Event ID
        );

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
    let count = contract.get_prediction_count();
    assert(count == 3, 'Should have 3 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_business_prediction_manually(market_id, 1);

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_active_business_markets();
    assert(market.len() == 2, 'active Market count should be 2');
}
// test get resolved business prediction markets
#[test]
fn test_get_resolved_business_prediction_market() {
    let (contract, _admin_contract) = setup_with_moderator();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_resolved_business_markets();
    assert(market.len() == 0, 'Market count should be 3');

    contract
        .create_business_prediction(
            "Will Apple acquire a gaming company by June 2025?",
            "business Predictions for Apple to acquire a specific gaming company by June 2025?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            35637 // Event ID
        );

    contract
        .create_business_prediction(
            "Will Apple acquire a gaming company by June 2025?",
            "business Predictions for Apple to acquire a specific gaming company by June 2025?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            35637 // Event ID
        );

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
    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 2 markets');

    start_cheat_block_timestamp(contract.contract_address, get_block_timestamp() + 86400 + 3600);

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

    // Resolve market
    contract.resolve_business_prediction_manually(market_id, 1);

    stop_cheat_caller_address(contract.contract_address);

    let market = contract.get_resolved_business_markets();
    assert(market.len() == 1, 'resolve count should be 1');
}
// test business prediction market is open
#[test]
fn test_is_business_prediction_market_open() {
    let (contract, _admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    contract
        .create_business_prediction(
            "Will Microsoft acquire a gaming company by June 2025?",
            "business Predictions for Microsoft to acquire a specific gaming company by June 2025?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            45337 // Event ID
        );

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
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

    // Verify market is open
    let market = contract.is_business_market_open_for_betting(market_id);
    assert(market, 'Market should be open');
}


#[test]
fn test_resolve_multiple_predictions() {
    let (contract, _admin_contract) = setup_with_moderator();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    let market = contract.get_active_business_markets();
    assert(market.len() == 0, 'Market count should be 0');
    // create general prediction market
    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2026?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2026",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );
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
    contract
        .create_crypto_prediction(
            "ETH Price Prediction",
            "Will Ethereum price be above $3000 by tomorrow?",
            ('Above $3000', 'Below $3000'),
            'eth_price',
            "https://example.com/eth.png",
            future_time,
            1, // Greater than comparison
            'ETH', // Asset key
            3000 // Target value
        );
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
    contract
        .create_sports_prediction(
            "Lakers vs Warriors",
            "Who will win the Lakers vs Warriors game?",
            ('Lakers', 'Warriors'),
            'nba',
            "https://example.com/nba.png",
            future_time,
            123456, // Event ID
            true // Team flag
        );
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
    contract
        .create_business_prediction(
            "Will Microsoft acquire a gaming company by June 2025?",
            "business Predictions for Microsoft to acquire a specific gaming company by June 2025?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            45337 // Event ID
        );

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

//test if emergency close market is working. And a closed market does not show up in the
//get_active_prediction_markets()
#[test]
fn test_emergencyclose_market() {
    let (contract, admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2026?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2026",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );
    let market_id = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };
    let market = contract.get_active_prediction_markets();
    assert(market.len() == 1, 'active Market count should be 1');

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    admin_contract.emergency_close_market(market_id, 0);
    stop_cheat_caller_address(contract.contract_address);
    let market = contract.get_active_prediction_markets();
    assert(market.len() == 0, 'active Market count should be 0');
}
//test if emergency resolve market is working. Admin can resolve market before it ends
#[test]
fn test_emergency_resolve_market() {
    let (contract, admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2026?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2026",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );
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
    let market = contract.get_active_prediction_markets();
    assert(market.len() == 1, 'active Market count should be 1');

    let prediction = contract.get_prediction(market_id);
    assert(!prediction.is_resolved, 'Dont resolved yet');

    // Admin emergency resolves the market before it ends
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    admin_contract
        .emergency_resolve_market(market_id, 0, 0); // Resolve with choice 0 (Yes) as winner
    stop_cheat_caller_address(contract.contract_address);

    // Verify market is now resolved and moved to resolved markets
    let active_markets = contract.get_active_prediction_markets();
    assert(active_markets.len() == 0, 'active Market count should be 0');

    let resolved_markets = contract.get_resolved_prediction_markets();
    assert(resolved_markets.len() == 1, 'resolved count should be 1');

    let resolved_prediction = contract.get_prediction(market_id);
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
    let (contract, admin_contract) = setup_with_moderator();
    let mut spy = spy_events();
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let future_time = get_block_timestamp() + 86400; // 1 day from now

    // Create multiple markets
    contract
        .create_prediction(
            "Will Bitcoin reach $100,000 by end of 2026?",
            "Prediction market for Bitcoin price reaching $100,000 USD by December 31, 2026",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/btc-image.png",
            future_time,
        );
    let market_id1 = match spy.get_events().events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            let market_id_felt = *event.data.at(0);
            market_id_felt.into()
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    contract
        .create_prediction(
            "Will Ethereum reach $10,000 by end of 2026?",
            "Prediction market for Ethereum price reaching $10,000 USD by December 31, 2026",
            ('Yes', 'No'),
            'crypto_milestone',
            "https://example.com/eth-image.png",
            future_time,
        );
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
    let active_markets = contract.get_active_prediction_markets();
    assert(active_markets.len() == 2, 'active Market count should be 2');

    let prediction1 = contract.get_prediction(market_id1);
    let prediction2 = contract.get_prediction(market_id2);
    assert(!prediction1.is_resolved, 'Market 1 is not resolved yet');
    assert(!prediction2.is_resolved, 'Market 2 is not resolved yet');

    // Admin emergency resolves multiple markets before they end
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    let market_ids = array![market_id1, market_id2];
    let market_types = array![0, 0]; // Both are general prediction markets
    let winning_choices = array![0, 1]; // First market: choice 0 wins, Second market: choice 1 wins
    admin_contract.emergency_resolve_multiple_markets(market_ids, market_types, winning_choices);
    stop_cheat_caller_address(contract.contract_address);

    // Verify markets are now resolved and moved to resolved markets
    let active_markets = contract.get_active_prediction_markets();
    assert(active_markets.len() == 0, 'active Market count should be 0');

    let resolved_markets = contract.get_resolved_prediction_markets();
    assert(resolved_markets.len() == 2, 'Market count should be 2');

    let resolved_prediction1 = contract.get_prediction(market_id1);
    let resolved_prediction2 = contract.get_prediction(market_id2);
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
