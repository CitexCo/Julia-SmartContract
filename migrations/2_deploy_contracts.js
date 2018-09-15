var BalanceSheet = artifacts.require("BalanceSheet");
var AllowanceSheet = artifacts.require("AllowanceSheet");
var RefferalRewardSheet = artifacts.require("RefferalRewardSheet");
var BurnQueue = artifacts.require('BurnQueue');
var TrueUSD = artifacts.require("TrueUSD");
var Registry = artifacts.require("Registry")

const fs = require('fs');

module.exports = async function (deployer) {
    await deployer;

    // AllowanceSheet 
    // balancesheet
    // burnque 
    // trueUSD
    // registry

    // setRegistry (registry)

    console.log("Create the small contracts that TrueUSD depends on...")
    const balances = await BalanceSheet.new()
    console.log("balanceSheet Address: ", balances.address)
    const allowances = await AllowanceSheet.new()
    console.log("allowanceSheet Address: ", allowances.address)
    const refferalRewardSheet = await RefferalRewardSheet.new()
    console.log("euroBalanceSheet Address: ", balances.address)
    const burnqueue = await BurnQueue.new()
    console.log("burnqueue Address: ", allowances.address)
    const registry = await Registry.new()
    console.log("registry Address: ", allowances.address)

    console.log("Create and configure TrueUSD...")
    const trueUSD = await TrueUSD.new()
    console.log("trueUSD Address: ", trueUSD.address)
    await balances.transferOwnership(trueUSD.address)
    await allowances.transferOwnership(trueUSD.address)
    await refferalRewardSheet.transferOwnership(trueUSD.address)
    await burnqueue.transferOwnership(trueUSD.address)
    await registry.transferOwnership(trueUSD.address)
    await trueUSD.setBalanceSheet(balances.address)
    await trueUSD.setRefferalRewardSheet(refferalRewardSheet.address)
    await trueUSD.setAllowanceSheet(allowances.address)
    await trueUSD.setBurnQueue(burnqueue.address)
    await trueUSD.setRegistry(registry.address)

    const contracts = {
        trueUSD: {
            abi: trueUSD.abi,
            address: trueUSD.address
        },
        registry: {
            abi: registry.abi,
            address: registry.address
        }
    }
    fs.writeFileSync('contracts.json', JSON.stringify(contracts))

    console.log("Deployment successful")
};
