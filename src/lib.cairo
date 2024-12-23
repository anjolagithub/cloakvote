// src/lib.cairo
use starknet::ContractAddress;

#[starknet::interface]
trait ICloakVote<TContractState> {
    // Initialization and admin functions
    fn initialize_voting(
        ref self: TContractState,
        start_time: u64,
        end_time: u64,
        encryption_key: felt252
    );
    fn add_proposal(ref self: TContractState, proposal_id: felt252);
    fn register_voter(ref self: TContractState, voter: ContractAddress);

    // Voting functions
    fn submit_vote(ref self: TContractState, encrypted_vote: felt252);

    // View functions
    fn get_voting_status(self: @TContractState) -> (bool, u64, u64);
    fn is_voter_registered(self: @TContractState, voter: ContractAddress) -> bool;
    fn has_voted(self: @TContractState, voter: ContractAddress) -> bool;
}

// Common errors
mod errors {
    const ONLY_ADMIN: felt252 = 'ONLY_ADMIN';
    const NOT_INITIALIZED: felt252 = 'NOT_INITIALIZED';
    const ALREADY_INITIALIZED: felt252 = 'ALREADY_INITIALIZED';
    const INVALID_TIMEFRAME: felt252 = 'INVALID_TIMEFRAME';
    const NOT_REGISTERED: felt252 = 'NOT_REGISTERED';
    const ALREADY_VOTED: felt252 = 'ALREADY_VOTED';
    const INVALID_VOTING_TIME: felt252 = 'INVALID_VOTING_TIME';
}

// Common events
#[starknet::interface]
trait ICloakVoteEvents<TContractState> {
    fn emit_vote_submitted(
        ref self: TContractState,
        voter: ContractAddress,
        encrypted_vote: felt252,
        timestamp: u64
    );

    fn emit_proposal_added(
        ref self: TContractState,
        proposal_id: felt252,
        timestamp: u64
    );

    fn emit_voting_started(
        ref self: TContractState,
        start_time: u64
    );

    fn emit_voting_ended(
        ref self: TContractState,
        end_time: u64
    );
}