// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "truffle/Assert.sol";
import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../contracts/NewCloudy.sol";

contract TestDistributedStorage {
    DistributedStorage public storageContract;

    function beforeEach() public {
        storageContract = new DistributedStorage();
    }

    function testUploadFile() public {
        // Create some sample data
        string memory ownerName = "Alice";
        string memory fileName = "test.txt";
        bytes32 fileHash = keccak256(abi.encodePacked("sample file content"));

        // Upload the file
        storageContract.uploadFile(ownerName, fileName, fileHash, new uint256[](0));

        // Get the file details
        (address owner, string memory uploadedOwnerName, string memory uploadedFileName, bytes32 uploadedFileHash) = storageContract.getFileDetails(fileHash);

        // Assert that the file details match the uploaded values
        Assert.equal(owner, address(this), "File owner should be the contract address");
        Assert.equal(uploadedOwnerName, ownerName, "Uploaded owner name should match");
        Assert.equal(uploadedFileName, fileName, "Uploaded file name should match");
        Assert.equal(uploadedFileHash, fileHash, "Uploaded file hash should match");
    }

    function testDeleteFile() public {
        // Create some sample data
        string memory ownerName = "Alice";
        string memory fileName = "test.txt";
        bytes32 fileHash = keccak256(abi.encodePacked("sample file content"));

        // Upload the file
        storageContract.uploadFile(ownerName, fileName, fileHash, new uint256[](0));

        // Delete the file
        storageContract.deleteFile(fileHash);

        // Try to get the deleted file details
        (address owner, , , bytes32 uploadedFileHash) = storageContract.getFileDetails(fileHash);

        // Assert that the file details are empty
        Assert.equal(owner, address(0), "File owner should be empty");
        Assert.equal(uploadedFileHash, bytes32(0), "Uploaded file hash should be empty");
    }

    function testAssignStorageProvider() public {
        // Create some sample data
        string memory ownerName = "Alice";
        string memory fileName = "test.txt";
        bytes32 fileHash = keccak256(abi.encodePacked("sample file content"));

        // Upload the file
        storageContract.uploadFile(ownerName, fileName, fileHash, new uint256[](0));

        // Add a storage provider
        address storageProvider = address(0x123);
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Assign the storage provider to the shard
        uint256 shardId = 1;
        storageContract.assignStorageProvider(shardId, storageProvider);

        // Get the shard details
        DistributedStorage.Shard memory shard = storageContract.shards(shardId);

        // Assert that the storage provider is assigned to the shard
        Assert.equal(shard.storageProvider, storageProvider, "Storage provider should be assigned to the shard");
    }

    function testAuditShard() public {
        // Create some sample data
        address storageProvider = address(0x123);
        uint256 shardId = 1;

        // Add a storage provider
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Assign the storage provider to the shard
        storageContract.assignStorageProvider(shardId, storageProvider);

        // Audit the shard
        storageContract.auditShard(shardId);

        // Get the shard details
        DistributedStorage.Shard memory shard = storageContract.shards(shardId);

        // Assert that the shard is still valid and the storage provider was rewarded
        Assert.isTrue(shard.exists, "Shard should still exist");
        Assert.equal(shard.storageProvider, storageProvider, "Storage provider should still be assigned to the shard");
    }

    function testRemoveShardFromProvider() public {
        // Create some sample data
        address storageProvider = address(0x123);
        uint256 shardId = 1;

        // Add a storage provider
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Assign the storage provider to the shard
        storageContract.assignStorageProvider(shardId, storageProvider);

        // Remove the shard from the provider
        storageContract.removeShardFromProvider(shardId);

        // Get the shard details
        DistributedStorage.Shard memory shard = storageContract.shards(shardId);

        // Assert that the shard no longer has a storage provider
        Assert.equal(shard.storageProvider, address(0), "Storage provider should be empty");
    }

    function testDeleteShard() public {
        // Create some sample data
        address storageProvider = address(0x123);
        uint256 shardId = 1;

        // Add a storage provider
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Assign the storage provider to the shard
        storageContract.assignStorageProvider(shardId, storageProvider);

        // Delete the shard
        storageContract.deleteShard(shardId);

        // Get the shard details
        DistributedStorage.Shard memory shard = storageContract.shards(shardId);

        // Assert that the shard no longer exists
        Assert.isFalse(shard.exists, "Shard should no longer exist");
    }

    function testAddStorageProvider() public {
        // Create some sample data
        bytes32 ip = "127.0.0.1";
        address walletAddress = address(0x123);
        uint256 maximumStorageSize = 100;

        // Add the storage provider
        storageContract.addStorageProvider(ip, walletAddress, maximumStorageSize);

        // Get the storage provider details
        (bytes32 storedIp, address storedWalletAddress, uint256 storedAvailableSpace, uint256 storedMaximumSize, bool isStoring) = storageContract.getStorageProviderDetails(walletAddress);

        // Assert that the storage provider details match the added values
        Assert.equal(storedIp, ip, "Stored IP should match");
        Assert.equal(storedWalletAddress, walletAddress, "Stored wallet address should match");
        Assert.equal(storedAvailableSpace, maximumStorageSize, "Stored available space should match");
        Assert.equal(storedMaximumSize, maximumStorageSize, "Stored maximum size should match");
        Assert.isTrue(isStoring, "Storage provider should be marked as storing");
    }

    function testUpdateStorageStatus() public {
        // Create some sample data
        address storageProvider = address(0x123);
        bool isStoring = false;

        // Add the storage provider
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Update the storage status
        storageContract.updateStorageStatus(storageProvider, isStoring);

        // Get the storage provider details
        (, , , , bool storedIsStoring) = storageContract.getStorageProviderDetails(storageProvider);

        // Assert that the storage status is updated
        Assert.equal(storedIsStoring, isStoring, "Storage status should be updated");
    }

    function testUpdateAvailableStorageSpace() public {
        // Create some sample data
        address storageProvider = address(0x123);
        uint256 newAvailableSpace = 50;

        // Add the storage provider
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Update the available storage space
        storageContract.updateAvailableStorageSpace(storageProvider, newAvailableSpace);

        // Get the storage provider details
        (, , uint256 storedAvailableSpace, , ) = storageContract.getStorageProviderDetails(storageProvider);

        // Assert that the available storage space is updated
        Assert.equal(storedAvailableSpace, newAvailableSpace, "Available storage space should be updated");
    }

    function testRemoveProviderFromArray() public {
        // Create an array of addresses
        address[] memory addresses = new address[](3);
        addresses[0] = address(0x111);
        addresses[1] = address(0x222);
        addresses[2] = address(0x333);

        // Remove an address from the array
        address addressToRemove = address(0x222);
        storageContract.removeProviderFromArray(addresses, addressToRemove);

        // Check if the address was removed
        Assert.equal(addresses.length, 2, "Array length should be reduced");
        Assert.equal(addresses[0], address(0x111), "First address should remain");
        Assert.equal(addresses[1], address(0x333), "Second address should shift");
    }

    function testAuditStorageProviders() public {
        // Create some sample data
        address storageProvider = address(0x123);
        uint256 shardId = 1;

        // Add a storage provider
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Assign the storage provider to the shard
        storageContract.assignStorageProvider(shardId, storageProvider);

        // Audit the storage providers
        storageContract.auditStorageProviders(new uint256[](1));

        // Get the storage provider details
        (bytes32 storedIp, address storedWalletAddress, uint256 storedAvailableSpace, uint256 storedMaximumSize, bool isStoring) = storageContract.getStorageProviderDetails(storageProvider);

        // Assert that the storage provider is still valid and was rewarded
        Assert.equal(storedIp, "127.0.0.1", "Stored IP should match");
        Assert.equal(storedWalletAddress, storageProvider, "Stored wallet address should match");
        Assert.equal(storedAvailableSpace, 100, "Stored available space should match");
        Assert.equal(storedMaximumSize, 100, "Stored maximum size should match");
        Assert.isTrue(isStoring, "Storage provider should be marked as storing");
    }

    function testDeleteStorageProvider() public {
        // Create some sample data
        address storageProvider = address(0x123);

        // Add the storage provider
        storageContract.addStorageProvider("127.0.0.1", storageProvider, 100);

        // Delete the storage provider
        storageContract.deleteStorageProvider(storageProvider);

        // Get the storage provider details
        (bytes32 storedIp, address storedWalletAddress, uint256 storedAvailableSpace, uint256 storedMaximumSize, bool isStoring) = storageContract.getStorageProviderDetails(storageProvider);

        // Assert that the storage provider details are empty
        Assert.equal(storedIp, bytes32(0), "Stored IP should be empty");
        Assert.equal(storedWalletAddress, address(0), "Stored wallet address should be empty");
        Assert.equal(storedAvailableSpace, uint256(0), "Stored available space should be empty");
        Assert.equal(storedMaximumSize, uint256(0), "Stored maximum size should be empty");
        Assert.isFalse(isStoring, "Storage provider should not be marked as storing");
    }

    function testGetStorageProviderDetails() public {
        // Create some sample data
        address storageProvider = address(0x123);
        bytes32 ip = "127.0.0.1";
        uint256 availableStorageSpace = 100;
        uint256 maximumStorageSize = 200;

        // Add the storage provider
        storageContract.addStorageProvider(ip, storageProvider, maximumStorageSize);

        // Get the storage provider details
        (bytes32 storedIp, address storedWalletAddress, uint256 storedAvailableSpace, uint256 storedMaximumSize, bool isStoring) = storageContract.getStorageProviderDetails(storageProvider);

        // Assert that the storage provider details match the added values
        Assert.equal(storedIp, ip, "Stored IP should match");
        Assert.equal(storedWalletAddress, storageProvider, "Stored wallet address should match");
        Assert.equal(storedAvailableSpace, availableStorageSpace, "Stored available space should match");
        Assert.equal(storedMaximumSize, maximumStorageSize, "Stored maximum size should match");
        Assert.isTrue(isStoring, "Storage provider should be marked as storing");
    }

    function testGetFileDetails() public {
        // Create some sample data
        string memory ownerName = "Alice";
        string memory fileName = "test.txt";
        bytes32 fileHash = keccak256(abi.encodePacked("sample file content"));

        // Upload the file
        storageContract.uploadFile(ownerName, fileName, fileHash, new uint256[](0));

        // Get the file details
        (address owner, string memory uploadedOwnerName, string memory uploadedFileName, bytes32 uploadedFileHash) = storageContract.getFileDetails(fileHash);

        // Assert that the file details match the uploaded values
        Assert.equal(owner, address(this), "File owner should be the contract address");
        Assert.equal(uploadedOwnerName, ownerName, "Uploaded owner name should match");
        Assert.equal(uploadedFileName, fileName, "Uploaded file name should match");
        Assert.equal(uploadedFileHash, fileHash, "Uploaded file hash should match");
    }

    function testGetOwnerFiles() public {
        // Create some sample data
        address owner = address(0x123);
        bytes32 fileHash1 = keccak256(abi.encodePacked("file1"));
        bytes32 fileHash2 = keccak256(abi.encodePacked("file2"));
        bytes32 fileHash3 = keccak256(abi.encodePacked("file3"));

        // Upload files for the owner
        storageContract.uploadFile("", "", fileHash1, new uint256[](0));
        storageContract.uploadFile("", "", fileHash2, new uint256[](0));
        storageContract.uploadFile("", "", fileHash3, new uint256[](0));

        // Get the owner's files
        bytes32[] memory ownerFiles = storageContract.getOwnerFiles(owner);

        // Assert that the owner's files match the uploaded file hashes
        Assert.equal(ownerFiles.length, 3, "Number of owner files should be 3");
        Assert.equal(ownerFiles[0], fileHash1, "First file hash should match");
        Assert.equal(ownerFiles[1], fileHash2, "Second file hash should match");
        Assert.equal(ownerFiles[2], fileHash3, "Third file hash should match");
    }

    function testGetFilesShards() public {
        // Create some sample data
        bytes32 fileHash = keccak256(abi.encodePacked("sample file content"));
        uint256[] memory shardIds = new uint256[](3);
        shardIds[0] = 1;
        shardIds[1] = 2;
        shardIds[2] = 3;

        // Upload the file
        storageContract.uploadFile("", "", fileHash, shardIds);

        // Get the file's shards
        uint256[] memory fileShards = storageContract.getFilesShards(fileHash);

        // Assert that the file's shards match the uploaded shard IDs
        Assert.equal(fileShards.length, 3, "Number of file shards should be 3");
        Assert.equal(fileShards[0], 1, "First shard ID should match");
        Assert.equal(fileShards[1], 2, "Second shard ID should match");
        Assert.equal(fileShards[2], 3, "Third shard ID should match");
    }

    function testGetStorageProvidersWithSpace() public {
        // Create some sample data
        address storageProvider1 = address(0x111);
        address storageProvider2 = address(0x222);
        address storageProvider3 = address(0x333);

        // Add storage providers
        storageContract.addStorageProvider("127.0.0.1", storageProvider1, 100);
        storageContract.addStorageProvider("127.0.0.2", storageProvider2, 0); // No space available
        storageContract.addStorageProvider("127.0.0.3", storageProvider3, 50);

        // Get the storage providers with available space
        address[] memory providersWithSpace = storageContract.getStorageProvidersWithSpace();

        // Assert that only the providers with available space are returned
        Assert.equal(providersWithSpace.length, 2, "Number of providers with space should be 2");
        Assert.equal(providersWithSpace[0], storageProvider1, "First provider should have space");
        Assert.equal(providersWithSpace[1], storageProvider3, "Second provider should have space");
    }

    function testGetStorageProvidersStoring() public {
        // Create some sample data
        address storageProvider1 = address(0x111);
        address storageProvider2 = address(0x222);
        address storageProvider3 = address(0x333);

        // Add storage providers
        storageContract.addStorageProvider("127.0.0.1", storageProvider1, 100);
        storageContract.addStorageProvider("127.0.0.2", storageProvider2, 0);
        storageContract.addStorageProvider("127.0.0.3", storageProvider3, 50);

        // Update the storage status of the providers
        storageContract.updateStorageStatus(storageProvider1, true);
        storageContract.updateStorageStatus(storageProvider2, false);
        storageContract.updateStorageStatus(storageProvider3, true);

        // Get the storage providers that are currently storing
        address[] memory providersStoring = storageContract.getStorageProvidersStoring();

        // Assert that only the providers currently storing are returned
        Assert.equal(providersStoring.length, 2, "Number of providers storing should be 2");
        Assert.equal(providersStoring[0], storageProvider1, "First provider should be storing");
        Assert.equal(providersStoring[1], storageProvider3, "Second provider should be storing");
    }
}