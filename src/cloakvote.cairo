// src/cloakvote.cairo

use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
use array::ArrayTrait;
use core::result::ResultTrait;
use core::option::OptionTrait;
use core::traits::Into;

use cloakvote::lib::{ICloakVote, ICloakVoteEvents, errors};
use cloakvote::utils;

#[starknet::contract]
mod CloakVote {
    use super::*;

    #[storage]
    struct Storage {
        // Voting configuration
        admin: ContractAddress,
        voting_start_time: u64,
        voting_end_time: u64,
        is_initialized: bool,
        
        // Voter management
        voters: LegacyMap<ContractAddress, bool>,
        voted: LegacyMap<ContractAddress, bool>,
        
        // Proposal management
        proposals: Array<felt252>,
        proposal_votes: LegacyMap<felt252, u256>,
        
        // Privacy features
        encryption_key: felt252,
        encrypted_votes: LegacyMap<ContractAddress, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        VoteSubmitted: VoteSubmitted,
        ProposalAdded: ProposalAdded,
        VotingStarted: VotingStarted,
        VotingEnded: VotingEnded
    }

    #[derive(Drop, starknet::Event)]
    struct VoteSubmitted {
        voter: ContractAddress,
        encrypted_vote: felt252,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ProposalAdded {
        proposal_id: felt252,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct VotingStarted {
        start_time: u64
    }

    #[derive(Drop, starknet::Event)]
    struct VotingEnded {
        end_time: u64
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
        self.is_initialized.write(false);
    }

    // Implementation of ICloakVote interface
    impl CloakVoteImpl of ICloakVote<ContractState> {
        fn initialize_voting(
            ref self: ContractState,
            start_time: u64,
            end_time: u64,
            encryption_key: felt252
        ) {
            // Only admin can initialize
            assert(get_caller_address() == self.admin.read(), errors::ONLY_ADMIN);
            assert(!self.is_initialized.read(), errors::ALREADY_INITIALIZED);
            assert(end_time > start_time, errors::INVALID_TIMEFRAME);

            self.voting_start_time.write(start_time);
            self.voting_end_time.write(end_time);
            self.encryption_key.write(encryption_key);
            self.is_initialized.write(true);

            // Emit event
            self.emit(VotingStarted { start_time });
        }

        fn add_proposal(ref self: ContractState, proposal_id: felt252) {
            // Only admin can add proposals
            assert(get_caller_address() == self.admin.read(), errors::ONLY_ADMIN);
            assert(self.is_initialized.read(), errors::NOT_INITIALIZED);
            
            self.proposals.append(proposal_id);
            
            // Emit event
            self.emit(ProposalAdded { 
                proposal_id, 
                timestamp: get_block_timestamp() 
            });
        }

        fn register_voter(ref self: ContractState, voter: ContractAddress) {
            assert(get_caller_address() == self.admin.read(), errors::ONLY_ADMIN);
            self.voters.write(voter, true);
        }

        fn submit_vote(ref self: ContractState, encrypted_vote: felt252) {
            let caller = get_caller_address();
            
            // Validate voting conditions
            assert(self.is_initialized.read(), errors::NOT_INITIALIZED);
            assert(self.voters.read(caller), errors::NOT_REGISTERED);
            assert(!self.voted.read(caller), errors::ALREADY_VOTED);
            
            let current_time = get_block_timestamp();
            assert(
                utils::is_valid_time_window(
                    current_time, 
                    self.voting_start_time.read(), 
                    self.voting_end_time.read()
                ),
                errors::INVALID_VOTING_TIME
            );

            // Store encrypted vote
            self.encrypted_votes.write(caller, encrypted_vote);
            self.voted.write(caller, true);

            // Emit event
            self.emit(VoteSubmitted { 
                voter: caller, 
                encrypted_vote,
                timestamp: current_time
            });
        }

        fn get_voting_status(self: @ContractState) -> (bool, u64, u64) {
            (
                self.is_initialized.read(),
                self.voting_start_time.read(),
                self.voting_end_time.read()
            )
        }

        fn is_voter_registered(self: @ContractState, voter: ContractAddress) -> bool {
            self.voters.read(voter)
        }

        fn has_voted(self: @ContractState, voter: ContractAddress) -> bool {
            self.voted.read(voter)
        }
    }

    // Implementation of event interface
    impl CloakVoteEventsImpl of ICloakVoteEvents<ContractState> {
        fn emit_vote_submitted(
            ref self: ContractState,
            voter: ContractAddress,
            encrypted_vote: felt252,
            timestamp: u64
        ) {
            self.emit(VoteSubmitted { voter, encrypted_vote, timestamp });
        }

        fn emit_proposal_added(
            ref self: ContractState,
            proposal_id: felt252,
            timestamp: u64
        ) {
            self.emit(ProposalAdded { proposal_id, timestamp });
        }

        fn emit_voting_started(
            ref self: ContractState,
            start_time: u64
        ) {
            self.emit(VotingStarted { start_time });
        }

        fn emit_voting_ended(
            ref self: ContractState,
            end_time: u64
        ) {
            self.emit(VotingEnded { end_time });
        }
    }
}