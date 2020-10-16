const { expectRevert } = require('@openzeppelin/test-helpers');
const IssuerManager = artifacts.require('IssuerManagerV1');
const IssuerBTC = artifacts.require('IssuerBTC');
const MockMigrator = artifacts.require('MockMigrator');
const MineTokenManager = artifacts.require('MineTokenManager');

const hostname = "minerswap.com";
const zero_address = "0x0000000000000000000000000000000000000000";
contract('IssuerManager', async ([boss, anyone, alice, bob]) => {
    beforeEach(async () => {
        this.issuerManager = await IssuerManager.new((await MineTokenManager.new({from:boss})).address, {from: boss});
        this.issuerBtc = await IssuerBTC.at((await this.issuerManager.registIssuerBTC(hostname, {from: alice})).logs[2].args.issuerAddress);
    });

    it('should regist successfully', async () => {
        assert.equal((await this.issuerManager.getIssuerAddress(hostname)).valueOf(), this.issuerBtc.address);
    });

    it('should not repeat registration', async () => {
        await expectRevert(
            this.issuerManager.registIssuerBTC(hostname, {from: anyone}),
            "IssuerManager: hostname already exist!"
        );
        await this.issuerManager.removeIssuer(hostname, {from: boss});
        await this.issuerManager.registIssuerBTC(hostname, {from: anyone});

        await expectRevert(
            this.issuerManager.addIssuer(hostname, this.issuerBtc.address, {from: boss}),
            "IssuerManager: hostname already exist!"
        );
        await this.issuerManager.removeIssuer(hostname, {from: boss});
        await this.issuerManager.addIssuer(hostname, this.issuerBtc.address, {from: boss});
    });

    it('should fail if you are not owner', async () => {
        await expectRevert(
            this.issuerManager.addIssuer("xxx", bob, {from: anyone}),
            'Ownable: caller is not the owner'
        );
        await expectRevert(
            this.issuerManager.removeIssuer("xxx", {from: anyone}),
            'Ownable: caller is not the owner'
        );
    });

    it('should have correct owner for issuer', async () => {
        assert.equal((await this.issuerBtc.owner()).valueOf(), alice);
    });

    it('should migrator work correctly', async () => {
        this.mockMigrator = await MockMigrator.new({ from: anyone});
        assert.equal(zero_address, await this.issuerManager.migrator());
        await expectRevert(
            this.issuerManager.setMigrator(this.mockMigrator.address, {from: bob}),
            'Ownable: caller is not the owner',
        );
        await this.issuerManager.setMigrator(this.mockMigrator.address, {from: boss});
        assert.equal(this.mockMigrator.address, await this.issuerManager.migrator());
    });
});
