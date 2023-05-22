// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "/contracts/494_storage_contract.sol";

contract ShardManagerTest {
    ShardManager shardManager;
    bytes20 fileHash;

    function beforeEach() public {
        shardManager = new ShardManager();
        fileHash = bytes20(0x1234567890123456789012345678901234567890);
    }

    function testStoreFile() public {

        // Call the _storeFile function
        shardManager._storeFile(fileHash);

        // Get the stored file hashes for the contract owner
        bytes20[] memory fileHashes = shardManager.getFilehashesByOwner(address(this));

        // Assert that the stored file hash matches the provided file hash
        Assert.equal(fileHashes.length, 1, "Incorrect number of file hashes");
        Assert.equal(fileHashes[0], fileHash, "Stored file hash does not match");
    }

    function checkFileHashTest() public {
        // Set up test data
        bytes20 fileHash1 = bytes20(0x1234567890123456789012345678901234567890);
        bytes20 fileHash2 = bytes20(hex"abcdefabcdefabcdefabcdefabcdefabcdefabcd");

        // Call the _storeFile function to add file hashes to the contract
        shardManager._storeFile(fileHash1);
        shardManager._storeFile(fileHash2);

        // Test the checkFileHash function
        uint result1 = shardManager.checkFileHash(fileHash1);
        Assert.equal(result1, 1, "Expected file hash to exist");

        uint result2 = shardManager.checkFileHash(fileHash2);
        Assert.equal(result2, 1, "Expected file hash to exist");

        bytes20 nonExistentFileHash = bytes20(0x1111111111111111111111111111111111111111);
        uint result3 = shardManager.checkFileHash(nonExistentFileHash);
        Assert.equal(result3, 0, "Expected file hash to not exist");
    }

    function testDeleteFileHash() public {
        // Use the already declared file hash to be deleted
        // Store the file hash using the ShardManager contract
        shardManager._storeFile(fileHash);
        
        // Get the initial file count
        uint initialCount = shardManager.ownerFileCount(address(this));
        
        // Delete the file hash
        shardManager._deleteFileHash(fileHash);
        
        // Get the updated file count
        uint updatedCount = shardManager.ownerFileCount(address(this));
        
        // Assert that the file count has decreased by 1
        Assert.equal(updatedCount, initialCount - 1, "File count should decrease by 1");
        
        // Assert that the file hash no longer exists
        Assert.equal(shardManager.checkFileHash(fileHash), 0, "File hash should not exist");
    }

    function testAssociateShardsWithFileHash() public {

        shardManager._storeFile(fileHash);

        // Generate some random shard IDs
        uint[] memory shardIDs = new uint[](3);
        shardIDs[0] = 1;
        shardIDs[1] = 2;
        shardIDs[2] = 3;
        
        // Call the associateShardsWithFileHash function
        shardManager.associateShardsWithFileHash(fileHash, shardIDs);
        
        // Assert that the shard IDs are associated with the file hash
        Assert.equal(shardManager.getShardIDs(fileHash).length, 3, "Incorrect number of shards associated with the file hash");
        Assert.equal(shardManager.getShardIDs(fileHash)[0], shardIDs[0], "Incorrect shard ID");
        Assert.equal(shardManager.getShardIDs(fileHash)[1], shardIDs[1], "Incorrect shard ID");
        Assert.equal(shardManager.getShardIDs(fileHash)[2], shardIDs[2], "Incorrect shard ID");
    }

    function testGetShardIDs() public {
        shardManager._storeFile(fileHash);

        // Associate some shard IDs with it
        uint[] memory shardIDs = new uint[](3);
        shardIDs[0] = 0;
        shardIDs[1] = 1;
        shardIDs[2] = 2;
        shardManager.associateShardsWithFileHash(fileHash, shardIDs);

        // Retrieve the shard IDs for the file hash
        uint[] memory result = shardManager.getShardIDs(fileHash);

        // Verify the result
        Assert.equal(result.length, shardIDs.length, "Incorrect number of shard IDs");
        for (uint i = 0; i < result.length; i++) {
            Assert.equal(result[i], shardIDs[i], "Incorrect shard ID");
        }
    }

    function testGetShardsInFile_Count() public {
        shardManager._storeFile(fileHash);

        uint[] memory shardIDs = new uint[](3);
        shardIDs[0] = 0;
        shardIDs[1] = 1;
        shardIDs[2] = 2;

        shardManager.associateShardsWithFileHash(fileHash, shardIDs);

        uint expectedCount = 3;
        uint actualCount = shardManager.getShardsInFile_Count(fileHash);

        Assert.equal(actualCount, expectedCount, "Incorrect count of shards in file.");
    }

    function testSetFileHashOwner() public {
        shardManager._storeFile(fileHash);

        // Set the file hash owner
        shardManager.setFileHashOwner(fileHash, address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2));

        // Get the file hash owner
        address fileOwner = shardManager.fileHashToOwner(fileHash);

        // Assert the owner is set correctly
        Assert.equal(fileOwner, address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), "File owner should be set correctly");
    }

    function testHasConsent() public {
        shardManager._storeFile(fileHash);
        
        // Assign the owner of the file hash
        shardManager.setFileHashOwner(fileHash, address(this));

        // Check if the owner has consent for the file hash
        bool hasConsent = shardManager.hasConsent(fileHash, address(this));

        Assert.equal(hasConsent, true, "Owner should have consent for the file hash");
    }

    function testNoConsent() public {
        shardManager._storeFile(fileHash);

        // Set a non-owner account
        address nonOwner = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; 

        // Check if the non-owner has consent for the file hash
        bool hasConsent = shardManager.hasConsent(fileHash, nonOwner);

        Assert.equal(hasConsent, false, "Non-owner should not have consent for the file hash");
    }

    function getFilehashesByOwnerTest() public {
        // Create some file hashes and associate them with the owner
        bytes20 fileHash1 = bytes20(0x1234567890123456789012345678901234567890);
        bytes20 fileHash2 = bytes20(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        bytes20 fileHash3 = bytes20(0x9876543210987654321098765432109876543210);
        shardManager._storeFile(fileHash1);
        shardManager._storeFile(fileHash2);
        shardManager._storeFile(fileHash3);

        // Get file hashes by owner
        bytes20[] memory filehashes = shardManager.getFilehashesByOwner(address(this));

        // Assert the returned file hashes match the expected values
        Assert.equal(filehashes.length, 3, "Incorrect number of file hashes");
        Assert.equal(filehashes[0], fileHash1, "Incorrect file hash at index 0");
        Assert.equal(filehashes[1], fileHash2, "Incorrect file hash at index 1");
        Assert.equal(filehashes[2], fileHash3, "Incorrect file hash at index 2");
    }

    function testGetShardsByFilehash() public {
        shardManager._storeFile(fileHash);
        
        uint[] memory shardIds = new uint[](3);
        shardIds[0] = 0;
        shardIds[1] = 1;
        shardIds[2] = 2;
        
        // Associate the shard IDs with the file hash
        shardManager.associateShardsWithFileHash(fileHash, shardIds);
        
        // Call the getShardsByFilehash function
        uint[] memory result = shardManager.getShardsByFilehash(fileHash);
        
        // Assert that the returned array length is equal to the expected length
        Assert.equal(result.length, 3, "Incorrect array length");
        
        // Assert that each element in the returned array is equal to the expected shard ID
        Assert.equal(result[0], 0, "Incorrect shard ID at index 0");
        Assert.equal(result[1], 1, "Incorrect shard ID at index 1");
        Assert.equal(result[2], 2, "Incorrect shard ID at index 2");
    }

    function testRemoveStorageProvider() public {

        // Set a farmer account
        address storageProvider = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        shardManager.addStorageProvider(storageProvider, 1, 100, "Type");

        // Get the initial storage provider count
        uint initialProviderCount = shardManager.getFarmerCount();
        // Remove the storage provider
        shardManager.removeStorageProvider(1);
        // Get the updated storage provider count
        uint updatedProviderCount = shardManager.getFarmerCount();
        // Assert that the provider count is decreased by 1
        Assert.equal(updatedProviderCount, initialProviderCount - 1, "Provider count should be decreased by 1");
    }

    function getStorageProviderNodeID_Test() public {
        shardManager.addStorageProvider(address(this), 1, 100, "Type A");
        shardManager.addStorageProvider(address(this), 2, 200, "Type B");

        uint nodeID = shardManager.getStorageProviderNodeID(address(this));
        Assert.equal(nodeID, 1, "Incorrect storage provider node ID");
    }

    function getStorageProviderNodeID_NonExistentProvider_Test() public {
        shardManager.addStorageProvider(address(this), 1, 100, "Type A");
        shardManager.addStorageProvider(address(this), 2, 200, "Type B");

        uint nodeID = shardManager.getStorageProviderNodeID(address(0x123456789));
        Assert.equal(nodeID, 0, "Expected 0 for non-existent storage provider node ID");
    }

    function testAddShardToStorageProvider() public {
        uint shardId = 0;
        uint farmerNodeId = 0;

        // Set a farmer account
        address storageProvider = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        // Add a storage provider
        shardManager.addStorageProvider(storageProvider, farmerNodeId, 10, "Type A");

        // Add a shard to the storage provider
        shardManager.addShardToStorageProvider(shardId, farmerNodeId);

        // Verify that the storage provider has the shard
        Assert.equal(farmerNodeId, shardManager.getFarmerIdFromShardId(shardId), "Shard wasn't added to the storage provider successfully");
    }

    function testRemoveShardFromStorageProvider() public {
        uint shardId = 0;
        uint farmerNodeId = 0;

        // Set a farmer account
        address storageProvider = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        // Add a storage provider
        shardManager.addStorageProvider(storageProvider, farmerNodeId, 10, "Type A");

        // Add a shard to the storage provider
        shardManager.addShardToStorageProvider(shardId, farmerNodeId);
        // Assert that the shard is initially assigned to the storage provider
        Assert.equal(shardManager.getFarmerIdFromShardId(shardId), farmerNodeId, "Shard should be assigned to the specified farmer.");

        // Assert that the storage provider's current stored size is initially 1
        (, , uint currentStoredSize, , ) = shardManager.getFarmer(farmerNodeId);
        Assert.equal(currentStoredSize, 1, "Storage provider should have one shard assigned.");

        // Remove the shard from the storage provider
        shardManager.removeShardFromStorageProvider(shardId, farmerNodeId);

        // Assert that the shard is no longer assigned to the storage provider
        Assert.equal(shardManager.getFarmerIdFromShardId(shardId), 0, "Shard should not be assigned to any farmer.");

        // Assert that the storage provider's current stored size is updated to 0
        (, , currentStoredSize, , ) = shardManager.getFarmer(farmerNodeId);
        Assert.equal(currentStoredSize, 0, "Storage provider should have no shards assigned.");
    }
}
