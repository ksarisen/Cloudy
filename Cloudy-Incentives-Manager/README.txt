Author: Benjamin Djukastein.
Created on July 6th, 2023.

This folder contains the service that runs a loop to ensure all storage providers are regularly audited for file integrity, and paid.

Startup guide for local development:

Installation guide:
make a folder where you want to code, and clone this repo there. 
Create a file called ".env" containing the lines:

CONTRACT_URL = "http://localhost:7545/"  #Ganache localhost test network. can also try "http://127.0.0.1:7545"
CONTRACT_ADDRESS = "Find your latest address in remix deployment, e.g. 0x3c627518B0EBBC15ab7B505B70B22F8cB455796E" #address of remix local javascript deployed contract.

If you have modified and recompiled the blockchain contract, 
    get the blockchain abi from remix by clicking the ABI button at the bottom of the Solidity Compiler tab and paste it in contractAbi.json


How to run the Incentive/Auditor Service:

For Mac (may need to replace the word "python" with "python3" in the rest of the guide):
If python isnt installed, run the following from the terminal: 
brew update --verbose
brew install python

For All:
    cd Cloudy-Incentives-Manager 
Create a virtual environment using:
    python -m venv venv
Enter the virtual environment using 
    (Windows) ".\venv\Scripts\activate"
    (Mac) "source venv/bin/activate"

    python -m pip install requests
    python -m pip install flask
    python -m pip install python-dotenv
    python -m pip install web3

Follow the README in Cloudy-Blockchain folder to set up a local version of our blockchain for testing.
Follow the README in Cloudy-Storage-Provider folder to set up a local instance of a Storage Provider for testing.

Deploy the File Storage Service(Run the program locally for testing):
python IncentiveAuditorMain.py 
