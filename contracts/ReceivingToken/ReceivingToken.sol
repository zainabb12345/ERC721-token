pragma solidity ^0.6.2;
import "./IReceivingToken.sol";


contract ReceivingToken {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure returns (bytes4) {
        revert("test");
    }
}
