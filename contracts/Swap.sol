// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

/* utils */
// OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* Interfaces */
// Token Interfaces
import "./utils/IWETH.sol";
// Sushi
import "./Sushi/ISushiRouter02.sol";
// Oracle
import "./utils/priceOracle.sol";

contract SwapContract is Ownable, relayutils {
    struct swapParameters {
        address[] path;
        uint256 amount;
        uint256 minReturn;
    }

    // API
    struct APIParameters {
        uint256 APIKey;
    }
    struct APIVols {
        mapping(address => uint256) Vol;
    }
    mapping(uint256 => uint256) APItoVolinETH;
    mapping(uint256 => APIVols) APItoVol;

    // Sushi
    address SushiContract = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    ISushiRouter02 SushiInterface = ISushiRouter02(SushiContract);
    // Tokens
    address ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WETHAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    WETHInterface WETH = WETHInterface(WETHAddress);
    // Oracle
    address chainLinkPriceOracle = 0x76B47460d7F7c5222cFb6b6A75615ab10895DDe4;
    ChainlinkPriceOracle priceOracleInterface =
        ChainlinkPriceOracle(chainLinkPriceOracle);

    // Events
    event SwapComplete(
        address Sender,
        address fromToken,
        address toToken,
        uint256 srcAmount,
        uint256 destAmount
    );

    function generateAPIKey(string memory apiName)
        public
        onlyOwner
        returns (uint256 apiKey)
    {
        apiKey = uint256(keccak256(abi.encodePacked(apiName)));
        APItoVolinETH[apiKey] = 0;
    }

    function APIVolume(uint256 APIKey, address Token)
        public
        view
        returns (uint256 VolumeinETH, uint256 VolumeinToken)
    {
        VolumeinETH = APItoVolinETH[APIKey];
        VolumeinToken = APItoVol[APIKey].Vol[Token];
    }

    function expectedReturn(
        address[] memory path,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view returns (uint256[] memory amounts) {
        amounts = SushiInterface.getAmountsOut(amount, path);
    }

    function _swap(swapParameters memory swapParams)
        private
        returns (uint256[] memory amounts)
    {
        if (swapParams.path[0] == ETHAddress) {
            WETH.deposit{value: msg.value}();
            swapParams.path[0] = WETHAddress;
            amounts = SushiInterface.swapExactTokensForTokens(
                swapParams.amount,
                swapParams.minReturn,
                swapParams.path,
                address(this),
                (now + 30 minutes)
            );
        } else if (swapParams.path[swapParams.path.length - 1] == ETHAddress) {
            swapParams.path[swapParams.path.length - 1] = WETHAddress;
            amounts = SushiInterface.swapExactTokensForTokens(
                swapParams.amount,
                swapParams.minReturn,
                swapParams.path,
                address(this),
                (now + 30 minutes)
            );
            WETH.withdraw(amounts[amounts.length - 1]);
        } else
            amounts = SushiInterface.swapExactTokensForTokens(
                swapParams.amount,
                swapParams.minReturn,
                swapParams.path,
                address(this),
                (now + 30 minutes)
            );
    }

    function swap(
        swapParameters memory swapParams,
        APIParameters memory APIParams
    ) public payable returns (bool status, uint256[] memory receivedAmounts) {
        // Consts
        IERC20 srcToken = IERC20(swapParams.path[0]);
        IERC20 targetToken =
            IERC20(swapParams.path[swapParams.path.length - 1]);
        {
            // Transfer
            if (address(srcToken) != ETHAddress) {
                require(
                    srcToken.transferFrom(
                        msg.sender,
                        address(this),
                        swapParams.amount
                    )
                );
                require(srcToken.approve(SushiContract, swapParams.amount));
            }
            // Swap
            uint256[] memory receivedAmounts = _swap(swapParams);
            // Transfer Back
            if (address(targetToken) != ETHAddress)
                status = targetToken.transfer(
                    msg.sender,
                    receivedAmounts[receivedAmounts.length - 1]
                );
            else
                msg.sender.transfer(
                    receivedAmounts[receivedAmounts.length - 1]
                );
            // API
            uint256 TargetTokeninETH =
                priceOracleInterface.getAssetPrice(address(srcToken)) / 1 ether;
            APItoVolinETH[APIParams.APIKey] +=
                swapParams.amount *
                TargetTokeninETH;
            APItoVol[APIParams.APIKey].Vol[address(srcToken)] += swapParams
                .amount;
            require(status);
        }
        // Emit Events
        emit SwapComplete(
            msg.sender,
            swapParams.path[0],
            swapParams.path[swapParams.path.length - 1],
            swapParams.amount,
            receivedAmounts[receivedAmounts.length - 1]
        );
    }
}
