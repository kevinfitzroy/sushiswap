const { expectRevert, time } = require('@openzeppelin/test-helpers');
const BitcoinMinerERC20 = artifacts.require('BitcoinMinerERC20');
const MockERC20 = artifacts.require('MockERC20');
const MockBitcoinOracle = artifacts.require('MockBitcoinOracle');

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

contract('BitcoinMinerERC20', ([minerERC20Admin, btcAdmin, oracleAdmin, bob, alice]) => {
    beforeEach(async () => {
        this.btc = await MockERC20.new('Wrapper bitcoin', 'WBTC', '10000000000', { from: btcAdmin });
        this.oracle = await MockBitcoinOracle.new(1, { from: oracleAdmin });
    });

    it('should mine all token at initialization', async () => {
        this.minerERC20 = await BitcoinMinerERC20.new('Huobi mine btc 1', 'HB_BTC_1', '10000', this.btc.address, this.oracle.address, 5000, { from: minerERC20Admin });
        const btc = await this.minerERC20.btc();
        const btcOracle = await this.minerERC20.btcOracle();
        const totalSupply = await this.minerERC20.totalSupply();
        const minerERC20AdminAmount = await this.minerERC20.balanceOf(minerERC20Admin);
        assert.equal(btc.valueOf(), this.btc.address);
        assert.equal(btcOracle.valueOf(), this.oracle.address);
        assert.equal(totalSupply.valueOf(), 10000);
        assert.equal(minerERC20AdminAmount.valueOf(), 10000);
    });

    it('should not produce btc reward when block number not in [1, end)', async () => {
        const blockHeight = await web3.eth.getBlockNumber();
        this.minerERC20 = await BitcoinMinerERC20.new('Huobi mine btc 1', 'HB_BTC_1', '10000', this.btc.address, this.oracle.address, blockHeight, { from: minerERC20Admin });
        var minerERC20AdminShare = await this.minerERC20.balanceOf(minerERC20Admin);
        assert.equal(minerERC20AdminShare.valueOf(), 10000);

        await this.btc.transfer(this.minerERC20.address, 2000000, { from: btcAdmin });
        const minerERC20BtcAmount = await this.btc.balanceOf(this.minerERC20.address);
        assert.equal(minerERC20BtcAmount.valueOf(), 2000000);

        var bobBtcAmount = await this.btc.balanceOf(bob);
        var minerERC20AdminBtcAmount = await this.btc.balanceOf(minerERC20Admin);
        assert.equal(bobBtcAmount.valueOf(), 0);
        assert.equal(minerERC20AdminBtcAmount.valueOf(), 0);

        await this.minerERC20.transfer(bob, 50, { from: minerERC20Admin });
        bobBtcAmount = await this.btc.balanceOf(bob);
        minerERC20AdminBtcAmount = await this.btc.balanceOf(minerERC20Admin);
        assert.equal(bobBtcAmount.valueOf(), 0);
        assert.equal(minerERC20AdminBtcAmount.valueOf(), 0);
    });

    it('should produce btc reward when block number in [1, end)', async () => {
        const blockHeight = await web3.eth.getBlockNumber();
        this.minerERC20 = await BitcoinMinerERC20.new('Huobi mine btc 1', 'HB_BTC_1', '10000', this.btc.address, this.oracle.address, blockHeight + 1000, { from: minerERC20Admin });
        var minerERC20AdminShare = await this.minerERC20.balanceOf(minerERC20Admin);
        assert.equal(minerERC20AdminShare.valueOf(), 10000);

        // miner pool has 2000000 btc
        await this.btc.transfer(this.minerERC20.address, 2000000, { from: btcAdmin });
        const minerERC20BtcAmount = await this.btc.balanceOf(this.minerERC20.address);
        assert.equal(minerERC20BtcAmount.valueOf(), 2000000);

        var minerERC20AdminBtcBalance = 0;
        var bobBtcBalance = 0;
        var aliceBtcBalance = 0;

        // miner pool admin [btc: 0, share: 10000]
        // bob [btc: 0, share: 0]
        var bobBtcAmount = await this.btc.balanceOf(bob);
        var minerERC20AdminBtcAmount = await this.btc.balanceOf(minerERC20Admin);
        assert.equal(bobBtcAmount.valueOf(), 0);
        assert.equal(minerERC20AdminBtcAmount.valueOf(), 0);
        minerERC20AdminBtcAmount = await this.btc.balanceOf(minerERC20Admin);

        var blockTimeBeforeTransfer = (await web3.eth.getBlock('latest')).timestamp;
        await sleep(2000);

        // transfer 50 share from miner pool admin to bob, miner pool admin receive 20000 btc earn
        // miner pool admin [btc: 20000, share: 9950]
        // bob [btc: 0, share: 50]
        await this.minerERC20.transfer(bob, 50, { from: minerERC20Admin });
        minerERC20AdminShare = await this.minerERC20.balanceOf(minerERC20Admin);    
        assert.equal(minerERC20AdminShare.valueOf(), 9950);
        var bobShare = await this.minerERC20.balanceOf(bob); 
        assert.equal(bobShare.valueOf(), 50);
        var blockTimeAfterTransfer = (await web3.eth.getBlock('latest')).timestamp;

        const dt0 = (blockTimeAfterTransfer - blockTimeBeforeTransfer);
        var minerERC20AdminBtcReward = 10000 * 1 * dt0;
        minerERC20AdminBtcBalance += minerERC20AdminBtcReward;
        minerERC20AdminBtcAmount = await this.btc.balanceOf(minerERC20Admin);
        bobBtcAmount = await this.btc.balanceOf(bob);
        assert.equal(minerERC20AdminBtcAmount.valueOf(), minerERC20AdminBtcReward);
        assert.equal(bobBtcAmount.valueOf(), 0);


        // transfer 10 share from bob to alice, bob receive 100 btc earn
        // bob [btc: 100, share: 40]
        // alice [btc: 0, share: 10]
        blockTimeBeforeTransfer = (await web3.eth.getBlock('latest')).timestamp;
        await sleep(2000);
        await this.minerERC20.transfer(alice, 10, { from: bob });
        blockTimeAfterTransfer = (await web3.eth.getBlock('latest')).timestamp;
        const dt1 = (blockTimeAfterTransfer - blockTimeBeforeTransfer);
        var bobBtcReward = 50 * 1 * dt1
        bobBtcBalance += bobBtcReward;
        bobBtcAmount = await this.btc.balanceOf(bob);
        var aliceBtcAmount = await this.btc.balanceOf(alice);
        assert.equal(bobBtcAmount.valueOf(), bobBtcReward);
        assert.equal(aliceBtcAmount.valueOf(), 0);

        // transfer 50 share from admin to alice, admin receive 19900 btc earn, alice receive 20 btc earn
        // miner pool admin [btc: 39900, share: 9900]
        // alice [btc: 20, share: 60]
        blockTimeBeforeTransfer = (await web3.eth.getBlock('latest')).timestamp;
        await sleep(2000);
        await this.minerERC20.transfer(alice, 10, { from: minerERC20Admin });
        blockTimeAfterTransfer = (await web3.eth.getBlock('latest')).timestamp;
        const dt2 = (blockTimeAfterTransfer - blockTimeBeforeTransfer);
        minerERC20AdminBtcReward = 9950 * 1 * (dt2 + dt1);
        var aliceBtcReward = 10 * 1 * dt2;
        minerERC20AdminBtcBalance += minerERC20AdminBtcReward;
        aliceBtcBalance += aliceBtcReward;
        minerERC20AdminBtcAmount = await this.btc.balanceOf(minerERC20Admin);
        aliceBtcAmount = await this.btc.balanceOf(alice);
        assert.equal(minerERC20AdminBtcAmount.valueOf(), minerERC20AdminBtcBalance);
        assert.equal(aliceBtcAmount.valueOf(), aliceBtcBalance);
    });

});
