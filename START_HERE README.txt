To run our Cloudy distributed storage App locally for testing, follow the README setup guides in each of the folders in the following order:
Note that each folder is a separate app that must be run from its own terminal window (Only exception is: Cloudy-Blockchain doesn't run from terminal, rather it's deployed from a Remix browser tab locally)

1.Cloudy-Blockchain, to set up a remix/ganache local blockchain instance tracking ownership and storage of files and shards.
2.Cloudy-File-Owner-Interface, to run our File Owner frontend browser interface for you try uploading downloading, and deleting files you wish to store.
3.Cloudy-Incentives-Manager, to run a looping function that ensures storage providers receive compensation for storing shards if they can confirm their successful storage.
4.Cloudy-Storage-Provider, to set your computer up as a File Storage Provider, and allow users to store shards on a local directory of your choice via an exposed port.


*******  Steps to Set-Up:  ********

1. Open remix.ethereum.org, and clone our repository "https://github.com/ksarisen/Cloudy".  
2. Click the file explorer icon in the left. Then, Select the Cloudy-Blockchain folder --> contracts --> NewCloudy.sol
3. Once the NewCloudy.sol file is selected, click on the Solidity Compiler Icon on the left.
4. Click on Compile NewCloudy.sol 
5. Below the Compilation Details Button, please click the copy ABI button.
6. Open Visual Studio Code and load the Cloudy-Blockchain code.
7. You will need to replace 3 ABI files (contractAbi.json) by CTRL + A and CTRL + V in the following:
   --> File 1: Select Cloudy-File-Owner-Interface --> src --> contractAbi.json
   --> File 2: Select Cloudy-Incentives-Manager --> contractAbi.json
   --> File 3: Select Cloudy-Storage-Provider --> contractAbi.json
8. Go to this site to download and install Ganache: https://trufflesuite.com/ganache/
9. Open Ganache and click on "Quickstart Ethereum". Please make sure the RPC endpoint is "http://127.0.0.1:7545"
10. Next, Return to Remix and Select the Deploy & Run Transactions icon on the left.
11. Click on the Environment Input field and select "Dev - Ganache Provider"
12. Enter "http://127.0.0.1:7545" in the RPC endpoint field, then click on "OK".
13. Click on the deploy button. In the deployed contracts section, it should be populated with an entry. 
14. Click on the "copy" button within the generated deployed contract. This will give us the contract address.
15. Open Visual Studio Code and open cloudy-file-owner-interface --> src --> components --> Home --> Home.jsx
16. In Home.jsx, search for "deployed_contract_address" which can most likely be found in Line 28. 
17. Replace the current "deployed_contract_address" with the contract address copied from remix.
18. Next, you will need to create/update the .env files:
    --> Under cloudy-storage-provider, access or create a .env file. Replace the "CONTRACT_ADDRESS" with 
        the contract address copied from remix. Also, make sure that your "LOCAL_STORAGE_PATH" contains the 
        PATH where you store the Cloudy Blockchain files.
    --> Under cloudy-incentives-manager, access or create a .env file. Replace the "CONTRACT_ADDRESS" with 
        the contract address copied from remix. Also, make sure that your "LOCAL_STORAGE_PATH" contains the 
        PATH where you store the Cloudy Blockchain files.
    * As an example, your .env files contain these two lines of code:
        LOCAL_STORAGE_PATH = "/Users/User1/Desktop/Cloudy-Storage-Files" # Path where the Cloudy Blockchain code is stored.
        GANACHE_ENDPOINT = "http://127.0.0.1:7545" # if it is not in the .env file, please add this.
        REMIX_CONTRACT_ADDRESS = "0xf473D48F3686affD89f73101a2bD1F0123456789" #from remix deployed contract. Must replace when you deploy in remix.
        MAX_STORAGE_IN_BYTES = "1000000000"
19. Open the terminal, enter "cd Cloudy-Storage-Provider". 
20. Enter "python -m venv venv" to create a virtual environment.
21. Enter the virtual environment using 
    (Windows) ".\venv\Scripts\activate"
    (Mac) "source venv/bin/activate"
22. Run the following on the terminal to install in the VM:
    python -m pip install numpy
    python -m pip install Flask==2.2 #2.3 deprecates the app.before_first_request flag
    python -m pip install werkzeug
    python -m pip install --upgrade setuptools
    python -m pip install python-dotenv
    python -m pip install web3
    pip install flask-cors
23. Deploy the File Storage Service by entering "python CloudyStorageMain.py" in the terminal. 
    If you want to quit using the venv, type "deactivate"
24. Open a separate terminal, enter "cd Cloudy-Incentives-Manager". 
25. Enter "python -m venv venv" to create a virtual environment.
21. Enter the virtual environment using 
    (Windows) ".\venv\Scripts\activate"
    (Mac) "source venv/bin/activate"
22. Run the following on the terminal to install in the VM:
    python -m pip install requests
    python -m pip install flask
    python -m pip install python-dotenv
    python -m pip install web3
23. To run the VM use, python IncentiveAuditorMain.py  
24. Open another terminal, enter "cd Cloudy-File-Owner-Interface" then "cd cloudy-file-owner-interface-react-app". 
25. Enter "npm install" in the terminal.
26. Enter "npm start" in the terminal. 
27. The react web application will open. 
28. Click on Choose File. Choose a File and click on the Upload Button.