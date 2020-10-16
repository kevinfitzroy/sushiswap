const { expectRevert } = require('@openzeppelin/test-helpers');
const IssuerManager = artifacts.require('IssuerManagerV1');
const IssuerBTC = artifacts.require('IssuerBTC');
const Issuer = artifacts.require('Issuer');
const BtcMineToken = artifacts.require('BtcMineToken');
const MockERC20 = artifacts.require('MockERC20');
const BitcoinOracle = artifacts.require('BitcoinOracle');

const hostname = "minerswap.com";
const zero_address = "0x0000000000000000000000000000000000000000";
contract('Issuer and IssuerBTC', async ([boss, anyone, alice, bob]) => {
    beforeEach(async () => {
        this.mbtc = await MockERC20.new("mbtc", "mbtc", {from: anyone});
        this.issuerManager = await IssuerManager.new({from: alice});
        await this.issuerManager.updateBtcConfig('mbtc', this.mbtc.address, {from: alice});

        this.currencyToken = await MockERC20.new("usd", "usd", {from: anyone});
        this.btcOracle = await BitcoinOracle.new({from:anyone});
        this.issuerBtc = await IssuerBTC.at((await this.issuerManager.registIssuerBTC(hostname, {from: boss})).logs[2].args.issuerAddress);

        this.btcMineToken = await BtcMineToken.at((await this.issuerBtc.issue(
            "mbtc",
            18,
            this.currencyToken.address,
            this.btcOracle.address,
            23,//buy price
            35,//buy total supply
            100,//pre mint number
            3,//time
            4,
            5,
            6,
            {from: boss}
        )).logs[1].args.tokenAddress);
    });

    it('should deployed successfully', async () => {
        assert.equal((await this.issuerBtc.getMineToken((await this.issuerBtc.SYMBOL()).valueOf() + "1")).valueOf(), this.btcMineToken.address);
        assert.equal((await this.btcMineToken.symbol()).valueOf(), (await this.issuerBtc.SYMBOL()).valueOf() + "1");
    });

    it('should owner is correct',  async () => {
        assert.equal(await this.btcMineToken.owner(), this.issuerBtc.address);
    });

    it('should uintToString work correctly', async () => {
        assert.equal((await this.issuerBtc.uintToString(2324)).valueOf(), "2324");
    });

});