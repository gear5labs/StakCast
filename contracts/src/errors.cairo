/// Central error definitions for the StakCast prediction market contract.
/// All error messages are defined here to ensure consistency and reusability.

// ================ Access Control Errors ================

/// Thrown when only an admin is allowed to perform an action
const ONLY_ADMIN_ALLOWED: felt252 = 'Only admin allowed';

/// Thrown when only a moderator or admin is allowed to perform an action
const ONLY_ADMIN_OR_MODERATOR: felt252 = 'Only admin or moderator';

/// Thrown when trying to add a user who is already a moderator
const ALREADY_A_MODERATOR: felt252 = 'Already a moderator';

/// Thrown when trying to remove a user who is not a moderator
const NOT_A_MODERATOR: felt252 = 'Not a moderator';

// ================ Contract State Errors ================

/// Thrown when the contract is paused and the action is not allowed
const CONTRACT_IS_PAUSED: felt252 = 'Contract is paused';

/// Thrown when market creation is paused
const MARKET_CREATION_PAUSED: felt252 = 'Market creation paused';

/// Thrown when betting is paused
const BETTING_PAUSED: felt252 = 'Betting paused';

/// Thrown when resolution is paused
const RESOLUTION_PAUSED: felt252 = 'Resolution paused';

/// Thrown when a reentrant call is detected
const REENTRANT_CALL: felt252 = 'Reentrant call';

// ================ Market Validation Errors ================

/// Thrown when a market does not exist
const MARKET_DOES_NOT_EXIST: felt252 = 'Market does not exist';

/// Thrown when trying to interact with a closed market
const MARKET_IS_CLOSED: felt252 = 'Market is closed';

/// Thrown when trying to resolve an already resolved market
const MARKET_ALREADY_RESOLVED: felt252 = 'Market already resolved';

/// Thrown when trying to interact with a market that has ended
const MARKET_HAS_ENDED: felt252 = 'Market has ended';

/// Thrown when a market is not resolved but resolution is required
const MARKET_IS_NOT_RESOLVED: felt252 = 'Market is not resolved';

/// Thrown when trying to resolve a market resolved without proper outcome
const MARKET_RESOLVED: felt252 = 'Market resolved';

// ================ Market Creation Errors ================

/// Thrown when the end time is not in the future
const END_TIME_MUST_BE_IN_FUTURE: felt252 = 'End time must be in future';

/// Thrown when market duration is too short
const MARKET_DURATION_TOO_SHORT: felt252 = 'Market duration too short';

/// Thrown when market duration is too long
const MARKET_DURATION_TOO_LONG: felt252 = 'Market duration too long';

/// Thrown when an invalid market type is provided
const INVALID_MARKET_TYPE: felt252 = 'Invalid market type';

/// Thrown when an invalid market category is provided
const INVALID_MARKET_CATEGORY: felt252 = 'Invalid market type!';

// ================ Betting Errors ================

/// Thrown when an invalid choice is selected (not 0 or 1)
const INVALID_CHOICE_SELECTED: felt252 = 'Invalid choice selected';

/// Thrown when an invalid choice is provided (generic)
const INVALID_CHOICE: felt252 = 'Invalid Choice';

/// Thrown when the bet amount is not positive
const AMOUNT_MUST_BE_POSITIVE: felt252 = 'Amount must be positive';

/// Thrown when the bet amount is below the minimum allowed
const AMOUNT_BELOW_MINIMUM: felt252 = 'Amount below minimum';

/// Thrown when the bet amount is above the maximum allowed
const AMOUNT_ABOVE_MAXIMUM: felt252 = 'Amount above maximum';

// ================ Token & Balance Errors ================

/// Thrown when user has insufficient token balance
const INSUFFICIENT_TOKEN_BALANCE: felt252 = 'Insufficient token balance';

/// Thrown when user has insufficient token allowance
const INSUFFICIENT_TOKEN_ALLOWANCE: felt252 = 'Insufficient token allowance';

/// Thrown when an ERC20 token transfer fails
const TOKEN_TRANSFER_FAILED: felt252 = 'Token transfer failed';

/// Thrown when an ERC20 token transfer fails (emergency case)
const ERC20_TRANSFER_FAILED: felt252 = 'ERC20 transfer failed';

/// Thrown when an emergency withdrawal fails
const EMERGENCY_WITHDRAWAL_FAILED: felt252 = 'Emergency withdrawal failed';

// ================ Resolution Errors ================

/// Thrown when trying to resolve a market that hasn't ended yet
const MARKET_NOT_YET_ENDED: felt252 = 'Market not yet ended';

/// Thrown when the resolution window has expired
const RESOLUTION_WINDOW_EXPIRED: felt252 = 'Resolution window expired';

/// Thrown when a market is not resolved for claiming
const MARKET_NOT_RESOLVED: felt252 = 'Market not resolved';

// ================ Claiming Errors ================

/// Thrown when a user tries to claim rewards they already claimed
const ALREADY_CLAIMED: felt252 = 'Already claimed';

/// Thrown when user has no winning stake for the resolved market
const NO_WINNING_STAKE_FOR_USER: felt252 = 'No winning stake for user';

// ================ Parameter Validation Errors ================

/// Thrown when class hash cannot be zero (upgrade function)
const CLASS_HASH_CANNOT_BE_ZERO: felt252 = 'Class hash cannot be zero';

/// Thrown when minimum duration must be positive
const MIN_DURATION_MUST_BE_POSITIVE: felt252 = 'Min duration must be positive';

/// Thrown when maximum duration must be greater than minimum
const MAX_MUST_BE_GREATER_THAN_MIN: felt252 = 'Max must be greater than min';

/// Thrown when resolution window must be positive
const RESOLUTION_WINDOW_POSITIVE: felt252 = 'Resolution window positive';

/// Thrown when platform fee exceeds the maximum allowed (10%)
const FEE_CANNOT_EXCEED_10_PERCENT: felt252 = 'Fee cannot exceed 10%';

/// Thrown when minimum amount must be positive
const MIN_AMOUNT_MUST_BE_POSITIVE: felt252 = 'Min amount must be positive';

/// Thrown when array lengths don't match in batch operations
const ARRAYS_LENGTH_MISMATCH: felt252 = 'Arrays length mismatch';

// ================ Generic Error Messages ================

/// Thrown when an invalid choice is made (catch-all)
const INVALID_CHOICE_PANIC: felt252 = 'invalid choice';
