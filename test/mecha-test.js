const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployMockContract } = require('ethereum-waffle')
const hardhat = require("hardhat");

describe("mecha_tests", function () {

    let greeter;

    let timestamp;

    let w2;

    before(async () => {
        [wallet, wallet2] = await hardhat.ethers.getSigners()
        w2 = wallet2;
        const MechaGnome = await ethers.getContractFactory("MechaGnomesNFT");
        greeter = await MechaGnome.deploy("MECHA", "MECH", "", ethers.utils.parseEther("0.1"));
    })

    describe("setMintPrice()", function () {
        it("Should update the mintPrice", async function () {
            await greeter.setMintPrice(ethers.utils.parseEther("0.2"));
            expect(await greeter.getMintPrice()).to.equal(ethers.utils.parseEther("0.2"));
        });
    });

    describe("mint()", function () {
        it("Should fail minting", async function () {
            await expect(greeter.mint(10, { value: ethers.utils.parseEther("1.1") })).to.be.revertedWith("validation_error:canMint:no_active_sale");
        });
    });

    describe("startWhitelist()", function () {
        it("Should start whitelist sale", async function () {
            let blockNum = await ethers.provider.getBlockNumber();
            let block = await ethers.provider.getBlock(blockNum);
            timestamp = block.timestamp;
            await greeter.startWhitelist(10000, 100)
        });
        it("Should have active whitelist sale", async function () {
            expect(await greeter.isWhitelistSale()).to.be.true;
        });
        it("Should have duration greater than 0", async function() {
            expect(await greeter.getRemainingSaleDuration()).to.not.equal("0");
        })
        it("Should fail whitelist minting", async function () {
            await expect(greeter.mint(0, { value: ethers.utils.parseEther("1") })).to.be.revertedWith("validation_error:canMint:amount_leq_zero");
        });
        it("Should fail whitelist minting", async function () {
            await expect(greeter.mint(99, { value: ethers.utils.parseEther("8") })).to.be.revertedWith("validation_error:mint:invalid_ether_amount");
            await expect(greeter.mint(101, { value: ethers.utils.parseEther("22") })).to.be.revertedWith("validation_error:canMint:exceeds_whitelistReserveCount");
            await expect(greeter.mint(7600, { value: ethers.utils.parseEther("70") })).to.be.revertedWith("validation_error:canMint:exceeds_total_supply");
        });
        it("Should pass whitelist minting", async function () {
            await greeter.mint(1, { value: ethers.utils.parseEther("0.2") });
        });
    });

    describe("startPublicSale()", function () {
        it("Should start public sale", async function () {
            await greeter.startPublicSale(10000)
        });
        it("Should have active public sale", async function () {
            expect(await greeter.isPublicSale()).to.true
        });
        it("Should have duration greater than 0", async function() {
            expect(await greeter.getRemainingSaleDuration()).to.not.equal("0");
        })
        it("Should fail public sale minting", async function () {
            await expect(greeter.mint(0, { value: ethers.utils.parseEther("11") })).to.be.revertedWith("validation_error:canMint:amount_leq_zero");
        });
        it("Should fail public sale minting", async function () {
            await expect(greeter.mint(1, { value: ethers.utils.parseEther("0") })).to.be.revertedWith("validation_error:mint:invalid_ether_amount");
            await expect(greeter.mint(7600, { value: ethers.utils.parseEther("11") })).to.be.revertedWith("validation_error:canMint:exceeds_total_supply");
        });
        /*it("Should pass public sale minting", async function () {
            let a  = await greeter.getRemainingMintable()
            console.log(a.toString())
            expect(await greeter.mint(100, { value: ethers.utils.parseEther("20") })).to.ok;
            let remaining = greeter.getRemainingMintable();
            await greeter.mint(remaining, { gasLimit: 30000000, value: ethers.utils.parseEther(String(a * 0.2)) });
        });*/
    });

    describe("withdraw()", function () {
        it("Should fail not owner", async function () {
            await expect(greeter.connect(wallet2).withdraw()).to.be.revertedWith("Ownable: caller is not the owner");
        });
        it("Should pass as owner", async function () {
            expect(await greeter.withdraw()).ok;
        });
    });
    //expect(await greeter.getMintPrice()).to.equal(ethers.utils.parseEther("0.2"));

})