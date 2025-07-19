use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};


const ADMIN_CONST: felt252 = 123;
const MODERATOR_CONST: felt252 = 456;
const USER1_CONST: felt252 = 101112;
const USER2_CONST: felt252 = 131415;
const FEE_RECIPIENT_CONST: felt252 = 161718;
const PRAGMA_ORACLE_CONST: felt252 = 192021;

pub fn ADMIN_ADDR() -> ContractAddress {
    ADMIN_CONST.try_into().unwrap()
}

pub fn MODERATOR_ADDR() -> ContractAddress {
    MODERATOR_CONST.try_into().unwrap()
}

pub fn USER1_ADDR() -> ContractAddress {
    USER1_CONST.try_into().unwrap()
}

pub fn USER2_ADDR() -> ContractAddress {
    USER2_CONST.try_into().unwrap()
}

pub fn USER3_ADDR() -> ContractAddress {
    USER2_CONST.try_into().unwrap()
}

pub fn FEE_RECIPIENT_ADDR() -> ContractAddress {
    FEE_RECIPIENT_CONST.try_into().unwrap()
}

pub fn PRAGMA_ORACLE_ADDR() -> ContractAddress {
    PRAGMA_ORACLE_CONST.try_into().unwrap()
}

// declare a test token contract
pub fn deploy_test_token() -> IERC20Dispatcher {
    let contract = declare("strktoken").unwrap().contract_class();
    let constructor_calldata = array![USER1_ADDR().into(), ADMIN_ADDR().into(), 18];

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IERC20Dispatcher { contract_address }
}

// deploy the prediction hub contract
fn deploy_prediction_contract(
    token_address: ContractAddress,
) -> (IPredictionHubDispatcher, IAdditionalAdminDispatcher) {
    let contract = declare("PredictionHub").unwrap().contract_class();
    let constructor_calldata = array![
        ADMIN_ADDR().into(),
        FEE_RECIPIENT_ADDR().into(),
        PRAGMA_ORACLE_ADDR().into(),
        token_address.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let prediction_hub = IPredictionHubDispatcher { contract_address };
    let admin_interface = IAdditionalAdminDispatcher { contract_address };

    (prediction_hub, admin_interface)
}

// Setup the test environment
// This function deploys the prediction hub and token contracts, sets up initial balances,
// and adds a moderator. It returns the prediction hub, admin interface, and token dispatcher.
pub fn setup_test_environment() -> (
    IPredictionHubDispatcher, IAdditionalAdminDispatcher, IERC20Dispatcher,
) {
    let token = deploy_test_token();
    let (prediction_hub, admin_interface) = deploy_prediction_contract(token.contract_address);

    // Add moderator
    start_cheat_caller_address(prediction_hub.contract_address, ADMIN_ADDR());
    prediction_hub.add_moderator(MODERATOR_ADDR());
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Setup token balances and allowances
    start_cheat_caller_address(token.contract_address, USER1_ADDR());
    token.transfer(USER2_ADDR(), 500000000000000000000000); // 500k tokens to USER2

    token.approve(prediction_hub.contract_address, 1000000000000000000000000); // 1M approval
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(token.contract_address, USER2_ADDR());
    token.approve(prediction_hub.contract_address, 500000000000000000000000); // 500k approval
    stop_cheat_caller_address(token.contract_address);

    (prediction_hub, admin_interface, token)
}


// a util function to create a test market
// This function creates a prediction market with a future time and returns the market ID.
pub fn create_test_market(prediction_hub: IPredictionHubDispatcher) -> u256 {
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    let future_time = get_block_timestamp() + 86400; // 1 day from now
    prediction_hub
        .create_prediction(
            "Will BTC reach $100k?",
            "A prediction about Bitcoin price",
            ('Yes', 'No'),
            'crypto',
            "https://example.com/btc.jpg",
            future_time,
        );

    stop_cheat_caller_address(prediction_hub.contract_address);

    // Fetch the MarketCreated event
    let events = spy.get_events();

    let market_id = match events.events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            // event is of type snforge_std::cheatcodes::events::Event
            // data is Array<felt252>, where data[0] is market_id (u256)
            let market_id_felt = *event.data.at(0); // Access first element
            market_id_felt.into() // Convert felt252 to u256
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    market_id
}


// a util function to create a test market
// This function creates a crypto prediction market with a future time and returns the market ID.
pub fn create_crypto_prediction(prediction_hub: IPredictionHubDispatcher) -> u256 {
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    let future_time = get_block_timestamp() + 86400; // 1 day from now
    prediction_hub
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
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Fetch the MarketCreated event
    let events = spy.get_events();

    let market_id = match events.events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            // event is of type snforge_std::cheatcodes::events::Event
            // data is Array<felt252>, where data[0] is market_id (u256)
            let market_id_felt = *event.data.at(0); // Access first element
            market_id_felt.into() // Convert felt252 to u256
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    market_id
}

// a util function to create a test market
// This function creates a buisness prediction market with a future time and returns the market ID.
pub fn create_business_prediction(prediction_hub: IPredictionHubDispatcher) -> u256 {
    let mut spy = spy_events();
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());

    let future_time = get_block_timestamp() + 86400; // 1 day from now
    prediction_hub
        .create_business_prediction(
            "Will Apple acquire a gaming company by June 2025?",
            "business Predictions for Apple to acquire a specific gaming company by June 2025?",
            ('Yes', 'No'),
            'business_acquisition',
            "https://example.com/microsoft-image.png",
            future_time,
            35637 // Event ID
        );
    stop_cheat_caller_address(prediction_hub.contract_address);

    // Fetch the MarketCreated event
    let events = spy.get_events();

    let market_id = match events.events.into_iter().last() {
        Option::Some((
            _, event,
        )) => {
            // event is of type snforge_std::cheatcodes::events::Event
            // data is Array<felt252>, where data[0] is market_id (u256)
            let market_id_felt = *event.data.at(0); // Access first element
            market_id_felt.into() // Convert felt252 to u256
        },
        Option::None => panic!("No MarketCreated event emitted"),
    };

    market_id
}

#[derive(Debug, Drop)]
pub struct market_details {}

#[derive(Drop, Debug)]
enum MarketType {
    SPORTS,
    BUISNESS,
    CRYPTO,
    GENERAL,
}
fn create_dynamic_market(
    prediction_hub: IPredictionHubDispatcher,
    details: Option<market_details>,
    market_type: MarketType,
) { // todo() : implement a dynamic create market function
}
