// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import ".deps/ownable.sol";

/**
 * @title ShardManager
 * @dev turns files into many shards.
 */
contract ShardManager {

    struct Shard {
      uint shardId;
      string shardData;
    }

    Shard[] private shards;
    string[] private filehashes;
    string[] private AvailableFarmerIds;

    //fileHashToOwner tracks files and who owns them
    memory mapping (string => address) private fileHashToOwner;
    mapping (uint => string) private ShardIdtoFileHash;
    mapping (uint => string) private ShardIdtoFarmerId;

    //the following function is NOT complete. Ben will improve it
    function _storeFile(string memory _filename, address owner,uint _dna) private {
        FilesToShards.push(_filename);
    }
}