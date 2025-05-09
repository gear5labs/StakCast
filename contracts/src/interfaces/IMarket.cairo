use starknet::contract_address::ContractAddress;
#[starknet::interface]
pub trait IPredictionMarket<TContractState> {
    fn create_market(
        ref self: TContractState,
        question: felt252,
        outcomes: Array<felt252>,
        startime: u64,
        end_time: u64,
    ) -> u64;

    fn purchase_units(ref self: TContractState, market_id: u64, outcome_id: u32, amount: u128);

    fn resolve_market(ref self: TContractState, market_id: u64, winning_outcome_id: u32);

    fn claim_rewards(ref self: TContractState, market_id: u64);

    fn get_market(self: @TContractState, market_id: u64) -> Market;
    fn get_user_position(
        self: @TContractState, user: ContractAddress, market_id: u64, outcome_id: u32,
    ) -> u128;
    fn get_total_outcome_units(self: @TContractState, market_id: u64, outcome_id: u32) -> u128;
    fn get_market_total_volume(self: @TContractState, market_id: u64) -> u128;
    fn get_resolved_outcome_id(self: @TContractState, market_id: u64) -> u32;
    fn get_market_count(self: @TContractState) -> u64;
    fn is_validator(self: @TContractState, address: ContractAddress) -> bool;
    fn add_validator(ref self: TContractState, account: ContractAddress);
    fn remove_validator(ref self: TContractState, account: ContractAddress);
}

