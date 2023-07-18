// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "truffle/Assert.sol";
import "../contracts/NewCloudy.sol";

contract TestDistributedStorage {
    DistributedStorage distributedStorage;

    function beforeEach() public {
        distributedStorage = new DistributedStorage();
    }

    function testUploadFile() public {
        bytes32 fileHash = bytes32("file123");
        uint256[] memory shardIds = new uint256[](3);
        shardIds[0] = 1;
        shardIds[1] = 2;
        shardIds[2] = 3;

        distributedStorage.uploadFile("Owner", "File", fileHash, shardIds);

        DistributedStorage.File memory file = distributedStorage.filesByHash(fileHash);

        Assert.equal(file.owner, address(this), "File owner should be the test contract");
        Assert.equal(file.ownerName, "Owner", "Incorrect owner name");
        Assert.equal(file.fileName, "File", "Incorrect file name");
        Assert.equal(file.fileHash, fileHash, "Incorrect file hash");
        Assert.equal(file.shardIds.length, 3, "Incorrect number of shard IDs");
        Assert.equal(file.shardIds[0], 1, "Incorrect shard ID at index 0");
        Assert.equal(file.shardIds[1], 2, "Incorrect shard ID at index 1");
        Assert.equal(file.shardIds[2], 3, "Incorrect shard ID at index 2");
    }

    // Add more unit tests for other functions

}
