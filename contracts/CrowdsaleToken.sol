
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";
import "./Ownable.sol";
import "./Vault.sol";



contract CrowdsaleToken is
StandardToken, Recoverable
{
	using FreezeVaultOp for FreezeVaultOp.t;
	using CrowdsaleTokenHelper for CrowdsaleTokenHelper.t;
	


	CrowdsaleTokenHelper.t  tokenInfo; 

	event Pause();
	event Unpause();

	event UpdatedTokenInformation(string newName, string newSymbol); 
	event Upgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);
	event ReceiveUpgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);

 
//////////////////////////////////////////////////////////////////////////////


	// solium-disable-next-line indentation
	function link(address _sale, TokenVault _voteVault,
		TokenVault _foundersVault)
	external onlyMaster
	{ 
		tokenInfo.link(_sale, _voteVault, _foundersVault, this, owner); 
	}
 
	function initFoundersTokens(
		address user, uint256 _amount, uint256 _unlockedAt)
	external onlyMaster
	{
		mintForFounders(user, _amount, _unlockedAt);
	}

	function deliverTokens(
		address _beneficiary,
		uint256 _tokenAmount
	)
	external
	onlySale
	{
		require(tokenInfo.sale != 0);
		mint(_beneficiary, _tokenAmount);
	}
 
	function pause() onlyOwner public {
		tokenInfo.paused = true;
		emit Pause();
	}

	function unpause() onlyOwner public {
		tokenInfo.paused = false;
		emit Unpause();
	}

	function setTokenInformation(string _name, string _symbol)
	external onlyOwner
	{
		tokenInfo.name = _name;
		tokenInfo.symbol = _symbol;
		emit UpdatedTokenInformation(_name, _symbol);
	}

	function setTokenURI(string _url)
	public onlyOwner
	{
		tokenInfo.tokenURI = _url;
	}

	function setTransferAgent(address addr, bool state)
	public
	onlyOwner inReleaseState(false)
	{
		tokenInfo.transferAgents[addr] = state;
	}
	function releaseTokenTransfer()
	public
	onlyReleaseAgent
	{
		tokenInfo.released = true;
	}

	function enableRefunds()
	public
	onlySale
	{
		tokenInfo.refunded = true;
	}

//////////////////////////////////////////////////////////////////////////////

	function transfer(address _to, uint _value)
	public
	canTransfer 
	returns(bool success)
	{
		return super.transfer(_to, _value);
	}
	function transferFrom(address _from, address _to, uint _value)
	public
	canTransfer 
	returns(bool success)
	{
		return super.transferFrom(_from, _to, _value);
	}


	function approve(
		address _spender,
		uint256 _value
	)
	public
	canTransfer 
	returns(bool)
	{
		return super.approve(_spender, _value);
	}

//////////////////////////////////////////////////////////////////////////////

	function paused() 
	public view returns(bool)
	{
		return tokenInfo.paused;
	}

	// solium-disable-next-line indentation
	function info()
	external
	view
	returns(string name, string symbol)
	{
		return tokenInfo.info(); 
	}

	function tokenURI() external view returns (string) {
		return tokenInfo.tokenURI;
	}
	
 

 

	function unlockfoundersToken(address _to)
	public
	{
		tokenInfo.unlockfoundersToken(_to);
	} 



	function startProposal(string title, string _url)
	public
	returns(uint256 ProposalID)
	{
		address sender = msg.sender;
		uint256 amount = lockBalanceTo(tokenInfo.vote_account.holder);
		uint256 total = totalSupply();
		return tokenInfo.startProposal(sender, title, _url, amount, MiscOp.currentTime().add(tokenInfo.voteLockSeconds), total);
	}

	function voteProposal(uint256 id)
	public
	{
		address sender = msg.sender;
		uint256 amount = lockBalanceTo(tokenInfo.vote_account.holder);
		tokenInfo.voteProposal(sender, id, amount, MiscOp.currentTime().add(tokenInfo.voteLockSeconds));
	}
	function unlockVotableToken()
	public
	{
		tokenInfo.unlockVotableToken();
	}



	function voteTotalSupply() public view returns(uint256) {
		return tokenInfo.voteTotalSupply(); 
	}
	function voteBalanceOf(address _owner) public view returns(uint256) {
		return tokenInfo.voteBalanceOf(_owner); 
	}

//////////////////////////////////////////////////////////////////////////////

	modifier onlySale() {
		require(msg.sender == address(tokenInfo.sale));
		_;
	}

	modifier onlyReleaseAgent() {
		require(msg.sender == address(tokenInfo.releaseAgent));
		_;
	}
 
	modifier canTransfer() {
		address sender = msg.sender;
		require(!tokenInfo.refunded && (tokenInfo.released || tokenInfo.transferAgents[sender]));
		_;
	}
	modifier inReleaseState(bool releaseState) {
		if (releaseState != tokenInfo.released) {
			revert();
		}
		_;
	}
//////////////////////////////////////////////////////////////////////////////



	modifier inUpgradable() {
		require(tokenInfo.inUpgrading);
		require(tokenInfo.inToken != 0);
		require(tokenInfo.inToken == msg.sender);
		_;
	}
	modifier outUpgradable() {
		require(tokenInfo.outUpgrading);
		require(tokenInfo.outToken != 0);
		_;
	}
	function setInToken(address _inToken)
	external onlyOwner  {
		tokenInfo.inToken = _inToken;
	}
	function setOutToken(address _outToken)
	external onlyOwner  {
		tokenInfo.outToken = _outToken;
	}

	function enableInUpgrading()
	external onlyOwner  {
		require(tokenInfo.inToken != 0);
		tokenInfo.inUpgrading = true;
	}

	function enableOutUpgrading()
	external onlyOwner  {
		require(tokenInfo.outToken != 0);
		tokenInfo.outUpgrading = true;
	}


	function burntTotalSupply() public view returns(uint256) {
		return tokenInfo.upgrade_burnt.totalSupply();
	}
	function burntBalanceOf(address _owner) public view returns(uint256) {
		return tokenInfo.upgrade_burnt.balanceOf(_owner);
	}

////////////////////////////////////////////////////////////////////////////////

	function upgrade()
	external
	outUpgradable
	{
		upgradeUser(msg.sender);

	}



	// https://steemit.com/ethereum/@johannlilly/executing-functions-on-other-contracts-with-multisig-wallets-or-multisig-functions-on-ethereum
	// multi-sig can't call other contract function easily?
	// normal account can call other contract.
	function upgradeUser(address user)
	public
	outUpgradable
	{
		tokenInfo.vote_account.forceUnlock(user);
		uint256 amount0 = balanceOf(user); // balance here
		burn(user, amount0);
		tokenInfo.informReceiver(user, user, amount0, 0, 0);

		uint256 amount1 = tokenInfo.founders_account.account.balanceOf(user);		
		uint256 until1 = tokenInfo.founders_account.freezeEnds.dic[user];
		burn(tokenInfo.founders_account.holder, amount1);
		tokenInfo.informReceiver(tokenInfo.founders_account.holder, user, amount1, until1, 1);
		tokenInfo.destroyfoundersAccount(user);
	}




	function receiveUpgrade(address to, uint256 amount, uint256 lockEndAt, uint256 vaultType)
	external
	inUpgradable
	{
		if (vaultType == 1) {
			mintForFounders(to, amount, lockEndAt);
		} else {
			mint(to, amount);
		}
		emit ReceiveUpgrade(msg.sender, to, amount, lockEndAt, vaultType);
	}



////////////////////////////////////////////////////////////////////////////////
	function lockBalanceTo(TokenVault holder)
	private
	returns(uint256)
	{
		address sender = msg.sender;
		require(address(holder) != address(0x0));
		uint256 amount = balanceOf(sender);
		if (amount > 0) {
			transfer(holder, amount);
		}
		return amount;
	} 

	function mintForFounders(
		address _teamMultisig, uint256 _amount, uint256 _unlockedAt)
	private
	{
		
		mint(tokenInfo.founders_account.holder, _amount);
		tokenInfo.founders_account.lock(_teamMultisig, _amount, _unlockedAt);
		
	}
////////////////////////////////////////////////////////////////////////////////


	function recoverTokens(ERC20Basic token) public onlyOwner { // override
		super.recoverTokens(token);
		uint256 keep = tokenInfo.founders_account.account.totalSupply();
		RecoverVaultOp.recoverVaultTokens(tokenInfo.founders_account.holder, token, owner, keep);
		uint256 keep2 = tokenInfo.vote_account.account.totalSupply();
		RecoverVaultOp.recoverVaultTokens(tokenInfo.vote_account.holder, token, owner, keep2);
	}

	function recoverWeis() public onlyOwner  { // ether  // override
		super.recoverWeis();
		RecoverVaultOp.recoverVaultWeis(tokenInfo.founders_account.holder, owner, 0);
		RecoverVaultOp.recoverVaultWeis(tokenInfo.vote_account.holder, owner, 0);
	}


}


contract IUpgradeable {
	function upgrade() public;
	function receiveUpgrade(address to, uint256 amount, uint256 lockEndAt, uint256 vaultType) public;
}

library CrowdsaleTokenHelper {
	using SafeMath for uint256; 
	using FreezeVaultOp for FreezeVaultOp.t;
	using BalanceOp for BalanceOp.t;

	event UpdatedTokenInformation(string newName, string newSymbol); 
	event Upgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);
	event ReceiveUpgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);


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
		
		string tokenURI;
		string name;
		string symbol;
		uint256 decimals;

		address sale;
		uint256 voteLockSeconds;

		uint256 numProposals;

		address releaseAgent;
		bool released;
		bool refunded;
		bool paused;

		bool inUpgrading;
		bool outUpgrading;


		address inToken;
		address outToken;

		mapping(address => bool) transferAgents;
		mapping(uint256 => Proposal) proposals;


		FreezeVaultOp.t founders_account;
		FreezeVaultOp.t vote_account;
 

		BalanceOp.t founders_burnt;  
		BalanceOp.t upgrade_burnt;

	}

	// solium-disable-next-line indentation
	function info(t storage _this)
	internal
	view
	returns(string name, string symbol)
	{
		return (_this.name,_this.symbol); 
	}


 

	function unlockfoundersToken(t storage _this, address _to)
	internal
	{
		_this.founders_account.unlock(_to);
	} 

	// solium-disable-next-line indentation
	function startProposal(t storage _this, address initiator, string title, string url, uint256 more_amount,
		uint256 endDate, uint256 totalTokens)
	internal
	returns(uint256 ProposalID)
	{
		uint256 minProposal = totalTokens * 1 / 100;
		uint256 passGoal = totalTokens * 5 / 100;
		
		_this.vote_account.lock(initiator, more_amount, endDate);
		
		uint256 amount = _this.vote_account.account.balanceOf(initiator);
		require(amount >= minProposal);
		uint256 id = _this.numProposals++;
		_this.proposals[id] = CrowdsaleTokenHelper.Proposal(id, minProposal, passGoal,
			initiator, title, url, endDate, amount);
		_this.proposals[id].votes[initiator] = amount;
		return id; 
	}






	function voteProposal(t storage _this, address votor, uint256 id, uint256 more_amount, uint256 endDate)
	internal 
	{
		require(id < _this.numProposals);
		CrowdsaleTokenHelper.Proposal storage p = _this.proposals[id];
 
		require(MiscOp.currentTime() < p.endDate);

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





	function destroyfoundersAccount(t storage _this, address user)
	internal  
	{
		uint256 amount = _this.founders_account.account.balanceOf(user);
		if (amount > 0) {
			_this.founders_account.account.burn(user, amount);
			_this.founders_burnt.mint(user, amount);
		}
	}

	function informReceiver(t storage _this, address user, address beneficiary, uint256 amount, uint256 unlockedAt, uint256 vaultType)
	internal
	{
		if (amount > 0) {
			_this.upgrade_burnt.mint(user, amount);
			IUpgradeable(_this.outToken).receiveUpgrade(beneficiary, amount, unlockedAt, vaultType);
			emit Upgrade(user, _this.outToken, amount, unlockedAt, vaultType);
		}
	}



	// solium-disable-next-line indentation
	function link(t storage _this, address _sale, TokenVault _voteVault,
		TokenVault _foundersVault, ERC20Basic token, address releaseAgent)
	internal 
	{
		_this.sale = _sale;
		_this.vote_account.holder = _voteVault;
		_this.vote_account.token = token;
		_this.founders_account.holder = _foundersVault;
		_this.founders_account.token = token;

		_this.releaseAgent = releaseAgent; 
	}


}

