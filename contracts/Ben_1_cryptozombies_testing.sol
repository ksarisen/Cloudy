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
    string[] private FileHashes;
    string[] private AvailableFarmerIds;

    //fileHashToOwner tracks files and who owns them
    mapping (string => address) private fileHashToOwner;
    mapping (uint => string) private ShardIdtoFileHash;
    mapping (uint => string) private ShardIdtoFarmerId;

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
    function _deleteFileHash(string memory _filehash, address _owner) public onlyOwner{
      //require(/*baseline identity check*/);
      uint index = FileHashToArrayIndexes[_filehash];

      //remove filehash from FileHashes Array
      FileHashes[index] = FileHashes[FileHashes.length - 1];
      FileHashes.pop();
      //Delete mapping References
      delete FileHashToArrayIndexes[_filehash];

      emit DeleteFile(_filehash); // assume shard manager will pick this up and tell farmers to drop the relevant shards.
    }
    function remove(uint index) internal{
    
  }
    // function getFarmerIdsStoringFile(address _owner) external view returns(string[] memory) {
    // // Start here
    // }
}