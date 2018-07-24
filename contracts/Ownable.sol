
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
	address master;

	modifier onlyMaster() {
		require(msg.sender==address(master));
		_;
	}
	modifier fromOwnerOrMaster() {
		require(msg.sender==owner||msg.sender==address(master));
		_;
	}

}


contract Pausable is OwnableEx {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() fromOwnerOrMaster whenNotPaused public {
		paused = true;
		emit Pause();
	}

	function unpause() fromOwnerOrMaster whenPaused public {
		paused = false;
		emit Unpause();
	}
}


contract Recoverable is OwnableEx {

	function recoverTokens(ERC20Basic token) public onlyOwner  {
		token.transfer(owner, tokensToBeReturned(token));
	}
	function tokensToBeReturned(ERC20Basic token) internal view returns(uint256) {
		return token.balanceOf(this);
	}
	function recoverWeis() public onlyOwner  { // ether
		owner.transfer(weisToBeReturned());
	}
	function weisToBeReturned() internal view returns(uint256) { // ether
		return address(this).balance;
	}
}




