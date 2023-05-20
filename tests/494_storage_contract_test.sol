// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "contracts/494_storage_contract.sol";

contract ShardManagerTest {
    ShardManager public shardManager;

    function beforeAll() public {
        shardManager = new ShardManager();
    }

    function testStoreFile() public {
        bytes20 fileHash = bytes20(0x1234567890123456789012345678901234567890);
        shardManager._storeFile(fileHash);

        // Call the _storeFile function
        shardManager._storeFile(fileHash);

        // Get the stored file hashes for the contract owner
        bytes20[] memory storedFileHashes = shardManager.getFilehashesByOwner(address(this));

        // Assert that the stored file hash matches the provided file hash
        assert(storedFileHashes.length == 1);
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
        bytes20 fileHash = 0x1234567890123456789012345678901234567890;
        uint[] memory shardIDs = new uint[](2);
        shardIDs[0] = 1;
        shardIDs[1] = 2;

        shardManager.associateShardsWithFileHash(fileHash, shardIDs);

        // Assert shard IDs are associated with the file hash
        assert(shardManager.getShardIDs(fileHash).length == 2);
    }

    function testGetShardsInFile_Count() public {
        bytes20 fileHash = 0x1234567890123456789012345678901234567890;

        // Only the file owner can check the number of shards
        uint shardCount = shardManager.getShardsInFile_Count(fileHash);
        assert(shardCount == 2);
    }

    function testSetFileHashOwner() public {
        bytes20 fileHash = 0x1234567890123456789012345678901234567890;
        address newOwner = address(0x123);

        shardManager.setFileHashOwner(fileHash, newOwner);

        // Assert file hash owner is updated
        assert(shardManager.fileHashToOwner(fileHash) == newOwner);
    }

    function testHasConsent() public {
        bytes20 fileHash = 0x1234567890123456789012345678901234567890;
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
        bytes20 fileHash = 0x1234567890123456789012345678901234567890;

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
