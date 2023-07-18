import { ethers } from "hardhat";

async function main() {
  const ObjectStorage = await ethers.getContractFactory("ObjectStorage");
  const objectStorage = await ObjectStorage.deploy();

  await objectStorage.deployed();

  console.log(`Yul ObjectStorage is deployed to ${objectStorage.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
