// import dotenv from 'dotenv';
import React, { useState, useEffect, useRef } from "react";
import './Home.css';
import Navbar from '../Navbar/Navbar';
import Web3 from 'web3';
import contractAbi from '../../contractAbi.json';
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
    const [uploadedFiles, setUploadedFiles] = useState([]);
    const fileInputRef = useRef(null);
    //NOTE the next line is a BAD temporary hardcoded way to access locally hosted blockchain.
    let ganacheEndpoint = "http://127.0.0.1:7545" //TODO: make dotenv import workprocess.env.GANACHE_ENDPOINT;
    let deployed_contract_address = "0x15dE6d3dccFC7052B1AAABe8D96Aa7c26deC9957"// process.env.REMIX_CONTRACT_ADDRESS
    //TODO: update the above lines to use .env variables rather than constants
    const web3 = new Web3(new Web3.providers.HttpProvider(ganacheEndpoint));
    web3.eth.handleRevert = true;

    const cloudyContract = new web3.eth.Contract(contractAbi, deployed_contract_address);

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
        console.log("handleFile Enter");
        if (typeof (event.target.files[0]) !== 'undefined' && event.target.files[0] != null) {
            setFile(event.target.files[0]);
            //for debugging file upload:
            // console.log(event.target.files[0]);
            // console.log({ file });
        } else {
            setFile(null);
            console.log("File Not Chosen");
        }
    }

    //turn the filename into a unique hashed id for the file
    //TODO: handle two files with the same name
    async function stringToBytes32(inputString) {
        const encoder = new TextEncoder();
        const data = encoder.encode(inputString);

        const hashBuffer = await crypto.subtle.digest('SHA-1', data);
        const hashArray = Array.from(new Uint8Array(hashBuffer));

        const desiredLength = 32; // 32 bytes * 2 characters per byte (since it's a hexadecimal string)

        if (hashArray.length < desiredLength) {
            const padding = Array(desiredLength - hashArray.length).fill(0);
            hashArray.push(...padding);
        } else {
            hashArray.splice(desiredLength);
        }

        const bytes32Hash = '0x' + hashArray.map((byte) => byte.toString(16).padStart(2, '0')).join('');
        return bytes32Hash;
    }


    function handleUpload(event) {
        event.preventDefault();
        checkHosting(); // confirm the blockchain is connected, for debugging only.
        uploadFile(file);
        fileInputRef.current.value = '';
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
            // TODO: Please change the way we hash stringToBytes32  
            const _filehash = await stringToBytes32(fileName);

            // TODO: Encrypt the file

            // Split file into shards
            // Do not split shards yet. Try to upload file as 1 shard / 1 file first and see if it works
            const shards = splitFile(file,1); // TODO: decide if we want to split files into more than 1 big shard
            
            // Get the first account from Ganache
            const accounts = await web3.eth.getAccounts();
            const sender = accounts[0];
            // Get all storage Providers
            //TODO: update to use uploadFile(string memory _ownerName, string memory _fileName, bytes32 _fileHash, uint256[] memory _shardIds)
            var gasEstimateForUpload = 50000

            try {
                gasEstimateForUpload = await cloudyContract.methods
                  .getIPsOfStorageProvidersWithSpace()
                  .estimateGas({ from: sender, gas: 500000 });
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
                // const shardID = generateShardId(shards[i]); //To be used once we confirm hashing shards works. for now shards will be globally unique ints from the blockchain's shardCounter
                
                //TODO Jen: get the storageProvider holding this shard (get it from the blockchain) then uncomment the line below
                //const endpoint = `${storageProviders[storageProviderIndex]/*.ip*/}:5002/upload`;
                const endpoint = `http://127.0.0.1:5002/upload`;

            // call upload file first and will return a series of new shard IDs.
            //TODO: estimate the gas as we did above instead of using gas: 5000000
            let response;
            try {
                //for the demo,  all files are owned by the single user "Ouldooz" since user management can be added later
                response = await cloudyContract.methods.uploadFile("ouldooz", file.name, _filehash, 1).send({ from: sender, gas: 5000000 });
                // Handle the response here if needed
              } catch (error) {
                // Handle the error gracefully
                // Check if error.data exists and has a specific error message
                if (error.data && error.data.includes('Revert')) {
                    // Use the contract's decodeErrorReason function to get the specific error message
                    const errorMessage = await cloudyContract.methods.decodeErrorReason(error.data).call();
                    console.error('Failed to add file to the blockchain. ', errorMessage);
                } else {
                    console.error(error);
                    console.info('Failed to add file to the blockchain. NO DUPLICATE FILES ALLOWED');//apparently web3 doesn't let us log errors from solidity's require messages.
                }
                return;
                
            } 
            console.log("Response from blockchain after calling uploadFile():", response);

            const newFile = {
                fileHash: _filehash, 
                fileName: fileName, 
                shardIds: [],
                fileUploadDate: Date.now()
            };

            //TODO: handle case where file has previously been uploaded and is a duplicate.
            const shardIdResponse = await cloudyContract.methods.getFilesShards(_filehash).call({ from: sender, gas: 5000000 }); //for the demo,  all files are owned by the single user "Ouldooz" since user management can be added later
            
            //update the UI with the newly updated file's data.
            newFile.shardIds = shardIdResponse;
            setUploadedFiles([...uploadedFiles, newFile]);
            
            var shardName;
            const formData = new FormData();
            if (shardIdResponse.length > 0) {
                shards.forEach((shard, index) => {
                    shardName = `shard_${shardIdResponse[index]}_of_file_${fileName}`;
                    formData.append(shardName, shard);
                    console.log("formData of shard being sent:")
                    console.log(formData)
                });
            }
            else{
               console.error("ERROR unable to connect to the Blockchain; No shardIds were returned!");
               console.log(shardIdResponse );
            }
                try {
                    const response = await fetch(endpoint, {
                        method: 'POST',
                        mode: 'cors',
                        body: formData,
                    });
    
                    if (response.ok) {
                        console.log(`Storing shards ${formData} with storage provider ${storageProvidersWithSpace[storageProviderIndex]}`);
                        successfulUpload = true;
                        shardIDs.push(shardName);
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


    function generateShardId(shard) {
        const hash = crypto.createHash('sha256');
        hash.update(shard);
        const shardId = hash.digest('hex');
        shardId = convertToBytes32(shardId);
        return shardId;
    }

    function convertToBytes32(hexString) {
        const hex = hexString.replace('0x', ''); // Remove '0x' prefix if present
        const uint8Array = new Uint8Array(hex.match(/.{1,2}/g).map((byte) => parseInt(byte, 16)));
        
        // If the hash is less than 32 bytes, pad the array with zeros at the beginning
        const bytes32 = new Uint8Array(32);
        bytes32.set(uint8Array, bytes32.length - uint8Array.length);
        
        return bytes32;
    }

    async function deleteShard(shardId) {
        try {
            //TODO Jen: get the storageProvider holding this shard (get it from the blockchain) then uncomment the line below
            //const endpoint = `${storageProviders[storageProviderIndex]/*.ip*/}:5002/delete/${shardId}`;
            const endpoint = `http://127.0.0.1:5002/delete/${shardId}`;
            const response = await fetch(endpoint, {
                method: 'DELETE',
                mode: 'cors'
            });
      
            if (response.ok) {
                console.log(`Shard with ID ${shardId} successfully deleted.`);
            } else {
                console.error('Server Error while deleting shard:', response.statusText);
            }
        } catch (error) {
          console.error('Error deleting the shard:', error);
        }
      }

    async function downloadShard(shardId) {
        //TODO Jen: get the storageProvider holding this shard (get it from the blockchain) then uncomment the line below
        //const endpoint = `${storageProviders[storageProviderIndex]/*.ip*/}:5002/upload`;
        const endpoint = `http://127.0.0.1:5002/download/${shardId}`;

        const response = await fetch(endpoint, {
            method: 'GET',
            mode: 'cors'
        }).catch(error => {
            console.error('Error fetching the shard:', error);
            // Handle the error in your app
        });

        //for debugging
        const headers = response.headers;
        headers.forEach((value, name) => {
            console.log(`${name}: ${value}`);
        });
          
        if (!response.ok) {
            console.error('Network response was not ok.');
            // Handle the error in your app
        } else {
            // const filename = response.headers.get('filename'); // Get the filename from the "filename" field
            // const blob = await response.blob();
            // // Assuming 'download' is a function that triggers the download of the blob
            // download(blob, filename);

            const responseData = await response.json(); // Parse the JSON response data
            const filename = responseData.filename; // Get the filename from the JSON response
            const filetype = responseData.file_type; // Get the filename from the JSON response
            const blob = new Blob([base64ToArrayBuffer(responseData.file_contents)], { type: filetype }); // Convert base64 string to Blob
            // Assuming 'download' is a function that triggers the download of the blob
            download(blob, filename);
        }

        


        // const response = await fetch(endpoint, {
        //     method: 'GET',
        //     mode: 'cors'
        // }).then(response => {
        //     if (!response.ok) {
        //       throw new Error('Network response was not ok.');
        //     }
        //     return response.blob();
        // })
        // .then(blob => {
        //     const filename = getFilenameFromResponse(response);
        //     // Assuming 'download' is a function that triggers the download of the blob
        //     download(blob, filename);
        // })
    }

    // Helper function to convert base64 string to ArrayBuffer
    const base64ToArrayBuffer = (base64) => {
        const binaryString = window.atob(base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    }

    function download(blob, filename) {
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = filename;
      
        // Trigger the download by simulating a click on the link
        document.body.appendChild(link);
        link.click();
      
        // Clean up the URL and link
        URL.revokeObjectURL(url);
        document.body.removeChild(link);
      }

    function getFilenameFromResponse(response) {
        const contentDisposition = response.headers.get('Content-Disposition');
        if (contentDisposition && contentDisposition.indexOf('attachment') !== -1) {
          const filenameRegex = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/;
          const matches = filenameRegex.exec(contentDisposition);
          if (matches != null && matches[1]) {
            return matches[1].replace(/['"]/g, '');
          }
        }
        return 'download';
    }
    function handleFileDownload(file) {
        file.shardIds.forEach((shardId) => {
          downloadShard(shardId);
        });
        //TODO: when we expect multiple shards per file, update this to combine all the shard blobs together.
    }
    async function handleFileDelete(file) {
        file.shardIds.forEach((shardId) => {
          deleteShard(shardId);
        });
        const accounts = await web3.eth.getAccounts();
        const sender = accounts[0]
        //todo: improve gas estimate
        const response = await cloudyContract.methods.deleteFile(file.fileHash).send({ from: sender,  gas: 5000000 });
            
        // Remove the file from uploadedFiles after deleting its shards
        const updatedFiles = uploadedFiles.filter((f) => f.fileHash !== file.fileHash);
        setUploadedFiles(updatedFiles);

        console.log("Deleted " + file.fileName);
        console.log(response)
    }


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
                                    <input className="file" type="file" name="file" onChange={handleFile}  ref={fileInputRef}/>
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
                            {uploadedFiles.map((file) => (
                                <tr key={file.fileHash}>
                                    <td className="filename">{file.fileName}</td>
                                    {/* <td>{file.fileUploadDate}</td> */}
                                    <td>
                                        <a className='download-button' onClick={() => handleFileDownload(file /*, encryptionKey*/)}>
                                            Download
                                        </a>
                                    </td>
                                    <td>
                                        <a className='delete-button' onClick={() => handleFileDelete(file)}>
                                            Delete
                                        </a>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            <div hidden className="ben-test">
            <h4>Ben's test zone: </h4>
            <button onClick={() => downloadShard(12)}>Download Shard 12 TEST BUTTON</button>
            <br/>
            <button onClick={() => deleteShard(12)}>Delete Shard 12 TEST BUTTON</button>
            To test the above methods, you need to manually add a file name shard_12_of_file_clouds.png to your Storage Location directory.
            TODO: render the buttons for newly uploaded files based on their shard Id.
            <br/><br/>
            Dont't forget to open the console to see helpful logs while debugging!
            </div>
            </div>

        </div>
    )
}
export default Home;