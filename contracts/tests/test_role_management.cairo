use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{
    IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait, IRoleManagementDispatcher,
    IRoleManagementDispatcherTrait,
};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use stakcast::prediction::PredictionHub::{
    ADMIN_ROLE, EMERGENCY_MANAGER, MARKET_MANAGER, TREASURY_MANAGER,
};
use stakcast::types::{MarketStatus, Outcome, UserStake};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR, USER3_ADDR, USER4_ADDR,
    create_test_market, setup_test_environment, turn_number_to_precision_point,
};

#[test]
fn test_initial_admin_role_setup() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Check that admin has ADMIN role
    let has_admin_role = role_interface.has_role(ADMIN_ROLE, ADMIN_ADDR());
    assert!(has_admin_role, "Admin should have ADMIN role");
}

#[test]
fn test_grant_market_manager_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Verify USER1 doesn't have role initially
    let has_role_before = role_interface.has_role(MARKET_MANAGER, USER1_ADDR());
    assert!(!has_role_before, "USER1 should not have role initially");

    // Admin grants MARKET_MANAGER role to USER1
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify USER1 has MARKET_MANAGER role
    let has_role_after = role_interface.has_role(MARKET_MANAGER, USER1_ADDR());
    assert!(has_role_after, "USER1 should have MARKET_MANAGER role");
}

#[test]
fn test_grant_emergency_manager_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Admin grants EMERGENCY_MANAGER role to USER2
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(EMERGENCY_MANAGER, USER2_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify USER2 has EMERGENCY_MANAGER role
    let has_role = role_interface.has_role(EMERGENCY_MANAGER, USER2_ADDR());
    assert!(has_role, "USER2 should have EMERGENCY_MANAGER role");
}

#[test]
fn test_grant_treasury_manager_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Admin grants TREASURY_MANAGER role to USER3
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(TREASURY_MANAGER, USER3_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify USER3 has TREASURY_MANAGER role
    let has_role = role_interface.has_role(TREASURY_MANAGER, USER3_ADDR());
    assert!(has_role, "USER3 should have TREASURY_MANAGER role");
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_non_admin_cannot_grant_market_manager_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // USER1 (non-admin) tries to grant MARKET_MANAGER role
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER2_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_non_admin_cannot_grant_emergency_manager_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // USER1 (non-admin) tries to grant EMERGENCY_MANAGER role
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    role_interface.grant_role(EMERGENCY_MANAGER, USER2_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_non_admin_cannot_grant_treasury_manager_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // USER1 (non-admin) tries to grant TREASURY_MANAGER role
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    role_interface.grant_role(TREASURY_MANAGER, USER2_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_revoke_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Grant then revoke MARKET_MANAGER role
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER1_ADDR());

    // Verify role was granted
    let has_role_before = role_interface.has_role(MARKET_MANAGER, USER1_ADDR());
    assert!(has_role_before, "Role should be granted");

    // Revoke the role
    role_interface.revoke_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify role was revoked
    let has_role_after = role_interface.has_role(MARKET_MANAGER, USER1_ADDR());
    assert!(!has_role_after, "Role should be revoked");
}

#[test]
#[should_panic(expected: ('Cannot revoke own admin role',))]
fn test_cannot_revoke_own_admin_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Admin tries to revoke their own ADMIN role
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.revoke_role(ADMIN_ROLE, ADMIN_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_non_admin_cannot_revoke_roles() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Grant role first
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // USER2 (non-admin) tries to revoke USER1's role
    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    role_interface.revoke_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_renounce_own_role() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Grant role first
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify role was granted
    let has_role_before = role_interface.has_role(MARKET_MANAGER, USER1_ADDR());
    assert!(has_role_before, "Role should be granted");

    // USER1 renounces their own role
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    role_interface.renounce_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify role was renounced
    let has_role_after = role_interface.has_role(MARKET_MANAGER, USER1_ADDR());
    assert!(!has_role_after, "Role should be renounced");
}

#[test]
#[should_panic(expected: ('Unauthorized role operation',))]
fn test_cannot_renounce_others_roles() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Grant role to USER1
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // USER2 tries to renounce USER1's role
    start_cheat_caller_address(contract.contract_address, USER2_ADDR());
    role_interface.renounce_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_market_manager_can_create_market() {
    let (contract, _admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Grant MARKET_MANAGER role to USER1
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // USER1 should be able to create a market
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    let future_time = get_block_timestamp() + 86400;
    contract
        .create_predictions(
            "Test Market",
            "Description",
            "https://example.com/image.jpg",
            ('Yes', 'No'),
            0,
            future_time,
            0,
            Option::None,
        );
    stop_cheat_caller_address(contract.contract_address);

    // Verify market was created
    let count = contract.get_prediction_count();
    assert!(count == 1, "Market should be created");
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_user_without_role_cannot_create_market() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    // USER1 (without MARKET_MANAGER role) tries to create market
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    let future_time = get_block_timestamp() + 86400;
    contract
        .create_predictions(
            "Test Market",
            "Description",
            "https://example.com/image.jpg",
            ('Yes', 'No'),
            0,
            future_time,
            0,
            Option::None,
        );
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_emergency_manager_can_close_market() {
    let (contract, admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Create a market first
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // Grant EMERGENCY_MANAGER role to USER1
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(EMERGENCY_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // USER1 should be able to emergency close the market
    start_cheat_caller_address(admin_interface.contract_address, USER1_ADDR());
    admin_interface.emergency_close_market(market_id);
    stop_cheat_caller_address(admin_interface.contract_address);

    // Verify market was closed
    let market = contract.get_prediction(market_id);
    assert!(market.status == MarketStatus::Closed, "Market should be closed");
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_user_without_emergency_role_cannot_close_market() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // Create a market first
    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let market_id = create_test_market(contract);
    stop_cheat_caller_address(contract.contract_address);

    // USER1 (without EMERGENCY_MANAGER role) tries to close market
    start_cheat_caller_address(admin_interface.contract_address, USER1_ADDR());
    admin_interface.emergency_close_market(market_id);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
fn test_treasury_manager_can_set_fees() {
    let (contract, admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Grant TREASURY_MANAGER role to USER1
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(TREASURY_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // USER1 should be able to set platform fees
    start_cheat_caller_address(admin_interface.contract_address, USER1_ADDR());
    admin_interface.set_platform_fee(300); // 3%
    stop_cheat_caller_address(admin_interface.contract_address);

    // Verify fee was set
    let fee = admin_interface.get_platform_fee();
    assert!(fee == 300, "Fee should be set to 300");
}

#[test]
#[should_panic(expected: ('Insufficient role privileges',))]
fn test_user_without_treasury_role_cannot_set_fees() {
    let (contract, admin_interface, _token) = setup_test_environment();

    // USER1 (without TREASURY_MANAGER role) tries to set fees
    start_cheat_caller_address(admin_interface.contract_address, USER1_ADDR());
    admin_interface.set_platform_fee(300);
    stop_cheat_caller_address(admin_interface.contract_address);
}

#[test]
fn test_user_with_multiple_roles() {
    let (contract, admin_interface, _token) = setup_test_environment();
    let role_interface = IRoleManagementDispatcher { contract_address: contract.contract_address };

    // Grant multiple roles to USER1
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR());
    role_interface.grant_role(MARKET_MANAGER, USER1_ADDR());
    role_interface.grant_role(TREASURY_MANAGER, USER1_ADDR());
    stop_cheat_caller_address(contract.contract_address);

    // Verify USER1 has both roles
    let has_market_manager = role_interface.has_role(MARKET_MANAGER, USER1_ADDR());
    let has_treasury_manager = role_interface.has_role(TREASURY_MANAGER, USER1_ADDR());
    assert!(has_market_manager, "Should have MARKET_MANAGER role");
    assert!(has_treasury_manager, "Should have TREASURY_MANAGER role");

    // USER1 should be able to use both functions
    start_cheat_caller_address(contract.contract_address, USER1_ADDR());
    let future_time = get_block_timestamp() + 86400;
    contract
        .create_predictions(
            "Test Market",
            "Description",
            "https://example.com/image.jpg",
            ('Yes', 'No'),
            0,
            future_time,
            0,
            Option::None,
        );
    stop_cheat_caller_address(contract.contract_address);

    start_cheat_caller_address(admin_interface.contract_address, USER1_ADDR());
    admin_interface.set_platform_fee(250);
    stop_cheat_caller_address(admin_interface.contract_address);

    let count = contract.get_prediction_count();
    let fee = admin_interface.get_platform_fee();
    assert!(count == 1, "Market should be created");
    assert!(fee == 250, "Fee should be set");
}
