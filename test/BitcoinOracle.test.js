const { expectRevert } = require('@openzeppelin/test-helpers');
const BitcoinOracle = artifacts.require('BitcoinOracle');

contract('BitcoinOracle', ([a]) => {
    beforeEach(async () => {
        this.oracle = await BitcoinOracle.new({ from: a });
    });

    it('add block info', async () => {
        let _timestamp = 1;
        let _rewardPerTPerSecond = 20;
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});
        let info = await this.oracle.blockInfos(0);
        assert.equal(_timestamp, info.timestamp);

        _timestamp = 0;
        _rewardPerTPerSecond = 18;
        await expectRevert(
            this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a}),
            'invalid timestamp',
        );

        _timestamp = 2;
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});
        info = await this.oracle.blockInfos(1);
        assert.equal(_timestamp, info.timestamp);
    });


    it('update latest block info', async () => {
        let _timestamp = 1;
        let _rewardPerTPerSecond = 20;
        await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});
        let info = await this.oracle.blockInfos(0);
        assert.equal(_timestamp, info.timestamp);

        _timestamp = 3;
        _rewardPerTPerSecond = 18;
        await this.oracle.updateLatestBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});
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
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});
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

        it('inner boundary with decimals = 17', async () => {
            let _h = 3;
            let _startTime = 100;
            let _endTime = 130;
            let _decimals = 17;
            let reward = await this.oracle.calReward(_h, _startTime, _endTime, _decimals);
            let expectReward = 20 * 3 * (130 - 100) / 10;
            assert.equal(expectReward, reward);
        });
    })

    context('cal reward with more then one block info', () => {
        beforeEach(async () => {
            let _timestamp = 100;
            let _rewardPerTPerSecond = 20;
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});

            _timestamp = 200;
            _rewardPerTPerSecond = 22;
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});

            _timestamp = 310;
            _rewardPerTPerSecond = 18;
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});

            _timestamp = 380;
            _rewardPerTPerSecond = 25;
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});

            _timestamp = 550;
            _rewardPerTPerSecond = 15;
            await this.oracle.addBlockInfo(_timestamp, _rewardPerTPerSecond, {from: a});
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
