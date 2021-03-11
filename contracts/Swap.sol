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

contract SwapContract is Ownable {
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

    address ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // Sushi
    ISushiRouter02 SushiInterface;
    // Tokens
    WETHInterface WETH;
    // Oracle
    ChainlinkPriceOracle priceOracleInterface;
    // Events
    event SwapComplete(
        address Sender,
        address fromToken,
        address toToken,
        uint256 srcAmount,
        uint256 destAmount
    );

    constructor(
        address _SushiInterfaceAddress,
        address _WETHAddress,
        address _chainLinkPriceOracleAddress
    ) public {
        SushiInterface = ISushiRouter02(_SushiInterfaceAddress);
        WETH = WETHInterface(_WETHAddress);
        priceOracleInterface = ChainlinkPriceOracle(
            _chainLinkPriceOracleAddress
        );
    }

    function generateAPIKey(string memory apiName)
        public
        onlyOwner
        returns (uint256 apiKey)
    {
        apiKey = uint256(keccak256(abi.encodePacked(apiName)));
        APItoVolinETH[apiKey] = 0;
    }

    function APIVolumeInETH(uint256 APIKey)
        public
        view
        returns (uint256 VolumeinETH)
    {
        VolumeinETH = APItoVolinETH[APIKey];
    }

    function APIVolumeInToken(uint256 APIKey, address Token)
        public
        view
        returns (uint256 VolumeinToken)
    {
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
            swapParams.path[0] = address(WETH);
            amounts = SushiInterface.swapExactTokensForTokens(
                swapParams.amount,
                swapParams.minReturn,
                swapParams.path,
                address(this),
                (now + 30 minutes)
            );
        } else if (swapParams.path[swapParams.path.length - 1] == ETHAddress) {
            swapParams.path[swapParams.path.length - 1] = address(WETH);
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
        // Consts.
        bool isSourceEthereum;
        IERC20 srcToken;
        if (swapParams.path[0] == ETHAddress) {
            srcToken = IERC20(address(WETH));
            isSourceEthereum = true;
        } else {
            srcToken = IERC20(swapParams.path[0]);
            // Transfer
            srcToken.transferFrom(msg.sender, address(this), swapParams.amount);
        }
        IERC20 targetToken =
            IERC20(swapParams.path[swapParams.path.length - 1]);

        uint256[] memory receivedAmounts;

        {
            // Approve
            srcToken.approve(address(SushiInterface), swapParams.amount);
            // Swap
            receivedAmounts = _swap(swapParams);
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
            uint256 TokenPriceinETH;
            if (!isSourceEthereum)
                TokenPriceinETH =
                    priceOracleInterface.getAssetPrice(address(srcToken)) /
                    1 ether;
            else TokenPriceinETH = 1;
            APItoVolinETH[APIParams.APIKey] +=
                swapParams.amount *
                TokenPriceinETH;
            APItoVol[APIParams.APIKey].Vol[address(srcToken)] += swapParams
                .amount;
            require(status, "Swap Failed!");
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
