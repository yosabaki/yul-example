import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

type StoredObject = [BigNumber, boolean, BigNumber, string] & {
  retIndex: BigNumber;
  flag: boolean;
  value: BigNumber;
  name: string;
}

describe("ObjectStorage", function () {
  async function deployObjectStorageFixture() {
    const [account] = await ethers.getSigners();

    const ObjectStorage = await ethers.getContractFactory("ObjectStorage");
    const objectStorage = await ObjectStorage.deploy();

    return { objectStorage, account };
  }

  function checkObject(object: StoredObject, index: number, flag: boolean, value: number, name: string) {
    expect(object.retIndex).to.be.equal(BigNumber.from(index))
    expect(object.flag).to.be.equal(flag)
    expect(object.value).to.be.equal(BigNumber.from(value))
    expect(object.name).to.be.equal(name)
  }

  function checkIndices(actualIndices: BigNumber[], indices: number[]) {
    expect(actualIndices.map(x => Number(x))).to.be.eql(indices)
  }

  describe("ObjectStorage", function () {
    describe("addObject", function () {
      it("Should add object properly", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        expect(await objectStorage.getSize()).to.be.equal(1)
        checkIndices(await objectStorage.getIndices(0, 1), [0])
        const object = await objectStorage.getObject(0)
        checkObject(object, 0, true, 100, "asdf")
      });

      it("Should add multiple objects properly", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        await objectStorage.addObject(1, true, 101, "asdfg")

        expect(await objectStorage.getSize()).to.be.equal(2)
        checkIndices(await objectStorage.getIndices(0, 2), [0, 1])
        checkObject(await objectStorage.getObject(0), 0, true, 100, "asdf")
        checkObject(await objectStorage.getObject(1), 1, true, 101, "asdfg")
      });

      it("Should revert on non-existing object", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        await expect(objectStorage.getObject(1)).to.be.reverted
      });
    });

    describe("removeObject", function () {
      it("Should remove object properly", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        await objectStorage.removeObject(0)
        expect(await objectStorage.getSize()).to.be.equal(0)
        await expect(objectStorage.getIndices(0, 0)).to.be.reverted
        await expect(objectStorage.getObject(0)).to.be.reverted
      });

      it("Should remove last object properly", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        await objectStorage.addObject(1, true, 101, "asdfg")

        await objectStorage.removeObject(1)
        expect(await objectStorage.getSize()).to.be.equal(1)
        checkIndices(await objectStorage.getIndices(0, 1), [0])
        await expect(objectStorage.getObject(1)).to.be.reverted
        checkObject(await objectStorage.getObject(0), 0, true, 100, "asdf")
      });

      it("Should remove first object properly", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        await objectStorage.addObject(1, true, 101, "asdfg")

        await objectStorage.removeObject(0)
        expect(await objectStorage.getSize()).to.be.equal(1)
        checkIndices(await objectStorage.getIndices(0, 1), [1])
        await expect(objectStorage.getObject(0)).to.be.reverted
        checkObject(await objectStorage.getObject(1), 1, true, 101, "asdfg")
      });

      it("Should remove object in the middle properly", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        await objectStorage.addObject(1, true, 101, "asdfg")
        await objectStorage.addObject(2, true, 102, "asdfge")
        await objectStorage.addObject(3, true, 103, "asdfgeh")



        await objectStorage.removeObject(1)
        expect(await objectStorage.getSize()).to.be.equal(3)
        checkIndices(await objectStorage.getIndices(0, 3), [0, 3, 2])
        await expect(objectStorage.getObject(1)).to.be.reverted
        checkObject(await objectStorage.getObject(0), 0, true, 100, "asdf")
        checkObject(await objectStorage.getObject(2), 2, true, 102, "asdfge")
        checkObject(await objectStorage.getObject(3), 3, true, 103, "asdfgeh")

      });

      it("Should revert on non-existing object", async function () {
        const { objectStorage, account } = await loadFixture(deployObjectStorageFixture);
        
        await objectStorage.addObject(0, true, 100, "asdf")
        await expect(objectStorage.removeObject(1)).to.be.reverted
      });
    });
  });
});
