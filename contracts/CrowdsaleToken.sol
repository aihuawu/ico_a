
pragma solidity ^ 0.4.24;

import "./ERC20.sol";
import "./Util.sol";
import "./ERC20Token.sol";
import "./Ownable.sol";
import "./Vault.sol";



contract CrowdsaleToken is 
ERC20Ex, StandardToken, Recoverable
{
	using FreezeBalanceOp for FreezeBalanceOp.t;
	using CrowdsaleTokenHelper for CrowdsaleTokenHelper.t;
	


	CrowdsaleTokenHelper.t  tokenInfo; 

	event Pause();
	event Unpause();

	event UpdatedTokenInformation(string newName, string newSymbol); 
	event Upgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);
	event ReceiveUpgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);

 
//////////////////////////////////////////////////////////////////////////////


	// solium-disable-next-line indentation
	function link(address _sale)
	external onlyMaster
	{ 
		tokenInfo.link(_sale, owner); 
	}
  

	function deliverTokens(
		address _beneficiary,
		uint256 _tokenAmount
	)
	external
	onlySale
	{
		MiscOp.requireEx(tokenInfo.sale != 0);
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
	
  
	modifier onlySale() {
		MiscOp.requireEx(msg.sender == address(tokenInfo.sale));
		_;
	}

	modifier onlyReleaseAgent() {
		MiscOp.requireEx(msg.sender == address(tokenInfo.releaseAgent));
		_;
	}
 
	modifier canTransfer() {
		address sender = msg.sender;
		MiscOp.requireEx(!tokenInfo.refunded && (tokenInfo.released || tokenInfo.transferAgents[sender]));
		_;
	}
	modifier inReleaseState(bool releaseState) {
		MiscOp.requireEx(releaseState != tokenInfo.released);
		_;
	}
//////////////////////////////////////////////////////////////////////////////

   
	// function recoverTokens(ERC20Basic token) public onlyOwner { // override
	// 	super.recoverTokens(token);
	// 	// uint256 keep = tokenInfo.founders_account.account.totalSupply();
	// 	// RecoverVaultOp.recoverVaultTokens(tokenInfo.founders_account.holder, token, owner, keep);
	// }

	// function recoverWeis() public onlyOwner  { // ether  // override
	// 	super.recoverWeis();
	// 	// RecoverVaultOp.recoverVaultWeis(tokenInfo.founders_account.holder, owner, 0);
	// }


}


 
library CrowdsaleTokenHelper {
	using SafeMath for uint256; 
	using FreezeBalanceOp for FreezeBalanceOp.t;
	using BalanceOp for BalanceOp.t;

	event UpdatedTokenInformation(string newName, string newSymbol); 
	event Upgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);
	event ReceiveUpgrade(address indexed _from, address indexed _to, uint256 _value, uint256 lockEndAt, uint256 vaultType);


	// struct Proposal {
	// 	uint256 id; // zero based

	// 	uint256 minProposal; // init
	// 	uint256 passGoal; // pass

	// 	address initiator;
	// 	string title;
	// 	string url;
	// 	uint256 endDate;
	// 	uint256 total;
	// 	mapping(address => uint256) votes;


	// }


	struct t {
		
		string tokenURI;
		string name;
		string symbol;
		uint256 decimals;

		address sale;

		address releaseAgent;
		bool released;
		bool refunded;
		bool paused;

		bool inUpgrading;
		bool outUpgrading;


		address inToken;
		address outToken;

		mapping(address => bool) transferAgents;

 
	}

	// solium-disable-next-line indentation
	function info(t storage _this)
	internal
	view
	returns(string name, string symbol)
	{
		return (_this.name,_this.symbol); 
	}


  


	// solium-disable-next-line indentation
	function link(t storage _this, address _sale, address releaseAgent)
	internal 
	{
		_this.sale = _sale;
		
		// _this.founders_account.holder = _foundersVault;
		// _this.founders_account.token = token;

		_this.releaseAgent = releaseAgent; 
	}


}

