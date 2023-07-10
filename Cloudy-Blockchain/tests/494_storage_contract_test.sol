// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../contracts/cloudy_contract.sol";

contract ClientManagerTest /*is ClientManager*/{
    ClientManager clientManager;
    bytes20 fileHash1;
    bytes20 fileHash2;
    address account0; //contract owner account.
    address account1; //file owner account with no files, used to test access permsissions

    function beforeAll() public {
        //one time setup initializing local variables
        fileHash1 = bytes20(0x1234567890123456789012345678901234567890);
        fileHash2 = bytes20(hex"abcdefabcdefabcdefabcdefabcdefabcdefabcd");
        account0 = TestsAccounts.getAccount(0);
        account1 = TestsAccounts.getAccount(1);
    }

    function beforeEach() public {
        //reset between tests with a fresh clientManager to preserve idempotence of tests
        //e.g. without this reset, adding a file to a mapping will not have a length of 1 after the first run.
        
        clientManager = new ClientManager();
        // if (clientManager.owner() != account0){
        //     //make sure the owner is consistent, and available
        //     clientManager.transferOwnership(account0);
        // }
        
    }

    /// #sender: account-0
    function testStoreFile() public {
        //Confirm a valid user can store a file, and retrieve it.
        Assert.equal(msg.sender, account0, "wrong sender in testStoreFile");

        // Call the _storeFile function to  associate a filehash with its owner: account-0
        clientManager._storeFile(fileHash1);

        // Get the stored file hashes for account-0
        try clientManager.getMyFilehashes() returns (bytes20[] memory fileHashes)
        {
            // Assert that the stored file hash matches the provided file hash
            Assert.equal(fileHashes.length, 1, "Incorrect number of file hashes");
            Assert.equal(fileHashes[0], fileHash1, "Stored file hash does not match");
        } catch Error(string memory reason) {
            //test case fails if we hit an error
            Assert.ok(false, reason);
        } catch {
            Assert.ok(false, "Unexpected error in getMyFilehashes");
        }
        
    }

    // /// #sender: account-0
    // function testStoreFile() public {
            //this function tries to get empty filehashes list

    
    /// #sender: account-0
    function testCheckFileHash() public {
        // Call the _storeFile function to add file hash to the contract

        //Store a couple files
        clientManager._storeFile(fileHash1);
        clientManager._storeFile(fileHash2);

        // Test the checkFileHash function valid case
        try clientManager.checkFileHash(fileHash1) returns (uint result1){
            //fileHash1 was added, so this check should find it
            Assert.equal(result1, 1, "A file that was added somehow did not pass checkFileHash");
        } catch {
            Assert.ok(false, "Unexpected error in checkFileHash");
        }

        try clientManager.checkFileHash(fileHash2) returns (uint result){
            //This file hasnt been added, so check should fail
            Assert.equal(result, 1, "A file that was never added somehow passed checkFileHash");
        } catch {
            Assert.ok(false, "Unexpected error in checkFileHash");
        }
        // Test the checkFileHash function invalid case
        bytes20 nonExistentFileHash = bytes20(0x1111111111111111111111111111111111111111);
        try clientManager.checkFileHash(nonExistentFileHash) returns (uint result){
            //This file hasnt been added, so check should fail
            Assert.equal(result, 0, "A file that was never added somehow passed checkFileHash");
        } catch {
            Assert.ok(false, "Unexpected error in checkFileHash");
        }
    }
    /// #sender: account-0
    function testDeleteFileHash() public {
        // Use the already declared file hash to be deleted
        // Store the file hash using the ClientManager contract
        clientManager._storeFile(fileHash1);
        
        // Get the initial file count
        uint initialCount = clientManager.ownerFileCount(address(this));
        
        // Delete the file hash
        clientManager._deleteFileHash(fileHash1);
        
        // Get the updated file count
        uint updatedCount = clientManager.ownerFileCount(address(this));
        
        // Assert that the file count has decreased by 1
        Assert.equal(updatedCount, initialCount - 1, "File count should decrease by 1");
        
        // Assert that the file hash no longer exists
        Assert.equal(clientManager.checkFileHash(fileHash1), 0, "File hash should not exist");
    }
    /// #sender: account-0
    function testAssociateShardsWithFileHash() public {

        clientManager._storeFile(fileHash1);

        // Generate some random shard IDs
        uint[] memory shardIDs = new uint[](3);
        shardIDs[0] = 1;
        shardIDs[1] = 2;
        shardIDs[2] = 3;
        
        // Call the associateShardsWithFileHash function
        clientManager.associateShardsWithFileHash(fileHash1, shardIDs);
        
        // Assert that the shard IDs are associated with the file hash
        Assert.equal(clientManager.getShardIDs(fileHash1).length, 3, "Incorrect number of shards associated with the file hash");
        Assert.equal(clientManager.getShardIDs(fileHash1)[0], shardIDs[0], "Incorrect shard ID");
        Assert.equal(clientManager.getShardIDs(fileHash1)[1], shardIDs[1], "Incorrect shard ID");
        Assert.equal(clientManager.getShardIDs(fileHash1)[2], shardIDs[2], "Incorrect shard ID");
    }
    /// #sender: account-0
    function testGetShardIDs() public {
        clientManager._storeFile(fileHash1);

        // Associate some shard IDs with it
        uint[] memory shardIDs = new uint[](3);
        shardIDs[0] = 0;
        shardIDs[1] = 1;
        shardIDs[2] = 2;
        clientManager.associateShardsWithFileHash(fileHash1, shardIDs);

        // Retrieve the shard IDs for the file hash
        uint[] memory result = clientManager.getShardIDs(fileHash1);

        // Verify the result
        Assert.equal(result.length, shardIDs.length, "Incorrect number of shard IDs");
        for (uint i = 0; i < result.length; i++) {
            Assert.equal(result[i], shardIDs[i], "Incorrect shard ID");
        }
    }
    /// #sender: account-0
    function testGetShardsInFile_Count() public {
        clientManager._storeFile(fileHash1);

        uint[] memory shardIDs = new uint[](3);
        shardIDs[0] = 0;
        shardIDs[1] = 1;
        shardIDs[2] = 2;

        clientManager.associateShardsWithFileHash(fileHash1, shardIDs);

        uint expectedCount = 3;
        uint actualCount = clientManager.getShardsInFile_Count(fileHash1);

        Assert.equal(actualCount, expectedCount, "Incorrect count of shards in file.");
    }
    /// #sender: account-0
    function testSetFileHashOwner() public {
        clientManager._storeFile(fileHash1);

        // Set the file hash owner
        clientManager.setFileHashOwner(fileHash1, address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2));

        // Get the file hash owner
        address fileOwner = clientManager.fileHashToOwner(fileHash1);

        // Assert the owner is set correctly
        Assert.equal(fileOwner, address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), "File owner should be set correctly");
    }
    /// #sender: account-0
    function testHasConsent() public {
        clientManager._storeFile(fileHash1);
        
        // Assign the owner of the file hash
        clientManager.setFileHashOwner(fileHash1, address(this));

        // Check if the owner has consent for the file hash
        bool hasConsent = clientManager.hasConsent(fileHash1, address(this));

        Assert.equal(hasConsent, true, "Owner should have consent for the file hash");
    }
    /// #sender: account-0
    function testNoConsent() public {
        clientManager._storeFile(fileHash1);

        // Set a non-owner account
        address nonOwner = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; 

        // Check if the non-owner has consent for the file hash
        bool hasConsent = clientManager.hasConsent(fileHash1, nonOwner);

        Assert.equal(hasConsent, false, "Non-owner should not have consent for the file hash");
    }
    /// #sender: account-0
    function getFilehashesByOwnerTest() public {
        // Create some file hashes and associate them with the owner
        bytes20 fileHash1 = bytes20(0x1234567890123456789012345678901234567890);
        bytes20 fileHash2 = bytes20(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        bytes20 fileHash3 = bytes20(0x9876543210987654321098765432109876543210);
        clientManager._storeFile(fileHash1);
        clientManager._storeFile(fileHash2);
        clientManager._storeFile(fileHash3);

        // Get file hashes by owner
        bytes20[] memory filehashes = clientManager.getMyFilehashes();

        // Assert the returned file hashes match the expected values
        Assert.equal(filehashes.length, 3, "Incorrect number of file hashes");
        Assert.equal(filehashes[0], fileHash1, "Incorrect file hash at index 0");
        Assert.equal(filehashes[1], fileHash2, "Incorrect file hash at index 1");
        Assert.equal(filehashes[2], fileHash3, "Incorrect file hash at index 2");
    }
    /// #sender: account-0
    function testGetShardsByFilehash() public {
        clientManager._storeFile(fileHash1);
        
        uint[] memory shardIds = new uint[](3);
        shardIds[0] = 0;
        shardIds[1] = 1;
        shardIds[2] = 2;
        
        // Associate the shard IDs with the file hash
        clientManager.associateShardsWithFileHash(fileHash1, shardIds);
        
        // Call the getShardsByFilehash function
        uint[] memory result = clientManager.getShardsByFilehash(fileHash1);
        
        // Assert that the returned array length is equal to the expected length
        Assert.equal(result.length, 3, "Incorrect array length");
        
        // Assert that each element in the returned array is equal to the expected shard ID
        Assert.equal(result[0], 0, "Incorrect shard ID at index 0");
        Assert.equal(result[1], 1, "Incorrect shard ID at index 1");
        Assert.equal(result[2], 2, "Incorrect shard ID at index 2");
    }
    /// #sender: account-0
    function testRemoveStorageProvider() public {

        // Set a farmer account
        //address storageProvider = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        uint nodeId;
        try clientManager.addStorageProvider(account1, 100, "Type") returns (uint newNodeId) {
            nodeId = newNodeId;
        } catch Error(string memory reason) {
            //test case fails if we hit an error
            Assert.ok(false, reason);
        } catch {
            Assert.ok(false, "Unexpected error in addStorageProvider");
        }
        
        

        // Get the initial storage provider count
        uint initialProviderCount = clientManager.getFarmerCount();

        //confirm addition worked
        Assert.equal(initialProviderCount, 1, "Failed to insert first provider in testRemoveStorageProvider()");

        // Remove the storage provider
        
        // Get the updated storage provider count
        try clientManager.removeStorageProvider(nodeId) {
        } catch Error(string memory reason) {
            //test case fails if we hit an error
            Assert.ok(false, reason);
        } catch {
            Assert.ok(false, "Unexpected error in removeStorageProvider");
        }

        try clientManager.getFarmerCount() returns (uint updatedProviderCount){
            // Assert that the provider count is decreased by 1
            Assert.equal(updatedProviderCount, initialProviderCount - 1, "Provider count should be decreased by 1");
        } catch {
            Assert.ok(false, "Unexpected error in getFarmerCount");
        }
    }
    /// #sender: account-0
    function getStorageProviderNodeID_Test() public {
        clientManager.addStorageProvider(address(this), 100,  "Type A");
        //We support adding the same storage provider with a different data storage type available
        uint nodeId;
        try clientManager.addStorageProvider(account1, 200, "Type B") returns (uint newNodeId) {
            nodeId = newNodeId;
        } catch Error(string memory reason) {
            //test case fails if we hit an error
            Assert.ok(false, reason);
        } catch {
            Assert.ok(false, "Unexpected error in addStorageProvider");
        }
        

        uint nodeID = clientManager.getStorageProviderNodeID(address(this));
        Assert.equal(nodeID, nodeId, "Incorrect storage provider node ID");
    }
    /// #sender: account-0
    function getStorageProviderNodeID_NonExistentProvider_Test() public {
        clientManager.addStorageProvider(address(this), 100,  "Type A");
        clientManager.addStorageProvider(address(this), 200, "Type B");

        uint nodeID = clientManager.getStorageProviderNodeID(address(0x123456789));
        Assert.equal(nodeID, 0, "Expected 0 for non-existent storage provider node ID");
    }
    /// #sender: account-0
    function testAddShardToStorageProvider() public {
        uint shardId = 0;

        // Set a farmer account
        address storageProvider = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        // Add a storage provider
        uint farmerNodeId = clientManager.addStorageProvider(storageProvider, 10, "Type A");

        // Add a shard to the storage provider
        clientManager.addShardToStorageProvider(shardId, farmerNodeId);

        // Verify that the storage provider has the shard
        Assert.equal(farmerNodeId, clientManager.getFarmerIdFromShardId(shardId), "Shard wasn't added to the storage provider successfully");
    }
    /// #sender: account-0
    function testRemoveShardFromStorageProvider() public {
        uint shardId = 0;

        // Set a farmer account
        address storageProvider = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        // Add a storage provider
        uint farmerNodeId = clientManager.addStorageProvider(storageProvider, 10, "Type A");

        // Add a shard to the storage provider
        clientManager.addShardToStorageProvider(shardId, farmerNodeId);
        // Assert that the shard is initially assigned to the storage provider
        Assert.equal(clientManager.getFarmerIdFromShardId(shardId), farmerNodeId, "Shard should be assigned to the specified farmer.");

        // Assert that the storage provider's current stored size is initially 1
        (, , uint currentStoredSize, , ) = clientManager.getFarmer(farmerNodeId);
        Assert.equal(currentStoredSize, 1, "Storage provider should have one shard assigned.");

        // Remove the shard from the storage provider
        clientManager.removeShardFromStorageProvider(shardId, farmerNodeId);

        // Assert that the shard is no longer assigned to the storage provider
        Assert.equal(clientManager.getFarmerIdFromShardId(shardId), 0, "Shard should not be assigned to any farmer.");

        // Assert that the storage provider's current stored size is updated to 0
        (, , currentStoredSize, , ) = clientManager.getFarmer(farmerNodeId);
        Assert.equal(currentStoredSize, 0, "Storage provider should have no shards assigned.");
    }
}
