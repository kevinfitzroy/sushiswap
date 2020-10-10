pragma solidity 0.6.12;

contract SwapMintDistributionRecipient {
    ///
    address public swapMintDistribution;
    //[0-255]  0% - 255%
    uint8 public swapMintRate;
    ///const
    uint256 public TOTAL_SUPPLY_FOR_SWAP_MINT = 273 * (10 ** 5) * (10 ** 18);//210,000,000 * 0.13 * 10^18;//TODO syntax error!
    ///accumulated supply for swap mint
    uint256 public supplyForSwapMint;

    function notifyRewardAmount(uint8 _swapMintRate) public onlySwapMintDistribution {
        swapMintRate = _swapMintRate;
    }

    function mint(uint256 _feeToMstAmount) internal returns (uint256){
        if(supplyForSwapMint == TOTAL_SUPPLY_FOR_SWAP_MINT){
            return 0;
        }
        uint256 amount = _feeToMstAmount.mul(swapMintRate).div(100);
        uint256 supplyAmount = supplyForSwapMint.add(amount);
        if( supplyAmount > TOTAL_SUPPLY_FOR_SWAP_MINT){
            amount = TOTAL_SUPPLY_FOR_SWAP_MINT.sub(supplyForSwapMint);
            supplyForSwapMint = TOTAL_SUPPLY_FOR_SWAP_MINT;
        }
        supplyForSwapMint = supplyAmount;
        return amount;
    }

    modifier onlySwapMintDistribution() {
        require(msg.sender == swapMintDistribution, "Caller is not swapMintDistribution contract");
        _;
    }

}