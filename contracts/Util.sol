
pragma solidity ^ 0.4.23;


import "./ERC20.sol";



library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}
	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		return a / b;
	}
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		assert(b <= a);
		return a - b;
	}
	function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}




library MiscOp {
	function currentTime() 
	internal view returns(uint256)
	{
		// solium-disable-next-line security/no-block-members
		return block.timestamp;
		// return now;
	}
}




library SortUtil {

	struct SimpleEntry {
		uint256 key;
		uint256 value;
	}
	// https://ethereum.stackexchange.com/questions/1517/sorting-an-array-of-integer-with-ethereum
	function quickSort(SimpleEntry[] memory arr, uint256 left, uint256 right, bool desc) internal {
		uint256 i = left;
		uint256 j = right;
		SimpleEntry memory tmp;
		SimpleEntry memory pivot = arr[(left + right) / 2];
		while (i <= j) {
			if (desc) {
				while (arr[i].key > pivot.key)
					i++;
				while (arr[j].key < pivot.key)
					j--;
			} else {
				while (arr[i].key < pivot.key)
					i++;
				while (arr[j].key > pivot.key)
					j--;
			}
			if (i <= j) {
				tmp = arr[i];
				arr[i] = arr[j];
				arr[j] = tmp;
				i++;
				j--;
			}
		}
		if (left < j)
			quickSort(arr, left, j, desc);
		if (i < right)
			quickSort(arr, i, right, desc);
	}

}


// https://github.com/aragon/zeppelin-solidity/blob/master/contracts/token/StandardToken.sol

library BalanceOp {
	using SafeMath for uint256; 

	struct t {
		mapping(address => uint256) balances;
		uint256 total;
	}

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);


	function totalSupply(t storage _this) 
	internal view returns(uint) {
		return _this.total;
	}

	function mint(t storage _this, address _to, uint256 _value) 
	internal returns(bool success) 
	{
		_this.total = _this.total.add(_value);
		_this.balances[_to] = _this.balances[_to].add(_value);
		emit Transfer(0x0, _to, _value);
		return true;
	}

	function burn(t storage _this, address _to, uint256 _value) 
	internal returns(bool success) 
	{
		_this.total = _this.total.sub(_value);
		_this.balances[_to] = _this.balances[_to].sub(_value);
		emit Transfer(_to, 0x0, _value);
		return true;
	}

	function transfer(t storage _this, address _from, address _to, uint256 _value) 
	internal returns(bool success) 
	{
		_this.balances[_from] = _this.balances[_from].sub(_value);
		_this.balances[_to] = _this.balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(t storage _this, address _owner) 
	internal view returns(uint256 balance) 
	{
		return _this.balances[_owner];
	}

}

library BalanceExOp {
	using SafeMath for uint256; 
	using BalanceOp for BalanceOp.t; 

	struct t {
		BalanceOp.t basic;
		mapping(address => mapping(address => uint256)) allowed;
	}

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);


	function transferFrom(t storage _this, address _sender, address _from, address _to, uint256 _value) 
	internal returns(bool success) 
	{
		uint256 _allowance = _this.allowed[_from][_sender];
		_this.allowed[_from][_sender] = _allowance.sub(_value);
		_this.basic.transfer(_from, _to, _value);
		return true;
	}

	function approve(t storage _this, address _sender, address _spender, uint256 _value) 
	internal returns(bool success) 
	{
		_this.allowed[_sender][_spender] = _value;
		emit Approval(_sender, _spender, _value);
		return true;
	}

	function allowance(t storage _this, address _owner, address _spender) 
	internal view returns(uint256 remaining) {
		return _this.allowed[_owner][_spender];
	}
}



