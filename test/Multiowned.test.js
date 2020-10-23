const BitcoinOracle = artifacts.require('BitcoinOracle');
const Multiowned = artifacts.require('Multiowned');

contract('Multiowned', ([a,o0,o1,o2,o3,o4,b]) => {
    beforeEach(async () => {
        this.multiowner = await Multiowned.new([o0,o1,o2,o3,o4], 3, { from: a });
    });

    it('check if owner', async () => {
        let m_required = await this.multiowner.m_required();
        assert.equal(3, m_required);
        let m_numOwners = await this.multiowner.m_numOwners();
        assert.equal(6, m_numOwners);
        let isOwner = await this.multiowner.isOwner(o0);
        assert.equal(true, isOwner);
        isOwner = await this.multiowner.isOwner(o4);
        assert.equal(true, isOwner);
        isOwner = await this.multiowner.isOwner(a);
        assert.equal(true, isOwner);
        isOwner = await this.multiowner.isOwner(b);
        assert.equal(false, isOwner);
    });

    context('bitcoin oracle', () => {
        beforeEach(async () => {
            this.oracle = await BitcoinOracle.new({ from: a });
            await this.oracle.transferOwnership(this.multiowner.address, { from: a });
        });

        it('add block info', async () => {
            let _data = web3.eth.abi.encodeFunctionCall({
                name: 'addBlockInfo',
                type: 'function',
                inputs: [{
                    type: 'uint256',
                    name: 'timestamp'
                },{
                    type: 'uint256',
                    name: 'rewardPerTPerSecond'
                }]
            }, ['1', '20']);
            await this.multiowner.proxy(this.oracle.address, _data, {from: o0});
            await this.multiowner.proxy(this.oracle.address, _data, {from: o1});
            await this.multiowner.proxy(this.oracle.address, _data, {from: o4});
            let info = await this.oracle.blockInfos(0);
            assert.equal(1, info.timestamp);
        });
    });
});
