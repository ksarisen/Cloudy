import time
import requests
import random
from flask import Flask, make_response

app = Flask(__name__)

# Initialize connection to smart contract instance
web3 = Web3(Web3.HTTPProvider(os.getenv('CONTRACT_PROVIDER_URL'))) 
contract_address = os.getenv('CONTRACT_ADDRESS')
local_storage_path = os.getenv('LOCAL_STORAGE_PATH')
contract_abi = os.getenv('BLOCKCHAIN_ABI')
max_stored_bytes = os.getenv('MAX_STORAGE_IN_BYTES')


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

            # Before selecting random shard IDs
            print("Selecting random shard IDs to audit...")
            shardIdsToAudit = selectRandomShardsToAudit(storageProvidersToAudit, 5)
            print("Shard IDs to audit:", shardIdsToAudit)

            # Before auditing storage providers
            print("Auditing storage providers...")
            cloudySmartContract.functions.auditStorageProviders(shardIdsToAudit).call()

            # After auditing storage providers (optional)
            print("Audit complete.")
            
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

        time.sleep(300)  # Sleep for 5 minutes (300 seconds)

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
