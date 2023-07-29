Author: Benjamin Djukastein.
Created on May 24th, 2023.

Startup guide for local development:

Installation guide:
make a folder where you want to code, and clone this repo there. Also, make a folder where you will want to store the incoming files.
Create a file called ".env" containing the lines, updating the values to your environment:
LOCAL_STORAGE_PATH = "D:/path/to/where/you/want/to/store/files" with the actual path where you want to store the uploaded files.
CONTRACT_URL = "http://localhost:7545/" #Ganache localhost test network
CONTRACT_ADDRESS = 0xaC85AE6B131e424a4275e57BBaC38097052ECb80 #address of remix local javascript deployed contract. You can find it in remix.
MAX_STORAGE_IN_BYTES = "10000000" #max bytes of storage in that local directory you want to allow to be used for storage by external users.
WALLET_ADDRESS = 0x88E4c0c12dBAe51877D99F443B1b052184568717 # the address you want to receive payment to.

If you have modified and recompiled the blockchain contract, 
    get the blockchain abi from remix by clicking the ABI button at the bottom of the Solidity Compiler tab and paste it in contractAbi.json

For Mac (may need to replace the word "python" with "python3"):
If python isnt installed, run the following from the terminal: 
brew update --verbose
brew install python

* The root is Cloudy-Storage-Provider 

For both Mac & Windows first-time set-up:
Create a virtual environment using:
"python -m venv venv" in the Cloudy-Storage-Provider directory

Once first time setup is done, to re-enter the virtual environment, type:
cd Cloudy-Storage-Provider 
(Windows) ".\venv\Scripts\activate"
(Mac) "source venv/bin/activate"

python -m pip install numpy
python -m pip install Flask==2.2 #2.3 deprecates the app.before_first_request flag
python -m pip install werkzeug
python -m pip install --upgrade setuptools
python -m pip install python-dotenv
python -m pip install web3
pip install flask-cors


To exit venv type "deactivate"

Follow the README in Cloudy-Blockchain folder to set up a local version of our blockchain for testing.


Deploy the File Storage Service(Run the program locally for testing):
python CloudyStorageMain.py

Interact with the running File Storage service as a file Owner by hitting the following endpoint with a POST containing the file you want to upload
http://127.0.0.1:5002/upload


TODOS:
Ensure the max storage limit is tracked and enforced.
Ensure only actual owner can delete relevant shards via a view external check the Provider can hit in the storage contract.