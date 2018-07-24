
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";
import "./Ownable.sol";
import "./Vault.sol";


contract CrowdsaleTokenBase is
StandardToken, Recoverable, Pausable
{
	Util.TokenInfo public tokenInfo;
	FoundersTokenVault foundersVault;
	VotableTokenVault voteVault;

	modifier onlySale() {
		require(msg.sender == address(tokenInfo.sale));
		_;
	}

}


contract FoundersToken is CrowdsaleTokenBase {


	function unlockfoundersToken(address _to)
	public
	{
		foundersVault.unlock(_to);
	}
}

contract VotableToken is CrowdsaleTokenBase {

	function startProposal(string title, string url)
	public
	returns(uint256 ProposalID)
	{
		require(address(voteVault) != address(0x0));
		uint256 amount = balanceOf(msg.sender);
		if (amount > 0) {
			transfer(voteVault, amount);
		}
		uint256 total = totalSupply();

		// solium-disable-next-line security/no-block-members
		return voteVault.startProposal(msg.sender, title, url, amount, now.add(tokenInfo.voteLockSeconds), total);
	}
	function voteProposal(uint256 id)
	public
	{
		require(address(voteVault) != address(0x0));
		uint256 amount = balanceOf(msg.sender);
		if (amount > 0) {
			transfer(voteVault, amount);
		}

		// solium-disable-next-line security/no-block-members
		voteVault.voteProposal(msg.sender, id, amount, now.add(tokenInfo.voteLockSeconds));
	}
	function unlockVotableToken()
	public
	{
		voteVault.unlockVotableToken(msg.sender);
	}


	function voteTotalSupply() public view returns(uint256) {
		return voteVault.totalSupply();
	}
	function voteBalanceOf(address _owner) public view returns(uint256) {
		return voteVault.balanceOf(_owner);
	}

}


contract ReleasableToken is CrowdsaleTokenBase {

	mapping(address => bool) transferAgents;

	modifier whenNotRefunded() {
		require(!tokenInfo.refunded);
		_;
	}
	modifier canTransfer(address _sender) {
		if (!tokenInfo.released) {
			if (!transferAgents[_sender]) {
				revert();
			}
		}
		_;
	}
	modifier inReleaseState(bool releaseState) {
		if (releaseState != tokenInfo.released) {
			revert();
		}
		_;
	}
	modifier onlyReleaseAgent() {
		if (msg.sender != tokenInfo.releaseAgent) {
			revert();
		}
		_;
	}

	function setReleaseAgent(address addr)
	public
	fromOwnerOrMaster inReleaseState(false)
	{
		tokenInfo.releaseAgent = addr;
	}
	function setTransferAgent(address addr, bool state)
	public
	fromOwnerOrMaster inReleaseState(false)
	{
		transferAgents[addr] = state;
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

	function transfer(address _to, uint _value)
	public
	canTransfer(msg.sender)
	whenNotPaused
	whenNotRefunded
	returns(bool success)
	{
		return super.transfer(_to, _value);
	}
	function transferFrom(address _from, address _to, uint _value)
	public
	canTransfer(_from)
	whenNotPaused
	whenNotRefunded
	returns(bool success)
	{
		return super.transferFrom(_from, _to, _value);
	}


	function approve(
		address _spender,
		uint256 _value
	)
	public
	whenNotPaused
	whenNotRefunded
	returns(bool)
	{
		return super.approve(_spender, _value);
	}

	function increaseApproval(
		address _spender,
		uint _addedValue
	)
	public
	whenNotPaused
	whenNotRefunded
	returns(bool success)
	{
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(
		address _spender,
		uint _subtractedValue
	)
	public
	whenNotPaused
	whenNotRefunded
	returns(bool success)
	{
		return super.decreaseApproval(_spender, _subtractedValue);
	}
}




contract IUpgradeable {
	function upgrade() external;
	function receiveUpgrade(address to, uint256 amount, uint256 lockEndAt, uint256 vaultType)external;
}


contract UpgradeableToken is IUpgradeable, CrowdsaleTokenBase, FoundersToken {
	event Upgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);
	event ReceiveUpgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);


	Util.Balance burnt;


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
	external fromOwnerOrMaster  {
		tokenInfo.inToken = _inToken;
	}
	function setOutToken(address _outToken)
	external fromOwnerOrMaster  {
		tokenInfo.outToken = _outToken;
	}

	function enableInUpgrading()
	external fromOwnerOrMaster  {
		require(tokenInfo.inToken != 0);
		tokenInfo.inUpgrading = true;
	}

	function enableOutUpgrading()
	external fromOwnerOrMaster  {
		require(tokenInfo.outToken != 0);
		tokenInfo.outUpgrading = true;
	}


	function burntTotalSupply() public view returns(uint256) {
		return Util.totalSupply(burnt);
	}
	function burntBalanceOf(address _owner) public view returns(uint256) {
		return Util.balanceOf(burnt, _owner);
	}


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
		voteVault.forceUnlockVotableToken(user);
		uint256 amount0 = balanceOf(user); // balance here
		burnMintTransfer(user, user, amount0, 0, 0);

		(uint256 amount1, uint256 until1) = foundersVault.freezeInfo(user);
		burnMintTransfer(foundersVault, user, amount1, until1, 1);
		foundersVault.burnMint(user);
	}

	function burnMintTransfer(address user, address beneficiary, uint256 amount, uint256 unlockedAt, uint256 vaultType)
	private
	{
		if (amount > 0) {
			Util.burn(account, user, amount);
			Util.mint(burnt, user, amount);
			IUpgradeable(tokenInfo.outToken).receiveUpgrade(beneficiary, amount, unlockedAt, vaultType);
			emit Upgrade(user, tokenInfo.outToken, amount, unlockedAt, vaultType);
		}
	}



	function receiveUpgrade(address to, uint256 amount, uint256 lockEndAt, uint256 vaultType)
	external
	inUpgradable
	{
		if (vaultType == 1) {
			mintForFounders(to, amount, lockEndAt);
		} else {
			Util.mint(account, to, amount);
		}
		emit ReceiveUpgrade(msg.sender, to, amount, lockEndAt, vaultType);
	}

	function mintForFounders(
		address _teamMultisig, uint256 _amount, uint256 _unlockedAt)
	internal
	{
		foundersVault.lock(_teamMultisig, _amount, _unlockedAt);
		Util.mint(account, foundersVault, _amount);
	}

}






contract DetailedERC20 is CrowdsaleTokenBase, ERC20Ex {
	event UpdatedTokenInformation(string newName, string newSymbol);

	string url;
	string public name;
	string public symbol;
	uint8 public decimals;


	function deliverTokens(
		address _beneficiary,
		uint256 _tokenAmount
	)
	external
	onlySale
	{
		require(tokenInfo.sale != 0);
		Util.mint(account, _beneficiary, _tokenAmount);
	}


	function setTokenInformation(string _name, string _symbol)
	external fromOwnerOrMaster
	{
		name = _name;
		symbol = _symbol;
		emit UpdatedTokenInformation(name, symbol);
	}

	function tokenURI() external view returns (string) {
		return url;
	}
	
	function setUrl(string _url)
	public fromOwnerOrMaster
	{
		url = _url;
	}

}


contract UnionCrowdsaleToken is DetailedERC20,
	ReleasableToken, FoundersToken, VotableToken, UpgradeableToken {


	// solium-disable-next-line indentation
	function link(address _sale, VotableTokenVault _voteVault,
		FoundersTokenVault _foundersVault)
	external fromOwnerOrMaster
	{
		tokenInfo.sale = _sale;
		voteVault = _voteVault;
		foundersVault = _foundersVault;

		setReleaseAgent(owner);
	}

	function initFoundersTokens(
		address user, uint256 _amount, uint256 _unlockedAt)
	external fromOwnerOrMaster
	{
		mintForFounders(user, _amount, _unlockedAt);
	}

}

