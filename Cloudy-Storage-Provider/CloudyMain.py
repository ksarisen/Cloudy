#Benjamin Djukastein, created in part via ChatGPT prompts
import os
from flask import Flask, abort, make_response, request, render_template, send_file
from werkzeug.utils import secure_filename
from dotenv import load_dotenv

#load the local variables from .env file
load_dotenv() 

app = Flask(__name__)

app.debug = True

@app.route('/upload', methods=['POST'])
def upload_shards():
    # Check if the 'shards' key exists in the request
    if 'shards' not in request.files:
        return 'No shards found in the request. Try POSTING again with your desired shard files sent under the key "shards".'
    
    # Confirm tadding this shard will not exceed storage space
    # Get the limit from the environment variable
    # limit = int(os.getenv('DIRECTORY_LIMIT_BYTES'))

    # # Check the usage of the directory
    # directory = '/path/to/directory'
    # usage = get_directory_usage(directory)

    # if usage <= limit:
    #     print("Directory usage is within the limit.")
    # else:
    #     print("Directory usage exceeds the limit.")

    
    shards = request.files.getlist('shards')

    for shard in shards:
        # Check if a file was selected
        if shard.filename == '':
            return 'Cannot save nameless shards.'
        # Save the file to the specified path
        shard_name = secure_filename(shard.filename)
        #use the raw path from .env file to prevent backslashes from being misinterpreted.
        shard.save(r"{}/{}".format(os.getenv('LOCAL_STORAGE_PATH'), shard_name))

    # Create a response with a custom message
    response = make_response('Shards uploaded successfully')

    # Set the status code to 200
    response.status_code = 200

    return response

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

def get_directory_usage(directory):
    stat = os.statvfs(directory)
    block_size = stat.f_frsize
    total_blocks = stat.f_blocks
    free_blocks = stat.f_bfree
    available_space = block_size * free_blocks
    return available_space

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
