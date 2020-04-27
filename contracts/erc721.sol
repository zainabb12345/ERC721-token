pragma solidity >=0.5.0 <0.7.0;
import "../library/safeMath.sol";
import "../library/Address.sol";
import "../library/Enumerable.sol";
import "../library/EnumerableAbstract.sol";
import "./IERC721.sol";
import "./ERC165/ERC165.sol";
import "./ReceivingToken/IReceivingToken.sol";


contract ERC721 is IERC721, ERC165 {
    //LIBRARIES
    //to prevent overflow
    using SafeMath for uint256;
    //for isContract check
    using Address for address;
    //add/remove/checkExistance in maps
    using EnumerableSet for EnumerableSet.UintSet;
    //add/remove/checkExistance in abstract datatypes
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    //state variables
    string public name;
    string public symbol;

    //mappings
    //id to address that owns it
    mapping(address => EnumerableSet.UintSet) idToOwner;
    // id to address that can approve it
    mapping(uint256 => address) idToApproval;
    //enables length,set,get etcv on the mapping
    EnumerableMap.UintToAddressMap private tokensOwner;
    //owner to operator approval
    mapping(address => mapping(address => bool)) ownerToOperator;

    //erc721 interface identifier
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    //erc721 required events
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /*when emitted events are stored in trasaction's logs
      logs are associated with contract address*/

    //upgradeable constructor
    function initialize() public override initializer {
        ERC165.initialize();
        Ownable.initialize();
        name = "ABC";
        symbol = "ABC";
        _registerInterface(_INTERFACE_ID_ERC721); // ERC721
    }

    //create tokens
    function mint(address to, uint256 tokenId) public onlyOwner {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        idToOwner[to].add(tokenId);
        tokensOwner.set(tokenId, to);
        emit Transfer(address(0), to, tokenId);
    }

    //to check balance
    function balanceOf(address owner) public override view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        return idToOwner[owner].length();
    }

    /**
     * @dev to get the owner (Get id from enumerable library)
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return
            tokensOwner.get(
                tokenId,
                "ERC721: owner query for nonexistent token"
            );
    }

    /**
     *@dev approves another address to transfer token
     *@param to address to be approved for the given token ID
     *@param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        idToApproval[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override 
        returns (bool)
    {
        return ownerToOperator[owner][operator];
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public override view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return idToApproval[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");

        ownerToOperator[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * not used but was part of erc721 interface
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override 
    {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override 
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        virtual 
    {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        idToApproval[tokenId] = to;
        //transfer
        idToOwner[from].remove(tokenId);
        idToOwner[to].add(tokenId);
        tokensOwner.set(tokenId, to);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * FROM OPENZEPPELIN LIBRARY
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(
            abi.encodeWithSelector(
                ERC721TokenReceiver(to).onERC721Receiver.selector,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == 0x150b7a02);
        }
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     * OZ REPO
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Returns whether the specified token exists.
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokensOwner.contains(tokenId);
    }

    // don't accept eth
    // taken from ethplode token contract
    receive() external payable {
        revert();
    }
}
