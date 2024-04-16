const { ethers } = require("hardhat");

const { run } = require("hardhat");

async function verify(address, constructorArguments) {
    console.log(`verify  ${address} with arguments ${constructorArguments.join(',')}`)
    await run("verify:verify", {
        address,
        constructorArguments
    })
}

async function main() {
    const StakingContract = await ethers.getContractFactory(
        "TestingContract"
    );
    console.log("Deploying Contract...");

    const contract = await upgrades.deployProxy(StakingContract, [], {
        initializer: "initialize",
        kind: "uups",
    });
    await contract.waitForDeployment();
    console.log("Contract deployed to:", contract.target);

    await new Promise(resolve => setTimeout(resolve, 15000));
    verify(contract.target, [])
    // verify("0x458c36768A5EEe9103D2c5E426c404Ec8c6303aa", [])

}

main();
