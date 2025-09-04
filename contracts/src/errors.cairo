// Access Control Errors
pub const CONTRACT_PAUSED: felt252 = 'Contract is paused';
pub const ONLY_ADMIN_ALLOWED: felt252 = 'Only admin allowed';
pub const ONLY_ADMIN_OR_MODERATOR: felt252 = 'Only admin or moderator';
pub const ALREADY_MODERATOR: felt252 = 'Already a moderator';
pub const NOT_MODERATOR: felt252 = 'Not a moderator';

// Market State Errors
pub const MARKET_CREATION_PAUSED: felt252 = 'Market creation paused';
pub const BETTING_PAUSED: felt252 = 'Betting paused';
pub const RESOLUTION_PAUSED: felt252 = 'Resolution paused';
pub const MARKET_CLOSED: felt252 = 'Market is closed';
pub const MARKET_ALREADY_RESOLVED: felt252 = 'Market already resolved';
pub const MARKET_NOT_RESOLVED: felt252 = 'Market not resolved';
pub const MARKET_HAS_ENDED: felt252 = 'Market has ended';
pub const MARKET_DOES_NOT_EXIST: felt252 = 'Market does not exist';
pub const MARKET_NOT_YET_ENDED: felt252 = 'Market not yet ended';
pub const RESOLUTION_WINDOW_EXPIRED: felt252 = 'Resolution window expired';

// Timing and Duration Errors
pub const END_TIME_MUST_BE_IN_FUTURE: felt252 = 'End time must be in future';
pub const MARKET_DURATION_TOO_SHORT: felt252 = 'Market duration too short';
pub const MARKET_DURATION_TOO_LONG: felt252 = 'Market duration too long';
pub const MIN_DURATION_MUST_BE_POSITIVE: felt252 = 'Min duration must be positive';
pub const MAX_MUST_BE_GREATER_THAN_MIN: felt252 = 'Max must be greater than min';
pub const RESOLUTION_WINDOW_POSITIVE: felt252 = 'Resolution window positive';

// Betting and Choice Errors
pub const INVALID_CHOICE_SELECTED: felt252 = 'Invalid choice selected';
pub const INVALID_CHOICE: felt252 = 'Invalid Choice';
pub const ALREADY_CLAIMED: felt252 = 'Already claimed';
pub const NO_WINNING_STAKE_FOR_USER: felt252 = 'No winning stake for user';

// Amount and Token Errors
pub const AMOUNT_MUST_BE_POSITIVE: felt252 = 'Amount must be positive';
pub const AMOUNT_BELOW_MINIMUM: felt252 = 'Amount below minimum';
pub const AMOUNT_ABOVE_MAXIMUM: felt252 = 'Amount above maximum';
pub const INSUFFICIENT_TOKEN_BALANCE: felt252 = 'Insufficient token balance';
pub const INSUFFICIENT_TOKEN_ALLOWANCE: felt252 = 'Insufficient token allowance';
pub const TOKEN_TRANSFER_FAILED: felt252 = 'Token transfer failed';
pub const ERC20_TRANSFER_FAILED: felt252 = 'ERC20 transfer failed';
pub const EMERGENCY_WITHDRAWAL_FAILED: felt252 = 'Emergency withdrawal failed';

// Market Type and Category Errors
pub const INVALID_MARKET_TYPE: felt252 = 'Invalid market type';
pub const ARRAYS_LENGTH_MISMATCH: felt252 = 'Arrays length mismatch';

// Security Errors
pub const REENTRANT_CALL: felt252 = 'Reentrant call';
pub const CLASS_HASH_CANNOT_BE_ZERO: felt252 = 'Class hash cannot be zero';

// Fee and Percentage Errors
pub const FEE_CANNOT_EXCEED_TEN_PERCENT: felt252 = 'Fee cannot exceed 10%';

// Claim Errors
pub const CLAIM_PAUSED: felt252 = 'Claim paused';

pub const INSUFFICIENT_ROLE_PRIVILEGES: felt252 = 'Insufficient role privileges';
pub const UNAUTHORIZED_ROLE_OPERATION: felt252 = 'Unauthorized role operation';
pub const INVALID_ROLE: felt252 = 'Invalid role';
pub const ROLE_ALREADY_GRANTED: felt252 = 'Role already granted';
pub const ROLE_NOT_GRANTED: felt252 = 'Role not granted';
pub const CANNOT_REVOKE_OWN_ADMIN_ROLE: felt252 = 'Cannot revoke own admin role';
