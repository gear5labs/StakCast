#[cfg(test)]
mod validator_tests {
    use core::option::OptionTrait;
    use core::traits::Into;
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::class_hash::ClassHash;
    use starknet::testing::{set_caller_address, set_contract_address};
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    
    // Import your contract components
    use stakcast::market::{Market, MarketTrait};
    // Update these imports based on your actual validator module structure
    use stakcast::validator::{
        Validator, ValidatorTrait, ValidatorInfo, 
        get_validator_info, is_active_validator, get_validator_by_index, get_validator_count
    };

    // Test constants
    const OWNER: felt252 = 0x123;
    const VALIDATOR_OPERATOR_1: felt252 = 0x456;
    const VALIDATOR_OPERATOR_2: felt252 = 0x789;
    const NON_VALIDATOR: felt252 = 0xabc;

    fn setup() -> (ContractAddress, ContractAddress) {
        let market_class = declare('Market');
        let market_address = market_class.deploy(@ArrayTrait::new()).unwrap();
        
        let validator_class = declare('Validator');
        let validator_address = validator_class.deploy(@ArrayTrait::new()).unwrap();
        
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Initialize contracts if needed
        // TODO: Add initialization code based on your contract requirements
        
        stop_prank(CheatTarget::One(validator_address));
        
        (market_address, validator_address)
    }

    #[test]
    fn test_get_validator_info_existing() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Register a validator
        let validator_pubkey = 0xabcd1234;
        let validator_operator: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator, validator_pubkey);
        
        let validator_info = get_validator_info(validator_pubkey);
        
        assert(validator_info.operator == validator_operator, 'Wrong operator');
        assert(validator_info.active == true, 'Should be active');
        assert(validator_info.pubkey == validator_pubkey, 'Wrong pubkey');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    fn test_get_validator_info_nonexistent() {
        // Setup
        let (_, validator_address) = setup();
        
        let non_existent_pubkey = 0xdeadbeef;
        let validator_info = get_validator_info(non_existent_pubkey);
        
        let zero_address: ContractAddress = 0.try_into().unwrap();
        assert(validator_info.operator == zero_address, 'Expected zero address');
        assert(validator_info.active == false, 'Should be inactive');
    }

    #[test]
    #[should_panic(expected: 'Invalid pubkey format')]
    fn test_get_validator_info_invalid_pubkey() {
        // Setup
        let (_, validator_address) = setup();
        
        // Try with invalid pubkey (this test assumes your contract validates pubkeys)
        let invalid_pubkey = 0;
        get_validator_info(invalid_pubkey);
    }

    #[test]
    fn test_is_active_validator_active() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Register a validator
        let validator_pubkey = 0xabcd1234;
        let validator_operator: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator, validator_pubkey);
        
        let is_active = is_active_validator(validator_pubkey);
        
        assert(is_active == true, 'Should be active');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    fn test_is_active_validator_unregistered() {
        // Setup
        let (_, validator_address) = setup();
        
        // Check unregistered validator
        let unregistered_pubkey = 0xdeadbeef;
        let is_active = is_active_validator(unregistered_pubkey);
        
        // Assert
        assert(is_active == false, 'Should be inactive');
    }

    #[test]
    fn test_is_active_validator_slashed() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Register a validator
        let validator_pubkey = 0xabcd1234;
        let validator_operator: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator, validator_pubkey);
        
        validator_contract.slash_validator(validator_pubkey);
        
        let is_active = is_active_validator(validator_pubkey);
        
        assert(is_active == false, 'Should be slashed');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    fn test_get_validator_by_index_valid() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Register validators
        let validator_pubkey1 = 0xabcd1234;
        let validator_pubkey2 = 0xdcba5678;
        let validator_operator1: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        let validator_operator2: ContractAddress = VALIDATOR_OPERATOR_2.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator1, validator_pubkey1);
        validator_contract.register_validator(validator_operator2, validator_pubkey2);
        
        // Get validator at index 0
        let validator = get_validator_by_index(0);
        
        // Assert
        assert(validator.pubkey == validator_pubkey1, 'Wrong pubkey');
        assert(validator.operator == validator_operator1, 'Wrong operator');
        
        // Get validator at index 1
        let validator2 = get_validator_by_index(1);
        
        // Assert
        assert(validator2.pubkey == validator_pubkey2, 'Wrong pubkey at idx 1');
        assert(validator2.operator == validator_operator2, 'Wrong operator at idx 1');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    #[should_panic(expected: 'Index out of bounds')]
    fn test_get_validator_by_index_out_of_bounds() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        let validator_pubkey = 0xabcd1234;
        let validator_operator: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator, validator_pubkey);
        
        stop_prank(CheatTarget::One(validator_address));
        
        let invalid_index = 999;
        get_validator_by_index(invalid_index);
    }

    #[test]
    fn test_get_validator_by_index_after_removal() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Register validators
        let validator_pubkey1 = 0xabcd1234;
        let validator_pubkey2 = 0xdcba5678;
        let validator_pubkey3 = 0x12345678;
        let validator_operator1: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        let validator_operator2: ContractAddress = VALIDATOR_OPERATOR_2.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator1, validator_pubkey1);
        validator_contract.register_validator(validator_operator2, validator_pubkey2);
        validator_contract.register_validator(validator_operator1, validator_pubkey3);
        
        validator_contract.remove_validator(validator_pubkey2);
        
        let validator = get_validator_by_index(1);
        
        assert(validator.pubkey == validator_pubkey3, 'Wrong pubkey after remove');
        assert(validator.operator == validator_operator1, 'Wrong operator after remove');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    fn test_get_validator_count_initial() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        let validator_pubkey1 = 0xabcd1234;
        let validator_pubkey2 = 0xdcba5678;
        let validator_operator1: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        let validator_operator2: ContractAddress = VALIDATOR_OPERATOR_2.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator1, validator_pubkey1);
        validator_contract.register_validator(validator_operator2, validator_pubkey2);
        
        let count = get_validator_count();
        
        assert(count == 2, 'Expected 2 validators');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    fn test_get_validator_count_additional_registration() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Register validators
        let validator_pubkey1 = 0xabcd1234;
        let validator_pubkey2 = 0xdcba5678;
        let validator_operator1: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        let validator_operator2: ContractAddress = VALIDATOR_OPERATOR_2.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator1, validator_pubkey1);
        validator_contract.register_validator(validator_operator2, validator_pubkey2);
        
        let validator_pubkey3 = 0x12345678;
        validator_contract.register_validator(validator_operator1, validator_pubkey3);
        
        let count = get_validator_count();
        
        assert(count == 3, 'Expected 3 validators');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    fn test_get_validator_count_after_slashing() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        // Register validators
        let validator_pubkey1 = 0xabcd1234;
        let validator_pubkey2 = 0xdcba5678;
        let validator_operator1: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        let validator_operator2: ContractAddress = VALIDATOR_OPERATOR_2.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator1, validator_pubkey1);
        validator_contract.register_validator(validator_operator2, validator_pubkey2);
        
        // Slash a validator
        validator_contract.slash_validator(validator_pubkey1);
        
        // Get count (assuming count only includes active validators)
        let count = get_validator_count();
        
        // Assert
        assert(count == 1, 'Expected 1 active validator');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    fn test_get_validator_count_empty() {
        let (_, validator_address) = setup();
        
        let count = get_validator_count();
        
        assert(count == 0, 'Expected 0 validators');
    }

    #[test]
    fn test_get_validator_count_after_operations() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        let validator_pubkey1 = 0xabcd1234;
        let validator_pubkey2 = 0xdcba5678;
        let validator_pubkey3 = 0x12345678;
        let validator_operator1: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        let validator_operator2: ContractAddress = VALIDATOR_OPERATOR_2.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator1, validator_pubkey1);
        validator_contract.register_validator(validator_operator2, validator_pubkey2);
        validator_contract.register_validator(validator_operator1, validator_pubkey3);
        
        validator_contract.remove_validator(validator_pubkey1);
        
        let count = get_validator_count();
        
        assert(count == 2, 'Expected 2 validators');
        
        stop_prank(CheatTarget::One(validator_address));
    }

    #[test]
    #[should_panic(expected: 'Unauthorized')]
    fn test_unauthorized_slash() {
        // Setup
        let (_, validator_address) = setup();
        let owner_address: ContractAddress = OWNER.try_into().unwrap();
        
        start_prank(CheatTarget::One(validator_address), owner_address);
        
        let validator_pubkey = 0xabcd1234;
        let validator_operator: ContractAddress = VALIDATOR_OPERATOR_1.try_into().unwrap();
        
        let validator_contract = ValidatorTrait::new(validator_address);
        validator_contract.register_validator(validator_operator, validator_pubkey);
        
        stop_prank(CheatTarget::One(validator_address));
        
        let non_validator_address: ContractAddress = NON_VALIDATOR.try_into().unwrap();
        start_prank(CheatTarget::One(validator_address), non_validator_address);
        
        validator_contract.slash_validator(validator_pubkey);
        
        // This should never execute due to the expected panic
        stop_prank(CheatTarget::One(validator_address));
    }
}