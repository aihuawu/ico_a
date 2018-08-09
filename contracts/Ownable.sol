
pragma solidity ^ 0.4.24;



import "./ERC20.sol";
import "./ERC777.sol";
import "./ERC721.sol";
import "./Util.sol";
import "./ERC20Token.sol";


contract Ownable {
	address owner;
	event OwnershipRenounced(address indexed previousOwner);
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);
	constructor() public {
		owner = msg.sender;
	}
	modifier onlyOwner() {
		MiscOp.requireEx(msg.sender == owner);
		_;
	}
	
	function transferOwnership(address _newOwner) 
	public 
	onlyOwner 
	{
		MiscOp.requireEx(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}


contract OwnableEx is Ownable {
	address master;	// we use it for smart contract owner

	modifier onlyMaster() {
		MiscOp.requireEx(msg.sender==address(master));
		_;
	}
}

contract MyERC721Receiver is ERC721Receiver {
	
	function onERC721Received(
		address /*_operator*/,
		address /*_from*/,
		uint256 /*_tokenId*/,
		bytes /*_data*/
	)
	public returns(bytes4)
	{
		// do bookkeeping here
	}

	function depositToken(address token, address sender, uint256 _tokenId) internal {
		ERC721Basic(token).safeTransferFrom(sender, this, _tokenId);
	}

}


// 
// https://github.com/forkdelta/smart_contract/blob/master/contracts/ForkDelta.sol#L128
contract MyERC20Receiver is OwnableEx {
	bool depositingTokenFlag = false;
	ERC820Registry erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);
	
	// for ERC777
	function initERC777() internal {
		setInterfaceImplementation("ERC777TokensRecipient", this);
	}
	function setInterfaceImplementation(string _interfaceLabel, address impl) internal {
		bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
		erc820Registry.setInterfaceImplementer(this, interfaceHash, impl);
	}
	function tokensReceived(
		address /*operator*/,
		address /*from*/,
		address /*to*/,
		uint256 /*amount*/,
		bytes /*userData*/,
		bytes /*operatorData*/
	) 
	public 
	{
		_tokenFallback();
	}

	// for ERC223
	function tokenFallback(address /*sender*/, uint256 /*amount*/, bytes /*data*/)
	public returns(bool ok) 
	{
		return _tokenFallback();
	}

	uint256 dummy;
	function _tokenFallback() 
	internal returns(bool ok) 
	{
		if (depositingTokenFlag) {
			// Transfer was initiated from depositToken(). User token balance will be updated there.
			return true;
		} else {
			dummy = 0; // To shut up the Warning: Function state mutability can be restricted to view
			// Direct ECR223 Token.transfer into this contract not allowed, to keep it consistent
			// with direct transfers of ECR20 and ETH.
			MiscOp.revertEx();
		}
	}

	function depositToken(address token, address sender, uint256 amount) internal {
		depositingTokenFlag = true;
		MiscOp.requireEx(ERC20(token).transferFrom(sender, this, amount));
		depositingTokenFlag = false;
		// do bookkeeping here
	}

}



contract Recoverable is OwnableEx {

	function recoverTokens(ERC20Basic token) public onlyOwner  {
		token.transfer(owner, token.balanceOf(this));
	}
	// function tokensToBeReturned(ERC20Basic token) private view returns(uint256) {
	// 	return token.balanceOf(this);
	// }
	function recoverWeis() public onlyOwner  { // ether
		owner.transfer(address(this).balance);
	}
	// function weisToBeReturned() private view returns(uint256) { // ether
	// 	return address(this).balance;
	// }
}




