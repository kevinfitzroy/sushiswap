// 注意，如果使用Ganache作为测试环境，必须在设置->CHAIN->HARDFORK中设为Istanbul（含）之后的阶段
// 因为BtcMineToken包含了chainid的获取代码，而EIP-1344（添加了ChainID操作码）是在Istanbul阶段实施的

const { expectRevert, time } = require('@openzeppelin/test-helpers');
const BtcMineToken = artifacts.require('BtcMineToken');
const MockERC20 = artifacts.require('MockERC20');
const BitcoinOracle = artifacts.require('BitcoinOracle');

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

contract('BtcMineToken', ([tokenOwner, btcOwner, usdtOwner, oracleOwner, bob, alice]) => {
    beforeEach(async () => {
        this.btc = await MockERC20.new('Wrapper bitcoin', 'WBTC', { from: btcOwner });
        this.usdt = await MockERC20.new('Tether USD', 'USDT', { from: usdtOwner });
        this.oracle = await BitcoinOracle.new({ from: oracleOwner });
        this.mineToken = await BtcMineToken.new('Huobi mine btc 1', 'HB_BTC_1', { from: tokenOwner });
        this.btime = (await web3.eth.getBlock('latest')).timestamp;
    });

    context('buy token', () => {
        beforeEach(async () => {
            let _buyPrice = 2;
            let _buyTotalSupply = 100;
            let _buyStartTime = this.btime + 5;
            let _buyEndTime = this.btime + 10;
            let _startTime = this.btime + 15;
            let _endTime = this.btime + 20;
            let _comment = "abcde";
            await this.mineToken.initialize(this.btc.address,
                18,
                this.usdt.address,
                this.oracle.address,
                _buyPrice,
                _buyTotalSupply,
                _buyStartTime,
                _buyEndTime,
                _startTime,
                _endTime,
                _comment, {from: tokenOwner});

            await this.usdt.mint(bob, 100000);
        });

        it('should fail if buy time not start', async () => {
            await expectRevert(
                this.mineToken.buy(1, { from: bob }),
                'Buy not start',
            );
        });

        it('should fail if buy time ended', async () => {
            await sleep(12000);
            await expectRevert(
                this.mineToken.buy(1, { from: bob }),
                'Buy ended',
            );
        });

        it('should buy success', async () => {
            await sleep(6000);
            let v = 2 * 1;
            await this.usdt.approve(this.mineToken.address, v, { from: bob });
            await this.mineToken.buy(1, { from: bob });
            let bobMineTokenBalance = await this.mineToken.balanceOf(bob);
            assert.equal(1, bobMineTokenBalance);
        });

        it('should buy faile if total buy supply capped', async () => {
            await sleep(6000);
            let v = 2 * 80;
            await this.usdt.approve(this.mineToken.address, v, { from: bob });
            await this.mineToken.buy(80, { from: bob });
            let bobMineTokenBalance = await this.mineToken.balanceOf(bob);
            assert.equal(80, bobMineTokenBalance);

            await expectRevert(
                this.mineToken.buy(21, { from: bob }),
                'Buy supply capped',
            );
        });
    })

    context('transfer token', () => {
        beforeEach(async () => {
            let _buyPrice = 2;
            let _buyTotalSupply = 100;
            let _buyStartTime = this.btime + 5;
            let _buyEndTime = this.btime + 6;
            let _startTime = this.btime + 7;
            let _endTime = this.btime + 15;
            let _comment = "abcde";
            await this.mineToken.initialize(this.btc.address,
                18,
                this.usdt.address,
                this.oracle.address,
                _buyPrice,
                _buyTotalSupply,
                _buyStartTime,
                _buyEndTime,
                _startTime,
                _endTime,
                _comment, {from: tokenOwner});

            await this.oracle.addBlockInfo(this.btime, 3, {from: oracleOwner});
            await this.mineToken.mint(alice, 2000, {from: tokenOwner});
            await this.btc.mint(this.mineToken.address, 10000, {from: btcOwner});
        });

        it('should not produce mine reward if time < startTime', async () => {
            await this.mineToken.transfer(bob, 100, {from: alice});
            let aliceInfo = await this.mineToken.minerInfo(alice);
            let bobInfo = await this.mineToken.minerInfo(bob);
            assert.equal(0, aliceInfo.nextRewardTime);
            assert.equal(0, aliceInfo.accReward);
            assert.equal(0, bobInfo.nextRewardTime);
            assert.equal(0, bobInfo.accReward);
        });

        it('should produce mine reward if time >= startTime', async () => {
            await sleep(8000);
            await this.mineToken.transfer(bob, 100, {from: alice});
            let aliceInfo = await this.mineToken.minerInfo(alice);
            let bobInfo = await this.mineToken.minerInfo(bob);
            let _bt = (await web3.eth.getBlock('latest')).timestamp;
            let startTime = await this.mineToken.startTime();
            let aliceReward = (_bt - startTime) * 2000 * 3;
            assert.equal(_bt, aliceInfo.nextRewardTime);
            assert.equal(aliceReward, aliceInfo.accReward);
            assert.equal(_bt, bobInfo.nextRewardTime);
            assert.equal(0, bobInfo.accReward);

            await sleep(2000);
            await this.mineToken.transfer(bob, 100, {from: alice});
            aliceInfo = await this.mineToken.minerInfo(alice);
            bobInfo = await this.mineToken.minerInfo(bob);
            let _bt1 = (await web3.eth.getBlock('latest')).timestamp;
            let aliceReward1 = aliceReward + (_bt1 - _bt) * 1900 * 3;
            let bobReward1 = (_bt1 - _bt) * 100 * 3;
            assert.equal(_bt1, aliceInfo.nextRewardTime);
            assert.equal(aliceReward1, aliceInfo.accReward);
            assert.equal(_bt1, bobInfo.nextRewardTime);
            assert.equal(bobReward1, bobInfo.accReward);

            await sleep(7000);
            await this.mineToken.transfer(alice, 50, {from: bob});
            aliceInfo = await this.mineToken.minerInfo(alice);
            bobInfo = await this.mineToken.minerInfo(bob);
            let _bt2 = (await web3.eth.getBlock('latest')).timestamp;
            let endTime = await this.mineToken.endTime();
            let aliceReward2 = aliceReward1 + (endTime - _bt1) * 1800 * 3;
            let bobReward2 = bobReward1 + (endTime - _bt1) * 200 * 3;
            assert.equal(_bt2, aliceInfo.nextRewardTime);
            assert.equal(aliceReward2, aliceInfo.accReward);
            assert.equal(_bt2, bobInfo.nextRewardTime);
            assert.equal(bobReward2, bobInfo.accReward);
        });

        it('harvest should success', async () => {
            await sleep(8000);
            await this.mineToken.transfer(bob, 100, {from: alice});
            let aliceInfo = await this.mineToken.minerInfo(alice);
            let bobInfo = await this.mineToken.minerInfo(bob);
            let _bt = (await web3.eth.getBlock('latest')).timestamp;
            let startTime = await this.mineToken.startTime();
            let aliceReward = (_bt - startTime) * 2000 * 3;
            assert.equal(_bt, aliceInfo.nextRewardTime);
            assert.equal(aliceReward, aliceInfo.accReward);
            assert.equal(_bt, bobInfo.nextRewardTime);
            assert.equal(0, bobInfo.accReward);

            let aliceBtcBalance = await this.btc.balanceOf(alice);
            assert.equal(0, aliceBtcBalance);
            await this.mineToken.harvest(50, {from: alice});
            aliceBtcBalance = await this.btc.balanceOf(alice);
            assert.equal(50, aliceBtcBalance);
            aliceInfo = await this.mineToken.minerInfo(alice);
            assert.equal(aliceReward - 50, aliceInfo.accReward);
        });
    })
});
