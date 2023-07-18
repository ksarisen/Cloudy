import os
import time
import random
import json

import requests
from dotenv import load_dotenv
from flask import Flask, make_response
from web3 import Web3

#load the local variables from .env file
load_dotenv() 

app = Flask(__name__)

app.debug = True

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

# Initialize connection to smart contract instance
web3 = Web3(Web3.HTTPProvider(os.getenv('CONTRACT_URL'))) 
contract_address = os.getenv('CONTRACT_ADDRESS')

cloudySmartContract = web3.eth.contract(address=contract_address, abi=contract_abi)


# @app.route('/ping')
# def ping_endpoint():
#     # Perform any desired actions or logic for the ping endpoint
#     # ...

#     return 'Ping received'

#Test endpoint just for making sure we are connected to the blockchain
@app.route('/ensureContractDeployment', methods=['GET'])
def ensureContractDeployment():
    exampleBytes20 = b'\x12\x34\x56\x78\x90\x12\x34\x56\x78\x90\x12\x34\x56\x78\x90\x12\x34\x56\x78\x90'
    result = cloudySmartContract.functions.checkFileHashExternal(exampleBytes20).call()
    response = make_response('Checking whether file 0x1234567890123456789012345678901234567890 exists returned: ' + str(result))
    print(response)
    return response

#loops every 5 minutes, calls blockchain auditStorageProviders(uint256[] calldata _shardIds)
def audit_storage_providers_loop():
    while True:  # TODO: Create a way to end the loop if needed.
        try:
            # TODO: Get array of of storage provider addresses from the blockchain, then loop to query each of them.
            # Before getting storage provider data
            print("Fetching storage provider data...")
            storageProvidersToAudit = cloudySmartContract.functions.getStorageProviderDataOfProvidersCurrentlyStoringShards().call()
            print("Storage providers to audit:", storageProvidersToAudit)

            if len(storageProvidersToAudit) > 0:
                # Before selecting random shard IDs
                print("Selecting random shard IDs to audit...")
                shardIdsToAudit = selectRandomShardsToAudit(storageProvidersToAudit, 5)
                print("Shard IDs to audit:", shardIdsToAudit)

                # Before auditing storage providers
                print("Auditing storage providers...")
                cloudySmartContract.functions.auditStorageProviders(shardIdsToAudit).call()

                # After auditing storage providers (optional)
                print("Audit complete.")
            
            else:
                print("Blockchain has no files currently being stored. No need to audit.")
            

            
            
        #     #Beyond here is ben's version that actually pings each storage provider.
        #     for storageProvider in storageProvidersToAudit:
        #         # TODO: Concatenate StorageProvider.ip + ":5000/audit" to create the URL
        #         audit_url = f"http://{storageProvider['ip']}:5000/audit"

        #         try:
        #             # Send a POST request to the audit URL and expect a boolean response
        #             response = requests.post(audit_url)
        #             #TODO: eventually upgrade the error checking to a proper merkle audit of the shards instead of trusting the storage provider to return true/false
        #             #You have access to the following data about each storageProvider:
        #             # struct StorageProvider {
        #             #     bytes32 ip;
        #             #     address walletAddress;
        #             #     uint256 availableStorageSpace;  // Tracking in bytes
        #             #     uint256 maximumStorageSize;     // Tracking in bytes
        #             #     bool isStoring;
        #             #     uint256[] storedShardIds;
        #             # }
        #             if not response.ok or response.text.lower() == 'false':
        #                 #If a storageProvider fails to respond, remove it from the list of available providers
        #                 #TODO: find a way to reassign the shards it was holding using other redundant shards
        #                 storageProvidersToAudit = cloudySmartContract.functions.getStorageProvidersStoring().call()
        #                 # Log an error if the response is not successful or returns False
        #                 print(f"Error with Storage Provider {storageProvider['ip']}. Response: {response.text}")

        #         except requests.RequestException as e:
        #             # Log an error if the request fails
        #             print(f"Error occurred during audit for Storage Provider {storageProvider['ip']}: {e}")

        except requests.RequestException as e:
            print('Error occurred during StorageProvider audit:', e)
        randomAuditInterval = random_seconds()
        print("Now waiting for " +randomAuditInterval+ " seconds...")
        time.sleep(randomAuditInterval)  # Sleep for 5 minutes (300 seconds)
        print('Error occurred during StorageProvider audit:', e)

def random_seconds():
    # Determine the maximum number of intervals (15 seconds each) up to 500 seconds
    max_intervals = 500 // 15
    
    # Pick a random number of intervals
    num_intervals = random.randint(1, max_intervals)
    
    # Calculate the total number of seconds
    total_seconds = num_intervals * 15
    
    return total_seconds

def selectRandomShardsToAudit(storageProviders, numShards):
     # Combine all storedShardIds from all storage providers into a single list
    allStoredShardIds = [shardId for storageProvider in storageProviders for shardId in storageProvider['storedShardIds']]

    # If there are less than numShards shard IDs in total, return them all
    if len(allStoredShardIds) <= numShards:
        return allStoredShardIds

    # Randomly select numShards shard IDs from the list
    selectedShardIds = random.sample(allStoredShardIds, numShards)
    return selectedShardIds

if __name__ == '__main__':
    # Start the ping loop in a separate thread
    import threading
    threading.Thread(target=audit_storage_providers_loop, daemon=True).start()

    # Run the Flask server
    app.run()
