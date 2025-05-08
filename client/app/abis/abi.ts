export default [
  {
    name: "PredictionMarketImp",
    type: "impl",
    interface_name: "stakcast::interface::IPredictionMarket",
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
    name: "stakcast::interface::Market",
    type: "struct",
    members: [
      {
        name: "creator",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        name: "title",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "description",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "category",
        type: "core::byte_array::ByteArray",
      },
      {
        name: "start_time",
        type: "core::integer::u64",
      },
      {
        name: "end_time",
        type: "core::integer::u64",
      },
      {
        name: "resolution_time",
        type: "core::integer::u64",
      },
      {
        name: "total_stake",
        type: "core::integer::u256",
      },
      {
        name: "min_stake",
        type: "core::integer::u256",
      },
      {
        name: "max_stake",
        type: "core::integer::u256",
      },
      {
        name: "num_outcomes",
        type: "core::integer::u32",
      },
      {
        name: "validator",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
  },
  {
    name: "stakcast::interface::MarketStatus",
    type: "enum",
    variants: [
      {
        name: "Active",
        type: "()",
      },
      {
        name: "Closed",
        type: "()",
      },
      {
        name: "Resolved",
        type: "()",
      },
      {
        name: "Disputed",
        type: "()",
      },
      {
        name: "Cancelled",
        type: "()",
      },
    ],
  },
  {
    name: "stakcast::interface::MarketOutcome",
    type: "struct",
    members: [
      {
        name: "winning_outcome",
        type: "core::integer::u32",
      },
      {
        name: "resolution_details",
        type: "core::felt252",
      },
    ],
  },
  {
    name: "core::option::Option::<stakcast::interface::MarketOutcome>",
    type: "enum",
    variants: [
      {
        name: "Some",
        type: "stakcast::interface::MarketOutcome",
      },
      {
        name: "None",
        type: "()",
      },
    ],
  },
  {
    name: "stakcast::interface::MarketDetails",
    type: "struct",
    members: [
      {
        name: "market",
        type: "stakcast::interface::Market",
      },
      {
        name: "status",
        type: "stakcast::interface::MarketStatus",
      },
      {
        name: "outcome",
        type: "core::option::Option::<stakcast::interface::MarketOutcome>",
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
    name: "stakcast::interface::Position",
    type: "struct",
    members: [
      {
        name: "amount",
        type: "core::integer::u256",
      },
      {
        name: "outcome_index",
        type: "core::integer::u32",
      },
      {
        name: "claimed",
        type: "core::bool",
      },
    ],
  },
  {
    name: "stakcast::interface::IPredictionMarket",
    type: "interface",
    items: [
      {
        name: "create_market",
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
            name: "category",
            type: "core::byte_array::ByteArray",
          },
          {
            name: "start_time",
            type: "core::integer::u64",
          },
          {
            name: "end_time",
            type: "core::integer::u64",
          },
          {
            name: "outcomes",
            type: "core::array::Array::<core::felt252>",
          },
          {
            name: "min_stake",
            type: "core::integer::u256",
          },
          {
            name: "max_stake",
            type: "core::integer::u256",
          },
        ],
        outputs: [
          {
            type: "core::integer::u32",
          },
        ],
        state_mutability: "external",
      },
      {
        name: "take_position",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
          {
            name: "outcome_index",
            type: "core::integer::u32",
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
        name: "claim_winnings",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "get_market_details",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
        ],
        outputs: [
          {
            type: "stakcast::interface::MarketDetails",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_user_position",
        type: "function",
        inputs: [
          {
            name: "user",
            type: "core::starknet::contract_address::ContractAddress",
          },
          {
            name: "market_id",
            type: "core::integer::u32",
          },
        ],
        outputs: [
          {
            type: "stakcast::interface::Position",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_market_stats",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
        ],
        outputs: [
          {
            type: "(core::integer::u256, core::array::Array::<core::integer::u256>)",
          },
        ],
        state_mutability: "view",
      },
      {
        name: "get_stake_token",
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
        name: "assign_validator",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "resolve_market",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
          {
            name: "winning_outcome",
            type: "core::integer::u32",
          },
          {
            name: "resolution_details",
            type: "core::felt252",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "dispute_market",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
          {
            name: "reason",
            type: "core::felt252",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "cancel_market",
        type: "function",
        inputs: [
          {
            name: "market_id",
            type: "core::integer::u32",
          },
          {
            name: "reason",
            type: "core::felt252",
          },
        ],
        outputs: [],
        state_mutability: "external",
      },
      {
        name: "set_market_validator",
        type: "function",
        inputs: [
          {
            name: "market_validator",
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
        name: "stake_token_address",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        name: "fee_collector",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        name: "platform_fee",
        type: "core::integer::u256",
      },
      {
        name: "market_validator_address",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::PredictionMarket::MarketCreated",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u32",
      },
      {
        kind: "data",
        name: "creator",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "title",
        type: "core::byte_array::ByteArray",
      },
      {
        kind: "data",
        name: "start_time",
        type: "core::integer::u64",
      },
      {
        kind: "data",
        name: "end_time",
        type: "core::integer::u64",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::PredictionMarket::PositionTaken",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u32",
      },
      {
        kind: "data",
        name: "user",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "outcome_index",
        type: "core::integer::u32",
      },
      {
        kind: "data",
        name: "amount",
        type: "core::integer::u256",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::PredictionMarket::MarketResolved",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u32",
      },
      {
        kind: "data",
        name: "outcome",
        type: "core::integer::u32",
      },
      {
        kind: "data",
        name: "resolver",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "resolution_details",
        type: "core::felt252",
      },
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::PredictionMarket::WinningsClaimed",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u32",
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
    ],
  },
  {
    kind: "struct",
    name: "stakcast::prediction::PredictionMarket::MarketDisputed",
    type: "event",
    members: [
      {
        kind: "data",
        name: "market_id",
        type: "core::integer::u32",
      },
      {
        kind: "data",
        name: "disputer",
        type: "core::starknet::contract_address::ContractAddress",
      },
      {
        kind: "data",
        name: "reason",
        type: "core::felt252",
      },
    ],
  },
  {
    kind: "enum",
    name: "stakcast::prediction::PredictionMarket::Event",
    type: "event",
    variants: [
      {
        kind: "nested",
        name: "MarketCreated",
        type: "stakcast::prediction::PredictionMarket::MarketCreated",
      },
      {
        kind: "nested",
        name: "PositionTaken",
        type: "stakcast::prediction::PredictionMarket::PositionTaken",
      },
      {
        kind: "nested",
        name: "MarketResolved",
        type: "stakcast::prediction::PredictionMarket::MarketResolved",
      },
      {
        kind: "nested",
        name: "WinningsClaimed",
        type: "stakcast::prediction::PredictionMarket::WinningsClaimed",
      },
      {
        kind: "nested",
        name: "MarketDisputed",
        type: "stakcast::prediction::PredictionMarket::MarketDisputed",
      },
    ],
  },
] as const;
