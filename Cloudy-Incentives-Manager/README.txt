Author: Benjamin Djukastein.
Created on July 6th, 2023.

This folder contains the service that runs a loop to ensure all storage providers are regularly audited for file integrity, and paid.

Startup guide for local development:

Installation guide:
make a folder where you want to code, and clone this repo there. 
Create a file called ".env" containing the lines:

LOCAL_STORAGE_PATH = "D:/path/to/where/you/want/to/store/files" with the actual path where you want to store the uploaded files.
CONTRACT_PROVIDER_URL = "http://localhost:7545/" #Ganache localhost test network
CONTRACT_ADDRESS #address of remix local javascript deployed contract.
BLOCKCHAIN_ABI #The ABI of our blockchain interface.

How to run the Incentive/Auditor Service:

For Mac (may need to replace the word "python" with "python3" in the rest of the guide):
If python isnt installed, run the following from the terminal: 
brew update --verbose
brew install python

For All:
Create a virtual environment using:
python -m venv venv

Enter the virtual environment using 
cd Cloudy-Incentives-Manager 
(Windows) ".\venv\Scripts\activate"
(Mac) "source venv/bin/activate"

python -m pip install requests
python -m pip install flask

Follow the README in Cloudy-Blockchain folder to set up a local version of our blockchain for testing.
Follow the README in Cloudy-Storage-Provider folder to set up a local instance of a Storage Provider for testing.

Deploy the File Storage Service(Run the program locally for testing):
python IncentiveAuditorMain.py 
