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
    name: "core::option::Option::<(core::felt252, core::integer::u128)>",
    type: "enum",
    variants: [
      {
        name: "Some",
        type: "(core::felt252, core::integer::u128)",
      },
      {
        name: "None",
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
    name: "stakcast::types::Outcome",
    type: "enum",
    variants: [
      {
        name: "Option1",
        type: "core::felt252",
      },
      {
        name: "Option2",
        type: "core::felt252",
      },
    ],
  },
  {
    name: "stakcast::types::MarketCategory",
    type: "enum",
    variants: [
      {
        name: "Normal",
        type: "()",
      },
      {
        name: "Politics",
        type: "()",
      },
      {
        name: "Sports",
        type: "()",
      },
      {
        name: "Crypto",
        type: "()",
      },
      {
        name: "Business",
        type: "()",
      },
      {
        name: "Entertainment",
        type: "()",
      },
      {
        name: "Science",
        type: "()",
      },
      {
        name: "Other",
        type: "()",
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
    name: "stakcast::types::MarketStatus",
    type: "enum",
    variants: [
      {
        name: "Active",
        type: "()",
      },
      {
        name: "Locked",
        type: "()",
      },
      {
        name: "Resolved",
        type: "stakcast::types::Outcome",
      },
    ],
  },
  {
    name: "core::option::Option::<core::integer::u8>",
    type: "enum",
    variants: [
      {
        name: "Some",
        type: "core::integer::u8",
      },
      {
        name: "None",
        type: "()",
      },
    ],
  },
  {
    name: "stakcast::types::PredictionMarket",
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
        type: "(stakcast::types::Outcome, stakcast::types::Outcome)",
      },
      {
        name: "category",
        type: "stakcast::types::MarketCategory",
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
        name: "status",
        type: "stakcast::types::MarketStatus",
      },
      {
        name: "winning_choice",
        type: "core::option::Option::<core::integer::u8>",
      },
      {
        name: "total_shares_option_one",
        type: "core::integer::u256",
      },
      {
        name: "total_shares_option_two",
        type: "core::integer::u256",
      },
      {
        name: "total_pool",
        type: "core::integer::u256",
      },
      {
        name: "crypto_prediction",
        type: "core::option::Option::<(core::felt252, core::integer::u128)>",
      },
    ],
  },
  {
    name: "stakcast::types::BetActivity",
    type: "struct",
    members: [
      {
        name: "choice",
        type: "core::integer::u8",
      },
      {
        name: "amount",
        type: "core::integer::u256",
      },
    ],
  },
  {
    name: "stakcast::types::UserStake",
    type: "struct",
    members: [
      {
        name: "shares_a",
        type: "core::integer::u256",
      },
      {
        name: "shares_b",
        type: "core::integer::u256",
      },
      {
        name: "total_invested",
        type: "core::integer::u256",
      },
    ],
  },
  {
    name: "stakcast::interface::IPredictionHub",
    type: "interface",
    items: [
      {
        name: "create_predictions",
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
            type: "core::integer::u8",
          },
          {
            name: "end_time",
            type: "core::integer::u64",
          },
          {
            name: "prediction_market_type",
            type: "core::integer::u8",
          },
          {
            name: "crypto_prediction",
            type: "core::option::Option::<(core::felt252, core::integer::u128)>",
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
            type: "stakcast::types::PredictionMarket",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_predictions_by_market_category",
        type: "function",
        inputs: [
          {
            name: "category",
            type: "core::integer::u8",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_market_activity",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::BetActivity>",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "get_all_predictions",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_general_predictions",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_market_status",
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
        outputs: [
          {
            type: "(core::bool, core::bool)",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_open_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_locked_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_resolved_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_closed_bets_for_user",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_open_bets_for_user",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_locked_bets_for_user",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_bets_for_user",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_protocol_token",
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
        name: "get_active_prediction_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_active_general_prediction_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_active_sport_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_active_crypto_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_all_resolved_prediction_markets",
        type: "function",
        inputs: [],
        outputs: [
          {
            type: "core::array::Array::<stakcast::types::PredictionMarket>",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "is_prediction_market_open_for_betting",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
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
        name: "calculate_share_prices",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "(core::integer::u256, core::integer::u256)",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "buy_shares",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "choice",
            type: "core::integer::u8",
          },
          {
            name: "amount",
            type: "core::integer::u256",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "get_user_stake_details",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u256",
          },
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
        ],
        outputs: [
          {
            type: "stakcast::types::UserStake",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "claim",
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
        inputs: [],
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
        name: "emergency_resolve_multiple_markets",
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
          {
            name: "winning_choices",
            type: "core::array::Array::<core::integer::u8>",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "set_protocol_token",
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
        name: "set_protocol_restrictions",
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
        name: "protocol_token",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
  },
] as const satisfies Abi;
