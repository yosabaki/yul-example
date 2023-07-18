# Project with Example Yul Contracts

This project serves to demonstrate how basic smart contract logic can be implemented using low-level Yul code. Yul is an intermediate language for Ethereum, which can be used to perform lower level operations, offering more control and can potentially enable efficient contract code.

## Smart Contract Examples

This repository consists of a set of example Yul contracts, described below:

### ObjectStorage
The ObjectStorage contract is designed to store basic object structures into an array.

#### Methods

1. `addObject(uint256 index, boolean flag, uint256 value, string memory name)`: This function adds an object that contains `uint256 index`, `boolean flag`, `uint256 value` and `string memory name` to an array. It also maps the object value with index into a `mapping`. `boolean flag` value is packed with a length of `name` variable to show the example of how `Yul` can provide gas savings and storage optimizations.

2. `getObject(uint256 index)`: This function returns an object value with a specified index.

3. `removeObject(uint256 index)`: This function removes the object with the specified index by swapping the object in the array with the last object.

4. `getIndices(uint256 from, uint256 to)`: This function returns the values of indices that are stored in the specified range of the array.

5. `getSize()`: This function returns the size of the array and correspondingly, the number of objects currently stored.

## Setting up

To get started with the project, just run tests and see the results:

```shell
npx hardhat test
```