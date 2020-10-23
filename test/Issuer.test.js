const { expectRevert } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const IssuerManager = artifacts.require('IssuerManagerV1');
const IssuerBTC = artifacts.require('IssuerBTC');
const BtcMineToken = artifacts.require('BtcMineToken');
const MockERC20 = artifacts.require('MockERC20');
const BitcoinOracle = artifacts.require('BitcoinOracle');
const MineTokenManager = artifacts.require('MineTokenManager');
const BN = require('bn.js');

const hostname = "minerswap.com";
contract('Issuer and IssuerBTC', async ([boss, anyone, alice, bob, kevin, kim, anyone2, jone]) => {
    beforeEach(async () => {
        this.bitcoinOracle = await BitcoinOracle.new({from: anyone2});
        this.mbtc = await MockERC20.new("mbtc", "mbtc", {from: anyone});
        this.issuerManager = await IssuerManager.new((await MineTokenManager.new({from: alice})).address, this.bitcoinOracle.address, {from: alice});
        await this.issuerManager.updateBtcConfig('mbtc', this.mbtc.address, 18, {from: alice});
        this.currencyToken = await MockERC20.new("usd", "usd", {from: anyone});
        this.issuerBtc = await IssuerBTC.at((await this.issuerManager.registIssuerBTC(hostname, 1, {from: boss})).logs[2].args.issuerAddress);

        let now = Date.now()/1000|0;
        this.btcMineToken = await BtcMineToken.at((await this.issuerBtc.issue(
            "mbtc",
            this.currencyToken.address,
            23,//buy price
            35,//buy total supply
            10000,//pre mint number
            now + 1,//time
            now + 2,
            now + 3,
            now + 4,
            "mine token comment",
            {from: boss}
        )).logs[2].args.tokenAddress);
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

    it('should withdraw work correctly', async () => {
        let xxToken = await MockERC20.new('xx', 'xx', {from: kevin});
        await xxToken.mint(anyone, 10000, {from: anyone});
        await xxToken.transfer(this.issuerBtc.address, 5000, {from: anyone});
        await expectRevert (
            this.issuerBtc.withdraw(xxToken.address, kevin, 1500, {from: alice}),
            "Ownable: caller is not the owner"
        );
        await this.issuerBtc.withdraw(xxToken.address, bob, 1500, {from: boss});
        assert.equal(1500, (await xxToken.balanceOf(bob)).valueOf());
        
        assert.equal(0, (await web3.eth.getBalance(this.issuerBtc.address)).valueOf());
        await web3.eth.sendTransaction({from: anyone, to: this.issuerBtc.address, value: web3.utils.toWei("3",'ether')});
        assert.equal(web3.utils.toWei("3",'ether'), (await web3.eth.getBalance(this.issuerBtc.address)).valueOf());
        await expectRevert (
            this.issuerBtc.withdrawETH(kim, web3.utils.toWei("1.3",'ether'), {from: anyone}),
            "Ownable: caller is not the owner"
        );
        let kimEthBalance = (await web3.eth.getBalance(kim)).valueOf();
        await this.issuerBtc.withdrawETH(kim, web3.utils.toWei("1.3",'ether'), {from: boss});
        assert.equal(web3.utils.toWei("1.7",'ether'), (await web3.eth.getBalance(this.issuerBtc.address)).valueOf());
        assert.equal((new BN(kimEthBalance,10)).add(new BN(web3.utils.toWei("1.3",'ether'), 10)).toString(16), new BN((await web3.eth.getBalance(kim)).valueOf(),10).toString(16));

        await xxToken.mint(anyone, 10000, {from: anyone});
        await xxToken.transfer(this.btcMineToken.address, 2000, {from: anyone});
        assert.equal(2000, (await xxToken.balanceOf(this.btcMineToken.address)).valueOf());
        let bobBalance = (await xxToken.balanceOf(bob)).valueOf();
        let symbol = (await this.btcMineToken.symbol()).valueOf();
        await expectRevert (
            this.issuerBtc.withdrawFromMineToken(xxToken.address, symbol, bob, 1567, {from: anyone}),
            "Ownable: caller is not the owner"
        );
        await this.issuerBtc.withdrawFromMineToken(xxToken.address, symbol, bob, 1567, {from: boss});
        assert.equal(bobBalance.toNumber() + 1567, (await xxToken.balanceOf(bob)).valueOf());

        let aliceEthBalance = (await web3.eth.getBalance(alice)).valueOf();
        await web3.eth.sendTransaction({from: anyone, to: this.btcMineToken.address, value: web3.utils.toWei("2",'ether')});
        await expectRevert (
            this.issuerBtc.withdrawETHFromMineToken(symbol, alice, web3.utils.toWei("15000",'wei'), {from: anyone}),
            "Ownable: caller is not the owner"
        );
        await this.issuerBtc.withdrawETHFromMineToken(symbol, alice, web3.utils.toWei("15000",'wei'), {from: boss});
        let expt = new BN(aliceEthBalance, 10).add(new BN(15000, 10));
        let acu = new BN((await web3.eth.getBalance(alice)).valueOf(), 10);
        assert.equal(expt.toString(16), acu.toString(16));
    });

    context('tutorials for front end',()=>{
        beforeEach(async () => {
            await this.issuerBtc.mint("mtBTC1", 10000, {from: boss});
            await this.issuerBtc.withdraw(this.btcMineToken.address, jone, 1500, {from: boss});
        });
        it('how to get minetokens belonging to the user through the address', async ()=> {
            //step1: front end known some hostname
            let hostname1 = hostname;
    
            //step2: get issuer address through hostname
            let issuerAddress = await this.issuerManager.getIssuerAddress(hostname1);//this.issuerManager is unique contract address
            let issuer = await IssuerBTC.at(issuerAddress);

            //step3: get minetoken address through serialNumber and SYMBOL
            let serialNumber = (await issuer.serialNumber()).valueOf().toNumber();
            let symbol = (await issuer.SYMBOL().valueOf());
            let minetokens = [];
            for(var sn = 1; sn <= serialNumber; sn++){
                let mt = (await issuer.getMineToken(symbol + sn)).valueOf();
                minetokens.push(mt);
            }

            //step4: iterate minetokens for user address
            minetokens.forEach(async (val) => {
                let minetoken = await BtcMineToken.at(val);
                let balance = await minetoken.balanceOf({from: jone})
                if(val == this.btcMineToken.address){
                    assert.equal(balance.toNumber(),1500);
                }
            })

        });
    });
    

});