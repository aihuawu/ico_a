
pragma solidity ^ 0.4.23;


import "./ERC20.sol";
import "./Util.sol";

contract StandardToken is ERC20 {
	using SafeMath for uint256; 

	using BalanceOp for BalanceOp.t;
	using BalanceExOp for BalanceExOp.t;

	/** warning: make it private to avoid inheritance misbehavior */
	BalanceExOp.t private token_account;
	/** warning: call it only for sale or upgrade, must be internal */
	function mint(address _to, uint256 _value) 
	internal returns(bool success) 
	{
		return token_account.basic.mint(_to, _value);
	}
	/** warning: call it only for upgrade, must be internal */
	function burn(address _to, uint256 _value) 
	internal returns(bool success) 
	{
		return token_account.basic.burn(_to, _value);
	}


	function totalSupply() public view returns(uint) {
		return token_account.basic.totalSupply();
	}

	function balanceOf(address who) public view returns(uint) {
		return token_account.basic.balanceOf(who);
	}

	function transfer(address to, uint value) public returns(bool ok) {
		return token_account.basic.transfer(msg.sender, to, value);
	}

	function allowance(address owner, address spender) public view returns(uint) {
		return token_account.allowance(owner, spender);
	}

	function transferFrom(address from, address to, uint value) public returns(bool ok) {
		return token_account.transferFrom(msg.sender, from, to, value);
	}

	function approve(address spender, uint value) public returns(bool ok) {
		return token_account.approve(msg.sender, spender, value);
	}

	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


