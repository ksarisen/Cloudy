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
