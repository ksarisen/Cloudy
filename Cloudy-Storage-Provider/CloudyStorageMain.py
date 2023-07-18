
#Benjamin Djukastein, created in part via ChatGPT prompts
import os
import json
from flask import Flask, abort, make_response, request, render_template, send_file, jsonify
from werkzeug.utils import secure_filename
from dotenv import load_dotenv
from web3 import Web3
import CloudyStorageFlaskServer  # Import the Flask app
import socket

#load the local variables from .env file
load_dotenv() 

def get_ABI():
    # Get path to contractabi.json
    current_directory = os.path.dirname(os.path.abspath(__file__))
    contractabi_filename = "contractabi.json"
    contractabi_path = os.path.join(current_directory, contractabi_filename)

    # Read the contents of contractabi.json as a Python dictionary
    with open(contractabi_path, "r") as contractabi_file:
        blockchain_ABI = json.load(contractabi_file)
    return blockchain_ABI
contract_abi = get_ABI()

# Initialize connection to smart contract instance using locally hosted Ganache as our provider
web3 = Web3(Web3.HTTPProvider('http://localhost:7545'))

#web3 = Web3(Web3.HTTPProvider(os.getenv('CONTRACT_URL'))) 
contract_address = os.getenv('CONTRACT_ADDRESS')
local_storage_path = os.getenv('LOCAL_STORAGE_PATH')
max_stored_bytes = int(os.getenv('MAX_STORAGE_IN_BYTES'))
wallet_address = os.getenv('WALLET_ADDRESS')
available_storage_bytes = 0 # this value is set properly in set_blockchain_endpoint

cloudySmartContract = web3.eth.contract(address=contract_address, abi=contract_abi)

def get_host_ip():
    # Create a temporary socket to get the host IP address
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))  # Connect to a public DNS server (Google DNS)
    host_ip = s.getsockname()[0]  # Get the IP address
    s.close()
    return host_ip

def get_storage_providers():
    # Get the list of storage providers from the contract
    storage_providers = cloudySmartContract.functions.getStorageProvidersStoring().call()
    print("Currently stored storage providers:")
    for provider in storage_providers:
        print(provider)
    print("-------------------------")

def set_blockchain_endpoint():
    global available_storage_bytes, wallet_address

    storage_provider_ip = "http://127.0.0.1"  # Replace this with the correct IP

    # Check if the storage provider already exists in the contract
    if wallet_address in cloudySmartContract.functions.getStorageProvidersStoring().call():
        print("Storage provider already exists in the contract.")
        return

    available_storage_bytes = max_stored_bytes - count_storage_bytes_in_use()

    response = None  # Initialize the response variable to None

    try:
        # Convert available_storage_bytes to uint256 type
        uint256_storage = int(available_storage_bytes)
        transaction = {
            'from': wallet_address,
            # Add other transaction parameters as needed
        }
        # What happens when I restart this service?
        response = cloudySmartContract.functions.addStorageProvider(storage_provider_ip, wallet_address, uint256_storage).transact(transaction)
        print(f"Transaction successful. Response: {response}")
        get_storage_providers()  # for debugging
    except Exception as e:
        print(f"Error: {e}")

    # Use the response variable here or handle it as needed
    if response:
        print(response)






#Returns number of storage bytes currently in use storing other people's shards
def count_storage_bytes_in_use():
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(local_storage_path):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            total_size += os.path.getsize(file_path)

    return total_size
currently_used_bytes = count_storage_bytes_in_use()


if __name__ == '__main__':
    # Run the other functions first
    set_blockchain_endpoint()

    # Start the Flask server
    CloudyStorageFlaskServer.app.run(debug=True, port=5002)

    
