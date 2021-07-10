const BUC = artifacts.require("BUC");

contract("Test for deployement", async accounts => {
    it("should put 1000000000 BUC in the first account", async() => {
        const instance = await BUC.deployed();
        const balance = await instance.balanceOf.call(accounts[0]);
        assert.equal(balance.valueOf() / Math.pow(10, 18), 1000000000);
    });

    // it("checking total supply", async accounts => {
    //     const instance = await BUC.deployed();
    //     const supply = await instance.totalSupply.call();
    //     assert.equal(supply / Math.pow(10, 18), 1000000000)
    // });

});  
    