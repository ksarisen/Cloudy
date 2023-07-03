// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../.deps/ownable.sol";

/**
 * @title ClientManager
 * @dev turns files into many shards. ./contracts/Ben_1_cryptozombies_testing.sol
 * @custom:dev-run-script ./scripts/web3-lib.ts
 */
contract ClientManager is Ownable {
    
    struct Shard {
      //bytes20 filehash; // if you need the filehash check shardIdtoFileHash
      uint shardId;
      string shardData;
    }

    struct Farmer {
      address walletAddress;
      uint nodeId;
      uint currentStoredSize;
      uint maxStorageSize;
      string storageType;
    }

    Farmer[] private availableFarmers; // lists all farmers, even ones that don't have space to add any more shards currently.
    uint[] private availableFarmerNodeIds; // lists farmers with space available to insert more shards
    mapping(uint => uint) private farmerNodeIdToFarmerArrayIndex;
    uint farmerNodeIdIncrementer = 0;

    Shard[] private shards;
    //Farmer[] private farmers; //TODO: actually keep track of all farmers
    bytes20[] private fileHashes; //a list of 40 character ripeMD-160 hashes

    //fileHashToOwner tracks files and who owns them
    mapping (bytes20 => address) public fileHashToOwner;
    mapping(bytes20 => uint) public fileHashToShardCount;
    mapping (uint => bytes20) private shardIdtoFileHash;
    mapping (uint => uint) private shardIdtoFarmerNodeId;
    mapping(bytes20 => uint[]) fileHashToShards;

    // mapping (uint => Farmer) public nodeIdToFarmer; //deprecated, instead use availableFarmers[farmerNodeIdToFarmerArrayIndex[nodeId]]
    
    // Mapping to store file hash owner's address
    mapping(string => address) fileHashOwners;

    mapping(bytes20 => uint) private fileHashToArrayIndexes;

    event NewFile(bytes20 _filehash);
    event DeleteFile(bytes20 _filehash);

    event ShardAdded(uint shardId);
    event ShardAssigned(uint shardId, uint farmerNodeId);
    event ShardDeleted(uint shardId, uint farmerNodeId);
    event FarmerAdded(uint farmerNodeId);
    event FarmerRemoved(uint farmerNodeId);

    function _storeFile(bytes20 _filehash) public {
      //File Owner uploads filehash to track their ownership
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

    function checkFileHashExternal(bytes20 _filehash) external view returns (uint) {
        // we go through all the filehashes
        for (uint i = 0; i < fileHashes.length; i++) {
            // if the filehash's owner is equal to the owner
            if (fileHashes[i] == _filehash) {
                return 1; //filehash found
            }
        }
        return 0; // filehash doesn't exist
    }

    function checkFileHash(bytes20 _filehash) internal view returns (uint) {
        //TODO: check internal mapping, no loops allowed
        //@kerem can you check the rest of our functions that use loops and make sure we dont call them in any other functions?
        
        // //something like:
        // return OwnerTofileHash[_filehash];
        // //THIS FUNCTION IS UNFINISHED, must actually store things into the OwnerTofileHash mapping before trying to return it here
        
        //delete this temp return var once implemented
        return 1;
    }


    function _deleteFileHash(bytes20 _fileHash) public {
        // Checks if the fileHash exists
        require(
            //fileHashToArrayIndexes[_fileHash] == 0, //this doesn't work as a "does the file exist" check because the first valid index 0 matches the unset default of 0.
            checkFileHash(_fileHash) == 1,
            "The file does not exist."
        );
      // Check if the sender is the owner of the file
        require(
            fileHashToOwner[_fileHash] == msg.sender,
            "Only the owner can delete the file."
        );

      uint index = fileHashToArrayIndexes[_fileHash];
      
      // Delete the file from mappings and arrays
      
      //remove fileHash from fileHashes Array
      fileHashes[index] = fileHashes[fileHashes.length - 1];
      fileHashes.pop();
      ownerFileCount[msg.sender]--;
      //Delete mapping References
      delete fileHashToArrayIndexes[_fileHash];
      delete fileHashToShards[_fileHash];
      delete shardsInFile_Count[_fileHash];

      emit DeleteFile(_fileHash); // Web application will pick this up and tell farmers to drop the relevant shards.
    }

    //given a filehash, return the list of farmers the website would need to contact to get all shard.
    // function getFarmerIdsStoringFile(bytes20 memory _filehash) internal returns(uint[] memory) {
        //return array of nodeIds
    // }

    // Modifier to restrict access to the file owner or an address with consent
    modifier _onlyFileOwnerOrConsent(bytes20 fileHash) {
        require(
            msg.sender == fileHashToOwner[fileHash] || 
            hasConsent(fileHash, msg.sender),
            "Caller is not the file owner or does not have consent"
        );
        _;
    }

    //function for user to notify blockchain which shards relate to their file.
    function associateShardsWithFileHash(bytes20 _fileHash, uint[] memory shardIDs) external _onlyFileOwnerOrConsent(_fileHash) {
        require(shardIDs.length > 0, "Shard IDs must not be empty");

        // Store shardIDs in the mapping under the fileHash
        fileHashToShards[_fileHash] = shardIDs; //file to shards implies i pass in a file to get shards

        // Increment the shardsInFile_Count
        shardsInFile_Count[_fileHash] += shardIDs.length;
    }

    // Function to retrieve shard IDs by file hash
    function getShardIDsExternal(bytes20 fileHash) external view returns (uint[] memory) {
        //TODO: implement this using a big inefficient loop and no accessing of mappings
        return fileHashToShards[fileHash];
    }

    // Function to retrieve shard IDs by file hash
    function getShardIDs(bytes20 fileHash) internal view returns (uint[] memory) {
        return fileHashToShards[fileHash];
    }

    // Function to get the total count of shards in a file
    function getShardsInFile_Count(bytes20 fileHash) external view returns (uint) {
        require(msg.sender == fileHashToOwner[fileHash], "Only the File Owner can check number of shards");

        return shardsInFile_Count[fileHash];
    }

    // Function to replace file hash owner's address
    function setFileHashOwner(bytes20 fileHash, address owner) external {
        require(msg.sender == fileHashToOwner[fileHash], "Only the File Owner can give away ownership of their file");
        fileHashToOwner[fileHash] = owner;
    }

    // Function to check if an address has consent from the file owner
    function hasConsent(bytes20 _fileHash, address caller) public view returns (bool) {
        return fileHashToOwner[_fileHash] == caller;
    }

    mapping (uint => uint) private farmerShardCount;
    mapping (address => uint) public ownerFileCount;

    //start of jennifer's code:
    mapping (bytes20 => uint) private shardsInFile_Count;

    // [Provide all my fileHashes] return all fileHashes owned by user.
    // NOTE: this doesnt return the actual files, just their identifiers.
    //Only called by the web server, not our users.
    function getMyFilehashes() external view returns (bytes20[] memory) {
    // _owner from contract ownable
    // we are creating a new array with the size based on the no. of filehashes the owner has
      bytes20[] memory ownerFilehashes = new bytes20[](ownerFileCount[msg.sender]); 
        uint counter = 0;
        // we go through all the filehashes
        for (uint i = 0; i < fileHashes.length; i++) {
          // if the filehash's owner is equal to the owner
          if (fileHashToOwner[fileHashes[i]] == msg.sender) {
            // we add it to the ownerFilehashes array
            ownerFilehashes[counter] = fileHashes[i];
            counter++;
          }
        }
      return ownerFilehashes;
    }

    function getShardsByFilehash(bytes20 _filehash) public view returns (uint[] memory) {
        require(msg.sender == fileHashToOwner[_filehash], "Only the File Owner can access its shards.");

        return fileHashToShards[_filehash];
    }

    // [Drop Deleted Shards] Storage Provider is told to stop storing deleted data 
    //After a user deletes a file, drop its shards
    //emits the farmerId and shardId

    function _dropShardsOfDeletedFile (bytes20 _filehash) public {
      require(msg.sender == fileHashToOwner[_filehash], "Only File Owner can delete the file!"); //either make this function public (if we expect it to be called outside the contract) or remove this security check
      // find shards by filehashId
      uint[] memory filehashShards = getShardIDs(_filehash);
      // go through all the filehash's shards
      for (uint i = 0; i < filehashShards.length; i++) {
        // check which farmer has the shard
        for (uint j = 0; j < availableFarmerNodeIds.length; j++) {
          if (shardIdtoFarmerNodeId[i] == availableFarmerNodeIds[j]) {  
            /// expect the caller to listen for a series of deleteShard events
            emit ShardDeleted(shardIdtoFarmerNodeId[filehashShards[i]], filehashShards[i]);
          }
        }
      }
    }

    function addStorageProvider(address _walletAddress, uint _maxStorageSize, string memory _storageType) public returns (uint _nodeId) {
      require(msg.sender == _walletAddress || msg.sender == owner(), "Storage Providers can only be added by the contract owner's address or the address being registered!");
      // OLD VERSION
      //availableFarmers.push(Farmer(_address, _farmerNodeId, 0, _storageSize, _storageType));

      Farmer memory farmer = Farmer({
          walletAddress: _walletAddress,
          nodeId: farmerNodeIdIncrementer,
          currentStoredSize: 0,
          maxStorageSize: _maxStorageSize,
          storageType: _storageType
      });

    //   mapping(uint => uint) private farmerNodeIdToArrayIndexes;
    // uint activeFarmerCount = 0;
      //Add new Farmer to list of Active Farmers; associate its nodeId
      

      availableFarmers.push(farmer);
      availableFarmerNodeIds.push(farmer.nodeId);

      uint index = availableFarmers.length - 1;
      farmerNodeIdToFarmerArrayIndex[farmer.nodeId] = index;
      farmerNodeIdIncrementer++; //ensures node ids are unique
      //farmerNodeIdToFarmerArrayIndex[farmer.nodeId] = farmer;

      emit FarmerAdded(farmer.nodeId);     
    }
    
    // OLD VERSION
    // function removeStorageProvider(address _address) external {
    //     for (uint i = 0; i < availableFarmers.length; i++) {
    //         if (availableFarmers[i].walletAddress == _address) {
    //             availableFarmers[i] = availableFarmers[
    //                 availableFarmers.length - 1
    //             ];
    //             availableFarmers.pop();
    //         }
    //     }
    // }

    function removeStorageProvider(uint _nodeId) public {

       // Check if the farmer exists
      require(containsNode(_nodeId), "Invalid farmer node ID.");

      uint index = farmerNodeIdToFarmerArrayIndex[_nodeId];
      require(msg.sender == availableFarmers[index].walletAddress || msg.sender == owner(), "Storage Providers can only be removed by the contract owner's address or the address being registered!"); 
      

      availableFarmers[index] = availableFarmers[availableFarmers.length - 1];
      availableFarmers.pop();

       // Remove the farmer from the available farmers list
      availableFarmerNodeIds[index] = availableFarmerNodeIds[availableFarmerNodeIds.length - 1];
      availableFarmerNodeIds.pop();

     

      emit FarmerRemoved(_nodeId);
    }

    function getStorageProviderNodeID(address _address) external view returns (uint) {
      for (uint i = 0; i < availableFarmers.length; i++) {
        if (availableFarmers[i].walletAddress == _address) {
          return availableFarmers[i].nodeId;
        }
      }

      return 0;
    }

    function addShardToStorageProvider(uint _shardId, uint _farmerNodeId) public onlyOwner {

        // Check if the farmer exists
        require(containsNode(_farmerNodeId), "Invalid farmer node ID.");

        // Check if the farmer has available storage
        Farmer storage farmer = availableFarmers[_farmerNodeId];
        require(farmer.currentStoredSize < farmer.maxStorageSize, "Farmer has reached maximum storage capacity.");

        // Check if the shard is already assigned to a farmer
        require(shardIdtoFarmerNodeId[_shardId] == 0, "Shard is already assigned to a farmer.");

        // Assign the shard to the farmer
        shardIdtoFarmerNodeId[_shardId] = _farmerNodeId;

        // Update the farmer's storage capacity
        farmer.currentStoredSize++;

        // Emit event
        emit ShardAssigned(_shardId, _farmerNodeId);

        // OLD VERSION
        // for (uint i = 0; i < availableFarmers.length; i++) {
        //     if (availableFarmers[i].nodeId == _farmerNodeId) {
        //         require((availableFarmers[i].maxStorageSize - availableFarmers[i].currentStoredSize) >= _shardSize,"farmer does not have enough space");
        //         availableFarmers[i].currentStoredSize += _shardSize;
        //         shardIdtoFarmerNodeId[_shardId] = _farmerNodeId;
        //     }
        // }
    }

    function removeShardFromStorageProvider(uint _shardId, uint _farmerNodeId) public onlyOwner {

        // Check if the farmer exists
        require(containsNode(_farmerNodeId), "Invalid farmer node ID.");

        // Check if the shard is assigned to the given farmer
        require(shardIdtoFarmerNodeId[_shardId] == _farmerNodeId, "Shard is not assigned to the specified farmer.");

        // Remove the shard from the farmer
        delete shardIdtoFarmerNodeId[_shardId];

        // Update the farmer's storage capacity
        Farmer storage farmer = availableFarmers[_farmerNodeId];
        farmer.currentStoredSize--;

        // Emit event
        emit ShardDeleted(_shardId, _farmerNodeId);
        
        
        // OLD VERSION
        // for (uint i = 0; i < availableFarmers.length; i++) {
        //     if (availableFarmers[i].nodeId == shardIdtoFarmerNodeId[_shardId]) {
        //         availableFarmers[i].currentStoredSize -= _shardSize;
        //         delete shardIdtoFarmerNodeId[_shardId];
        //     }
        // }
    }

    function getShardData(uint _shardId) public view returns (string memory) {
        // Check if the shard exists
        require(_shardId < shards.length, "Invalid shard ID.");

        return shards[_shardId].shardData;
    }

    function getFarmerIdFromShardId(uint _shardId) public view returns (uint) {
      return shardIdtoFarmerNodeId[_shardId];
    }

    function getShardCount() public view returns (uint) {
        return shards.length;
    }

    function getFarmerCount() public view returns (uint) {
        return availableFarmers.length;
    }

    function getFarmer(uint _nodeId) public view returns (address, uint, uint, uint, string memory) {
        // Check if the farmer exists
        require(_nodeId < availableFarmers.length, "Invalid farmer node ID.");

        Farmer storage farmer = availableFarmers[_nodeId];
        return (
            farmer.walletAddress,
            farmer.nodeId,
            farmer.currentStoredSize,
            farmer.maxStorageSize,
            farmer.storageType
        );
    }

    function containsNode(uint nodeId) public view returns (bool) {
        for (uint i = 0; i < availableFarmerNodeIds.length; i++) {
            if (availableFarmerNodeIds[i] == nodeId) {
                return true;
            }
        }
        return false;
    }
} //end of contract
