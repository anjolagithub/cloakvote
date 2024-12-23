// tests/test_cloakvote.cairo
use core::result::ResultTrait;
use core::option::OptionTrait;
use array::ArrayTrait;
use starknet::testing::set_caller_address;
use starknet::ContractAddress;
use starknet::contract_address_const;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
use super::utils::{encrypt_vote, decrypt_vote, validate_vote};

use cloakvote::CloakVote;

#[test]
fn test_contract_initialization() {
    // Deploy contract
    let contract = deploy_contract('CloakVote');
    let admin = contract_address_const::<0x123>();
    
    // Initialize voting
    let start_time = 1000_u64;
    let end_time = 2000_u64;
    let encryption_key = 0x456;
    
    start_prank(CheatTarget::All, admin);
    contract.initialize_voting(start_time, end_time, encryption_key);
    stop_prank(CheatTarget::All);
    
    // Verify initialization
    let (is_initialized, actual_start, actual_end) = contract.get_voting_status();
    assert(is_initialized == true, 'Should be initialized');
    assert(actual_start == start_time, 'Wrong start time');
    assert(actual_end == end_time, 'Wrong end time');
}

#[test]
fn test_voter_registration() {
    let contract = deploy_contract('CloakVote');
    let admin = contract_address_const::<0x123>();
    let voter = contract_address_const::<0x456>();
    
    // Register voter
    start_prank(CheatTarget::All, admin);
    contract.register_voter(voter);
    stop_prank(CheatTarget::All);
    
    // Verify registration
    assert(contract.is_voter_registered(voter) == true, 'Voter not registered');
}

#[test]
fn test_vote_submission() {
    let contract = deploy_contract('CloakVote');
    let admin = contract_address_const::<0x123>();
    let voter = contract_address_const::<0x456>();
    
    // Setup voting
    start_prank(CheatTarget::All, admin);
    contract.initialize_voting(0_u64, 9999999_u64, 0x789);
    contract.register_voter(voter);
    stop_prank(CheatTarget::All);
    
    // Submit vote
    let encrypted_vote = encrypt_vote(1, 0x789);
    start_prank(CheatTarget::All, voter);
    contract.submit_vote(encrypted_vote);
    stop_prank(CheatTarget::All);
    
    // Verify vote submission
    assert(contract.has_voted(voter) == true, 'Vote not recorded');
}

#[test]
#[should_panic(expected: ('ALREADY_VOTED',))]
fn test_double_voting_prevention() {
    let contract = deploy_contract('CloakVote');
    let admin = contract_address_const::<0x123>();
    let voter = contract_address_const::<0x456>();
    
    // Setup and first vote
    start_prank(CheatTarget::All, admin);
    contract.initialize_voting(0_u64, 9999999_u64, 0x789);
    contract.register_voter(voter);
    stop_prank(CheatTarget::All);
    
    let encrypted_vote = encrypt_vote(1, 0x789);
    start_prank(CheatTarget::All, voter);
    contract.submit_vote(encrypted_vote);
    
    // Attempt second vote - should fail
    contract.submit_vote(encrypted_vote);
}

fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);
    let admin = contract_address_const::<0x123>();
    contract.deploy(@array![admin]).unwrap()
}