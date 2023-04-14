// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import ".deps/ownable.sol";

/**
 * @title ShardManager
 * @dev turns files into many shards. ./contracts/Ben_1_cryptozombies_testing.sol
 * @custom:dev-run-script ./scripts/web3-lib.ts
 */
contract ShardManager is Ownable {

    // struct FileData {
    //   string filehash
    // }
    
    struct Shard {
      //bytes20 filehash; // if you need the filehash check shardIdtoFileHash
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
    uint[] private availableFarmerNodeIds;

    Shard[] private shards;
    //Farmer[] private farmers; //TODO: actually keep track of all farmers
    bytes20[] private fileHashes;//a list of 40 character ripeMD-160 hashes

    //fileHashToOwner tracks files and who owns them
    mapping (bytes20 => address) private fileHashToOwner;
    mapping (uint => bytes20) private shardIdtoFileHash;
    mapping (uint => uint) private shardIdtoFarmerNodeId;//TODO: changes to index reference of farmerd[]



    mapping(bytes20 => uint) private fileHashToArrayIndexes;

    event NewFile(bytes20 _filehash);
    event DeleteFile(bytes20 _filehash);
    event deleteShardFromFarmer(uint shardId, uint farmerId);

    function _storeFile(bytes20 _filehash) public {
      //[Activate File] Owner can Upload filename and store in a map, along with tracking identity/wallet
      //require(/*baseline payment check*/);

      fileHashes.push(_filehash);
      uint index = fileHashes.length - 1;
      fileHashToOwner[_filehash] = msg.sender;

      fileHashToArrayIndexes[_filehash] = index; //not sure if we need this.

      ownerFileCount[msg.sender]++;

      //Think of filehash as the id of the file.
      //E.g. first time use will store filehash A at index 0 of FileHashes, keep track of that index in fileHashToArrayIndexes, and keep track of the owner in fileHashToOwner
      emit NewFile(_filehash); // assume frontend js will pick this up and shard the file from FileHashes[index].

      //expect shard manager to track 

      //the hash is the ripemd160 of a sha256 digest
    }

    function _deleteFileHash(bytes20 _filehash) public {
      require(msg.sender == fileHashToOwner[_filehash], "Only File Owner can delete the file!");

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

    mapping (address => uint) private ownerFileCount;

    // Storage Provider will provide(upload) their node ID(not sure if we need id, just address might be sufficent) and list of stored shards. 
    function getDetailsByFarmer(Farmer memory _farmer) external view returns(uint, Shard[] memory) {
      uint nodeId = _farmer.nodeId;

      Shard[] memory shardList  = new Shard[](farmerShardCount[nodeId]);
      uint counter;
      for (uint i = 0; i < shards.length; i++) {
        if ((shardIdtoFarmerNodeId[shards[i].shardId]) == _farmer.nodeId) {
          shardList[counter] = shards[i];
          counter++;
        }
      }
      return (nodeId, shardList);
    }

    // // Returns the list of file hashes, and shard ids.
    // function getDetailsByUser() external view returns(string[] memory, Shard[] memory) {
    //   bytes20[] memory hashes = new bytes20[](ownerFileCount[msg.sender]);
    //   uint counterOne;

    //   for (uint i = 0; i < fileHashes.length; i++) {
    //     if (fileHashToOwner[fileHashes[i]] == msg.sender) {
    //       hashes[counterOne] = fileHashes[i];
    //       counterOne++;
    //     }
    //   }
    //   //number of shards for bob the farmer = number of files * shards per file

    //   Shard[] memory shardList = new Shard[](farmerShardCount[hashes.length]);
    //   uint counterTwo;
    //   for (uint i = 0; i < shards.length; i++) {
    //     if (fileHashToOwner[(shardIdtoFileHash[shards[i].shardId])] == msg.sender) {
    //       shardList[counterTwo] = shards[i];
    //       counterTwo++;
    //     }
    //   }
    //   return (hashes, shardList);
    // }

    //start of jennifer's code:
    mapping (address => uint) private ownerFilehashCount;
    mapping (bytes20 => uint) private shardsinFile_Count;

    // [Provide all my fileHashes] return all fileHashes owned by user
    //Only called by the web server, not our users.
    function getFilehashesByOwner(address _owner) external view onlyOwner returns(bytes20[] memory) {
    // _owner from contract ownable
    // we are creating a new array with the size based on the no. of filehashes the owner has
      bytes20[] memory ownerFilehashes = new bytes20[](ownerFilehashCount[_owner]); 
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < fileHashes.length; i++) {
          // if the filehash's owner is equal to the owner
          if (fileHashToOwner[ownerFilehashes[i]] == _owner) {
            // we add it to the ownerFilehashes array
            ownerFilehashes[counter] = fileHashes[i];
            counter++;
          }
        }
      return ownerFilehashes;
    }

    
    function getShardsByFilehash (bytes20 _filehash) public view returns(uint[] memory) {
      require(msg.sender == fileHashToOwner[_filehash], "Only the File Owner can access its shards.");

      uint[] memory filehashShards = new uint[](shardsinFile_Count[_filehash]); 
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < shards.length; i++) {
          // if the filehash's owner is equal to the owner
          if (shardIdtoFileHash[shards[i].shardId] == _filehash) {
            // we add it to the ownerFilehashes array
            filehashShards[counter] = shards[i].shardId; 
            counter++;
          }
        }
      return filehashShards;
    }

    // [Drop Deleted Shards] Storage Provider is told to stop storing deleted data 
    //After a user deletes a file, drop its shards
    //emits the farmerId and shardId
    function _dropShardsOfDeletedFile (bytes20 _filehash) private {
      require(msg.sender == fileHashToOwner[_filehash], "Only File Owner can delete the file!"); //either make this function public (if we expect it to be called outside the contract) or remove this security check
      // find shards by filehashId
      uint[] memory filehashShards = getShardsByFilehash(_filehash);
      // go through all the filehash's shards
      for (uint i = 0; i < filehashShards.length; i++) {
        // check which farmer has the shard

         for (uint j = 0; j < availableFarmerNodeIds.length; j++) {
           if (shardIdtoFarmerNodeId[i] == availableFarmerNodeIds[j]) {  
              /// expect the caller to listen for a series of deleteShard events
              emit deleteShardFromFarmer(shardIdtoFarmerNodeId[filehashShards[i]], filehashShards[i]);
           }
         }
        }
    }

    function addStorageProvider(address _address, uint _nodeID, uint _storageSize, string memory _storageType) external {
      // should we use msg.sender instead?
      availableFarmers.push(Farmer(_address, _nodeID, _storageSize, _storageType));
    }

    function getStorageProviderNodeID(address _address) external view returns (uint) {
      for (uint i=0; i<availableFarmers.length; i++) {
        if (availableFarmers[i].walletAddress == _address) {
          return availableFarmers[i].nodeId;
        }
      }

      revert('Not found');
    }
}//end of contract
