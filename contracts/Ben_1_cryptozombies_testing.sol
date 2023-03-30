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
      uint shardId;
      string shardData;
    }

    Shard[] private shards;
    string[] private fileHashes;
    string[] private availableFarmerIds;

    //fileHashToOwner tracks files and who owns them
    mapping (string => address) private fileHashToOwner;
    mapping (uint => string) private shardIdtoFileHash;
    mapping (uint => string) private shardIdtoFarmerId;

    mapping(string => uint) private fileHashToArrayIndexes;

    event NewFile(uint index, string _filehash);
    event DeleteFile(string _filehash);

    //the following function is NOT complete. Ben will improve it
    function _storeFile(string memory _filehash) public onlyOwner {
      //[Activate File] Owner can Upload filename and store in a map, along with tracking identity/wallet
      //require(/*baseline payment check*/);
      fileHashes.push(_filehash);
      uint index = fileHashes.length - 1;
      fileHashToOwner[_filehash] = msg.sender;
      fileHashToArrayIndexes[_filehash] = index;
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

    // Kerem's code below
    // Implemented according to the google doc (Contract functions TODOS for March 24th)

    mapping (address => uint) private farmerToNodeId;
    mapping (uint => uint) private farmerShardCount;

    mapping (address => uint) private userFileCount;

    // Storage Provider will provide(upload) their node ID(not sure if we need id, just address might be sufficent) and list of stored shards. 
    function getDetailsByFarmer(address _farmer) external view returns(uint memory, Shard[]) {
      uint result1 = (FarmerToNodeId[_farmer]);

      Shard[] memory result2 = new Shard[](farmerShardCount[result1]);
      uint counter;
      for (uint i = 0; i < shards.length; i++) {
        if ((shardIdtoFarmerId[Shards[i].shardId]) == _farmer) {
          result2[counter] = Shards[i];
          counter++;
        }
      }
      return (result1, result2);
    }

    // Owner will provide the filename(fileHash?), and list of shard hashes (shardIds)?
    function getDetailsByUser(address _user) external view returns(string[], Shard[]) {
      string[] result1 = new string[](userFileCount[_user]);
      uint counterOne;

      for (uint i = 0; i < fileHashes.length; i++) {
        if ((fileHashToOwner[FileHashes[i]) == _user) {
          result1[counter] = FileHashes[i];
          counterOne++;
        }
      }

      Shard[] memory result2 = new Shard[](farmerShardCount[result1]);
      uint counterTwo;
      for (uint i = 0; i < shards.length; i++) {
        if (fileHashToOwner[(shardIdtoFileHash[Shards[i].shardId])] == _user) {
          result2[counter] = Shards[i];
          counterTwo++;
        }
      }
      return (result1, result2);
    }
}
