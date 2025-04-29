pub mod Errors {
    // Validator errors
    pub const ERR_INSUFFICIENT_STAKE: felt252 = 'Insufficient stake';
    pub const ERR_VALIDATOR_NOT_FOUND_OR_INACTIVE: felt252 = 'Validator not found or inactive';
    pub const ERR_UNAUTHORIZED_SLASHING: felt252 = 'Unauthorized slashing';
    pub const ERR_INVALID_VALIDATOR_INDEX: felt252 = 'Invalid validator index';
    pub const ERR_TOO_FREQUENT_RESOLUTION: felt252 = 'Too frequent resolutions';

    // Market errors
    pub const ERR_INSUFFICIENT_BALANCE: felt252 = 'Insufficient balance';
    pub const ERR_INVALID_START_TIME: felt252 = 'Invalid start time';
    pub const ERR_INVALID_END_TIME: felt252 = 'Invalid end time';
    pub const ERR_MIN_OUTCOMES_REQUIRED: felt252 = 'Minimum 2 outcomes required';
    pub const ERR_MIN_STAKE_ABOVE_ZERO: felt252 = 'Min stake must be > 0';
    pub const ERR_MAX_STAKE_LESS_THAN_MIN: felt252 = 'Max stake < min stake';
    pub const ERR_BELOW_MIN_STAKE: felt252 = 'Below min stake';
    pub const ERR_ABOVE_MAX_STAKE: felt252 = 'Above max stake';
    pub const ERR_INVALID_OUTCOME: felt252 = 'Invalid outcome';
    pub const ERR_INACTIVE_MARKET: felt252 = 'Market not active';
    pub const ERR_MARKET_NOT_STARTED: felt252 = 'Market not started';
    pub const ERR_MARKET_ENDED: felt252 = 'Market ended';
    pub const ERR_NO_CLAIMING_POSITION: felt252 = 'No position to claim';
    pub const ERR_POSITION_CLAIMED: felt252 = 'Already claimed';
    pub const ERR_RESOLVABLE_BY_ASSIGNED_VALIDATORS: felt252 = 'Only assigned validator';
    pub const ERR_MARKET_NOT_ENDED: felt252 = 'Market not yet ended';
    pub const ERR_RESOLUTION_PERIOD_EXP: felt252 = 'Resolution period expired';
    pub const ERR_INVALID_WINNING_OUTCOME: felt252 = 'Invalid winning outcome';
    pub const ERR_CANCELLATION_ONLY_BY_MARKET_CREATOR: felt252 = 'Only creator can cancel';
    pub const ERR_UNRESOLVED_MARKET: felt252 = 'Market not resolved';
}

