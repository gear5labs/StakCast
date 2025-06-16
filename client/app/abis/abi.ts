import { type Abi } from "starknet";
export default [
  {
    name: "PredictionHubImpl",
    type: "impl",
    interface_name: "stakcast::interface::IPredictionHub",
  },
  {
    name: "core::byte_array::ByteArray",
    type: "struct",
    members: [
      {
        name: "data",
        type: "core::array::Array::<core::bytes_31::bytes31>",
      },
      {
        name: "pending_word",
        type: "core::felt252",
      },
      {
        name: "pending_word_len",
        type: "core::integer::u32",
      },
    ],
  },
  {
    name: "core::bool",
    type: "enum",
    variants: [
      {
        name: "False",
        type: "()",
      },
      {
        name: "True",
        type: "()",
      },
    ],
  },
  {
    name: "core::integer::u256",
    type: "struct",
    members: [
      {
        name: "low",
        type: "core::integer::u128",
      },
      {
        name: "high",
        type: "core::integer::u128",
      },
    ],
  },
  {
    name: "stakcast::interface::Choice",
    type: "struct",
    members: [
      {
        name: "label",
        type: "core::felt252",
      },
      {
        name: "staked_amount",
        type: "core::integer::u256",
      },
    ],
  },
  {
    name: "core::option::Option::<stakcast::interface::Choice>",
    type: "enum",
    variants: [
      {
        name: "Some",
        type: "stakcast::interface::Choice",
      },
      {
        name: "None",
        type: "()",
      },
    ],
  },
  {
    name: "stakcast::interface::PredictionMarket",
    type: "struct",
    members: [
      {
        name: "title",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        name: "description",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "choices",
        type: "(stakcast::interface::Choice, stakcast::interface::Choice)",
      },
      {
        name: "category",
        type: "core::felt252",
      },
      {
        name: "image_url",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "is_resolved",
        type: "core::bool",
      },
      {
        name: "is_open",
        type: "core::bool",
      },
      {
        name: "end_time",
        type: "core::integer::u64",
      },
      {
        name: "winning_choice",
        type: "core::option::Option::<stakcast::interface::Choice>",
      },
      {
        name: "total_pool",
        type: "core::integer::u256",
      },
    ],
  },
  {
    name: "stakcast::interface::CryptoPrediction",
    type: "struct",
    members: [
      {
        name: "title",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        name: "description",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "choices",
        type: "(stakcast::interface::Choice, stakcast::interface::Choice)",
      },
      {
        name: "category",
        type: "core::felt252",
      },
      {
        name: "image_url",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "is_resolved",
        type: "core::bool",
      },
      {
        name: "is_open",
        type: "core::bool",
      },
      {
        name: "end_time",
        type: "core::integer::u64",
      },
      {
        name: "winning_choice",
        type: "core::option::Option::<stakcast::interface::Choice>",
      },
      {
        name: "total_pool",
        type: "core::integer::u256",
      },
      {
        name: "comparison_type",
        type: "core::integer::u8",
      },
      {
        name: "asset_key",
        type: "core::felt252",
      },
      {
        name: "target_value",
        type: "core::integer::u128",
      },
    ],
  },
  {
    name: "stakcast::interface::SportsPrediction",
    type: "struct",
    members: [
      {
        name: "title",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        name: "description",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "choices",
        type: "(stakcast::interface::Choice, stakcast::interface::Choice)",
      },
      {
        name: "category",
        type: "core::felt252",
      },
      {
        name: "image_url",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "is_resolved",
        type: "core::bool",
      },
      {
        name: "is_open",
        type: "core::bool",
      },
      {
        name: "end_time",
        type: "core::integer::u64",
      },
      {
        name: "winning_choice",
        type: "core::option::Option::<stakcast::interface::Choice>",
      },
      {
        name: "total_pool",
        type: "core::integer::u256",
      },
      {
        name: "event_id",
        type: "core::integer::u64",
      },
      {
        name: "team_flag",
        type: "core::bool",
      },
    ],
  },
  {
    name: "stakcast::interface::UserStake",
    type: "struct",
    members: [
      {
        name: "amount",
        type: "core::integer::u256",
      },
      {
        name: "claimed",
        type: "core::bool",
      },
    ],
  },
  {
    name: "stakcast::interface::UserBet",
    type: "struct",
    members: [
      {
        name: "choice",
        type: "stakcast::interface::Choice",
      },
      {
        name: "stake",
        type: "stakcast::interface::UserStake",
      },
    ],
  },
  {
    name: "stakcast::interface::IPredictionHub",
    type: "interface",
    items: [
      {
        name: "create_prediction",
        type: "function",
        inputs: [
          {
            name: "title",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "description",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "choices",
            type: "(core::felt252, core::felt252)",
          },
          {
            name: "category",
            type: "core::felt252",
          },
          {
            name: "image_url",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "end_time",
            type: "core::integer::u64",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "create_crypto_prediction",
        type: "function",
        inputs: [
          {
            name: "title",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "description",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "choices",
            type: "(core::felt252, core::felt252)",
          },
          {
            name: "category",
            type: "core::felt252",
          },
          {
            name: "image_url",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "end_time",
            type: "core::integer::u64",
          },
          {
            name: "comparison_type",
            type: "core::integer::u8",
          },
          {
            name: "asset_key",
            type: "core::felt252",
          },
          {
            name: "target_value",
            type: "core::integer::u128",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "create_sports_prediction",
        type: "function",
        inputs: [
          {
            name: "title",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "description",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "choices",
            type: "(core::felt252, core::felt252)",
          },
          {
            name: "category",
            type: "core::felt252",
          },
          {
            name: "image_url",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "end_time",
            type: "core::integer::u64",
          },
          {
            name: "event_id",
            type: "core::integer::u64",
          },
          {
            name: "team_flag",
            type: "core::bool",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "get_prediction_count",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::integer::u256",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_prediction",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "stakcast::interface::PredictionMarket",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_predictions",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::interface::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_crypto_prediction",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "stakcast::interface::CryptoPrediction",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_crypto_predictions",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::interface::CryptoPrediction>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_sports_prediction",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "stakcast::interface::SportsPrediction",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_sports_predictions",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::interface::SportsPrediction>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "place_bet",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "choice_idx",
            type: "core::integer::u8",
          },
          {
            name: "amount",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
        ],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "place_wager",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "choice_idx",
            type: "core::integer::u8",
          },
          {
            name: "amount",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
        ],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "get_bet_count_for_market",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
        ],
        outputs: [
          {
            type: "core::integer::u8",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_choice_and_bet",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
          {
            name: "bet_idx",
            type: "core::integer::u8",
          },
        ],
        outputs: [
          {
            type: "stakcast::interface::UserBet",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_betting_token",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_market_fees",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "core::integer::u256",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_total_fees_collected",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::integer::u256",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_betting_restrictions",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "(core::integer::u256, core::integer::u256)",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_market_liquidity",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "core::integer::u256",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_total_value_locked",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::integer::u256",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "resolve_prediction",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "winning_choice",
            type: "core::integer::u8",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "resolve_crypto_prediction_manually",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "winning_choice",
            type: "core::integer::u8",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "resolve_sports_prediction_manually",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "winning_choice",
            type: "core::integer::u8",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "resolve_crypto_prediction",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "resolve_sports_prediction",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "winning_choice",
            type: "core::integer::u8",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "collect_winnings",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
          {
            name: "bet_idx",
            type: "core::integer::u8",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "get_user_claimable_amount",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::integer::u256",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_user_predictions",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::interface::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_user_crypto_predictions",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::interface::CryptoPrediction>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_user_sports_predictions",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::interface::SportsPrediction>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_admin",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_fee_recipient",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "set_fee_recipient",
        type: "function",
        inputs: [
          {
            name: "recipient",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "toggle_market_status",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "add_moderator",
        type: "function",
        inputs: [
          {
            name: "moderator",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "remove_all_predictions",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "upgrade",
        type: "function",
        inputs: [
          {
            name: "impl_hash",
            type: "core::starknet::class_hash::ClassHash",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "place_bet_with_token",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "choice_idx",
            type: "core::integer::u8",
          },
          {
            name: "amount",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
          {
            name: "token_name",
            type: "core::felt252",
          },
        ],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "place_wager_with_token",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "choice_idx",
            type: "core::integer::u8",
          },
          {
            name: "amount",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
          {
            name: "token_name",
            type: "core::felt252",
          },
        ],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "get_supported_token",
        type: "function",
        inputs: [
          {
            name: "token_name",
            type: "core::felt252",
          },
        ],
        outputs: [
          {
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_market_token",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "is_token_supported",
        type: "function",
        inputs: [
          {
            name: "token_name",
            type: "core::felt252",
          },
        ],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "view",
      },
    ],
  },
  {
    name: "AdditionalAdminImpl",
    type: "impl",
    interface_name: "stakcast::admin_interface::IAdditionalAdmin",
  },
  {
    name: "stakcast::admin_interface::IAdditionalAdmin",
    type: "interface",
    items: [
      {
        name: "remove_moderator",
        type: "function",
        inputs: [
          {
            name: "moderator",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "is_moderator",
        type: "function",
        inputs: [
          {
            name: "address",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_moderator_count",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::integer::u32",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "emergency_pause",
        type: "function",
        inputs: [
          {
            name: "reason",
            type: "core::byte_array::ByteArray",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "emergency_unpause",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "pause_market_creation",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "unpause_market_creation",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "pause_betting",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "unpause_betting",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "pause_resolution",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "unpause_resolution",
        type: "function",
        inputs: [],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "set_time_restrictions",
        type: "function",
        inputs: [
          {
            name: "min_duration",
            type: "core::integer::u64",
          },
          {
            name: "max_duration",
            type: "core::integer::u64",
          },
          {
            name: "resolution_window",
            type: "core::integer::u64",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "set_platform_fee",
        type: "function",
        inputs: [
          {
            name: "fee_percentage",
            type: "core::integer::u256",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "get_platform_fee",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::integer::u256",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "is_paused",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_emergency_pause_reason",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::byte_array::ByteArray",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_time_restrictions",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "(core::integer::u64, core::integer::u64, core::integer::u64)",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "is_market_creation_paused",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "is_betting_paused",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "is_resolution_paused",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::bool",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "set_oracle_address",
        type: "function",
        inputs: [
          {
            name: "oracle",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "get_oracle_address",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_market_stats",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "(core::integer::u256, core::integer::u256, core::integer::u256)",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "emergency_close_market",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "market_type",
            type: "core::integer::u8",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "emergency_close_multiple_markets",
        type: "function",
        inputs: [
          {
            name: "market_ids",
            type: "core::array::Array::<core::integer::u256>",
          },
          {
            name: "market_types",
            type: "core::array::Array::<core::integer::u8>",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "set_betting_token",
        type: "function",
        inputs: [
          {
            name: "token_address",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "set_betting_restrictions",
        type: "function",
        inputs: [
          {
            name: "min_amount",
            type: "core::integer::u256",
          },
          {
            name: "max_amount",
            type: "core::integer::u256",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "emergency_withdraw_tokens",
        type: "function",
        inputs: [
          {
            name: "amount",
            type: "core::integer::u256",
          },
          {
            name: "recipient",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "emergency_withdraw_specific_token",
        type: "function",
        inputs: [
          {
            name: "token_name",
            type: "core::felt252",
          },
          {
            name: "amount",
            type: "core::integer::u256",
          },
          {
            name: "recipient",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "add_supported_token",
        type: "function",
        inputs: [
          {
            name: "token_name",
            type: "core::felt252",
          },
          {
            name: "token_address",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "remove_supported_token",
        type: "function",
        inputs: [
          {
            name: "token_name",
            type: "core::felt252",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
    ],
  },
  {
    name: "constructor",
    type: "constructor",
    inputs: [
      {
        name: "admin",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        name: "fee_recipient",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        name: "pragma_oracle",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        name: "betting_token",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::ModeratorAdded",
    type: "event",
    members: [
      {
        kind: "data",
        name: "moderator",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "added_by",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::ModeratorRemoved",
    type: "event",
    members: [
      {
        kind: "data",
        name: "moderator",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "removed_by",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::EmergencyPaused",
    type: "event",
    members: [
      {
        kind: "data",
        name: "paused_by",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "reason",
        type: "core::byte_array::ByteArray",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::MarketCreated",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "creator",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "market_type",
        type: "core::integer::u8",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::MarketResolved",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "resolver",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "winning_choice",
        type: "core::integer::u8",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::WagerPlaced",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "user",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "choice",
        type: "core::integer::u8",
      },
      {
        kind: "data",
        name: "amount",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "fee_amount",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "net_amount",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "wager_index",
        type: "core::integer::u8",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::FeesCollected",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "fee_amount",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "fee_recipient",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::WinningsCollected",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "user",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "amount",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "wager_index",
        type: "core::integer::u8",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::BetPlaced",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u256",
      },
      {
        kind: "data",
        name: "user",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "choice",
        type: "core::integer::u8",
      },
      {
        kind: "data",
        name: "amount",
        type: "core::integer::u256",
      },
    ],
  },
  {
    kind: "enum",
    name: "stakcast::prediction::PredictionHub::Event",
    type: "event",
    variants: [
      {
        kind: "nested",
        name: "ModeratorAdded",
        type: "stakcast::prediction::ModeratorAdded",
      },
      {
        kind: "nested",
        name: "ModeratorRemoved",
        type: "stakcast::prediction::ModeratorRemoved",
      },
      {
        kind: "nested",
        name: "EmergencyPaused",
        type: "stakcast::prediction::EmergencyPaused",
      },
      {
        kind: "nested",
        name: "MarketCreated",
        type: "stakcast::prediction::MarketCreated",
      },
      {
        kind: "nested",
        name: "MarketResolved",
        type: "stakcast::prediction::MarketResolved",
      },
      {
        kind: "nested",
        name: "WagerPlaced",
        type: "stakcast::prediction::WagerPlaced",
      },
      {
        kind: "nested",
        name: "FeesCollected",
        type: "stakcast::prediction::FeesCollected",
      },
      {
        kind: "nested",
        name: "WinningsCollected",
        type: "stakcast::prediction::WinningsCollected",
      },
      {
        kind: "nested",
        name: "BetPlaced",
        type: "stakcast::prediction::BetPlaced",
      },
    ],
  },
] as const satisfies Abi;
