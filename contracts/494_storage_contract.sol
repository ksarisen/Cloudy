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
      //bytes20 filehash; // if you need the filehash check ShardIdtoFileHash
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
    bytes20[] private filehashes;//a list of 40 character ripeMD-160 hashes

    //fileHashToOwner tracks files and who owns them
    mapping (bytes20 => address) private fileHashToOwner;
    mapping (uint => bytes20) private ShardIdtoFileHash;
    mapping (uint => string) private ShardIdtoFarmerId;



    mapping(bytes20 => uint) private fileHashToArrayIndexes;

    event NewFile(uint index, bytes20 _filehash);
    event DeleteFile(bytes20 _filehash);
    event deleteShardFromFarmer(uint shardId, uint farmerId);

    event NewFile(uint index, bytes20 _filehash);
    event DeleteFile(bytes20 _filehash);

    function _storeFile(bytes20 memory _filehash) public {
      //[Activate File] Owner can Upload filename and store in a map, along with tracking identity/wallet
      //require(/*baseline payment check*/);

      FileHashes.push(_filehash);
      uint index = FileHashes.length - 1;
      fileHashToOwner[_filehash] = msg.sender;

      fileHashToArrayIndexes[_filehash] = index; //not sure if we need this.

      //Think of filehash as the id of the file.
      //E.g. first time use will store filehash A at index 0 of FileHashes, keep track of that index in fileHashToArrayIndexes, and keep track of the owner in fileHashToOwner
      emit NewFile(_filehash); // assume frontend js will pick this up and shard the file from FileHashes[index].

      //expect shard manager to track 

      //the hash is the ripemd160 of a sha256 digest
    }
    function _deleteFileHash(bytes20 memory _filehash, address _owner) public {
      require(msg.sender == fileHashToOwner[_filehash], "Only File Owner can delete the file!");

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
    function getDetailsByUser() external view returns(string[] memory, Shard[] memory) {
      //ben's note: I updated this to only allow data from msg.sender to be returned so they cant just read other user's data.
      string[] memory result1 = new string[](userFileCount[msg.sender]);
      uint counterOne;

      for (uint i = 0; i < fileHashes.length; i++) {
        if ((fileHashToOwner[FileHashes[i]]) == _user) {
          result1[counter] = FileHashes[i];
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
    mapping (uint => bytes20) private ShardIdtoFileHash;
    mapping (address => uint) private shardsInFilehashCount;
    mapping (uint => string) private ShardIdtoFarmerId;

    // [Provide all my Filehashes] return all filehashes owned by user
    function getFilehashesByOwner() public view returns(uint[] memory) {
    //Jennifer TODO: lets just add each new file's hash to ownerFilehashes in the Storefile Method, to save gas.

    // _owner from contract ownable
    // we are creating a new array with the size based on the no. of filehashes the owner has
      uint[] memory ownerFilehashes = new bytes20[](ownerFilehashCount[msg.sender]); 
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

    
    function _getShardsByFilehash (bytes20 _filehash) public view returns(uint[] memory) {
      require(msg.sender == fileHashToOwner[_filehash], "Only the File Owner can access its shards.");

      uint[] memory filehashShards = new uint[](shardsInFilehashCount[_filehash]); 
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < Shards.length; i++) {
          // if the filehash's owner is equal to the owner
          if (Shards[i].filehash == _filehash) {
            // we add it to the ownerFilehashes array
            filehashShards[counter] = Shards[i].shardId; 
            counter++;
          }
        }
      return filehashShards;
    }

    // [Drop Deleted Shards] Storage Provider is told to stop storing deleted data 
    //After a user deletes a file, drop its shards
    //emits the farmerId and shardId
    function dropShardsOfDeletedFile (bytes20 _filehash) private {
      require(msg.sender == fileHashToOwner[_filehash], "Only File Owner can delete the file!"); //either make this function public (if we expect it to be called outside the contract) or remove this security check
      // find shards by filehashId
      uint[] memory filehashShards = _getShardsByFilehash(_filehash);
      // go through all the filehash's shards
      for (uint i = 0; i < filehashShards.length; i++) {
        // check which farmer has the shard

        ///TODO: decide why we need to iterate through available farmers when we already have the id tof the farmer holding the shard. can't we delete the following lines?
        //  for (uint j = 0; j < AvailableFarmerIds.length; j++) {
        //    if (ShardIdtoFarmerId[i] == AvailableFarmerIds[j]) {
              
              /// expect the caller to listen for a series of deleteShard events
              emit deleteShard(ShardIdtoFarmerId[filehashShards[i]], filehashShards[i]);

        //    }
        //  }
        }

    }

    function addStorageProvider(address _address, uint _nodeID, uint _storageSize, string memory _storageType) external {
      // should we use msg.sender instead?
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
