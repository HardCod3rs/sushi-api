const ethers = require("ethers");
require("dotenv").config("");
const SushiAPIContractABI = require("../build/contracts/SwapContract.json");

const Provider = new ethers.providers.JsonRpcProvider(
  process.env.KovanWEB3Provider
);
const Signer = ethers.Wallet.fromMnemonic(process.env.PrivateKey).connect(
  Provider
);

const SushiAPIContract = new ethers.Contract(
  "0xf5367055649680C6A4Dc0Aa9de90C54BeAb6f772",
  SushiAPIContractABI.abi,
  Signer
);

// Logic
const Amount = 1000000000000000000;
SushiAPIContract.swap(
  {
    path: [
      "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      "0x71bC5dBdf71add8a92a44B5BEA33f36Dd2503db3",
    ],
    amount: Amount.toString(),
    minReturn: 1,
  },
  {
    APIKey: 2121211215152,
  },
  {
    value: Amount.toString(),
    gasLimit: 12487794,
  }
).then((res) => console.log(res));
