// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import ".deps/ownable.sol";

/**
 * @title ShardManager
 * @dev turns files into many shards.
 */
contract ShardManager {

    struct Shard {
      uint filehashId;
      uint shardId;
      string shardData;
    }

    Shard[] private shards;
    string[] private filehashes;
    string[] private AvailableFarmerIds;

    //fileHashToOwner tracks files and who owns them
    mapping (string => address) private fileHashToOwner;
    mapping (address => uint) private ownerFilehashCount;
    mapping (uint => string) private ShardIdtoFileHash;
    mapping (address => uint) private shardsInFilehashCount;
    mapping (uint => string) private ShardIdtoFarmerId;

    //the following function is NOT complete. Ben will improve it
    function _storeFile(string memory _filename, address owner,uint _dna) private {
        //FilesToShards.push(_filename);
    }

    // [Provide all my Filehashes] return all filehashes owned by user
    function getFilehashesByOwner(address _owner) public view returns(uint[] memory) {
    // _owner from contract ownable
    // we are creating a new array with the size based on the no. of filehashes the owner has
      uint[] memory ownerFilehashes = new uint[](ownerFilehashCount[_owner]); 
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < filehashes.length; i++) {
          // if the filehash's owner is equal to the owner
          if (fileHashToOwner[i] == _owner) {
            // we add it to the ownerFilehashes array
            ownerFilehashes[counter] = filehashes[i].filehashId; // not sure about this one
            counter++;
          }
        }
      return ownerFilehashes;
    }

    // [Drop Deleted Shards] Storage Provider is told to stop storing deleted data 
    function _getShardsByFilehash (uint _filehashId) private view returns(uint[] memory) {
      uint[] memory filehashShards = new uint[](shardsInFilehashCount[_filehashId]); 
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < shards.length; i++) {
          // if the filehash's owner is equal to the owner
          if (shards[i].filehashId == _filehashId) {
            // we add it to the ownerFilehashes array
            filehashShards[counter] = shards[i].shardId; 
            counter++;
          }
        }
      return filehashShards;
    }


    function dropDeletedShards (uint _filehashId) public {
      // find shards by filehashId
      uint[] memory filehashShards = _getShardsByFilehash (_filehashId);
      // go through all the filehash's shards
      for (uint i = 0; i < filehashShards.length; i++) {
        // check which farmer has the shard
         for (uint j = 0; j < AvailableFarmerIds.length; j++) {
           if (ShardIdtoFarmerId[i] == AvailableFarmerIds[j]) {
              // notify farmer to drop
              emit deleteShard(ShardIdtoFarmerId[i], )
           }
         }
        }

    }

}
