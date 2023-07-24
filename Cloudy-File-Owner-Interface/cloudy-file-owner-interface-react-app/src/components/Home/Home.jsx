// import dotenv from 'dotenv';
import React, { useState, useEffect } from "react";
import './Home.css';
import Navbar from '../Navbar/Navbar';
import Web3 from 'web3';
import contractAbi from '../../contractAbi.json';
import CryptoJS from 'crypto-js';
// import dotenv from 'dotenv';

// import { config } from 'dotenv';
// import path from 'path';

// const rootPath = path.resolve(__dirname, '../../../'); // Adjust the number of '../' based on the file location
// config({ path: path.join(rootPath, '.env') });

// dotenv.config();

// Initialize web3 instance

// dotenv.config(); // Load environment variables from .env file

export const Home = (props) => {
    const [file, setFile] = useState('');
    // store uploaded files
    const [uploadedFiles, setUploadedFiles] = useState([]);

    //NOTE the next line is a BAD temporary hardcoded way to access loclaly hosted blockchain.
    let ganacheEndpoint = "http://127.0.0.1:7545" //TODO: make dotenv import workprocess.env.GANACHE_ENDPOINT;
    let deployed_contract_address = "0xF7fb4e91bE2587148BB651d892D87a1E1F334cfE"// process.env.REMIX_CONTRACT_ADDRESS
    //TODO: update the above lines to use .env variables rather than constants

    const web3 = new Web3(new Web3.providers.HttpProvider(ganacheEndpoint));

    const cloudyContract = new web3.eth.Contract(contractAbi, deployed_contract_address);
    fetchUploadedFiles();

    // Use the web3 instance in your code
    async function checkHosting() {
        const accounts = await web3.eth.getAccounts();
        const accountAddress = accounts[0]; // Assuming you want to check the first account

        //process.env.CONTRACT_ADDRESS 
        // Check if the Ganache instance is hosting your contract
        const isHosting = await web3.eth.getCode(deployed_contract_address) !== '0x';

        console.log(`Is Ganache hosting your contract? ${isHosting}`);
    }

    function handleFile(event) {
        if (typeof (event.target.files[0]) !== 'undefined' && event.target.files[0] != null) {
            setFile(event.target.files[0]);
            console.log(event.target.files[0]);
            console.log({ file });
        } else {
            setFile(null);
            console.log("File Not Chosen");
        }
    }

    //turn the filename into a unique hashed id for the file
    //TODO: handle two files with the same name
    async function stringToBytes20(inputString) {
        const encoder = new TextEncoder();
        const data = encoder.encode(inputString);

        const hashBuffer = await crypto.subtle.digest('SHA-1', data);
        const hashArray = Array.from(new Uint8Array(hashBuffer));

        const desiredLength = 20;

        if (hashArray.length < desiredLength) {
            const padding = Array(desiredLength - hashArray.length).fill(0);
            hashArray.push(...padding);
        } else {
            hashArray.splice(desiredLength);
        }

        const bytes20Hash = '0x' + hashArray.map((byte) => byte.toString(16).padStart(2, '0')).join('');
        return bytes20Hash;
    }


    function handleUpload(event) {
        event.preventDefault();
        checkHosting(); // confirm the blockchain is connected, for debugging only.
        uploadFile(file);
        fetchUploadedFiles();
    }




    //     //TODO: Encrypt file using AES
    // function encryptFile(file, encryptionKey) {
    //     return new Promise((resolve, reject) => {
    //     const reader = new FileReader();
    //     reader.onload = (event) => {
    //         const fileData = event.target.result;
    //         const encryptedData = CryptoJS.AES.encrypt(fileData, encryptionKey);
    //         resolve(encryptedData.toString());
    //     };
    //     reader.onerror = (event) => {
    //         reject(event.target.error);
    //     };
    //     reader.readAsDataURL(file);
    //     });
    // }

    // //TODO: Decrypt file using AES
    // function decryptFile(encryptedFile, encryptionKey) {
    //     const decryptedData = CryptoJS.AES.decrypt(encryptedFile, encryptionKey);
    //     const decryptedText = decryptedData.toString(CryptoJS.enc.Utf8);
    //     return decryptedText;
    // }


    // Function to fetch uploaded files from the blockchain contract
    async function fetchUploadedFiles() {
        try {
            // Get the first account from Ganache
            const accounts = await web3.eth.getAccounts();
            const sender = accounts[0];

            // Call the blockchain contract function to fetch the uploaded files list of filehashes
            // TODO: Figure out how to get the name of the filehashes
            const uploadedFiles = await cloudyContract.methods.getOwnerFiles(sender).call({ from: sender });

            // Update the state with the fetched files
            setUploadedFiles(uploadedFiles);
        } catch (error) {
            console.error('Failed to fetch uploaded files:', error);
        }
    }

    // useEffect hook to fetch uploaded files when the component mounts
    useEffect(() => {
        fetchUploadedFiles();
    }, []);


    function splitFile(file, numSlices) {
        const sliceSize = Math.ceil(file.size / numSlices);
        const shards = [];

        let start = 0;
        for (let i = 0; i < numSlices; i++) {
            const end = Math.min(start + sliceSize, file.size);
            const slice = file.slice(start, end);
            shards.push(slice);
            start += sliceSize;
        }
        return shards;
    }


    async function uploadFile(file) {
        try {
            const fileName = file.name;
            // TODO: Please change the way we hash stringToBytes20  
            const _filehash = await stringToBytes20(fileName);

            // TODO: Encrypt the file

            // Split file into shards
            // Do not split shards yet. Try to upload file as 1 shard / 1 file first and see if it works
            const shards = splitFile(file,1); // TODO: decide if we want to split files into more than 1 big shard
        
            // Get the first account from Ganache
            const accounts = await web3.eth.getAccounts();
            const sender = accounts[0];

            console.log("uploadFile function: checkpoint 1"); 
            // Get all storage Providers
            //TODO: update to use uploadFile(string memory _ownerName, string memory _fileName, bytes32 _fileHash, uint256[] memory _shardIds)
            var gasEstimateForUpload = 50000

            try {
                gasEstimateForUpload = await cloudyContract.methods
                  .getIPsOfStorageProvidersWithSpace()
                  .estimateGas({ from: sender });
              } catch (error) {
                console.error("ContractExecutionError:", error);
              }

            // Convert the gas estimate to a regular JavaScript number
            const gasEstimateNumber = Number(gasEstimateForUpload);

            // Check if the gas estimate exceeds the maximum safe integer limit
            const gasBuffer = gasEstimateNumber <= Number.MAX_SAFE_INTEGER
            ? gasEstimateNumber + 100000
            : Number.MAX_SAFE_INTEGER;

            // Call the contract function and expect an array of addresses as the result
            // getStorageProvidersWithSpace()
            const unformattedStorageProviders = await cloudyContract.methods.getIPsOfStorageProvidersWithSpace().call({ from: sender,  gas: gasBuffer });
            const storageProviders = cleanUpIPsArray(unformattedStorageProviders);

            console.log("List of Storage Providers: ", storageProviders); // Assuming the function returns an array of addresses

            if(storageProviders.length < 1){
                throw new Error('No available Storage Providers.');
            }
            
            // TODO: change blockchain code so that uploadFile function includes storage providers with no space and updates it
            const storageProvidersNoSpace = [];
            const storageProvidersWithSpace = [];

            // Loop through providers
            for (let i = 0; i < storageProviders.length; i++) {
                // if(storageProviders[i].availableStorageSpace < 1024 * 1024){ // 1024 * 1024 = 1MB
            if(storageProviders[i].availableStorageSpace < file.length){ // 1024 * 1024 = 1MB
                    storageProvidersNoSpace.push(storageProviders[i]);
            }else{
                    storageProvidersWithSpace.push(storageProviders[i]);
            }
            }

            // const shardsToProviders = new Map();
            
            // what happends if we have more shards than storage providers?
            // --> Loop over the storage providers again.

            // TODO: for each upload that doesn't work please make sure that it is going to be uploaded
            // TODO: make sure that successful upload checks that all the shards are uploaded first. since currently the logic is working for 1 file.
        
            let successfulUpload = false;
            const shardIDs = [];
            for (let i = 0; i < shards.length; i++) {
                let storageProviderIndex = i;
                if (i == storageProvidersWithSpace.length) {
                    storageProviderIndex = i % storageProvidersWithSpace.length;
                }
                const shardID = i;
                // const shardID = generateShardId(shards[i]);
            const endpoint = `${storageProviders[storageProviderIndex]/*.ip*/}:5002/upload`;
            
            const formData = new FormData();
            shards.forEach((shard, index) => {
                //TODO: ensure fileName isnt just "blob"
                const shardName = `shard_${index}_of_file_${fileName}`;
                formData.append(shardName, shard);
                console.log("formData of shard being sent:")
                console.log(formData)
            });
    
                try {
                    const response = await fetch(endpoint, {
                        method: 'POST',
                        mode: 'cors',
                        body: formData,
                    });
    
                    if (response.ok) {
                        console.log('Shard uploaded successfully');
                        // shardsToProviders.set(shardID, storageProviders[storageProviderIndex]);
                        console.log(`Storing shard ${i} with storage provider ${storageProvidersWithSpace[storageProviderIndex]}`);
                        successfulUpload = true;
                        shardIDs.push(shardID);
                    } else {
                        throw new Error('Failed to upload shard');
                    }
    
                    // Log the response content
                    const data = await response.text();
                    console.log('Response:', data);
                } catch (error) {
                    console.error('Error uploading shard:', error);
                }
            }
    
            if (successfulUpload) {

                // TODO: Change to send the owner's wallet address instead

                const response = await cloudyContract.methods.uploadFile("ouldooz", file.name, _filehash, shardIDs).send({ from: sender, gas: 500000 }); //for the demo,  all files are owned by the single user "Ouldooz" since user management can be added later
                console.log("response to uploadFile():", response);
            }
    
            // const response = await cloudyContract.methods._storeFile(_filehash).send({ from: sender,  gas: 500000 });
        // console.log("response: " + response);

        // Send a transaction to the blockchain
        // Vague idea of how to work with Blockchain:
        /* 
            1. User uploads file
            2. Split file into shards (array)
            3. call getStorageProvidersWithSpace() 
                // Assume we get returned IPs and available space per storage provider
                // what happens if the storage provider has space but not enough to store the shard?
                    // if there is no space for shards, let the blockchain know 
            4. Loop through the providers and send them shards by calling the ip address + post
                // const endpoint = `http://${farmerAddress}/upload`;
            5. call the blockchains upload file function to send the shard data matching with the storage provider along with the filehash
                // filehash
                // ownername 
                // shardIds (array) + storage providers

        */
        const senderBalance = await web3.eth.getBalance(sender);
        console.log ("Current account balance is " + senderBalance);
    
        //console.log("File: "+ fileName +"With Hash: " +_filehash+ "uploaded to the blockchain.");
        //fetchUploadedFiles();
        } catch (error) {
            console.error('Failed to upload file:', error);
        }
    }

    function cleanUpIPsArray(ipsArray) {
        //removes singel quotes added around solidity strings in arrays
        return ipsArray.map((ip) => ip.replace(/'/g, ''));
    }


    // Function to delete the file and its shards
    async function handleDelete(fileHash) {
        try {
            // Get the first account from Ganache
            const accounts = await web3.eth.getAccounts();
            const sender = accounts[0];

            // Call the blockchain contract function to delete the file and its shards
            const response = await cloudyContract.methods.deleteFile(fileHash).send({ from: sender, gas: 500000 });

            console.log("Response to handleDelete():", response);

            // After successful deletion, fetch the updated list of uploaded files
            fetchUploadedFiles();
        } catch (error) {
            console.error('Failed to delete file:', error);
        }
    }

    async function handleDownload(fileHash) {
        try {
            // Get the first account from Ganache
            const accounts = await web3.eth.getAccounts();
            const sender = accounts[0];

            // Call the blockchain contract function to get the shard IDs of the file
            const shardIds = await cloudyContract.methods.getFilesShards(fileHash).call({ from: sender });

            // Retrieve the shards from storage providers and reconstruct the file
            const fileData = await fetchAndCombineShards(shardIds);

            // Convert the fileData to a Blob
            const blob = new Blob([fileData]);

            // Create a download link for the file
            const downloadLink = document.createElement('a');
            downloadLink.href = URL.createObjectURL(blob);
            downloadLink.download = "downloaded_file"; // Change the name of the downloaded file here (if needed)
            downloadLink.click();
        } catch (error) {
            console.error('Failed to download file:', error);
        }
    }

    async function fetchAndCombineShards(shardIds) {
        // Assuming you have an API endpoint to fetch shards from storage providers
        // Combine the shards to reconstruct the original file
        // For demonstration purposes, we will simply concatenate the shard data here.
        let combinedData = '';

        for (const shardId of shardIds) {
            const endpoint = `${storageProviderIP}/${shardId}`; // Replace with your storage provider's API endpoint
            const response = await fetch(endpoint);
            const shardData = await response.text();
            combinedData += shardData;
        }

        return combinedData;
    }

    // function generateShardId(shard) {
    //     const hash = crypto.createHash('sha256');
    //     hash.update(shard);
    //     const shardId = hash.digest('hex');
    //     return shardId;
    // }


    return (
        // body
        <div>
            {/* top bar */}
            <Navbar />
            <div>
                <div className="upload-form">
                    <div className="flex-container">
                        <div className="flex-child">
                            <label className="greeting-labels">Nice to see you, Ouldooz!</label>
                            <br />
                            <br />
                        </div>
                        <div className="flex-child">
                            <form>
                                <div className="upload-container">
                                    <label className="upload-labels">Try to Upload a File: &nbsp;</label>
                                    <input className="file" type="file" name="file" onChange={handleFile} />
                                </div>
                                <br />
                                <button className="button" type="submit" onClick={handleUpload}>Upload</button>
                            </form>
                            {/* If we want to add anything to the right side of the uploads */}
                        </div>
                    </div>
                </div>
                <br />
                <br />
                <div className="table-container">
                    <table className="search-table">
                        <tbody>
                            <tr>
                                <th>File Name</th>
                                {/* <th>Date Uploaded</th> */}
                                <th>Download</th>
                                <th>Delete</th>
                            </tr>
                            {/* TODO: type file may cause an error because of the bytes 32 address (filehash) that are being stored in uploaded files */}
                            {uploadedFiles.map((file) => (
                                <tr key={file.fileHash}>
                                    <td className="filename">{file.fileHash}</td>
                                    {/* <td>{file.fileUploadDate}</td> */}
                                    <td>
                                        <a className='download-button'onClick={() => handleDownload(file.fileHash)} >
                                            {/* <a className='download-button' onClick={() => handleDownload(file.fileHash, encryptionKey)}> */}
                                            Download
                                        </a>
                                    </td>
                                    <td>
                                        <a className='delete-button' onClick={() => handleDelete(file.fileHash)}>
                                            {/* <a className='delete-button' onClick={() => handleDelete(file.fileHash)}> */}
                                            Delete
                                        </a>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

        </div>
    )
}
export default Home;