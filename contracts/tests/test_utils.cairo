use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::types::PredictionMarket;
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

pub fn PRECISION() -> u256 {
    1000000000000000000
}

pub fn HALF_PRECISION() -> u256 {
    500000000000000000
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

pub fn default_create_predictions(prediction_hub: IPredictionHubDispatcher) {
    let title: ByteArray = "Will Donald Trump Be President";
    let description: ByteArray = "This is a pool to check if donald trump will be president";
    let choices: (felt252, felt252) = ('Yes', 'No');
    let category: u8 = 0;
    let end_time: u64 = get_block_timestamp() + 86400; // 1 day from now
    let prediction_market_type: u8 = 0;
    let crypto_prediction: Option<(felt252, u128)> = Option::None;

    let mut spy = spy_events();

    prediction_hub
        .create_predictions(
            title.clone(),
            description,
            choices,
            category,
            end_time,
            prediction_market_type,
            crypto_prediction,
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

    let all_normal_predictions = prediction_hub.get_all_predictions_by_market_category(0);
    assert(all_normal_predictions.len() == 1, 'should be increased by 1');

    let market = prediction_hub.get_prediction(market_id);
    assert(market.market_id == market_id, 'Market ID mismatch');
    assert(market.title == title, 'Title mismatch');
    assert(market.is_open, 'Market should be open');
    assert(!market.is_resolved, 'Market not resolved');
    assert(market.total_pool == PRECISION(), 'Initial pool 0');
}

// Default create for a crypto prediction market
pub fn default_create_crypto_prediction(prediction_hub: IPredictionHubDispatcher) {
    let title: ByteArray = "ETH Price Prediction";
    let description: ByteArray = "Will Ethereum price be above $3000 by tomorrow?";
    let choices: (felt252, felt252) = ('Above $3000', 'Below $3000');
    let category: u8 = 2;
    let end_time: u64 = get_block_timestamp() + 86400;
    let prediction_market_type: u8 = 1;
    let crypto_prediction: Option<(felt252, u128)> = Option::Some(('ETH', 3000));
    let mut spy = spy_events();

    prediction_hub
        .create_predictions(
            title.clone(),
            description,
            choices,
            category,
            end_time,
            prediction_market_type,
            crypto_prediction,
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

    let list_of_genenral_predictions: Array<PredictionMarket> = prediction_hub
        .get_all_predictions_by_market_category(2);

    assert(list_of_genenral_predictions.len() == 1, 'list not updated as expceted');

    let market = prediction_hub.get_prediction(market_id);
    assert(market.market_id == market_id, 'Market ID mismatch');
    assert(market.title == title, 'Title mismatch');
    assert(market.is_open, 'Market should be open');
    assert(!market.is_resolved, 'Market not resolved');
    assert(market.total_pool == PRECISION(), 'Initial pool 0');

    let (token, price) = market.crypto_prediction.unwrap();
    assert(token == 'ETH', 'token shoiuld be ETH');
    assert(price == 3000, 'price should be 3000');
}


pub fn create_test_market(prediction_hub: IPredictionHubDispatcher) -> u256 {
    start_cheat_caller_address(prediction_hub.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();

    prediction_hub
        .create_predictions(
            "Will Donald Trump Be President",
            "This is a pool to check if donald trump will be president",
            ('Yes', 'No'),
            0,
            get_block_timestamp() + 86400,
            0,
            Option::None,
        );

    stop_cheat_caller_address(prediction_hub.contract_address);

    let events = spy.get_events();

    let mut market_id: u256 = 0;
    if let Some((_, event)) = events.events.into_iter().last() {
        let market_id_felt = *event.data.at(0);
        market_id = market_id_felt.into();
    }
    market_id
}


pub fn turn_number_to_precision_point(number: u256) -> u256 {
    number * PRECISION()
}
