// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ObjectStorage {
    uint8 constant OBJECT_SLOT_SIZE = 3;
    uint8 constant OBJECT_VALUE_OFFSET = 1;
    uint8 constant OBJECT_NAME_FLAG_OFFSET = 2;
    uint8 constant ARRAY_SLOT = 0;
    uint8 constant MAPPING_SLOT = 1;
    uint256 constant FLAG_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 tmp;

    function addObject(uint256 index, bool flag, uint256 value, string memory name) external {
        assembly {
            // check that object hasn't been already added
            let ptr := mload(0x40)
            mstore(ptr, MAPPING_SLOT)
            mstore(add(ptr, 0x20), index)
            let mappingAddr := keccak256(ptr, 0x40)
            if gt(sload(mappingAddr), 0) { revert(0, 0) }
            // get the address of object in array
            mstore(ptr, ARRAY_SLOT)
            let arrSize := sload(ARRAY_SLOT)
            let arrAddr := add(keccak256(ptr, 0x20), mul(arrSize, OBJECT_SLOT_SIZE))
            // store static values into the array
            sstore(arrAddr, index)
            sstore(add(arrAddr, OBJECT_VALUE_OFFSET), value)
            // get the name size and pack it with flag value
            let nameSize := mload(name)
            sstore(add(arrAddr, OBJECT_NAME_FLAG_OFFSET), or(nameSize, shl(255, flag)))
            // store the name into the storage
            mstore(ptr, add(arrAddr, OBJECT_NAME_FLAG_OFFSET))
            let nameAddr := keccak256(ptr, 0x20)
            for {let mNamePtr := 0 let sNamePtr := 0} lt(mNamePtr, nameSize) {
                mNamePtr:= add(mNamePtr, 0x20) 
                sNamePtr := add(sNamePtr, 1)} {
                sstore(add(nameAddr, sNamePtr), mload(add(name, add(0x20, mNamePtr))))
            }
            // update the mapping value
            sstore(mappingAddr, add(arrSize, 1))
            // update the size of array
            sstore(ARRAY_SLOT, add(arrSize, 1))
            // update 0x40
            mstore(0x40, add(ptr, 0x40))
        }
    }

    function removeObject(uint256 index) external {
        assembly {
            // check that object has been already added
            let ptr := mload(0x40)
            mstore(ptr, MAPPING_SLOT)
            mstore(add(ptr, 0x20), index)
            let mappingAddr := keccak256(ptr, 0x40)
            let arrIndex := sload(mappingAddr)
            if iszero(arrIndex) { revert(0, 0) }
            // get the address of object in array
            mstore(ptr, ARRAY_SLOT)
            let arrSize := sload(ARRAY_SLOT)
            let swapAddr := add(keccak256(ptr, 0x20), mul(sub(arrSize, 1), OBJECT_SLOT_SIZE))
            // get address of name contents
            mstore(ptr, add(swapAddr, OBJECT_NAME_FLAG_OFFSET))
            let swapNameAddr := keccak256(ptr, 0x20)
            let swapNameSize := sload(add(swapAddr, OBJECT_NAME_FLAG_OFFSET))

            // if object to remove is not last, than swap it with last object
            if lt(arrIndex, arrSize) {
                mstore(ptr, ARRAY_SLOT)
                let arrAddr := add(keccak256(ptr, 0x20), mul(sub(arrIndex, 1), OBJECT_SLOT_SIZE))
                // swap static values with last element
                let swapIndex := sload(swapAddr)
                sstore(arrAddr, swapIndex)
                sstore(add(arrAddr, OBJECT_VALUE_OFFSET), sload(add(swapAddr, OBJECT_VALUE_OFFSET)))
                // swap name size and unpack them
                let arrNameSize := sload(add(arrAddr, OBJECT_NAME_FLAG_OFFSET))
                sstore(add(arrAddr, OBJECT_NAME_FLAG_OFFSET), swapNameSize)
                swapNameSize := and(swapNameSize, not(FLAG_MASK))
                arrNameSize := and(arrNameSize, not(FLAG_MASK))
                // swap name contents
                mstore(ptr, add(arrAddr, OBJECT_NAME_FLAG_OFFSET))
                let arrNameAddr := keccak256(ptr, 0x20)
                let namePtr := 0
                for {} lt(mul(namePtr, 0x20), swapNameSize) {namePtr:= add(namePtr, 1)} {
                    sstore(add(arrNameAddr, namePtr), sload(add(swapNameAddr, namePtr))) 
                }
                for {} lt(mul(namePtr, 0x20), arrNameSize) { namePtr := add(namePtr, 1)} {
                    sstore(add(arrNameAddr, namePtr), 0)
                }
                // update the mapping value of swap index
                mstore(ptr, MAPPING_SLOT)
                mstore(add(ptr, 0x20), swapIndex)
                let swapMappingAddr := keccak256(ptr, 0x40)
                sstore(swapMappingAddr, arrIndex)
            }
            // remove static values from swapAddress
            sstore(swapAddr, 0)
            sstore(add(swapAddr, OBJECT_VALUE_OFFSET), 0)
            // remove name size
            sstore(add(swapAddr, OBJECT_NAME_FLAG_OFFSET), 0)
            swapNameSize := and(swapNameSize, not(FLAG_MASK))
            // remove old name contents
            for {let namePtr := 0} lt(mul(namePtr, 0x20), swapNameSize) {namePtr:= add(namePtr, 1)} {
                sstore(add(swapNameAddr, namePtr), 0)
            }
            // update the mapping value of index
            sstore(mappingAddr, 0)
            // update the size of array
            sstore(0, sub(arrSize, 1))
            // update 0x40
            mstore(0x40, add(ptr, 0x40))
        }
    }

    function getObject(uint256 index) external view returns (uint256 retIndex, bool flag, int256 value, string memory name) {
        assembly {
            // check that object has been already added
            let ptr := mload(0x40)
            mstore(ptr, MAPPING_SLOT)
            mstore(add(ptr, 0x20), index)
            let mappingAddr := keccak256(ptr, 0x40)
            let arrIndex := sload(mappingAddr)
            if iszero(arrIndex) { revert(0, 0) }
            // get the address of object in array
            mstore(ptr, ARRAY_SLOT)
            let arrSize := sload(ARRAY_SLOT)
            let arrAddr := add(keccak256(ptr, 0x20), mul(sub(arrIndex, 1), OBJECT_SLOT_SIZE))
            // get static values
            retIndex := sload(arrAddr)
            value:= sload(add(arrAddr, OBJECT_VALUE_OFFSET))
            // unpack flag and name size
            let nameSizeWithFlag := sload(add(arrAddr, OBJECT_NAME_FLAG_OFFSET))
            let nameSize := and(nameSizeWithFlag, not(FLAG_MASK))
            flag := gt(and(nameSizeWithFlag, FLAG_MASK), 0)
            // get address of name contents
            mstore(ptr, add(arrAddr, OBJECT_NAME_FLAG_OFFSET))
            let nameAddr := keccak256(ptr, 0x20)
            mstore(ptr, nameSize)
            name := ptr
            // get name contents
            for {let namePtr := 0} lt(mul(namePtr, 0x20), nameSize) {namePtr := add(namePtr, 1) } {
                ptr := add(ptr, 0x20)
                mstore(ptr, sload(add(nameAddr, namePtr)))
            }
            mstore(0x40, add(ptr, 0x20))
        }
    }
    
    function getSize() external view returns (uint256 size) {
        assembly {
            size := sload(ARRAY_SLOT)
        }
    }
    function getIndices(uint256 from, uint256 to) external view returns (uint256[] memory indices) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, ARRAY_SLOT)
            let arrSize := sload(ARRAY_SLOT)
            if iszero(gt(arrSize, from)) { revert(0,0) }
            if lt(arrSize, to) { to:= arrSize }
            let arrAddr := keccak256(ptr, 0x20)
            // get static values
            indices := ptr
            mstore(ptr, sub(to, from))
            for {let i := from } lt(i, to) { i := add(i, 1) } {
                ptr := add(ptr, 0x20)
                mstore(ptr, sload(add(arrAddr, mul(i, OBJECT_SLOT_SIZE))))
            }
            mstore(0x40, add(ptr, 0x20))
        }
    }
}
