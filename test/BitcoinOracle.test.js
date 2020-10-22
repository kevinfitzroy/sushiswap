const { expectRevert } = require('@openzeppelin/test-helpers');
const BitcoinOracle = artifacts.require('BitcoinOracle');

contract('BitcoinOracle', ([a, o0, o1, o2, o3, o4, b]) => {
    beforeEach(async () => {
        this.oracle = await BitcoinOracle.new([o0,o1,o2,o3,o4], 3, { from: a });
    });

    it('check if owner', async () => {
        let m_required = await this.oracle.m_required();
        assert.equal(3, m_required);
        let m_numOwners = await this.oracle.m_numOwners();
        assert.equal(6, m_numOwners);
        let isOwner = await this.oracle.isOwner(o0);
        assert.equal(true, isOwner);
        isOwner = await this.oracle.isOwner(o4);
        assert.equal(true, isOwner);
        isOwner = await this.oracle.isOwner(a);
        assert.equal(true, isOwner);
        isOwner = await this.oracle.isOwner(b);
        assert.equal(false, isOwner);
    });

    it('add block info', async () => {
        let _timestamp = 1;
        let _rewardPerTPerSecond = 20;
        let _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000ca8e9f9543db1e9dd2125f2fa709edf0a1a0f1bf69cd1");
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});
        let info = await this.oracle.blockInfos(0);
        assert.equal(_timestamp, info.timestamp);
        
        _timestamp = 0;
        _rewardPerTPerSecond = 18;
        _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000021e34608c35caa2cc1a1efc49bb5f0ffdb429d82293b");
        await expectRevert(
            this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0}),
            'invalid timestamp',
        );

        _timestamp = 2;
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: a});
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o4});
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o2});
        info = await this.oracle.blockInfos(1);
        assert.equal(_timestamp, info.timestamp);
    });


    it('update latest block info', async () => {
        let _timestamp = 1;
        let _rewardPerTPerSecond = 20;
        let _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000ca8e9f9543db1e9dd2125f2fa709edf0a1a0f1bf69cd1");
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});
        let info = await this.oracle.blockInfos(0);
        assert.equal(_timestamp, info.timestamp);
        
        _timestamp = 3;
        _rewardPerTPerSecond = 18;
        await this.oracle.updateLatestBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: a});
        await this.oracle.updateLatestBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o4});
        await this.oracle.updateLatestBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o2});
        info = await this.oracle.blockInfos(0);
        assert.equal(_timestamp, info.timestamp);
        assert.equal(_rewardPerTPerSecond, info.rewardPerTPerSecond);
    });

    it('cal reward with no block info', async () => {
        let _h = 100;
        let _startTime = 10;
        let _endTime = 25;
        let _decimals = 18;
        let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
        assert.equal(0, reward);
    });

    context('cal reward with one block info', () => {
        beforeEach(async () => {
            let _timestamp = 100;
            let _rewardPerTPerSecond = 20;
            let _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000ca8e9f9543db1e9dd2125f2fa709edf0a1a0f1bf69cd1");
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});
        });

        it('lower boundary', async () => {
            let _h = 3;
            let _startTime = 10;
            let _endTime = 100;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            assert.equal(0, reward);
        });

        it('upper boundary', async () => {
            let _h = 3;
            let _startTime = 110;
            let _endTime = 130;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = 20 * 3 * (130 - 110);
            assert.equal(expectReward, reward);
        });

        it('inner boundary 0', async () => {
            let _h = 3;
            let _startTime = 99;
            let _endTime = 130;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = 20 * 3 * (130 - 100);
            assert.equal(expectReward, reward);
        });

        it('inner boundary 1', async () => {
            let _h = 3;
            let _startTime = 100;
            let _endTime = 130;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = 20 * 3 * (130 - 100);
            assert.equal(expectReward, reward);
        });
    })

    context('cal reward with more then one block info', () => {
        beforeEach(async () => {
            let _timestamp = 100;
            let _rewardPerTPerSecond = 20;
            let _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000ca8e9f9543db1e9dd2125f2fa709edf0a1a0f1bf69cd1");
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});

            _timestamp = 200;
            _rewardPerTPerSecond = 22;
            _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000021e34608c35caa2cc1a1efc49bb5f0ffdb429d82293b");
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});

            _timestamp = 310;
            _rewardPerTPerSecond = 18;
            _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000867bec0b7931295bfdaf1238e7e642b7af251b7c21d2f");
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});

            _timestamp = 380;
            _rewardPerTPerSecond = 25;
            _blockHeaderHash = web3.utils.hexToBytes("0x00000000000000000007ef0d33274c1eb34d556875edd82fd3850334d8c1907e");
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});

            _timestamp = 550;
            _rewardPerTPerSecond = 15;
            _blockHeaderHash = web3.utils.hexToBytes("0x0000000000000000000adffe509a7339dde1a8868ae0430a8397c63133916413");
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o0});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o1});
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, _blockHeaderHash, {from: o3});
        });

        it('lower boundary', async () => {
            let _h = 3;
            let _startTime = 10;
            let _endTime = 100;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            assert.equal(0, reward);
        });

        it('upper boundary', async () => {
            let _h = 3;
            let _startTime = 550;
            let _endTime = 600;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = 15 * 3 * (600 - 550);
            assert.equal(expectReward, reward);
        });

        it('inner boundary 0', async () => {
            let _h = 3;
            let _startTime = 400;
            let _endTime = 600;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = (15 * (600 - 550) + 25 * (550 - 400)) * 3;
            assert.equal(expectReward, reward);
        });

        it('inner boundary 1', async () => {
            let _h = 3;
            let _startTime = 210;
            let _endTime = 600;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = (15 * (600 - 550) + 25 * (550 - 380) + 18 * (380 - 310) + 22 * (310 - 210)) * 3;
            assert.equal(expectReward, reward);
        });

        it('inner boundary 2', async () => {
            let _h = 3;
            let _startTime = 50;
            let _endTime = 600;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = (15 * (600 - 550) + 25 * (550 - 380) + 18 * (380 - 310) + 22 * (310 - 200) + 20 * (200 - 100)) * 3;
            assert.equal(expectReward, reward);
        });

        it('inner boundary 3', async () => {
            let _h = 3;
            let _startTime = 120;
            let _endTime = 340;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = (18 * (340 - 310) + 22 * (310 - 200) + 20 * (200 - 120)) * 3;
            assert.equal(expectReward, reward);
        });

        it('inner boundary 4', async () => {
            let _h = 3;
            let _startTime = 50;
            let _endTime = 250;
            let _decimals = 18;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = (22 * (250 - 200) + 20 * (200 - 100)) * 3;
            assert.equal(expectReward, reward);
        });
    })
});
