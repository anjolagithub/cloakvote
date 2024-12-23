// src/utils.cairo
use core::traits::Into;
use core::option::OptionTrait;
use core::array::ArrayTrait;

// Simple encryption using XOR - in production, use stronger encryption
fn encrypt_vote(vote: felt252, key: felt252) -> felt252 {
    vote ^ key
}

fn decrypt_vote(encrypted_vote: felt252, key: felt252) -> felt252 {
    encrypted_vote ^ key
}

// Verify vote is within valid range
fn validate_vote(vote: felt252) -> bool {
    vote >= 0 && vote <= 1
}

// Hash function for vote commitment
fn hash_vote(vote: felt252, salt: felt252) -> felt252 {
    let mut data = ArrayTrait::new();
    data.append(vote);
    data.append(salt);
    poseidon_hash_span(data.span())
}

// Helper to convert address to felt
fn address_to_felt(address: ContractAddress) -> felt252 {
    address.into()
}

// Helper for time-based validations
fn is_valid_time_window(current_time: u64, start_time: u64, end_time: u64) -> bool {
    current_time >= start_time && current_time <= end_time
}