const SwapContract = artifacts.require("SwapContract");
const Networks = require("../networks.json");

module.exports = async function (deployer) {
  const getNetworkDetails = async () => {
    return web3.eth.net.getNetworkType();
  };

  await getNetworkDetails().then((network) => {
    var Network;

    switch (network) {
      case "kovan":
        Network = Networks["kovan"];
        break;
      case "development":
        Network = Networks["mainnet"];
        break;
    }

    deployer.deploy(
      SwapContract,
      Network.SushiContractAddress,
      Network.WETHAddress,
      Network.chainLinkPriceOracleAddress
    );
  });
};
