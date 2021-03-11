const ethers = require("ethers");
require("dotenv").config("");
const SushiAPIContractABI = require("../build/contracts/SwapContract.json");
const ERC20ContractABI = require("../build/contracts/IERC20.json");

const Provider = new ethers.providers.JsonRpcProvider(
  process.env.KovanWEB3Provider
);
const Signer = ethers.Wallet.fromMnemonic(process.env.PrivateKey).connect(
  Provider
);

const SushiAPIContract = new ethers.Contract(
  "0xD2A5c881D06083d275251299C3AB4ce822A7A0D5",
  SushiAPIContractABI.abi,
  Signer
);

const AAVEToken = "0xB597cd8D3217ea6477232F9217fa70837ff667Af";
const WETHToken = "0xd0A1E359811322d97991E03f863a0C30C2cF029C";

const ERC20Contract = new ethers.Contract(
  AAVEToken,
  ERC20ContractABI.abi,
  Signer
);

// Logic
const Amount = 1000000000000000000;
SushiAPIContract.swap(
  {
    path: ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", AAVEToken],
    amount: Amount.toString(),
    minReturn: 1,
  },
  {
    APIKey: 2121211215152,
  },
  {
    value: Amount.toString(),
    gasLimit: 3000000,
  }
)
  .then((res) => console.log(res))
  .catch((err) => console.log(err));

SushiAPIContract.APIVolumeInETH(2121211215152).then((res) => console.log(res));

SushiAPIContract.APIVolumeInToken(2121211215152, WETHToken).then((res) =>
  console.log(res)
);

ERC20Contract.balanceOf(AAVEToken).then((res) => console.log(res));
