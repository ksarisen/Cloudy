// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import ".deps/ownable.sol";

/**
 * @title ShardManager
 * @dev turns files into many shards.
 */
contract ShardManager {

    function _storeFile(string memory _filename, address owner,uint _dna) private {
        FilesToShards.push(_filename);
    }
}