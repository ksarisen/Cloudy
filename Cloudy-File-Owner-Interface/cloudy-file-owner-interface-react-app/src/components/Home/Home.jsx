// import dotenv from 'dotenv';
import React, { useState, useEffect } from "react";
import './Home.css';
import Navbar from '../Navbar/Navbar';
import Web3 from 'web3';
import contractAbi from './contractAbi.json';
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
    const[file, setFile] = useState('');
    const [uploadedFiles, setUploadedFiles] = useState([]);

    //NOTE the next line is a BAD temporary hardcoded way to access loclaly hosted blockchain.
    let ganacheEndpoint = "http://127.0.0.1:7545" //TODO: make dotenv import workprocess.env.GANACHE_ENDPOINT;
    let deployed_contract_address = "0xd11352a329d74A4C0bBdeF922855E96E7538F83C"// process.env.REMIX_CONTRACT_ADDRESS
    //TODO: update the above lines to use .env variables rather than constants
    
    const web3 = new Web3(new Web3.providers.HttpProvider(ganacheEndpoint));

    // Use the web3 instance in your code
    async function checkHosting() {
    const accounts = await web3.eth.getAccounts();
    const accountAddress = accounts[0]; // Assuming you want to check the first account

    //process.env.CONTRACT_ADDRESS 
    // Check if the Ganache instance is hosting your contract
    const isHosting = await web3.eth.getCode(deployed_contract_address) !== '0x';

    console.log(`Is Ganache hosting your contract? ${isHosting}`);
    }

    function handleFile(event){
        if(typeof(event.target.files[0]) !== 'undefined' && event.target.files[0] != null){
            setFile(event.target.files[0]);
            console.log(event.target.files[0]);
            console.log({file});
        }else{
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


      function handleUpload(event){
        event.preventDefault();
        checkHosting(); // confirm the blockchain is connected, for debugging only.
        uploadFile(file);
        // const formData = new FormData()
        // formData.append('file', file)
        // fetch(
        //     'url',
        //     {
        //         method: "POST",
        //         body: formData
        //     }
        // )
        // .then((response) => response.json())
        // .then(
        //     (result) => {
        //         console.log('success', result)
        //     }
        // )
        // .catch(error =>{
        //     console.error("Error:", error)
        // })
    }

    //     // Encrypt file using AES
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

    // // Decrypt file using AES
    // function decryptFile(encryptedFile, encryptionKey) {
    //     const decryptedData = CryptoJS.AES.decrypt(encryptedFile, encryptionKey);
    //     const decryptedText = decryptedData.toString(CryptoJS.enc.Utf8);
    //     return decryptedText;
    // }



    // async function fetchUploadedFiles() {
    //     try {
    //       // Get the first account from Ganache
    //       const accounts = await web3.eth.getAccounts();
    //       const sender = accounts[0];
    
    //       // Fetch the uploaded files from the blockchain
    //       const cloudyContract = new web3.eth.Contract(contractAbi, deployed_contract_address);
    //       const fileCount = await cloudyContract.methods.getFileCount().call({ from: sender });
    
    //       const files = [];
    //       for (let i = 0; i < fileCount; i++) {
    //         const fileHash = await cloudyContract.methods.getFileHash(i).call({ from: sender });
    //         const fileName = await cloudyContract.methods.getFileName(fileHash).call({ from: sender });
    //         const fileUploadDate = await cloudyContract.methods.getFileUploadDate(fileHash).call({ from: sender });
    //         files.push({ fileHash, fileName, fileUploadDate });
    //       }
    
    //       setUploadedFiles(files);
    //     } catch (error) {
    //       console.error('Failed to fetch uploaded files:', error);
    //     }
    //   }
    
    //   useEffect(() => {
    //     fetchUploadedFiles();
    //   }, []);



    // split File Into Shards
    function splitFile(file) {
        console.log("Enter splitFile function")
        const shardSize = 1024 * 1024; // 1MB shard size
        const totalShards = Math.ceil(file.size / shardSize);
        const shards = [];


        // temporary shard code

        shards.push(file);
        

        // let offset = 0;
        // // splits the files into each shard
        // // Note that shard are in the form of a blob when we console.log them
        // for (let i = 0; i < totalShards; i++) {
        //     const shard = file.slice(offset, offset + shardSize);
        //     console.log(shard); 
        //     shards.push(shard);
        //     offset += shardSize;
        // }
        console.log("Exit splitFile function")
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
        const shards = splitFile(file);
    
        // Get the first account from Ganache
        const accounts = await web3.eth.getAccounts();
        const sender = accounts[0];

        const cloudyContract = new web3.eth.Contract(contractAbi, deployed_contract_address);
        console.log("uploadFile function: checkpoint 1"); 
        // Get all storage Providers
        const storageProviders = await cloudyContract.methods.getStorageProvidersWithSpace();
        console.log("List of Storage Providers: " + storageProviders);

        
        // TODO: change blockchain code so that uploadFile function includes storage providers with no space and updates it
        const storageProvidersNoSpace = [];
        const storageProvidersWithSpace = [];

        // Loop through providers
        for (let i = 0; i < storageProviders.size(); i++) {
            // if(storageProviders[i].availableStorageSpace < 1024 * 1024){ // 1024 * 1024 = 1MB
           if(storageProviders[i].availableStorageSpace < file.size()){ // 1024 * 1024 = 1MB
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

        const successfulUpload = false;
        const shardIDs = [];
        for (let i = 0; i < shards.size(); i++) {
            const storageProviderIndex = i;
            if(i == storageProvidersWithSpace.size()){
                storageProviderIndex = i % storageProvidersWithSpace.size();
            }
            const shardID = i;
            // const shardID = generateShardId(shards[i]);
            const endpoint = `http://${storageProviders[storageProviderIndex]}:5000/upload`;
            const formData = new FormData();
                formData.append('shard', shards[i]);
                formData.append('shardID', shardID);

                fetch(endpoint, {
                    method: 'POST',
                    body: formData,
                  })
                    .then((response) => {
                      if (response.ok) {
                        console.log('Shards uploaded successfully');
                        // shardsToProviders.set(shardID, storageProviders[storageProviderIndex]);
                        console.log(`Storing shard ${i} with storage provider ${storageProvidersWithSpace[storageProviderIndex]}`);  
                        successfulUpload = true;
                        shardIDs.push(shardID);
                      } else {
                        throw new Error('Failed to upload shards');
                      }
                    })
                    .catch((error) => {
                      console.error('Error uploading shards:', error);
                    });
                          
         }

         if(successfulUpload){
            const response = await cloudyContract.methods.uploadFile("ouldooz", file.name, _filehash, shardIDs).send({ from: sender,  gas: 500000 });
            console.log("response to uploadFile(): " + response);
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

    
    // function generateShardId(shard) {
    //     const hash = crypto.createHash('sha256');
    //     hash.update(shard);
    //     const shardId = hash.digest('hex');
    //     return shardId;
    // }




    }

      



    return(
        // body
        <div>
             {/* top bar */}
             <Navbar/>
            <div>
                <div className="upload-form">
                    <div className="flex-container">
                    <div className="flex-child">
                    <label className="greeting-labels">Nice to see you, Ouldooz!</label>
                    <br/>
                    <br/>
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
                <br/>
                <br/>
                <div className="table-container">
                    <table className="search-table">
                    <tbody>    
                        <tr>
                            <th>File Name</th>
                            {/* <th>Date Uploaded</th> */}
                            <th>Download</th>
                            <th>Delete</th>
                        </tr>
                        {uploadedFiles.map((file) => (
                            <tr key={file.fileHash}>
                            <td className="filename">{file.fileName}</td>
                            {/* <td>{file.fileUploadDate}</td> */}
                            <td>
                                <a className='download-button'>
                                {/* <a className='download-button' onClick={() => handleDownload(file.fileHash, encryptionKey)}> */}
                                Download
                                </a>
                            </td>
                            <td>
                                <a className='delete-button'>
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