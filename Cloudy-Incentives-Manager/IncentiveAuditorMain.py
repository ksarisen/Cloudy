import time
import requests
from flask import Flask

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

def ping_loop():
    while True: #TODO create a way to end the loop if needed.
        try:
            # Ping the desired endpoint
            #TODO: get list of storage provider ips from blockchain, then loop to query each of them.
            response = requests.get('http://localhost:5000/audit')
            print(response.text)  # Print the response for demonstration

            #TODO loop and every 5 minute ping auditStorageProviders(uint256[] calldata _shardIds)

        except requests.RequestException as e:
            print('Error occurred during ping:', e)

        time.sleep(300)  # Sleep for 5 minutes (300 seconds)

if __name__ == '__main__':
    # Start the ping loop in a separate thread
    import threading
    threading.Thread(target=ping_loop, daemon=True).start()

    # Run the Flask server
    app.run()
