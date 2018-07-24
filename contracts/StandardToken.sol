
pragma solidity ^ 0.4.23;


import "./ERC20.sol";
import "./Util.sol";


contract BasicToken is ERC20 {
	using SafeMath for uint256;

	Util.Balance account;
	
	function totalSupply() public view returns (uint256) {
		return Util.totalSupply(account); 
	}
	function transfer(address _to, uint256 _value) public returns(bool) {
		Util.transfer(account, msg.sender, _to,_value); 
		return true;
	}
	function balanceOf(address _owner) public view returns (uint256) {
		return Util.balanceOf(account, _owner); 
	}
}
contract StandardToken is ERC20, BasicToken {
	mapping(address => mapping(address => uint256)) internal allowed;
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
	public
	returns(bool)
	{
		require(_value <= allowed[_from][msg.sender]);

		Util.transfer(account, _from, _to,_value);

		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		return true;
	}
	function approve(address _spender, uint256 _value) public returns(bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	function allowance(
		address _owner,
		address _spender
	)
	public
	view
	returns(uint256)
	{
		return allowed[_owner][_spender];
	}



	function increaseApproval(
		address _spender,
		uint _addedValue
	)
	public
	returns(bool)
	{
		allowed[msg.sender][_spender] = (
			allowed[msg.sender][_spender].add(_addedValue));
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	function decreaseApproval(
		address _spender,
		uint _subtractedValue
	)
	public
	returns(bool)
	{
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}


}

