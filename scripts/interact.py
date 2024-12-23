import calimero_sdk as calimero
from starknet_py.contract import Contract

async def interact():
    # Initialize Calimero SDK
    calimero.init("calimero_config.toml")
    signer = calimero.get_signer()

    # Get contract address
    contract_address = "0xYourContractAddress"  # Replace with the deployed contract address
    contract = await Contract.from_address(contract_address)

    # Call vote function to cast a vote
    voter = 1  # Voter ID
    choice = 2  # Vote choice
    response = await contract.invoke("vote", args=[voter, choice], signer=signer)
    
    print(f"Vote casted: {response}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(interact())
