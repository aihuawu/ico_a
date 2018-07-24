
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


library Util {
	using SafeMath for uint256; 

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	event Mint(address indexed to, uint256 amount);
	event Burn(address indexed to, uint256 value);

	struct Balance {
		mapping(address => uint256) dic;
		uint256 total;
	}
	struct AddressInt {
		mapping(address => uint256) dic;
	}
	struct AddressAddressInt {
		mapping(address => mapping(address => uint256)) allowed;//dic2
	}

	enum RefundState { Active, Refunding, Closed } 
	struct RefundInfo {
		uint256 cashed; 
		address wallet;
		RefundState state;
		address sale;
	} 
	struct SaleInfo {
		
		uint256 initialAllocatedSupply;

		uint256 weiRaised;

		uint256 weiPerUSCent;

		uint256 multiplier;
		uint256 tokenSellTarget;

		uint256 openingTime;
		uint256 closingTime;

		uint256 cap;

		uint256 goal;

		bool isFinalized;

	}

	struct VotableInfo {
		uint256 numProposals;
	}

	struct Proposal {
		uint256 id; // zero based

		uint256 minProposal; // init
		uint256 passGoal; // pass

		address initiator;
		string title;
		string url;
		uint256 endDate;
		uint256 total;
		mapping(address => uint256) votes;
	}

	struct TokenInfo {
		
		address sale;
		uint256 voteLockSeconds;


		address releaseAgent;
		bool released;
		bool refunded;
		bool inUpgrading;
		bool outUpgrading;


		address inToken;
		address outToken;

	}


	function totalSupply(Balance storage d) 
	internal view returns (uint256) 
	{
		return d.total;
	}
	
	function balanceOf(Balance storage d, address _owner) 
	internal view returns(uint256) 
	{
		return d.dic[_owner];
	}


	function transfer(Balance storage d, address _from, address _to, uint256 _value) 
	internal returns(bool) 
	{
		require(_to != address(0));
		require(_value <= d.dic[_from]);
		d.dic[_from] = d.dic[_from].sub(_value);
		d.dic[_to] = d.dic[_to].add(_value);

		emit Transfer(_from, _to, _value);
		return true;
	}

	function mint(
		Balance storage d,
		address _to,
		uint256 _amount
	)
	internal
	returns(bool)
	{
		d.total = d.total.add(_amount);
		d.dic[_to] = d.dic[_to].add(_amount);
		emit Mint(_to, _amount);
		emit Transfer(address(0), _to, _amount);
		return true;
	}


	function burn(Balance storage d, address _who, uint256 _value) 
	internal 
	{
		require(_value <= d.dic[_who]);
		d.dic[_who] = d.dic[_who].sub(_value);
		d.total = d.total.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}



	// solium-disable-next-line indentation
	function lock(Balance storage d, 
		AddressInt storage freezeEnds, 
		address _who, uint256 amount, uint256 unlockedAt) 
	internal 
	{
		if(amount>0){
			mint(d, _who, amount);
			freezeEnds.dic[_who] = unlockedAt;
		}
	}

	function unlockToken(
		Balance storage d,
		AddressInt storage freezeEnds, 
		address _to,
		ERC20Basic token) 
	internal 
	{
		uint256 unlockedAt = freezeEnds.dic[_to]; 
	// solium-disable-next-line security/no-block-members
		if (now >= unlockedAt) { 
			forceUnlockToken(d, _to, token);
		}
	}

	function forceUnlockToken(
		Balance storage d,
		address _to,
		ERC20Basic token) 
	internal 
	{
		uint256 _amount = balanceOf(d, _to);
		if (_amount > 0) {
			burn(d, _to, _amount);
			token.transfer(_to, _amount);
		}
	}


}

