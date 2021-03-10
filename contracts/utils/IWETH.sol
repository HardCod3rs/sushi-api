pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface WETHInterface is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}
