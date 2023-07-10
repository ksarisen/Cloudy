import React, { useState } from "react";
import './Home.css';
import Navbar from '../Navbar/Navbar';
// import dotenv from 'dotenv';
import Web3 from 'web3';
import contractAbi from './contractAbi.json';
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

    //NOTE the next line is a BAD temporary hardcoded way to access loclaly hosted blockchain.
    let ganacheEndpoint = "http://127.0.0.1:7545" //TODO: make dotenv import workprocess.env.GANACHE_ENDPOINT;
    let deployed_contract_address = "0x3c627518B0EBBC15ab7B505B70B22F8cB455796E"// process.env.REMIX_CONTRACT_ADDRESS
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
      async function uploadFile(file) {
        try {
          const fileName = file.name;
          const _filehash = await stringToBytes20(fileName);
      
          // Get the first account from Ganache
          const accounts = await web3.eth.getAccounts();
          const sender = accounts[0];
      
          // Send a transaction to the blockchain
          const cloudyContract = new web3.eth.Contract(contractAbi, deployed_contract_address);
          const response = await cloudyContract.methods._storeFile(_filehash).send({ from: sender,  gas: 500000 });
          console.log(response);

          const senderBalance = await web3.eth.getBalance(sender);
          console.log ("Current account balance is " + senderBalance);
      
          console.log("File: "+ fileName +"With Hash: " +_filehash+ "uploaded to the blockchain.");
        } catch (error) {
          console.error('Failed to upload file:', error);
        }
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
                    <form onSubmit={handleUpload}>
                    <div className="upload-container">
                        <label className="upload-labels">Try to Upload a File: &nbsp;</label> 
                        <input className="file" type="file" name="file" onChange={handleFile} />
                    </div>
                    <br />
                    <button className="button" type="submit">Upload</button>
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
                            <th>Date Uploaded</th>
                            <th>Download</th>
                            <th>Delete</th>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 1</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 2</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 3</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 4</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 5</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                    </tbody>
                    </table>
                </div>
            </div>

        </div>
    )
}
export default Home;