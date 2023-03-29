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

    struct Farmer {
      address walletAddress;
      uint nodeId;
      uint storageSize;
      string storageType;
    }

    Shard[] private shards;
    string[] private filehashes;
    Farmer[] private availableFarmers;

    //fileHashToOwner tracks files and who owns them
    mapping (string => address) private fileHashToOwner;
    mapping (uint => string) private ShardIdtoFileHash;
    mapping (uint => string) private ShardIdtoFarmerId;

    function addStorageProvider(address _address, uint _nodeID, uint _storageSize, string memory _storageType) external {
      availableFarmers.push(Farmer(_address, _nodeID, _storageSize, _storageType));
    }

    function getStorageProviderNodeID(address _address) external returns (uint) {
      for (uint i=0; i<availableFarmers.length; i++) {
        if (availableFarmers[i].walletAddress == _address) {
          return availableFarmers[i].nodeId;
        }
      }

      revert('Not found');
    }



}