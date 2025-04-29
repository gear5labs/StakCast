use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
    start_cheat_caller_address, test_address, stop_cheat_caller_address,
};
use starknet::testing::set_block_timestamp;
use starknet::ContractAddress;
use stakcast::interface::{
    IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait, IMarketValidatorDispatcher,
};
use stakcast::interface::MarketStatus; // Import MarketStatus
use stakcast::prediction::PredictionMarket::{Event, MarketResolved, MarketDisputed};

// Helper to deploy MarketValidator (dependency)
fn deploy_market_validator(
    prediction_market: ContractAddress,
    min_stake: u256,
    resolution_timeout: u64,
    slash_percentage: u64,
    owner: ContractAddress,
) -> IMarketValidatorDispatcher {
    let declare_result = declare("MarketValidator").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        prediction_market.into(),
        min_stake.low.into(),
        min_stake.high.into(),
        resolution_timeout.into(),
        slash_percentage.into(),
        owner.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IMarketValidatorDispatcher { contract_address: address }
}

// Helper to deploy PredictionMarket
fn deploy_prediction_market(
    fee_collector: ContractAddress,
    platform_fee: u256,
    market_validator: ContractAddress,
) -> IPredictionMarketDispatcher {
    let declare_result = declare("PredictionMarket").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        fee_collector.into(),
        platform_fee.low.into(),
        platform_fee.high.into(),
        market_validator.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IPredictionMarketDispatcher { contract_address: address }
}

// Helper to deploy a mock ERC20 token
fn deploy_mock_erc20() -> IERC20Dispatcher {
    let declare_result = declare("MockERC20").unwrap();
    let contract_class = declare_result.contract_class();
    let (address, _) = contract_class.deploy(@array![].into()).unwrap();
    IERC20Dispatcher { contract_address: address }
}

const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
const INVALID_ROLE: felt252 = selector!("INVALID_ROLE");

fn RANDOM_ADDRESS() -> ContractAddress {
    'RANDOM_ADDRESS'.try_into().unwrap()
}

// Test: Market Creation
#[test]
fn test_create_market() {
    let fee_collector = test_address();
    let owner = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        fee_collector, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(pm_contract.contract_address, owner);
    set_block_timestamp(1000);

    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    let market_details = pm_contract.get_market_details(market_id);
    assert_eq!(market_details.market.title, "Test Market", "Incorrect market title");
    assert_eq!(market_details.status, MarketStatus::Active, "Market should be active");
}

// Test: Taking a Position
#[test]
fn test_take_position() {
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(500_u256); // Fund user internally

    pm_contract.take_position(market_id, 0, 500_u256);

    let position = pm_contract.get_user_position(user, market_id);
    assert_eq!(position.outcome_index, 0, "Incorrect outcome index");
    assert_eq!(position.amount, 500_u256, "Incorrect stake amount");
}

// Test: Resolve Market
#[test]
fn test_resolve_market() {
    let owner = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    let mv_contract_dispatcher = IMarketValidatorDispatcher { contract_address: mv_contract.contract_address };
    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract.create_market(
        "Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256,
    );

    set_block_timestamp(3500);
    start_cheat_caller_address(pm_contract.contract_address, owner);
    let mut spy = spy_events();
    pm_contract.resolve_market(market_id, 0, 'Resolution details');

    let market_details = pm_contract.get_market_details(market_id);
    assert_eq!(market_details.status, MarketStatus::Resolved, "Market should be resolved");
    spy
        .assert_emitted(
            @array![
                (
                    pm_contract.contract_address,
                    Event::MarketResolved(
                        MarketResolved {
                            market_id: market_id,
                            outcome: 0,
                            resolver: owner,
                            resolution_details: 'Resolution details',
                        },
                    ),
                ),
            ],
        );
}

// Test: Dispute Market
#[test]
fn test_dispute_market() {
    let owner = test_address();
    let disputer = test_address();
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        erc20.contract_address, owner, 500_u256, mv_contract.contract_address,
    );

    // Update MarketValidator with PredictionMarket address
    let mv_contract_dispatcher = IMarketValidatorDispatcher {
        contract_address: mv_contract.contract_address,
    };

    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];

    let market_id = pm_contract.create_market(
        "Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256,
    );
    set_block_timestamp(3500);
    pm_contract.resolve_market(market_id, 0, 'Resolution details');

    start_cheat_caller_address(pm_contract.contract_address, disputer);
    let mut spy = spy_events();
    pm_contract.dispute_market(market_id, 'Dispute reason');

    let market_details = pm_contract.get_market_details(market_id);
    assert_eq!(market_details.status, MarketStatus::Disputed, "Market should be disputed");
    spy
        .assert_emitted(
            @array![
                (
                    pm_contract.contract_address,
                    Event::MarketDisputed(
                        MarketDisputed {
                            market_id: market_id, disputer: disputer, reason: 'Dispute reason',
                        },
                    ),
                ),
            ],
        );
}

// Test: Market Cancellation
#[test]
fn test_cancel_market() {
    let creator = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, creator,
    );
    let pm_contract = deploy_prediction_market(
        creator, 500_u256, mv_contract.contract_address,
    );


    let mv_contract_dispatcher = IMarketValidatorDispatcher { contract_address: mv_contract.contract_address };
    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    start_cheat_caller_address(pm_contract.contract_address, creator);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    pm_contract.cancel_market(market_id, 'Cancel reason');

    let market = pm_contract.get_market_details(market_id);
    assert_eq!(market.status, MarketStatus::Cancelled, "Market should be cancelled");
}

// Test: Claim Winnings
#[test]
fn test_claim_winnings() {
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );


    let mv_contract_dispatcher = IMarketValidatorDispatcher { contract_address: mv_contract.contract_address };
    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market(
            "Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256,
        );

    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(500_u256); // Fund user internally
    pm_contract.take_position(market_id, 0, 500_u256);

    set_block_timestamp(3500);
    start_cheat_caller_address(pm_contract.contract_address, owner);
    pm_contract.resolve_market(market_id, 0, 'Resolution details');

    start_cheat_caller_address(pm_contract.contract_address, user);
    let initial_balance = pm_contract.get_balance(user);
    pm_contract.claim_winnings(market_id);
    let final_balance = pm_contract.get_balance(user);

    let position = pm_contract.get_user_position(user, market_id);
    assert!(position.claimed, "Position should be claimed");
    assert!(final_balance > initial_balance, "Balance should increase after claiming");
}

// Test: Deposit
#[test]
fn test_deposit() {
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(pm_contract.contract_address, user);
    let initial_balance = pm_contract.get_balance(user);
    pm_contract.deposit(1000_u256);
    let final_balance = pm_contract.get_balance(user);

    assert_eq!(final_balance, initial_balance + 1000_u256, "Balance should increase by deposit amount");
}

// Test: Withdraw
#[test]
#[should_panic(expected: "Insufficient balance")]
fn test_withdraw() {
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(1000_u256);

    let initial_balance = pm_contract.get_balance(user);
    pm_contract.withdraw(600_u256);
    let final_balance = pm_contract.get_balance(user);

    assert_eq!(final_balance, initial_balance - 600_u256, "Balance should decrease by withdrawal amount");

    pm_contract.withdraw(500_u256); // Should panic with "Insufficient balance"
}

// Test: Multiple Deposits and Withdrawals
#[test]
fn test_multiple_deposits_and_withdrawals() {
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(500_u256);
    assert_eq!(pm_contract.get_balance(user), 500_u256, "First deposit failed");
    pm_contract.deposit(300_u256);
    assert_eq!(pm_contract.get_balance(user), 800_u256, "Second deposit failed");
    pm_contract.withdraw(400_u256);
    assert_eq!(pm_contract.get_balance(user), 400_u256, "Withdrawal failed");
}

// Edge Case Test: Invalid Market ID
#[test]
#[should_panic(expected: "Input too long for arguments")]
fn test_invalid_market_id() {
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, test_address());
    let pm_contract = deploy_prediction_market(
        test_address(), 500_u256, mv_contract.contract_address,
    );
    pm_contract.resolve_market(9999, 0, 'Invalid'); // Non-existent market
}

#[test]
fn test_set_role() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    // set the role of the admin contract address to an admin
    mv_contract.set_role(admin, ADMIN_ROLE, true);

    // get admin status to check weather his role changed to an admin
    let admin_status = mv_contract.is_admin(ADMIN_ROLE, admin);
    assert!(admin_status, "Admin status should be true");
}


#[test]
fn test_remove_role() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    // set the role of the admin contract address to an admin
    mv_contract.set_role(admin, ADMIN_ROLE, true);

    // get admin status to check weather his role changed to an admin
    let admin_status = mv_contract.is_admin(ADMIN_ROLE, admin);
    assert!(admin_status, "Admin status should be true");

    // remove the role
    mv_contract.set_role(admin, ADMIN_ROLE, false);

    // assert that it is false now
    let admin_status = mv_contract.is_admin(ADMIN_ROLE, admin);
    assert!(!admin_status, "Admin status should be true");
}

#[test]
#[should_panic]
fn test_set_role_should_panic_when_invalid_role_is_passed() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    mv_contract.set_role(admin, INVALID_ROLE, false);
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_set_role_should_panic_when_called_by_non_owner() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(mv_contract.contract_address, RANDOM_ADDRESS());
    mv_contract.set_role(admin, ADMIN_ROLE, true);
    stop_cheat_caller_address(mv_contract.contract_address);

    start_cheat_caller_address(mv_contract.contract_address, RANDOM_ADDRESS());
    mv_contract.set_role(admin, ADMIN_ROLE, true);
    stop_cheat_caller_address(mv_contract.contract_address);
}

#[test]
fn test_set_prediction_market() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mock_prediction_market = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );
    mv_contract.set_role(admin, ADMIN_ROLE, true);
    mv_contract.set_prediction_market(mock_prediction_market);
    let prediction_market = mv_contract.get_prediction_market();
    assert!(prediction_market == mock_prediction_market, "Market not set correctly");
}


#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_set_prediction_should_panic_when_called_by_non_owner() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mock_prediction_market = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(mv_contract.contract_address, RANDOM_ADDRESS());
    mv_contract.set_prediction_market(mock_prediction_market);
    stop_cheat_caller_address(mv_contract.contract_address);
}
