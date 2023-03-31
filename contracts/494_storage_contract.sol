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

    Shard[] private Shards;
    string[] private FileHashes;

    //fileHashToOwner tracks files and who owns them
    mapping (string => address) private fileHashToOwner;
    mapping (uint => string) private ShardIdtoFileHash;
    mapping (uint => uint) private ShardIdtoFarmerId;



    mapping(string => uint) private fileHashToArrayIndexes;

    event NewFile(uint index, string _filehash);
    event DeleteFile(string _filehash);
    event deleteShardFromFarmer(uint shardId, uint farmerId);

    mapping(string => uint) private FileHashToArrayIndexes;

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
      FileHashes[index] = FileHashes[FileHashes.length - 1];
      FileHashes.pop();
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

    //mapping (address => uint) private FarmerToNodeId;
    mapping (uint => uint) private farmerShardCount;

    mapping (address => uint) private userFileCount;

    // Storage Provider will provide(upload) their node ID(not sure if we need id, just address might be sufficent) and list of stored shards. 
    function getDetailsByFarmer(Farmer memory _farmer) external view returns(uint, Shard[] memory) {
      uint result1 = _farmer.nodeId;

      Shard[] memory result2 = new Shard[](farmerShardCount[result1]);
      uint counter;
      for (uint i = 0; i < Shards.length; i++) {
        if (ShardIdtoFarmerId[Shards[i].shardId] == _farmer.nodeId) {
          result2[counter] = Shards[i];
          counter++;
        }
      }
      return (result1, result2);
    }

    // Owner will provide the filename(fileHash?), and list of shard hashes (shardIds)?
    function getDetailsByUser(address _user) external view returns(string[] memory, Shard[] memory) {
      string[] memory  result1 = new string[](userFileCount[_user]);
      uint counterOne;

      for (uint i = 0; i < FileHashes.length; i++) {
        if ((fileHashToOwner[FileHashes[i]]) == _user) {
          result1[counterOne] = FileHashes[i];
          counterOne++;
        }
      }

      Shard[] memory result2; //todo if you want: make it constant sized rather than dynamic
      uint counterTwo;
      for (uint i = 0; i < Shards.length; i++) {
        if (fileHashToOwner[(ShardIdtoFileHash[Shards[i].shardId])] == _user) {
          result2[counterTwo] = Shards[i];
          counterTwo++;
        }
      }
      return (result1, result2);
    }

    //start of jennifer's code:
    mapping (address => uint) private ownerFilehashCount;
    mapping (string => uint) private shardsInFilehashCount;

    // [Provide all my Filehashes] return all filehashes owned by user
    function getFilehashesByOwner(address _owner) public view returns(string[] memory) {
    // _owner from contract ownable
    // we are creating a new array with the size based on the no. of filehashes the owner has
      string[] memory ownerFilehashes = new string[](ownerFilehashCount[_owner]); 
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < FileHashes.length; i++) {
          // if the filehash's owner is equal to the owner
          if (fileHashToOwner["this is filler text by ben because you though this was an int you could iterate over"] == _owner) {
            // we add it to the ownerFilehashes array
            ownerFilehashes[counter] = FileHashes[i]; // not sure about this one
            counter++;
          }
        }
      return ownerFilehashes;
    }

    // [Drop Deleted Shards] Storage Provider is told to stop storing deleted data 
    function _getShardsByFilehash (string memory _filehash, uint _fileHashId) private view returns(uint[] memory) {
      uint[] memory filehashShards; //todo make it constant of size shardsInFilehashCount[_filehash]
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < Shards.length; i++) {
          // if the filehash's owner is equal to the owner
          if (Shards[i].filehashId == _fileHashId) {
            // we add it to the ownerFilehashes array
            filehashShards[counter] = Shards[i].shardId; 
            counter++;
          }
        }
      return filehashShards;
    }

    function dropDeletedShards (string memory _filehash, uint _filehashId) public {
      // find shards by filehashId
      uint[] memory filehashShards = _getShardsByFilehash(_filehash,_filehashId);
      // go through all the filehash's shards
      for (uint i = 0; i < filehashShards.length; i++) {
        // check which farmer has the shard
         for (uint j = 0; j < availableFarmers.length; j++) {
           if (ShardIdtoFarmerId[i] == availableFarmers[j].nodeId) {
              // notify farmer to drop
              emit deleteShardFromFarmer(filehashShards[i],ShardIdtoFarmerId[i]);
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
}//end of contract
