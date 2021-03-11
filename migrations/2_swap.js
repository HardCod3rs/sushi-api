const SwapContract = artifacts.require("SwapContract");
const Networks = require("../networks.json");

module.exports = function (deployer) {
  const getNetworkDetails = async () => {
    return await web3.eth.net.getNetworkType();
  };

  getNetworkDetails().then((network) => {
    const Network = Networks[network];

    deployer.deploy(
      SwapContract,
      Network.SushiContractAddress,
      Network.ETHAddress,
      Network.WETHAddress,
      Network.chainLinkPriceOracleAddress
    );
  });
};
