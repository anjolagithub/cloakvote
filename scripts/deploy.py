# scripts/deploy.py
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.models import StarknetChainId
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.contract import Contract
import asyncio
import json
import os
from datetime import datetime, timedelta

async def main():
    # Configure deployment parameters
    TESTNET_URL = os.getenv("STARKNET_TESTNET_URL", "http://127.0.0.1:5050")
    PRIVATE_KEY = os.getenv("STARKNET_PRIVATE_KEY")
    ACCOUNT_ADDRESS = os.getenv("STARKNET_ACCOUNT_ADDRESS")
    
    # Initialize client
    client = GatewayClient(TESTNET_URL)
    account = AccountClient(
        client=client,
        address=ACCOUNT_ADDRESS,
        key_pair=KeyPair.from_private_key(PRIVATE_KEY),
        chain=StarknetChainId.TESTNET,
    )
    
    print("Deploying CloakVote contract...")
    
    # Load compiled contract
    with open("target/dev/cloakvote.json", "r") as f:
        contract_definition = json.load(f)
    
    # Deploy contract
    deploy_result = await Contract.deploy(
        account=account,
        compilation_source=contract_definition,
        constructor_args=[account.address],  # Admin address
    )
    
    contract = deploy_result.deployed_contract
    print(f"Contract deployed at: {contract.address}")
    
    # Initialize voting parameters
    print("Initializing voting parameters...")
    
    # Set voting period (24 hours from now)
    start_time = int(datetime.now().timestamp())
    end_time = int((datetime.now() + timedelta(days=1)).timestamp())
    encryption_key = 123456789  # In production, use secure key generation
    
    await contract.functions["initialize_voting"].invoke(
        start_time,
        end_time,
        encryption_key,
    )
    
    print("Contract initialized successfully!")
    print(f"Voting start time: {start_time}")
    print(f"Voting end time: {end_time}")
    
    # Save deployment info
    deployment_info = {
        "contract_address": hex(contract.address),
        "admin_address": ACCOUNT_ADDRESS,
        "start_time": start_time,
        "end_time": end_time,
        "network": "testnet",
        "timestamp": datetime.now().isoformat()
    }
    
    with open("deployment_info.json", "w") as f:
        json.dump(deployment_info, f, indent=2)
    
    print("Deployment info saved to deployment_info.json")

if __name__ == "__main__":
    asyncio.run(main())