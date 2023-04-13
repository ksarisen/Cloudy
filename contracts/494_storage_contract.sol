// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import ".deps/ownable.sol";

/**
 * @title ShardManager
 * @dev turns files into many shards. ./contracts/Ben_1_cryptozombies_testing.sol
 * @custom:dev-run-script ./scripts/web3-lib.ts
 */
contract ShardManager is Ownable {

    struct Shard {
      uint filehashId;
      uint shardId;
      string shardData;
    }

    struct Farmer {
      address walletAddress;
      uint nodeId;
      uint storageSize;
      string storageType;
    }

    Farmer[] private availableFarmers;
    //string[] private availableFarmerIds;

    Shard[] private shards;
    string[] private filehashes;

    //fileHashToOwner tracks files and who owns them
    mapping (string => address) private fileHashToOwner;
    mapping (uint => string) private ShardIdtoFileHash;
    mapping (uint => string) private ShardIdtoFarmerId;



    mapping(string => uint) private fileHashToArrayIndexes;

    event NewFile(uint index, string _filehash);
    event DeleteFile(string _filehash);

    mapping(string => uint) private FileHashToArrayIndexes;

    event NewFile(uint index, string _filehash);
    event DeleteFile(string _filehash);

    //the following function is NOT complete. Ben will improve it
    function _storeFile(string memory _filehash) public onlyOwner{
      //[Activate File] Owner can Upload filename and store in a map, along with tracking identity/wallet
      //require(/*baseline payment check*/);
      FileHashes.push(_filehash);
      uint index = FileHashes.length - 1;
      fileHashToOwner[_filehash] = msg.sender;
      FileHashToArrayIndexes[_filehash] = index;
      emit NewFile(index, _filehash); // assume shard manager will pick this up and shard the file.

      //the hash is the ripemd160 of a sha256 digest
    }
    function _deleteFileHash(string memory _filehash, address _owner) public onlyOwner {
      //require(/*baseline identity check*/);
      uint index = fileHashToArrayIndexes[_filehash];

      //remove filehash from FileHashes Array
      fileHashes[index] = fileHashes[fileHashes.length - 1];
      fileHashes.pop();
      //Delete mapping References
      delete fileHashToArrayIndexes[_filehash];

      emit DeleteFile(_filehash); // assume shard manager will pick this up and tell farmers to drop the relevant shards.
    }
    function remove(uint index) internal {
    
    }
    // function getFarmerIdsStoringFile(address _owner) external view returns(string[] memory) {
    // // Start here
    // }
    //End of Ben's code

    // Kerem's code below
    // Implemented according to the google doc (Contract functions TODOS for March 24th)

    //mapping (address => uint) private farmerToNodeId;
    mapping (uint => uint) private farmerShardCount;

    mapping (address => uint) private userFileCount;

    // Storage Provider will provide(upload) their node ID(not sure if we need id, just address might be sufficent) and list of stored shards. 
    function getDetailsByFarmer(Farmer _farmer) external view returns(uint memory, Shard[]) {
      uint nodeId = _farmer.nodeId;

      Shard[] memory shardList = new Shard[](farmerShardCount[result1]);
      uint counter;
      for (uint i = 0; i < shards.length; i++) {
        if ((shardIdtoFarmerId[Shards[i].shardId]) == _farmer) {
          shardList[counter] = Shards[i];
          counter++;
        }
      }
      return (nodeId, shardList);
    }

    // Owner will provide the filename(fileHash?), and list of shard hashes (shardIds)?
    function getDetailsByUser(address _user) external view returns(string[], Shard[]) {
      string[] hashes = new string[](userFileCount[_user]);
      uint counterOne;

      for (uint i = 0; i < fileHashes.length; i++) {
        if (fileHashToOwner[FileHashes[i]] == _user) {
          hashes[counter] = FileHashes[i];
          counterOne++;
        }
      }

      Shard[] memory shardList = new Shard[](farmerShardCount[hashes]);
      uint counterTwo;
      for (uint i = 0; i < shards.length; i++) {
        if (fileHashToOwner[(shardIdtoFileHash[Shards[i].shardId])] == _user) {
          shardList[counter] = Shards[i];
          counterTwo++;
        }
      }
      return (hashes, shardList);
    }

    //start of jennifer's code:
    mapping (address => uint) private ownerFilehashCount;
    mapping (uint => string) private ShardIdtoFileHash;
    mapping (address => uint) private shardsInFilehashCount;
    mapping (uint => string) private ShardIdtoFarmerId;

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
