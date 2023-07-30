#Benjamin Djukastein, created in part via ChatGPT prompts
import os
import json
import re
from flask import Flask, abort, make_response, request, render_template, send_file, jsonify
from werkzeug.utils import secure_filename
from dotenv import load_dotenv
from web3 import Web3
import base64
from flask_cors import CORS

#load the local variables from .env file
load_dotenv() 

app = Flask(__name__)
CORS(app,origins=["http://localhost:3000"])

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
max_stored_bytes = int(os.getenv('MAX_STORAGE_IN_BYTES'))
wallet_address = os.getenv('WALLET_ADDRESS')
available_storage_bytes = 1000000000 # this value is set properly in set_blockchain_endpoint

cloudySmartContract = web3.eth.contract(address=contract_address, abi=contract_abi)

# app._got_first_request = False
# if not app._got_first_request:
#         set_blockchain_endpoint()
#         app._got_first_request = True

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
    if len(request.files) < 1:
        return 'No shards found in the request. Try POSTING again with your desired shard files sent under the key "request.files".'
    
    #Confirm adding this shard will not exceed storage space
    total_bytes_uploading = 0
    for shard in request.files.values():
        if shard:
            shard_size = len(shard.read())
            total_bytes_uploading += shard_size

    if total_bytes_uploading <= available_storage_bytes:

        for shard in request.files.values():
            # Check if a file was selected
            if shard.name == '':
                return jsonify({'error': 'Cannot save nameless shards.'}), 400 
            if not is_valid_filename(shard.name):
                return jsonify({'error': 'shard name invalid, must start with the phrase "shard_1"..., where 1 is the id of the shard'}), 400

            # Save the file to the specified path
            shard_name = secure_filename(shard.name)
            #use the raw path from .env file to prevent backslashes from being misinterpreted.
            shard.save(r"{}/{}".format(os.getenv('LOCAL_STORAGE_PATH'), shard_name))
            #update blockchain to track which storage provider is storing this shard
            #TODO: get id from shard/sent file blob.
            shardId = getShardIdfromShardName(shard_name)
            if shardId == -1:
                response_str = f"Unable to find shardId of shard {shard_name}"
                return jsonify({'error': response_str}), 400
            response = cloudySmartContract.functions.assignShardToStorageProvider(shardId, wallet_address).call()
            print(f"Successfully assigned shard {shardId} to storage provider {wallet_address}")
            print(F"blockchain's response to assigning shard to storage provider:", response)
            #TODO: check if storageProvider is now full. if so, take it off the blockchain list of availableProviders
            get_storage_providers()  # for debugging
            

        response = make_response('Shards uploaded successfully')
        response.status_code = 200

        #update available storage space
        available_storage_bytes = max_stored_bytes - count_storage_bytes_in_use()
        
        return response
    
    else:
        error_message = f'Not enough space to store the shards. Total bytes uploading: {total_bytes_uploading}, Available storage bytes: {available_storage_bytes}'
        print(error_message)
        return jsonify({'error': error_message}), 507 #507 means Insufficient Storage


@app.route('/download/<shardId>', methods=['GET'])
def download_shard(shardId):
    file_path = getShardPathFromShardID(shardId)
    if file_path is None:
        return 'Shard with the specified ID does not exist.', 404
    
    if os.path.exists(file_path):
        filename = os.path.basename(file_path)
        # Read the file contents
        with open(file_path, 'rb') as file:
            file_contents = file.read()

        # Convert the binary data to a base64-encoded string
        file_contents_base64 = base64.b64encode(file_contents).decode('utf-8')

        # Create a response data object with the filename and file contents
        response_data = {
            'filename': filename,
            'file_type': get_filetype_from_filename(filename),
            'file_contents': file_contents_base64
        }
    
        # response = send_file(file_path, as_attachment=True) #, add_etags=False
        
        return jsonify(response_data), 200
    else:
        response = make_response(f"File '{file_path}' does not exist.")
        response.status_code = 404
        return response
#TODO declare your storage provider info to blockchain
#TODO: making sure file size limit is respected. Auditor method checking who is requesting the file. Updating the blockchain contract with which shards are being stored.
#TODO: have a function the auditor can hit, which this service responds whether it has the requested file, via merkle tree ideally.

@app.route('/delete/<shardId>', methods=['DELETE'])
def delete_shard(shardId):
    file_path = getShardPathFromShardID(shardId)
    if file_path is None:
        return 'Shard with the specified ID does not exist.', 404
    if os.path.exists(file_path):
        os.remove(file_path)
        response = make_response(f"Shard '{file_path}' has been deleted.")
        response.status_code = 204
         #TODO: check if storageProvider is now no longer full. if so, add it to the blockchain list of availableProviders
        return response
    else:
        abort(404, f"Shard '{file_path}' does not exist.")

@app.errorhandler(404)
def not_found_error(error):
    return f"Error {error.code}: {error.description}", error.code

@app.route('/', methods=['GET'])
def home():
    return render_template('index.html')

#Helper methods

def ip_to_hex(ip_address):
    try:
        # Convert the IP address from string to bytes
        ip_bytes = socket.inet_aton(ip_address)

        # Convert the bytes to hexadecimal representation
        hex_representation = binascii.hexlify(ip_bytes).decode()

        # Ensure the hexadecimal representation is 64 characters long
        # If it's shorter, pad it with leading zeros
        hex_representation = hex_representation.zfill(64)

        # Add the "0x" prefix to indicate it's a hexadecimal value
        hex_representation = "0x" + hex_representation

        return hex_representation
    except socket.error:
        # If the IP address is invalid, handle the exception as needed
        raise ValueError("Invalid IP address format")

# # Test the function
# ip_address = "127.0.0.1"
# hex_value = ip_to_hex(ip_address)
# print(hex_value)

#TODO: make this function return properly formatted IP.
# def hex_to_ip(hex_value):
#     # Remove the '0x' prefix from the hex_value
#     hex_value = hex_value[2:]
    
#     # Split the hex value into 4 segments (each representing 8 bits or 2 bytes)
#     segments = [hex_value[i:i+8] for i in range(0, len(hex_value), 8)]
    
#     # Convert each segment from hexadecimal to decimal
#     decimal_segments = [int(segment, 16) for segment in segments]
    
#     # Convert the decimal segments into an IP address string
#     ip_address = ".".join(str(dec) for dec in decimal_segments)
    
#     return ip_address

# # Example usage:
# hex_value = "0x0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
# ip_address = hex_to_ip(hex_value)
# print(ip_address)  # Output: "1.35.69.103.137.171.205.239.1.35.69.103.137.171.205.239"

def get_storage_providers():
    # Get the list of storage providers from the contract
    storage_providers = cloudySmartContract.functions.getStorageProviderDataOfProvidersCurrentlyStoringShards().call()
    print("Displaying all storage providers currently Storing Shards:")
    for provider in storage_providers:
        print(provider)
    print("-------------------------")
    return storage_providers

def ip_to_hex(ip_address):
    # Split the IP address into 4 segments
    ip_segments = ip_address.split('.')

    # Convert each segment from decimal to hexadecimal and format it to be 2 digits wide
    hex_segments = [format(int(segment), '02x') for segment in ip_segments]

    # Join the hex segments and prepend '0x'
    hex_value = '0x' + ''.join(hex_segments)

    return hex_value
# Example usage:
# ip_address = "127.0.0.1"
# hex_value = ip_to_hex(ip_address)
# print(hex_value)  # Output: "0x7f000001"


def is_valid_filename(filename):
    # Define the regular expression pattern to match the filename format
    pattern = r'^shard_\d+_of_file_.+$'
    return re.match(pattern, filename)

def get_filetype_from_filename(filename):
    # Use the is_valid_filename function to check if the filename is in the valid format
    pattern = r'^shard_\d+_of_file_(.+)$'
    match = re.match(pattern, filename)
    if match:
        # If the filename is in the valid format, extract the file type (extension)
        file_type = match.group(1).split('.')[-1]
        return file_type
    else:
        # If the filename is not in the valid format, return the default file type 'blob'
        return 'blob'

def getShardIdfromShardName(filename):
    if is_valid_filename(filename):
        # Define the regular expression pattern to match the integer after the first underscore
        pattern = r'_\d+'

        # Search for the pattern in the filename
        match = re.search(pattern, filename)

        if match:
            # If a match is found, extract the integer part and convert it to an integer
            shard_number = int(match.group()[1:])
            return shard_number

    # If the filename is not valid or no match is found, return the default value of 0
    return -1

def getShardPathFromShardID(shardId):
    #Returns filepath to shard if it exists, or None.
    #TODO: may need to pass in filename as well if shardIDs arent always unique.
    storage_path = os.getenv('LOCAL_STORAGE_PATH')
    shard_prefix = f"shard_{shardId}_of_file_"
    shard_files = [f for f in os.listdir(storage_path) if f.startswith(shard_prefix)]

    if not shard_files:
        # Shard file not present, so return None.
        return None  

    # Assuming only one file exists with the given shardId
    shard_filename = shard_files[0]
    filepath = os.path.join(storage_path, shard_filename)

    return filepath

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

# def start_ShardDeleted_event_listener():

#     # Specify the event you want to listen for
#     FileDeleted_event_filter = cloudySmartContract.events.ShardDeleted.createFilter(fromBlock="latest")

#     # Start the event listener loop
#     while True:
#         for event in FileDeleted_event_filter.get_new_entries():
#             delete_shard(event["shardId"])


@app.route('/audit', methods=['POST'])
def audit_files():
    # Check if 'shards' key exists in the request JSON data
    # if request.json  TODO: UNFINISHED CODE HERE PUSHED TO UNBLOCK JEN
    
    if 'shards' not in request.json:
        return 'No shard IDs found in the request', 400

    shardIDs = request.json['shards']
    storage_path = os.getenv('LOCAL_STORAGE_PATH')

    # Check if all shards exist in the storage directory
    #TODO: update this to use shardName instead of shardID
    for shardID in shardIDs:
        #TODO ensure this path is actually valid
        file_path = os.path.join(storage_path, shardID)
        if not os.path.exists(file_path):
            return 'Not all files are stored locally', 200

    # All files exist in the storage directory
    return 'All files are stored locally', 200

if __name__ == '__main__':
    # import threading
    # event_listener_thread = threading.Thread(target=start_ShardDeleted_event_listener)
    # event_listener_thread.start()
    app.run(host='0.0.0.0', port=5002, debug=False) #debug=True to auto reload when making changes

