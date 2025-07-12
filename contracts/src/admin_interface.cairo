use starknet::ContractAddress;

/// Extended administrative interface for security and emergency functions
#[starknet::interface]
pub trait IAdditionalAdmin<TContractState> {
    // ================ Moderator Management ================

    /// Removes a moderator (admin only)
    fn remove_moderator(ref self: TContractState, moderator: ContractAddress);

    /// Checks if an address is a moderator
    fn is_moderator(self: @TContractState, address: ContractAddress) -> bool;

    /// Returns the total number of moderators
    fn get_moderator_count(self: @TContractState) -> u32;

    // ================ Emergency Controls ================

    /// Emergency pause the entire contract (admin only)
    fn emergency_pause(ref self: TContractState);

    /// Remove emergency pause (admin only)
    fn emergency_unpause(ref self: TContractState);

    // ================ Granular Pause Controls ================

    /// Pause only market creation (admin only)
    fn pause_market_creation(ref self: TContractState);

    /// Unpause market creation (admin only)
    fn unpause_market_creation(ref self: TContractState);

    /// Pause only betting functionality (admin only)
    fn pause_betting(ref self: TContractState);

    /// Unpause betting functionality (admin only)
    fn unpause_betting(ref self: TContractState);

    /// Pause only market resolution (admin only)
    fn pause_resolution(ref self: TContractState);

    /// Unpause market resolution (admin only)
    fn unpause_resolution(ref self: TContractState);

    // ================ Time and Fee Management ================

    /// Set time restrictions for markets (admin only)
    fn set_time_restrictions(
        ref self: TContractState, min_duration: u64, max_duration: u64, resolution_window: u64,
    );

    /// Set platform fee percentage (admin only)
    fn set_platform_fee(ref self: TContractState, fee_percentage: u256);

    /// Get current platform fee percentage
    fn get_platform_fee(self: @TContractState) -> u256;

    // ================ Status Queries ================

    /// Check if contract is paused
    fn is_paused(self: @TContractState) -> bool;

    /// Get current time restrictions
    fn get_time_restrictions(self: @TContractState) -> (u64, u64, u64);

    /// Check if market creation is paused
    fn is_market_creation_paused(self: @TContractState) -> bool;

    /// Check if betting is paused
    fn is_betting_paused(self: @TContractState) -> bool;

    /// Check if resolution is paused
    fn is_resolution_paused(self: @TContractState) -> bool;

    // ================ Oracle Management ================

    /// Set new oracle address (admin only)
    fn set_oracle_address(ref self: TContractState, oracle: ContractAddress);

    /// Get current oracle address
    fn get_oracle_address(self: @TContractState) -> ContractAddress;

    // ================ Security Audit Functions ================

    /// Get market statistics for security monitoring
    fn get_market_stats(
        self: @TContractState,
    ) -> (u256, u256, u256); // (total_markets, active_markets, resolved_markets)

    /// Emergency function to close a specific market (admin only)
    fn emergency_close_market(ref self: TContractState, market_id: u256, market_type: u8);

    /// Batch function to close multiple markets (admin only)
    fn emergency_close_multiple_markets(
        ref self: TContractState, market_ids: Array<u256>, market_types: Array<u8>,
    );

    /// Emergency function to resolve a specific market (admin only)
    fn emergency_resolve_market(
        ref self: TContractState, market_id: u256, market_type: u8, winning_choice: u8,
    );

    /// Batch function to resolve multiple markets (admin only)
    fn emergency_resolve_multiple_markets(
        ref self: TContractState,
        market_ids: Array<u256>,
        market_types: Array<u8>,
        winning_choices: Array<u8>,
    );

    // ================ Token and Betting Management ================

    /// Set protocol token address (admin only)
    fn set_protocol_token(ref self: TContractState, token_address: ContractAddress);

    /// Set protocol restrictions (admin only)
    fn set_protocol_restrictions(ref self: TContractState, min_amount: u256, max_amount: u256);

    /// Emergency withdraw tokens from contract (admin only)
    fn emergency_withdraw_tokens(
        ref self: TContractState, amount: u256, recipient: ContractAddress,
    );
}
