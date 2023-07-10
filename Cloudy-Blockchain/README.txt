Authors: Benjamin Djukastein, Kerem Sarisen, and Jennifer Kim.
Created January 15th, 2023.

Summary:
The Cloudy Blockchain directory holds code for our Blockchain service, which tracks ownership of files and the current distribution of shards among storage providers renting out some of their disk space.

Setup guide:
Set up locally hosted blockchain for testing (later on we may deploy to a hosted testnet.)
Download Ganache from https://www.trufflesuite.com/ganache
Open the Ganache application.
Follow the one-click-setup instructions (Quickstart Ethereum)
Confirm in its Server tab that Ganache's RPC Server is running locally on  "http://localhost:7545/" or "HTTP://127.0.0.1:7545".

Run the following commands:
yarn global add ganache

Open remix.ethereum.org, and clone our repository "https://github.com/ksarisen/Cloudy".
You may need to set up a git personal access token, follow the instructions in Remix.
In the "Solidity Compiler" tab, compile Cloudy-Blockchain/contracts/cloudy_contract.sol
Select the "Deploy and Run Transactions" tab, select environment "Dev - Ganache Provider",
Ensure the "Ganache JSON-RPC Endpoint" in the pop up dialog matches "http://localhost:7545/" .
Click the orange Deploy button selecting cloudy_contract.sol


This Cloudy-Blockchain workspace contains the following directories:

1. 'contracts': Holds our main cloudy_contract
2. 'scripts': default deployment files, we plan to look into them more when trying to deploy properly.
3. 'tests': Contains one Solidity test file for our main cloudy_contract. TODO: create JS test file.
4. '.deps': Dependencies like the Ownable contract our main contract relies on.

NOTES ON DEPLOYING CONTRACT

The 'scripts' folder has four typescript files which help to deploy the 'Storage' contract using 'web3.js' and 'ethers.js' libraries.

For the deployment of any other contract, just update the contract's name from 'Storage' to the desired contract and provide constructor arguments accordingly 
in the file `deploy_with_ethers.ts` or  `deploy_with_web3.ts`

In the 'tests' folder there is a script containing Mocha-Chai unit tests for 'Storage' contract.

To run a script, right click on file name in the file explorer and click 'Run'. Remember, Solidity file must already be compiled.
Output from script will appear in remix terminal.

Please note, require/import is supported in a limited manner for Remix supported modules.
For now, modules supported by Remix are ethers, web3, swarmgw, chai, multihashes, remix and hardhat only for hardhat.ethers object/plugin.
For unsupported modules, an error like this will be thrown: '<module_name> module require is not supported by Remix IDE' will be shown.
