
pragma solidity ^ 0.4.24;

import "./ERC20.sol";
import "./Util.sol";
import "./ERC20Token.sol";
import "./Ownable.sol";
import "./Vault.sol";




contract SimpleProposalVoting is 
Recoverable 
{
	using SafeMath for uint256; 

	using BalanceOp for BalanceOp.t;
	using FreezeBalanceOp for FreezeBalanceOp.t;
	using ProposalVotingHelper for ProposalVotingHelper.t;
	


	ProposalVotingHelper.t  proposalInfo; 


	function link(ERC20 token, TokenVault vault)
	external onlyMaster
	{
		MiscOp.requireEx(vault != address(0));
		proposalInfo.vote_account.holder = vault;
		proposalInfo.vote_account.token = token;
	}


////////////////////////////////////////////////////////////////////////////////
	function lockBalanceTo(TokenVault holder)
	private
	returns(uint256)
	{
		address sender = msg.sender;
		MiscOp.requireEx(address(holder) != address(0x0));
		uint256 amount = proposalInfo.vote_account.token.balanceOf(sender);
		if (amount > 0) {
			ERC20(proposalInfo.vote_account.token).transferFrom(sender, holder, amount);
		}
		return amount;
		// return 0;
	} 

//////////////////////////////////////////////////////////////////////////////

	function startProposal(string title, string _url)
	public
	returns(uint256 ProposalID)
	{
		address sender = msg.sender;
		uint256 amount = lockBalanceTo(proposalInfo.vote_account.holder);
		uint256 total = proposalInfo.vote_account.token.totalSupply();
		return proposalInfo.startProposal(sender, title, _url, amount, MiscOp.currentTime().add(proposalInfo.voteLockSeconds), total);
		// return 0;
	}

	function voteProposal(uint256 id)
	public
	{
		address sender = msg.sender;
		uint256 amount = lockBalanceTo(proposalInfo.vote_account.holder);
		proposalInfo.voteProposal(sender, id, amount, MiscOp.currentTime().add(proposalInfo.voteLockSeconds));
	}
	function unlockVotableToken()
	public
	{
		proposalInfo.unlockVotableToken();
	}



	function voteTotalSupply() public view returns(uint256) {
		return proposalInfo.voteTotalSupply(); 
	}
	function voteBalanceOf(address _owner) public view returns(uint256) {
		return proposalInfo.voteBalanceOf(_owner); 
	}

//////////////////////////////////////////////////////////////////////////////



	function recoverTokens(ERC20Basic token) public onlyOwner { // override
		super.recoverTokens(token);
		uint256 keep2 = proposalInfo.vote_account.account.totalSupply();
		RecoverVaultOp.recoverVaultTokens(proposalInfo.vote_account.holder, token, owner, keep2);
	}

	function recoverWeis() public onlyOwner  { // ether  // override
		super.recoverWeis();
		RecoverVaultOp.recoverVaultWeis(proposalInfo.vote_account.holder, owner, 0);
	}


}

library ProposalVotingHelper {
	using SafeMath for uint256; 
	using FreezeBalanceOp for FreezeBalanceOp.t;
	using BalanceOp for BalanceOp.t;
	
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

	struct t {
		
		// ERC20 token;

		FreezeBalanceOp.t vote_account;
		mapping(uint256 => Proposal) proposals;
		uint256 voteLockSeconds;
		uint256 numProposals;
	}


	// solium-disable-next-line indentation
	function startProposal(t storage _this, address initiator, string title, string url, uint256 more_amount,
		uint256 endDate, uint256 totalTokens)
	internal
	returns(uint256 ProposalID)
	{
		uint256 minProposal = totalTokens * 1 / 1000;
		uint256 passGoal = totalTokens * 5 / 1000;
		
		_this.vote_account.lock(initiator, more_amount, endDate);
		
		uint256 amount = _this.vote_account.account.balanceOf(initiator);
		MiscOp.requireEx(amount >= minProposal);
		uint256 id = _this.numProposals++;
	// solium-disable-next-line indentation
		_this.proposals[id] = Proposal(id, minProposal, passGoal,
			initiator, title, url, endDate, amount);
		_this.proposals[id].votes[initiator] = amount;
		return id; 
	}






	function voteProposal(t storage _this, address votor, uint256 id, uint256 more_amount, uint256 endDate)
	internal 
	{
		MiscOp.requireEx(id < _this.numProposals);
		Proposal storage p = _this.proposals[id];
 
		MiscOp.requireEx(MiscOp.currentTime() < p.endDate);

		_this.vote_account.lock(votor, more_amount, endDate);
		uint256 amount = _this.vote_account.account.balanceOf(votor);
		uint256 v = p.votes[votor];
		if (v < amount) {
			uint256 c = amount - v;
			p.votes[votor] = amount;
			p.total += c;
		}
	}


	function unlockVotableToken(t storage _this)
	internal
	{
		_this.vote_account.unlock(msg.sender);
	}



	function voteTotalSupply(t storage _this) internal view returns(uint256) {
		return _this.vote_account.account.totalSupply();
	}
	function voteBalanceOf(t storage _this, address _owner) internal view returns(uint256) {
		return _this.vote_account.account.balanceOf(_owner);
	}

}


