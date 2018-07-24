
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";
import "./Ownable.sol";


contract RefundVault is Recoverable { // token is ether
	using SafeMath for uint256;

	Util.Balance account;
	// mapping(address => uint256) private balances;

	Util.RefundInfo public refundInfo;


	modifier onlySale() {
		require(msg.sender == address(refundInfo.sale));
		_;
	}

	event Closed();
	event RefundsEnabled();
	event Refunded(address indexed beneficiary, uint256 weiAmount);

	constructor(address _owner, address _master, address _sale, address _wallet)
	public
	{
		require(_wallet != address(0));
		owner = _owner;
		master = _master;
		refundInfo.sale = _sale;
		refundInfo.wallet = _wallet;
		refundInfo.state = Util.RefundState.Active;
	}

	function deposit(address investor)  
	public payable
	onlySale
	{
		require(refundInfo.state == Util.RefundState.Active);

		Util.mint(account, investor, msg.value);
		// balances[investor] = balances[investor].add(msg.value);
		// refundInfo.totalSupply_ = refundInfo.totalSupply_.add(msg.value);
	}
	function close() onlySale public {
		require(refundInfo.state == Util.RefundState.Active);
		refundInfo.state = Util.RefundState.Closed;
		uint256 r = remains();
		refundInfo.wallet.transfer(r);
		refundInfo.cashed = refundInfo.cashed.add(r);
		emit Closed();
	}
	function enableRefunds()  
	public onlySale
	{
		require(refundInfo.state == Util.RefundState.Active);
		refundInfo.state = Util.RefundState.Refunding;
		emit RefundsEnabled();
	}
	function refund(address investor)
	public
	{
		require(refundInfo.state == Util.RefundState.Refunding);
		
		uint256 amount = Util.balanceOf(account, investor);
		Util.burn(account, investor, amount);

		investor.transfer(amount); 	// ether 
		emit Refunded(investor, amount);
	}

	function remains() private view returns(uint256) { // ether
		return Util.totalSupply(account).sub(refundInfo.cashed);
	}
	function weisToBeReturned() internal view returns(uint256) { // ether
		return address(this).balance.sub(remains());
	}
}

contract TokenVault is Recoverable {
	using SafeMath for uint256;

	Util.Balance account;
	ERC20Basic token;
	Util.AddressInt freezeEnds;

	modifier fromToken() {
		require(msg.sender == address(token));
		_;
	}

	function tokensToBeReturned(ERC20Basic tokenToClaim)
	internal view returns(uint256)
	{
		if (address(tokenToClaim) == address(token)) {
			return token.balanceOf(address(this)).sub(Util.totalSupply(account));
		} else {
			return tokenToClaim.balanceOf(this);
		}
	}

}

contract IFoundersTokenVault {
	function lock(address _to, uint256 _amount, uint256 _unlockedAt) public;
	function unlock(address _to) public;
}

contract IVotableTokenVault {

	// solium-disable-next-line indentation
	function startProposal(address initiator, string title, string url, 
		uint256 more_amount, uint256 endDate, uint256 totalTokens) external returns(uint256 ProposalID);
	function voteProposal(address votor, uint256 id, uint256 more_amount, uint256 endDate) external;
	function unlockVotableToken(address _to) external;
}




contract FoundersTokenVault is IFoundersTokenVault, TokenVault {
	using SafeMath for uint256;

	Util.Balance burnt; 


	constructor(address _owner, address _master, ERC20Basic _token) public {
		owner = _owner;
		master = _master;
		token = _token;

		require(address(token) != address(0x0));
	}

	modifier fromToken() {
		require(msg.sender == address(token));
		_;
	}
	function lock(address _to, uint256 _amount, uint256 _unlockedAt)
	public 
	fromToken
	{
		Util.lock(account, freezeEnds, _to, _amount, _unlockedAt);
	}



	function unlock(address _to) public {
		Util.unlockToken(account, freezeEnds, _to, token);
	}




	function burnMint(address user)
	public 
	fromToken
	{
		uint256 amount = Util.balanceOf(account, user);
		if (amount > 0) {
			Util.burn(account, user, amount);
			Util.mint(burnt, user, amount);
		}
	}

	function freezeInfo(address _user)
	public
	view
	returns(uint256 amount, uint256 until)
	{
		return (	
			Util.balanceOf(account, _user),			
			freezeEnds.dic[_user] 
		);
	}


}




contract VotableTokenVault is TokenVault, IVotableTokenVault {

	Util.VotableInfo public votableInfo;

	mapping(uint256 => Util.Proposal) public proposals;


	constructor(address _owner, address _master, ERC20Basic _token) public {
		owner = _owner;
		master = _master;
		token = _token;

		votableInfo.numProposals = 0;
		// votableInfo.minProposal = 1;
		// votableInfo.passGoal = 5;
	}

	// solium-disable-next-line indentation
	function startProposal(address initiator, string title, string url, uint256 more_amount,
		uint256 endDate, uint256 totalTokens)
	external
	fromToken
	returns(uint256 ProposalID)
	{
		uint256 minProposal = totalTokens * 1 / 100;
		uint256 passGoal = totalTokens * 5 / 100;
		Util.lock(account, freezeEnds, initiator, more_amount, endDate);
		uint256 amount = Util.balanceOf(account, initiator);
		require(amount >= minProposal);
		uint256 id = votableInfo.numProposals++;
		proposals[id] = Util.Proposal(id, minProposal, passGoal,
			initiator, title, url, endDate, amount);
		proposals[id].votes[initiator] = amount;
		return id;
	}



	function voteProposal(address votor, uint256 id, uint256 more_amount, uint256 endDate)
	external
	fromToken
	{
		require(id < votableInfo.numProposals);
		Util.Proposal storage p = proposals[id];

	// solium-disable-next-line security/no-block-members
		require(now < p.endDate);

		Util.lock(account, freezeEnds, votor, more_amount, endDate);
		uint256 amount = Util.balanceOf(account, votor);
		uint256 v = p.votes[votor];
		if (v < amount) {
			uint256 c = amount - v;
			p.votes[votor] = amount;
			p.total += c;
		}
	}

	function unlockVotableToken(address _to)
	external
	{
		Util.unlockToken(account, freezeEnds, _to, token);
	}

	function forceUnlockVotableToken(address _to)
	external
	fromToken
	{
		Util.forceUnlockToken(account, _to, token);
	}

	function totalSupply() public view returns(uint256) {
		return Util.totalSupply(account);
	}
	function balanceOf(address _owner) public view returns(uint256) {
		return Util.balanceOf(account, _owner);
	}
}

