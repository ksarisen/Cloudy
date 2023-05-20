// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "contracts/494_storage_contract.sol";
import "remix_tests.sol"; // this import is automatically injected by Remix
import "remix_accounts.sol";

contract ShardManagerTest {
    ShardManager public shardManager;

    function beforeAll() public {
        shardManager = new ShardManager();
    }

    function testStoreFile() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);

        // Call the _storeFile function
        shardManager._storeFile(fileHash);

        // Get the stored file hashes for the contract owner
        bytes20[] memory storedFileHashes = shardManager.getFilehashesByOwner(address(this));

        // Assert that the stored file hash matches the provided file hash
        Assert.ok(storedFileHashes.length == 1, "TestCase: Failed (Error)");
        assert(storedFileHashes[0] == fileHash);
    }

    function testDeleteFileHash() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);

        // Delete the file hash
        shardManager._deleteFileHash(fileHash);

        // Assert file hash is deleted
        assert(shardManager.checkFileHash(fileHash) == 0);
    }

    function testAssociateShardsWithFileHash() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);
        uint[] memory shardIDs = new uint[](2);
        shardIDs[0] = 1;
        shardIDs[1] = 2;

        // Call the _storeFile function to store a file hash
        shardManager._storeFile(fileHash);

        // Call the associateShardsWithFileHash function to associate shards with the file hash
        shardManager.associateShardsWithFileHash(fileHash, shardIDs);

        // Call the getShardIDs function to retrieve the associated shard IDs
        uint[] memory retrievedShardIDs = shardManager.getShardIDs(fileHash);

        // Assert that the retrieved shard IDs match the associated shard IDs
        assert(retrievedShardIDs.length == shardIDs.length);
        for (uint i = 0; i < shardIDs.length; i++) {
            assert(retrievedShardIDs[i] == shardIDs[i]);
        }
    }

    function testGetShardsInFile_Count() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);

        // Only the file owner can check the number of shards
        uint shardCount = shardManager.getShardsInFile_Count(fileHash);
        assert(shardCount == 2);
    }

    function testSetFileHashOwner() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);
        address newOwner = address(0x1234567890123456789012345678901234567890);

        // Call the setFileHashOwner function to set the owner of the file hash
        shardManager.setFileHashOwner(fileHash, newOwner);

        // Retrieve the owner of the file hash using the fileHashToOwner mapping
        address retrievedOwner = shardManager.fileHashToOwner(fileHash);

        // Assert that the retrieved owner matches the new owner
        assert(retrievedOwner == newOwner);
}


    function testHasConsent() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);
        address owner = address(0x123);
        address caller = address(0x456);

        // Set file hash owner
        shardManager.setFileHashOwner(fileHash, owner);

        // Assert caller has consent from the file owner
        assert(shardManager.hasConsent(fileHash, caller) == false);
    }

    function testGetFilehashesByOwner() public {
        address owner = address(0x123);

        // Store file hashes for the owner
        shardManager._storeFile(0x1111111111111111111111111111111111111111);
        shardManager._storeFile(0x2222222222222222222222222222222222222222);

        // Get file hashes by owner
        bytes20[] memory fileHashes = shardManager.getFilehashesByOwner(owner);

        // Assert correct number of file hashes are returned
        assert(fileHashes.length == 2);
    }

     function testGetShardsByFilehash() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);

        // Associate shards with the file hash
        uint[] memory shardIDs = new uint[](2);
        shardIDs[0] = 1;
        shardIDs[1] = 2;
        shardManager.associateShardsWithFileHash(fileHash, shardIDs);

        // Get shards by file hash
        uint[] memory shards = shardManager.getShardsByFilehash(fileHash);

        // Assert correct number of shards are returned
        assert(shards.length == 2);
    }

    function testGetAllFileHashes() public {
        // Store file hashes
        shardManager._storeFile(0x1111111111111111111111111111111111111111);
        shardManager._storeFile(0x2222222222222222222222222222222222222222);
        shardManager._storeFile(0x3333333333333333333333333333333333333333);

        // Get all file hashes
        bytes20[] memory fileHashes = shardManager.getAllFileHashes();

        // Assert correct number of file hashes are returned
        assert(fileHashes.length == 3);
    }
}
