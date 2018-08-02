
pragma solidity ^ 0.4.23;



import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";


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
		require(msg.sender == owner);
		_;
	}
	
	function transferOwnership(address _newOwner) 
	public 
	onlyOwner 
	{
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}


contract OwnableEx is Ownable {
	address master;	// we use it for smart contract owner

	modifier onlyMaster() {
		require(msg.sender==address(master));
		_;
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




