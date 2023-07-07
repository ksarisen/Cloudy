Author: Benjamin Djukastein.
Created on May 24th, 2023.

Startup guide for local development:

Installation guide:
make a folder where you want to code, and clone this repo there. Also, make a folder where you will want to store the incoming files.
Create a file called ".env" containing the lines:

LOCAL_STORAGE_PATH = "D:/path/to/where/you/want/to/store/files" with the actual path where you want to store the uploaded files.
CONTRACT_PROVIDER_URL = "http://localhost:7545/" #Ganache localhost test network
CONTRACT_ADDRESS #address of remix local javascript deployed contract.
MAX_STORAGE_IN_BYTES #max bytes of storage in that local directory you want to allow to be used for storage by external users.
BLOCKCHAIN_ABI #The ABI of our blockchain interface.

Create a virtual environment using "python -m venv venv"
Enter the virtual environment using ".\venv\Scripts\activate"
python -m pip install numpy
python -m pip install flask
python -m pip install werkzeug
python -m pip install --upgrade setuptools
python -m pip install python-dotenv
python -m pip install web3

Set up locally hosted blockchain for testing (later on we may deploy to a hosted testnet.)
Download Ganache from https://www.trufflesuite.com/ganache
yarn global add ganache
Follow the one-click-setup instructions, then confirm in Server tab that its running locally on port http://localhost:7545/.
In solidity "Deploy and Run Transactions" tab, select environment "Dev - Ganache Provider", and ensure port matches.

Run the program locally for testing using the command:
.\venv\Scripts\activate
python CloudyStorageMain.py

Interact with the running service by hitting the following endpoint with a POST containing the file you want to upload
http://127.0.0.1:5000/upload


TODOS:
Ensure the max storage limit is tracked and enforced.
connect to the blockchain to track available shards
Ensure only actual owner can delete relevant shards via a view external check the Provider can hit in the storage contract.