// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DistributedStorage {
    struct File {
        address owner;
        string ownerName;
        string fileName;
        bytes32 fileHash;
        uint256[] shardIds;
        bool exists;
    }

    struct Shard {
        uint256 id;
        address storageProvider;
        uint256 timestamp;
        bytes32 fileHash;
        bool exists;
    }
    
    struct StorageProvider {
        string ip; //TODO: update this to bytes32 then write js converters from string to bytes32 to use in Home.jsx, and python converters from string to bytes32 to use in andIncentiveAuditorMain.py
        address walletAddress;
        uint256 availableStorageSpace;  // Tracking in bytes
        uint256 maximumStorageSize;     // Tracking in bytes
        bool isStoring;
        uint256[] storedShardIds;
    }

    mapping(uint256 => Shard) public shards; // mapping that stores all the shards by their ID.
    mapping(bytes32 => File) public filesByHash; // Updated to use file hash as key
    mapping(address => uint256[]) public shardsHeldByStorageProvider; // mapping that associates each storage provider wallet address with the shards they hold.
    mapping(address => StorageProvider) public providerDetails;
    mapping(address => bytes32[]) public ownerFiles; // mapping has been added to track which files are owned by each address (owner)
    mapping(bytes32 => bool) public isFileBeingStored; // mapping is used to track the existence of a file based on its file hash

    address[] public providersWithSpace; // array has been added to store the addresses of storage providers who still have space available for new files
    address[] public providersStoring; // array has been added to store the addresses of storage providers currently storing any shards

    uint256 public shardCounter;
    uint256 public rewardAmount;

    event ShardStored(uint256 shardId, address storageProvider);
    event ShardAudited(uint256 shardId, address storageProvider, bool valid);
    event ShardDeleted(uint256 shardId);
    event RewardPaid(address storageProvider, uint256 amount);
    event FileUploaded(address indexed owner, bytes32 fileHash);
    event ShardDeleted(uint256 shardId);
    event StorageProviderAdded(address indexed storageProvider);
    event StorageProviderDeleted(address indexed storageProvider);

    constructor() {
        shardCounter = 1;
        rewardAmount = 0.00001 ether; // Set the initial reward amount
    }

    // Function allows users to upload a file by providing its hash

    // In this updated version, the uploadFile function now accepts an additional parameter shardIds 
    // which is an array of uint256 values representing the shard IDs related to the file being uploaded.

    // It checks that at least one shard is provided, and then iterates through the shard IDs to update the necessary relationships.
    
    // The function assigns the file owner, owner name, file name, file hash, and shard IDs to the files mapping. 
    // It also adds the shard IDs to the ownerFiles mapping and updates the storage provider and shard mappings (shardsHeldBystorageProvider and fileShards) accordingly.

    // This ensures that the relationships between shards and files are stored and tracked as the file is being uploaded.

    /*
     * The function calculates the number of shards required to store the file based on the file data length and the shard size. 
     * It then iterates through each shard, extracts the corresponding portion of the file data, and creates a shard using the createShard internal function.
     * The createShard function assigns the storage provider, sets the shard's creation timestamp, and emits the ShardStored event.

     * Please note that this is a basic implementation of the sharding process within the contract. It splits the file data into shards based on a specified shard size. 
     * You can enhance this implementation according to your specific requirements, such as implementing redundancy mechanisms, optimizing shard sizes, or considering encryption and integrity checks.

     * Keep in mind that large files may have gas limitations and require additional considerations. 
     * Additionally, it's essential to carefully assess the costs, security, and scalability aspects of storing large amounts of data on the blockchain.
     */
    // function uploadFile(string memory _ownerName, string memory _fileName, bytes32 _fileHash, bytes memory _fileData, uint256 _shardSize) external {
    //     require(_fileData.length > 0, "File data must be provided");

    //     uint256 numShards = (uint256(_fileData.length) + _shardSize - 1) / _shardSize;

    //     uint256[] memory shardIds = new uint256[](numShards);

    //     for (uint256 i = 0; i < numShards; i++) {
    //         uint256 start = i * _shardSize;
    //         uint256 end = start + _shardSize;
    //         if (end > _fileData.length) {
    //             end = _fileData.length;
    //         }

    //         bytes memory shardData = new bytes(end - start);

    //         for (uint256 j = start; j < end; j++) {
    //             shardData[j - start] = _fileData[j];
    //         }

    //         shardIds[i] = createShard(shardData, _fileHash, msg.sender);
    //     }

    //     filesByHash[_fileHash] = File(msg.sender, _ownerName, _fileName, _fileHash, shardIds, true);

    //     ownerFiles[msg.sender].push(_fileHash);

    //     shardCounter++;
    // }

    function uploadFile(string memory _ownerName, string memory _fileName, bytes32 _fileHash, uint256[] memory _shardIds) external {
        require(!doesFileExist(_fileHash), "File already exists");
        require(bytes(_ownerName).length > 0, "Owner name must be provided");
        require(bytes(_fileName).length > 0, "File name must be provided");

        filesByHash[_fileHash] = File(msg.sender, _ownerName, _fileName, _fileHash, _shardIds, true);
        ownerFiles[msg.sender].push(_fileHash);
        isFileBeingStored[_fileHash] = true;
        for (uint256 i = 0; i < _shardIds.length; i++) {
            uint256 shardId = _shardIds[i];
            createShard(shardId, _fileHash);
        }
        emit FileUploaded(msg.sender, _fileHash);
    }

    function createShard(uint256 shardId, bytes32 _fileHash) internal
    {
        shards[shardId] = Shard(shardId, address(0), block.timestamp, _fileHash, true);
        filesByHash[_fileHash].shardIds.push(shardId); 
        shardCounter++;
    }

    function deleteFile(bytes32 _fileHash) external {
        require(isFileBeingStored[_fileHash] = true, "File does not exist");
        File storage fileToDelete = filesByHash[_fileHash];
        require(msg.sender == fileToDelete.owner, "Only the file owner can delete the file");

        uint256[] storage fileShardIds = filesByHash[_fileHash].shardIds;
        for (uint256 i = 0; i < fileShardIds.length; i++) {
            emit ShardDeleted(fileShardIds[i]);//this is listened for by CloudyStorageMain.py
            delete shards[fileShardIds[i]];
        }
        isFileBeingStored[_fileHash] = false;
        // Delete the file from the owner's list of files
        bytes32[] storage ownerFileHashes = ownerFiles[msg.sender];
        for (uint256 i = 0; i < ownerFileHashes.length; i++) {
            if (ownerFileHashes[i] == _fileHash) {
                delete ownerFileHashes[i];
                break;
            }
        }

        // Delete the file from the filesByHash mapping
        delete filesByHash[_fileHash];

    }

    // Function assigns a storage provider to a new shard, or reassigns existing shard to new storage provider
    function assignShardToStorageProvider(uint256 _shardId, address _storageProvider) external {
        //TODO: ensure we check the msg.sender (the storage provider holding this shard) is the one being assigned to it
        //require(shards[_shardId].exists, "Shard does not exist");
        //require(providerDetails[_storageProvider].walletAddress != address(0), "Storage provider does not exist");

        address currentProvider = shards[_shardId].storageProvider;
        if (currentProvider != _storageProvider) {
            //this shard is being reassigned from a different provider.
            // Remove the shard from the current provider's list
            uint256[] storage currentProviderShards = shardsHeldByStorageProvider[currentProvider];
            for (uint256 i = 0; i < currentProviderShards.length; i++) {
                if (currentProviderShards[i] == _shardId) {
                    currentProviderShards[i] = currentProviderShards[currentProviderShards.length - 1];
                    currentProviderShards.pop();
                    //delete currentProviderShards[i];
                    break;
                }
            }

            // Assign the shard to the new provider

            uint256[] storage newProviderShards = shardsHeldByStorageProvider[_storageProvider];

            shards[_shardId].storageProvider = _storageProvider;
            newProviderShards.push(_shardId);

            // shards[_shardId].storageProvider = _storageProvider;
            // shardsHeldBystorageProvider[_storageProvider].push(_shardId);

            emit ShardStored(_shardId, _storageProvider);
        }
        else{
            //this is a new shard

            //TODO: why do we have two different spots tracking the same data? lets just pick one and roll with it.
            //shardsHeldByStorageProvider[_storageProvider].push(_shardId);
            providerDetails[_storageProvider].storedShardIds.push(_shardId);
            shards[_shardId].storageProvider = _storageProvider;
        }
    }

    // Function audits the storage providers by checking if they still hold the assigned shards and rewards them accordingly
    function auditStorageProviders(uint256[] calldata _shardIds) external {
        for (uint256 i = 0; i < _shardIds.length; i++) {
            uint256 shardId = _shardIds[i];
            Shard storage shard = shards[shardId];
            bool valid = isShardValid(shard.id);

            emit ShardAudited(shardId, shard.storageProvider, valid);

            if (valid) {
                payReward(shard.storageProvider);
            }
        }
    }

    function doesFileExist(bytes32 _fileHash) internal view returns (bool) {
        return isFileBeingStored[_fileHash];
        
        //TODO: update this check so it doesnt need to use a whole new mapping
        //the file exists if its filehash corresponds to a file object.
        //return filesByHash[_fileHash].length > 0;
    }

    // Function is a placeholder for your specific shard validation logic. You can implement your own checks to determine if the storage provider still holds the shard.
    function isShardValid(uint256 _shardId) internal view returns (bool) {
        Shard storage shard = shards[_shardId];
        return shard.exists;
    }

    // Function transfers the reward amount to the storage provider if the shard is valid
    function payReward(address _storageProvider) internal {
        require(address(this).balance >= rewardAmount, "Insufficient contract balance");

        (bool success, ) = _storageProvider.call{value: rewardAmount}("");
        require(success, "Reward payment failed");

        emit RewardPaid(_storageProvider, rewardAmount);
    }

    // Function allows updating the reward amount
    function updateRewardAmount(uint256 _newRewardAmount) external {
        rewardAmount = _newRewardAmount;
    }
    
    // Please note that these functions are marked as internal, which means they can only be called from within the contract. 
    // If you need to update these values externally, you can change the visibility to external and add appropriate access control mechanisms to protect them.

    // Function allows storage providers to register themselves and provide their IP, wallet address, available storage space, and maximum storage size
    function addStorageProvider(string memory _ip, address _walletAddress, uint256 _maximumStorageSize) external {
        //what can we use for ip addresses? e.g. "127.0.0.1"  cant figure out how to send _ip as bytes32 using python
        //send it without a type, then pack/unpack.

        require(!providerDetails[msg.sender].isStoring, "Storage provider already exists");

        providerDetails[msg.sender] = StorageProvider(_ip, _walletAddress, _maximumStorageSize, _maximumStorageSize, true, new uint256[](0));
        providersWithSpace.push(msg.sender);

        emit StorageProviderAdded(msg.sender);
    }

    // Function allows updating the storage status of a provider, marking them as either storing or not storing any shards
    function updateStorageStatus(address _storageProvider, bool _isStoring) internal {
        StorageProvider storage provider = providerDetails[_storageProvider];
        provider.isStoring = _isStoring;
        
        if (_isStoring) {
            providersStoring.push(_storageProvider);
        } else {
            removeProviderFromArray(providersStoring, _storageProvider);

            // for (uint256 i = 0; i < providersStoring.length; i++) {
            //     if (providersStoring[i] == _storageProvider) {
            //         providersStoring[i] = providersStoring[providersStoring.length - 1];
            //         providersStoring.pop();
            //         break;
            //     }
            // }
        }
    }

    // Function enables updating the available storage space for a provider and automatically updates the providersWithSpace array based on the new available space value
    function updateAvailableStorageSpace(address _storageProvider, uint256 _newAvailableSpace) external {
        StorageProvider storage provider = providerDetails[_storageProvider];
        uint256 oldAvailableSpace = provider.availableStorageSpace;
        provider.availableStorageSpace = _newAvailableSpace;
        
        // if (_newAvailableSpace > 0) {
        //     bool providerFound = false;
            
        //     for (uint256 i = 0; i < providersWithSpace.length; i++) {
        //         if (providersWithSpace[i] == _storageProvider) {
        //             providerFound = true;
        //             break;
        //         }
        //     }
            
        //     if (!providerFound) {
        //         providersWithSpace.push(_storageProvider);
        //     }
        // } else {
        //     for (uint256 i = 0; i < providersWithSpace.length; i++) {
        //         if (providersWithSpace[i] == _storageProvider) {
        //             providersWithSpace[i] = providersWithSpace[providersWithSpace.length - 1];
        //             providersWithSpace.pop();
        //             break;
        //         }
        //     }
        // }

        if (oldAvailableSpace == 0 && _newAvailableSpace > 0) {
            providersWithSpace.push(_storageProvider);
        } else if (oldAvailableSpace > 0 && _newAvailableSpace == 0) {
            removeProviderFromArray(providersWithSpace, _storageProvider);
        }
    }

    function removeProviderFromArray(address[] storage _array, address _provider) internal {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == _provider) {
                if (i < length - 1) {
                    _array[i] = _array[length - 1];
                }
                _array.pop();
                break;
            }
        }
    }  

    // Deletes a shard and its associated data.
    function deleteShard(uint256 _shardId) external {
        require(shards[_shardId].exists, "Shard does not exist");
        Shard storage shardToDelete = shards[_shardId];
        address storageProvider = shardToDelete.storageProvider;
        require(msg.sender == storageProvider, "Only the storage provider can delete the shard");

        // Delete the shard from the storage provider's list
        uint256[] storage providerShards = shardsHeldByStorageProvider[storageProvider];
        for (uint256 i = 0; i < providerShards.length; i++) {
            if (providerShards[i] == _shardId) {
                providerShards[i] = providerShards[providerShards.length - 1];
                providerShards.pop();
                //delete providerShards[i];
                break;
            }
        }

        // Delete the shard from the file's list of shards
        uint256[] storage fileShardIds = filesByHash[shardToDelete.fileHash].shardIds ; 
        for (uint256 i = 0; i < fileShardIds.length; i++) {
            if (fileShardIds[i] == _shardId) {
                fileShardIds[i] = fileShardIds[fileShardIds.length - 1];
                fileShardIds.pop();
                //delete fileShardIds[i];
                break;
            }
        }

        // Delete the shard from the shards mapping
        delete shards[_shardId];

        emit ShardDeleted(_shardId);
    }

    function auditShard(uint256 _shardId) external {
        Shard storage shard = shards[_shardId];
        require(shard.exists, "Shard does not exist");

        bool isValid = isShardValid(_shardId);

        emit ShardAudited(_shardId, shard.storageProvider, isValid);

        if (isValid) {
            // Reward the storage provider
            payReward(shard.storageProvider);
        } else {
            // Remove the shard from the storage provider
            removeShardFromProvider(_shardId);
        }
    }

    function removeShardFromProvider(uint256 _shardId) internal {
        Shard storage shard = shards[_shardId];
        address storageProvider = shard.storageProvider;

        // Remove the shard from the storage provider's list
        uint256[] storage providerShards = shardsHeldByStorageProvider[storageProvider];
        for (uint256 i = 0; i < providerShards.length; i++) {
            if (providerShards[i] == _shardId) {
                providerShards[i] = providerShards[providerShards.length - 1];
                providerShards.pop();
                //delete providerShards[i];
                break;
            }
        }

        emit ShardDeleted(_shardId);
    }

    // Deletes a storage provider, provided it is not currently storing any shards.
    function deleteStorageProvider(address _storageProvider) external {
        //TODO: improve security so random people cant just delete all our storage providers
        require(providerDetails[_storageProvider].isStoring, "Storage provider does not exist");

        // Remove the storage provider from the mappings
        delete providerDetails[_storageProvider];
        delete shardsHeldByStorageProvider[_storageProvider];

        // Remove the storage provider from the arrays
        for (uint256 i = 0; i < providersWithSpace.length; i++) {
            if (providersWithSpace[i] ==_storageProvider) {
                providersWithSpace[i] = providersWithSpace[providersWithSpace.length - 1];
                providersWithSpace.pop();
                break;
            }
        }

        for (uint256 i = 0; i < providersStoring.length; i++) {
            if (providersStoring[i] == _storageProvider) {
                providersStoring[i] = providersStoring[providersStoring.length - 1];
                providersStoring.pop();
                break;
            }
        }

        emit StorageProviderDeleted(_storageProvider);
    }

    // Function allows users to retrieve the details of a specific storage provider by providing their address
    function getStorageProviderDetails(address _storageProvider) external view returns (string memory, address, uint256, uint256, bool) {
        StorageProvider storage provider = providerDetails[_storageProvider];
        return (provider.ip, provider.walletAddress, provider.availableStorageSpace, provider.maximumStorageSize, provider.isStoring);
    }
    
    function getFileDetails(bytes32 _fileHash) external view returns (address, string memory, string memory, bytes32) {
        File storage file = filesByHash[_fileHash];
        return (file.owner, file.ownerName, file.fileName, file.fileHash);
    }
    
    function getOwnerFiles(address _owner) external view returns (bytes32[] memory) {
        return ownerFiles[_owner];
    }
    
    function getFilesShards(bytes32 _fileHash) external view returns (uint256[] memory) {
        return filesByHash[_fileHash].shardIds ;
    }

    function getStorageProvidersWithSpace() external view returns (StorageProvider[] memory) {
        uint256 length = providersWithSpace.length;
        StorageProvider[] memory providerDetailsArray = new StorageProvider[](length);

        for (uint256 i = 0; i < length; i++) {
            address providerAddress = providersWithSpace[i];
            StorageProvider memory provider = providerDetails[providerAddress];
            providerDetailsArray[i] = StorageProvider({
                ip: provider.ip,
                walletAddress: provider.walletAddress,
                availableStorageSpace: provider.availableStorageSpace,
                maximumStorageSize: provider.maximumStorageSize,
                isStoring: provider.isStoring,
                storedShardIds: provider.storedShardIds
            });
        }

        return providerDetailsArray;
    }

    // Access the data of StorageProviders whose addresses are in providersStoring
    // The function is used by the incentiveAuditor
    function getStorageProviderDataOfProvidersCurrentlyStoringShards() external view returns (StorageProvider[] memory) {
        uint256 providersCount = providersStoring.length;
        if (providersCount == 0) {
            // Return an empty array if there are no storage providers
            return new StorageProvider[](0);
        }

        StorageProvider[] memory providersData = new StorageProvider[](providersCount);

        for (uint256 i = 0; i < providersCount; i++) {
            address providerAddress = providersStoring[i];
            providersData[i] = providerDetails[providerAddress]; //actually access the data stored in the associated StorageProvider struct
        }
        return providersData;
    }

    

    function getProviderStoredShards(address _storageProvider) external view returns (uint256[] memory) {
        return providerDetails[_storageProvider].storedShardIds;
    }

    function getIPsOfStorageProvidersWithSpace() external view returns (string[] memory) {
        uint256 length = providersWithSpace.length;
        string[] memory ips = new string[](length);
        
        
        for (uint256 i = 0; i < length; i++) {
            address providerAddress = providersWithSpace[i];
            ips[i] = providerDetails[providerAddress].ip;
        }
        
        return ips;
    }

    function getIPsOfStorageProvidersStoringShards() external view returns (string[] memory) {
        uint256 length = providersStoring.length;
        string[] memory ips = new string[](length);
        
        for (uint256 i = 0; i < length; i++) {
            address providerAddress = providersStoring[i];
            ips[i] = providerDetails[providerAddress].ip;
        }
        
        return ips;
    }
}
