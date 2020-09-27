/**
 * supply ratio in the k-st week = lambda^k * c
 * c is the first week supply ratio
 */
const lambda = 1 / Math.pow(3, 1/2); //decrease ratio
const c = (3 - Math.pow(3, 1/2))/(4 * lambda); //first week supply ratio
const period = 1; //week
const refsum = 2.1 * Math.pow(10, 8) * 0.87; // ref max supply 
const blocksPerWeek = 2 * 60 * 24 * 7;// block number per week

/**
 *  sum [1-k] supply 
 * @param {number} weeks 
 */
const supplyRatio = function(weeks){
    return  lambda * c * (1 - Math.pow(lambda, weeks)) / (1- lambda);
}

/**
 * In the case of stable supply,calc how the number of weeks after the total supply exceeds the max supply.
 * @param {number} weeks 
 */
const overflowTimeForWeeks = function(weeks){
    return (1- supplyRatio(weeks)) / (Math.pow(lambda, weeks) * c);
}
/**
 * after several weeks, stable supply per eth block
 * @param {number} weeks 
 */
const stableSupplyPerBlock = function(weeks){
    return refsum * c * Math.pow(lambda, weeks) / blocksPerWeek;
}

String.format = function(src){
    if (arguments.length == 0) return null;
    var args = Array.prototype.slice.call(arguments, 1);
    return src.replace(/\{(\d+)\}/g, function(m, i){
        return args[i];
    });
};

var weeks = process.argv[2]|0;

console.log(String.format("After {0} weeks, the total supply ratio is {1}%",weeks, (supplyRatio(weeks)*100).toFixed(2)));
console.log(String.format
    (
        "If the supply is linear after {0} weeks, "
        + "\n\tthe supply volume will exceed 210,000,000*87% in {1} weeks,"
        + " \n\tand the stable supply value per block is {2}"
        , weeks, overflowTimeForWeeks(weeks).toFixed(2), stableSupplyPerBlock(weeks).toFixed(2)
    ))