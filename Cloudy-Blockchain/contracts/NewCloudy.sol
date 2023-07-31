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
        address payable storageProvider;
        bytes32 fileHash;
        bool exists;
    }
    
    struct StorageProvider {
        string ip; //TODO: update this to bytes32 then write js converters from string to bytes32 to use in Home.jsx, and python converters from string to bytes32 to use in andIncentiveAuditorMain.py
        address payable walletAddress;
        uint256 availableStorageSpace;  // Tracking in bytes
        uint256 maximumStorageSize;     // Tracking in bytes
        bool isStoring; //Boolean that measures whether storage provider has been added to the Cloudy system regardless of whether it is actually storing any files. TODO: rename this
        uint256[] storedShardIds; // mapping that associates each storage provider wallet address with the shards they hold.
    }

    mapping(uint256 => Shard) private shards; // mapping that stores all the shards by their ID.
    mapping(bytes32 => File) private filesByHash; // Updated to use file hash as key
    mapping(address => StorageProvider) private providerDetails;
    mapping(address => bytes32[]) private ownerFiles; // mapping has been added to track which files are owned by each address (owner)
    mapping(bytes32 => bool) private isFileBeingStored; // mapping is used to track the existence of a file based on its file hash

    address[] private providersWithSpace; // array has been added to store the addresses of storage providers who still have space available for new files
    address[] private providersStoring; // array has been added to store the addresses of storage providers currently storing any shards

    uint256 private shardCounter;
    uint256 private rewardAmount;

    event ShardStored(uint256 shardId, address storageProvider);
    event ShardAudited(uint256 shardId, address storageProvider, bool valid);
    event ShardDeleted(uint256 shardId);
    event RewardPaid(address storageProvider, uint256 amount);
    event FileUploaded(address indexed owner, bytes32 fileHash);
    event StorageProviderAdded(address indexed storageProvider);
    event StorageProviderDeleted(address indexed storageProvider);

    constructor () {
        shardCounter = 1;
        rewardAmount = 0.00001 ether; // Set the initial reward amount
    }

    // Function allows users to upload a file by providing its hash

    // In this updated version, the uploadFile function now accepts an additional parameter shardIds 
    // which is an array of uint256 values representing the shard IDs related to the file being uploaded.

    // It checks that at least one shard is provided, and then iterates through the shard IDs to update the necessary relationships.
    
    // The function assigns the file owner, owner name, file name, file hash, and shard IDs to the files mapping. 
    // It also adds the shard IDs to the ownerFiles mapping and updates the storage provider and shard mappings (storageProvider.storedShardIds) accordingly.

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


function uploadFile(string memory _ownerName, string memory _fileName, bytes32 _fileHash, uint256 _shardCount) external returns (uint256[] memory) {
    //require(!doesFileExist(_fileHash), "File already exists");
    if (doesFileExist(_fileHash)) {
        revert("File already exists");
    }
    if (bytes(_ownerName).length == 0) {
        revert("Owner name must be provided");
    }
    if (bytes(_fileName).length == 0) {
        revert("File name must be provided");
    }
    if (_shardCount == 0) {
        revert("Shard count must be greater than zero");
    }


    uint256 numShards = _shardCount;
    uint256[] memory shardIds = new uint256[](numShards);

    for (uint256 i = 0; i < numShards; i++) {
        // Use shardCounter as the unique shard ID
        uint256 shardId = shardCounter;
        shards[shardId] = Shard(shardId, payable(address(0)), _fileHash, true);
        shardIds[i] = shardId;
        shardCounter++;
    }

    filesByHash[_fileHash] = File(msg.sender, _ownerName, _fileName, _fileHash, shardIds, true);
    ownerFiles[msg.sender].push(_fileHash);
    isFileBeingStored[_fileHash] = true;
    emit FileUploaded(msg.sender, _fileHash);
    // Return the array of shardIds so the frontend has access to the gloablly unique shardIds assigned to its shards
    return shardIds;
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
    function assignShardToStorageProvider(uint256 _shardId, address payable _storageProvider) external {
        //TODO: ensure we check the msg.sender (the storage provider holding this shard) is the one being assigned to it
        require(shards[_shardId].exists, "Shard does not exist");
        require(providerDetails[_storageProvider].walletAddress != address(0), "Storage provider does not exist");

        address currentProviderAddress = shards[_shardId].storageProvider;
        if (providerDetails[_storageProvider].storedShardIds.length == 0) {
            //if this is their first shard, add to list of providers actively storing shards
            providersStoring.push(_storageProvider);
        }
        if (currentProviderAddress != _storageProvider && currentProviderAddress != address(0)) {
            //this shard is being reassigned from a different provider.
            // Remove the shard from the current provider's list
            StorageProvider storage currentProviderDetails = providerDetails[currentProviderAddress];
            for (uint256 i = 0; i < currentProviderDetails.storedShardIds.length; i++) {
                if (currentProviderDetails.storedShardIds[i] == _shardId) {
                    currentProviderDetails.storedShardIds[i] = currentProviderDetails.storedShardIds[currentProviderDetails.storedShardIds.length - 1];
                    currentProviderDetails.storedShardIds.pop();
                    break;
                }
            }

            // Assign the shard to the new provider
            shards[_shardId].storageProvider = _storageProvider;

            StorageProvider storage newProviderDetails = providerDetails[_storageProvider];
            newProviderDetails.storedShardIds.push(_shardId);
            providerDetails[_storageProvider].storedShardIds.push(_shardId);
            emit ShardStored(_shardId, _storageProvider);
        }
        else{
            //this is a new shard
            providerDetails[_storageProvider].storedShardIds.push(_shardId);
            shards[_shardId].storageProvider = _storageProvider;
        }
    }

    // Function audits the storage providers by checking if they still hold the assigned shards and rewards them accordingly
    function auditStorageProviders(uint256[] calldata _shardIds) external payable{
        for (uint256 i = 0; i < _shardIds.length; i++) {
            uint256 shardId = _shardIds[i];
            Shard storage shard = shards[shardId];
            bool valid = isShardValid(shard.id);

            emit ShardAudited(shardId, shard.storageProvider, valid);

            if (valid) {
                require(rewardAmount > 0, "Amount must be greater than 0");
                
                // Way 1:
                // shard.storageProvider.transfer(rewardAmount);

                // Call returns a boolean value indicating success or failure.
                // This is the current recommended method to use.

                // Way 2:
                (bool sent, ) = shard.storageProvider.call{value: rewardAmount}("");
                require(sent, "Failed to send Ether");
                
                emit RewardPaid(shard.storageProvider, rewardAmount);
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
    // function payReward(address _storageProvider) internal {
    //     //require(address(this).balance >= rewardAmount, "Insufficient contract balance");

    //     (bool success, ) = _storageProvider.call{value: rewardAmount}("");
    //     require(success, "Reward payment failed");
    //TODO: if file owner can't pay, make sure storage provider knows to stop storing the related shards

    //     emit RewardPaid(_storageProvider, rewardAmount);
    // }

    // Function allows updating the reward amount
    function updateRewardAmount(uint256 _newRewardAmount) external {
        rewardAmount = _newRewardAmount;
    }
    
    // Please note that these functions are marked as internal, which means they can only be called from within the contract. 
    // If you need to update these values externally, you can change the visibility to external and add appropriate access control mechanisms to protect them.

    // Function allows storage providers to register themselves and provide their IP, wallet address, available storage space, and maximum storage size
    function addStorageProvider(string memory _ip, address payable _walletAddress, uint256 _maximumStorageSize) external {
        require (msg.sender == _walletAddress, "only the storage provider can add themselves to the system. please make sure your wallet address matches the one being passed in.");
        require(!providerDetails[msg.sender].isStoring, "Storage provider already exists");

        providerDetails[_walletAddress] = StorageProvider(_ip, _walletAddress, _maximumStorageSize, _maximumStorageSize, true, new uint256[](0));
        providersWithSpace.push(_walletAddress);

        emit StorageProviderAdded(_walletAddress);
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
        address storageProviderAddress = shardToDelete.storageProvider;
        StorageProvider storage storageProviderDetails = providerDetails[storageProviderAddress];
        require(msg.sender == storageProviderAddress, "Only the storage provider can delete the shard");

        // Delete the shard from the storage provider's list
        uint256[] storage providerShards = storageProviderDetails.storedShardIds;
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

        //TODO: pop/remove the shard from storageProviderDetails.storedShardIds
        //TODO: ensure if this is a storage provider's last shard, we remove them from the list of storage providers currently storing shards.
        
        

        emit ShardDeleted(_shardId);
    }

    // function auditShard(uint256 _shardId) external {
    //     Shard storage shard = shards[_shardId];
    //     require(shard.exists, "Shard does not exist");

    //     bool isValid = isShardValid(_shardId);

    //     emit ShardAudited(_shardId, shard.storageProvider, isValid);

    //     if (isValid) {
    //         // Reward the storage provider
    //         payReward(shard.storageProvider);
    //     } else {
    //         // Remove the shard from the storage provider
    //         removeShardFromProvider(_shardId);
    //     }
    // }

    function removeShardFromProvider(uint256 _shardId) internal {
        Shard storage shard = shards[_shardId];
        address storageProviderAddress = shard.storageProvider;
        StorageProvider storage storageProviderDetails = providerDetails[storageProviderAddress];

        // Remove the shard from the storage provider's list
        uint256[] storage providerShards = storageProviderDetails.storedShardIds;
        for (uint256 i = 0; i < providerShards.length; i++) {
            if (storageProviderDetails.storedShardIds[i] == _shardId) {
                storageProviderDetails.storedShardIds[i] = storageProviderDetails.storedShardIds[storageProviderDetails.storedShardIds.length - 1];
                storageProviderDetails.storedShardIds.pop();
                break;
            }
        }

        emit ShardDeleted(_shardId);
    }

    // Deletes a storage provider, provided it is not currently storing any shards.
    function deleteStorageProvider(address _storageProvider) external {
        //TODO: improve security so random people cant just delete all our storage providers
        require(providerDetails[_storageProvider].isStoring, "Storage provider does not exist");
        // Remove the storage provider's details
        delete providerDetails[_storageProvider].storedShardIds;
        delete providerDetails[_storageProvider];

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
        delete _storageProvider;

        emit StorageProviderDeleted(_storageProvider);
    }

    // Function allows users to retrieve the details of a specific storage provider by providing their address
    function getStorageProviderDetails(address _storageProvider) external view returns (string memory, address, uint256, uint256, bool, uint256[] memory) {
        StorageProvider storage provider = providerDetails[_storageProvider];
        return (provider.ip, provider.walletAddress, provider.availableStorageSpace, provider.maximumStorageSize, provider.isStoring, provider.storedShardIds);
    }
    
    function getFileDetails(bytes32 _fileHash) external view returns (address, string memory, string memory, bytes32, uint256[] memory) {
        File storage file = filesByHash[_fileHash];
        return (file.owner, file.ownerName, file.fileName, file.fileHash, file.shardIds);
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
        uint256 length = providersStoring.length;
        StorageProvider[] memory providerDetailsArray = new StorageProvider[](length);

        for (uint256 i = 0; i < length; i++) {
            address providerAddress = providersStoring[i];
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

    function getFileNamesByOwner(address _owner) external view returns (string[] memory) {
        bytes32[] storage fileHashes = ownerFiles[_owner];
        uint256 length = fileHashes.length;
        string[] memory fileNames = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            File storage file = filesByHash[fileHashes[i]];
            fileNames[i] = file.fileName;
        }

        return fileNames;
    }

    function getFileDetailsByOwner(address _owner) external view returns (FileDetails[] memory) {
        bytes32[] memory fileHashes = ownerFiles[_owner];
        FileDetails[] memory allFileDetails = new FileDetails[](fileHashes.length);

        for (uint256 i = 0; i < fileHashes.length; i++) {
            File storage file = filesByHash[fileHashes[i]];
            allFileDetails[i] = FileDetails({
                owner: file.owner,
                ownerName: file.ownerName,
                fileName: file.fileName,
                fileHash: file.fileHash,
                shardIds: file.shardIds
            });
        }

        return allFileDetails;
    }

    // Define a custom struct to hold the File details for the view function
    struct FileDetails {
        address owner;
        string ownerName;
        string fileName;
        bytes32 fileHash;
        uint256[] shardIds;
    }
}

