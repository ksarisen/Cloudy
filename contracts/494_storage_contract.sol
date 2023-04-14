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
        uint currentStoredSize;
        uint maxStorageSize;
        string storageType;
    }

    Farmer[] private availableFarmers;
    uint[] private availableFarmerNodeIds;

    Shard[] private shards;
    //Farmer[] private farmers; //TODO: actually keep track of all farmers
    bytes20[] private fileHashes; //a list of 40 character ripeMD-160 hashes

    //fileHashToOwner tracks files and who owns them
    mapping(bytes20 => address) private fileHashToOwner;
    mapping(uint => bytes20) private shardIdtoFileHash;
    mapping(uint => uint) private shardIdtoFarmerNodeId; //TODO: changes to index reference of farmerd[]

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

        ownerFilehashCount[msg.sender]++;

        //Think of filehash as the id of the file.
        //E.g. first time use will store filehash A at index 0 of FileHashes, keep track of that index in fileHashToArrayIndexes, and keep track of the owner in fileHashToOwner
        emit NewFile(_filehash); // assume frontend js will pick this up and shard the file from FileHashes[index].

        //expect shard manager to track

        //the hash is the ripemd160 of a sha256 digest
    }

    function _deleteFileHash(bytes20 _fileHash) public {
        // Checks if the fileHash exists
        require(
            //fileHashToArrayIndexes[_fileHash] == 0, //this doesn't work as a "does the file exist" check because the first valid index 0 matches the unset default of 0.
            checkFileHash(_fileHash) == 0,
            "The file does not exist."
        );
        require(
            msg.sender == fileHashToOwner[_fileHash],
            "Only File Owner can delete the file!"
        );

        uint index = fileHashToArrayIndexes[_fileHash];

        //remove fileHash from fileHashes Array
        fileHashes[index] = fileHashes[fileHashes.length - 1];
        fileHashes.pop();
        //Delete mapping References
        delete fileHashToArrayIndexes[_fileHash];
        delete fileHashToShards[_fileHash];
        delete shardsInFile_Count[_fileHash];

        emit DeleteFile(_fileHash); // Web application will pick this up and tell farmers to drop the relevant shards.
    }

    function checkFileHash(bytes20 _filehash) internal view returns (uint) {
        // we go through all the filehashes
        for (uint i = 0; i < fileHashes.length; i++) {
            // if the filehash's owner is equal to the owner
            if (fileHashes[i] == _filehash) {
                return 1; //filehash found
            }
        }
        return 0; // filehash doesn't exist
    }

    //given a filehash, return the list of farmers the website would need to contact to get all shard.
    // function getFarmerIdsStoringFile(bytes20 memory _filehash) internal returns(uint[] memory) {
    //return array of nodeIds
    // }

    //End of Ben's code

    // Kerem's code below

    mapping(bytes20 => uint[]) fileHashToShards;

    // Mapping to store file hash owner's address
    mapping(string => address) fileHashOwners;

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
    function associateShardsWithFileHash(
        bytes20 _fileHash,
        uint[] memory shardIDs
    ) external _onlyFileOwnerOrConsent(_fileHash) {
        require(shardIDs.length > 0, "Shard IDs must not be empty");

        // Store shardIDs in the mapping under the fileHash
        fileHashToShards[_fileHash] = shardIDs; //file to shards implies i pass in a file to get shards

        // Increment the shardsInFile_Count
        shardsInFile_Count[_fileHash] += shardIDs.length;
    }

    // Function to retrieve shard IDs by file hash
    function getShardIDs(
        bytes20 fileHash
    ) external view returns (uint[] memory) {
        return fileHashToShards[fileHash];
    }

    // Function to get the total count of shards in a file
    function getshardsInFile_Count(
        bytes20 fileHash
    ) external view returns (uint) {
        return shardsInFile_Count[fileHash];
    }

    // Function to replace file hash owner's address
    function setFileHashOwner(bytes20 fileHash, address owner) external {
        require(
            msg.sender == fileHashToOwner[fileHash],
            "Only the File Owner can give away ownership of their file"
        );
        fileHashToOwner[fileHash] = owner;
    }

    // Function to check if an address has consent from the file owner
    function hasConsent(
        bytes20 _fileHash,
        address caller
    ) internal view returns (bool) {
        return fileHashToOwner[_fileHash] == caller;
    }

    // Implemented according to the google doc (Contract functions TODOS for March 24th)

    //mapping (address => uint) private farmerToNodeId;
    mapping(uint => uint) private farmerShardCount;

    // // Storage Provider will provide(upload) their node ID(not sure if we need id, just address might be sufficent) and list of stored shards.
    // function getDetailsByFarmer(Farmer memory _farmer) external view returns(uint, Shard[] memory) {
    //   uint nodeId = _farmer.nodeId;

    //   Shard[] memory shardList  = new Shard[](farmerShardCount[nodeId]);
    //   uint counter;
    //   for (uint i = 0; i < shards.length; i++) {
    //     if ((shardIdtoFarmerNodeId[shards[i].shardId]) == _farmer.nodeId) {
    //       shardList[counter] = shards[i];
    //       counter++;
    //     }
    //   }
    //   return (nodeId, shardList);
    // }

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
    mapping(address => uint) private ownerFilehashCount;
    mapping(bytes20 => uint) private shardsInFile_Count;

    // [Provide all my fileHashes] return all fileHashes owned by user
    //Only called by the web server, not our users.
    function getFilehashesByOwner(
        address _owner
    ) external view onlyOwner returns (bytes20[] memory) {
        // _owner from contract ownable
        // we are creating a new array with the size based on the no. of filehashes the owner has
        bytes20[] memory ownerFilehashes = new bytes20[](
            ownerFilehashCount[_owner]
        );
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

    function getShardsByFilehash(
        bytes20 _filehash
    ) public view returns (uint[] memory) {
        require(
            msg.sender == fileHashToOwner[_filehash],
            "Only the File Owner can access its shards."
        );

        uint[] memory filehashShards = new uint[](
            shardsInFile_Count[_filehash]
        );
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
    function _dropShardsOfDeletedFile(bytes20 _filehash) private {
        require(
            msg.sender == fileHashToOwner[_filehash],
            "Only File Owner can delete the file!"
        ); //either make this function public (if we expect it to be called outside the contract) or remove this security check
        // find shards by filehashId
        uint[] memory filehashShards = getShardsByFilehash(_filehash);
        // go through all the filehash's shards
        for (uint i = 0; i < filehashShards.length; i++) {
            // check which farmer has the shard

            for (uint j = 0; j < availableFarmerNodeIds.length; j++) {
                if (shardIdtoFarmerNodeId[i] == availableFarmerNodeIds[j]) {
                    /// expect the caller to listen for a series of deleteShard events
                    emit deleteShardFromFarmer(
                        shardIdtoFarmerNodeId[filehashShards[i]],
                        filehashShards[i]
                    );
                }
            }
        }
    }

    function addStorageProvider(
        address _address,
        uint _nodeID,
        uint _storageSize,
        string memory _storageType
    ) external {
        availableFarmers.push(
            Farmer(_address, _nodeID, 0, _storageSize, _storageType)
        );
    }

    function removeStorageProvider(address _address) external {
        for (uint i = 0; i < availableFarmers.length; i++) {
            if (availableFarmers[i].walletAddress == _address) {
                availableFarmers[i] = availableFarmers[
                    availableFarmers.length - 1
                ];
                availableFarmers.pop();
            }
        }
    }

    function getStorageProviderNodeID(
        address _address
    ) external view returns (uint) {
        for (uint i = 0; i < availableFarmers.length; i++) {
            if (availableFarmers[i].walletAddress == _address) {
                return availableFarmers[i].nodeId;
            }
        }

        revert("Not found");
    }

    function addShardToStorageProvider(
        uint _shardId,
        uint _shardSize,
        uint _nodeId
    ) external {
        for (uint i = 0; i < availableFarmers.length; i++) {
            if (availableFarmers[i].nodeId == _nodeId) {
                require(
                    (availableFarmers[i].maxStorageSize -
                        availableFarmers[i].currentStoredSize) >= _shardSize,
                    "farmer does not have enough space"
                );
                availableFarmers[i].currentStoredSize += _shardSize;
                shardIdtoFarmerNodeId[_shardId] = _nodeId;
            }
        }
    }

    function removeShardFromStorageProvider(
        uint _shardId,
        uint _shardSize
    ) external {
        for (uint i = 0; i < availableFarmers.length; i++) {
            if (availableFarmers[i].nodeId == shardIdtoFarmerNodeId[_shardId]) {
                availableFarmers[i].currentStoredSize -= _shardSize;
                delete shardIdtoFarmerNodeId[_shardId];
            }
        }
    }
} //end of contract
