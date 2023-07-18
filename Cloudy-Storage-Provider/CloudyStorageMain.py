#Benjamin Djukastein, created in part via ChatGPT prompts
import os
import json
from flask import Flask, abort, make_response, request, render_template, send_file, jsonify
from werkzeug.utils import secure_filename
from dotenv import load_dotenv
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

# Initialize connection to smart contract instance using locally hosted Ganache as our provider
web3 = Web3(Web3.HTTPProvider(os.getenv('CONTRACT_URL'))) 
contract_address = os.getenv('CONTRACT_ADDRESS')
local_storage_path = os.getenv('LOCAL_STORAGE_PATH')
max_stored_bytes = os.getenv('MAX_STORAGE_IN_BYTES')
wallet_address = os.getenv('WALLET_ADDRESS')
available_storage_bytes = 0 # this value is set properly in set_blockchain_endpoint

cloudySmartContract = web3.eth.contract(address=contract_address, abi=contract_abi)
app._got_first_request = False

@app.before_request
def run_setup_once():
    if not app._got_first_request:
        set_blockchain_endpoint()
        app._got_first_request = True

def set_blockchain_endpoint():
    global available_storage_bytes, wallet_address
    #NOTE this is untested!
    storage_provider_ip = request.host.split(':')[0]
    
    available_storage_bytes = max_stored_bytes - count_storage_bytes_in_use()

    try:
        response = cloudySmartContract.functions.addStorageProvider(storage_provider_ip, wallet_address, available_storage_bytes).call()
        if response.status_code == 200:
            print(f"Successfully Initialized storage provider at {storage_provider_ip}")
        else:
            print("Error: Unable to connect to Cloudy Blockchain")
    except response.RequestException:
        print("Error: Unable to connect to Cloudy Blockchain")




# How to call a Cloudy contract function
# result = cloudySmartContract.functions.function_name().call()

#Test endpoint just for making sure we are connected to the blockchain
@app.route('/ensureContractDeployment', methods=['GET'])
def ensureContractDeployment():
    exampleBytes20 = b'\x12\x34\x56\x78\x90\x12\x34\x56\x78\x90\x12\x34\x56\x78\x90\x12\x34\x56\x78\x90'
    result = cloudySmartContract.functions.checkFileHashExternal(exampleBytes20).call()
    response = make_response('Checking whether file 0x1234567890123456789012345678901234567890 exists returned: ' + str(result))
    print(response)
    return response

@app.route('/upload', methods=['POST'])
def upload_shards():
    global available_storage_bytes, wallet_address
    # Check if the 'shards' key exists in the request
    if 'shards' not in request.files:
        return 'No shards found in the request. Try POSTING again with your desired shard files sent under the key "shards".'
    
    #Confirm adding this shard will not exceed storage space
    total_bytes_uploading = 0
    for file in request.files.values():
        if file:
            file_size = len(file.read())
            total_bytes_uploading += file_size

    if total_bytes_uploading <= available_storage_bytes:
        print("Directory usage is within the limit.")
        shards = request.files.getlist('shards')

        for shard in shards:
            # Check if a file was selected
            if shard.filename == '':
                return 'Cannot save nameless shards.'
            # Save the file to the specified path
            shard_name = secure_filename(shard.filename)
            #use the raw path from .env file to prevent backslashes from being misinterpreted.
            shard.save(r"{}/{}".format(os.getenv('LOCAL_STORAGE_PATH'), shard_name))
            #update blockchain to track which storage provider is storing this shard
            response = cloudySmartContract.functions.assignStorageProvider(shard.id, wallet_address).call()
        
            

        response = make_response('Shards uploaded successfully')
        response.status_code = 200

        #update available storage space
        available_storage_bytes = max_stored_bytes - count_storage_bytes_in_use()
        
        return response
    
    else:
        error_message = f'Not enough space to store the shards. Total bytes uploading: {total_bytes_uploading}, Available storage bytes: {available_storage_bytes}'
        print(error_message)
        return jsonify({'error': error_message}), 507 #507 means Insufficient Storage


@app.route('/download/<shardname>', methods=['GET'])
def download_shard(shardname):
    file_path = os.path.join(os.getenv('LOCAL_STORAGE_PATH'), shardname)

    if os.path.exists(file_path):
        return send_file(file_path, as_attachment=True)
    else:
        response = make_response(f"File '{shardname}' does not exist.")
        response.status_code = 404
        return response
#TODO declare your storage provider info to blockchain
#TODO: making sure file size limit is respected. Auditor method checking who is requesting the file. Updating the blockchain contract with which shards are being stored.
#TODO: have a function the auditor can hit, which this service responds whether it has the requested file, via merkle tree ideally.
@app.route('/delete/<shardname>', methods=['DELETE'])
def delete_shard(shardname):
    file_path = os.path.join(os.getenv('LOCAL_STORAGE_PATH'), shardname)
    if os.path.exists(file_path):
        os.remove(file_path)
        response = make_response(f"Shard '{shardname}' has been deleted.")
        response.status_code = 204
        return response
    else:
        abort(404, f"Shard '{shardname}' does not exist.")

@app.errorhandler(404)
def not_found_error(error):
    return f"Error {error.code}: {error.description}", error.code

@app.route('/', methods=['GET'])
def home():
    return render_template('index.html')

#Helper methods

def get_directory_usage(directory):
    stat = os.statvfs(directory)
    block_size = stat.f_frsize
    total_blocks = stat.f_blocks
    free_blocks = stat.f_bfree
    available_space = block_size * free_blocks
    return available_space

#Returns number of storage bytes currently in use storing other people's shards
def count_storage_bytes_in_use():
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(local_storage_path):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            total_size += os.path.getsize(file_path)

    return total_size
currently_used_bytes = count_storage_bytes_in_use()

#TODO: finish the method
# def is_space_available_to_store(nextShard):
#     if (currently_used_bytes + nextShard < )

@app.route('/audit', methods=['POST'])
def audit_files():
    # Check if 'shards' key exists in the request JSON data
    # if request.json  TODO: UNFINISHED CODE HERE PUSHED TO UNBLOCK JEN
    
    if 'shards' not in request.json:
        return 'No shard IDs found in the request', 400

    shardIDs = request.json['shards']
    storage_path = os.getenv('LOCAL_STORAGE_PATH')

    # Check if all shards exist in the storage directory
    for shardID in shardIDs:
        #TODO ensure this path is actually valid
        file_path = os.path.join(storage_path, shardID)
        if not os.path.exists(file_path):
            return 'Not all files are stored locally', 200

    # All files exist in the storage directory
    return 'All files are stored locally', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
