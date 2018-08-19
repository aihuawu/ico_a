
pragma solidity ^ 0.4.24;

import "./ERC20.sol";
import "./Util.sol";
import "./List.sol";
import "./ERC20Token.sol";
import "./Ownable.sol";
import "./Vault.sol";
import "./CrowdsaleToken.sol";
import "./ERC721.sol";
import "./ERC721Token.sol";
import "./ERC777.sol";
import "./ERC777Token.sol";






contract SimpleOwnable
{
	using SafeMath for uint256;
	using AddressUtils for address;

	address _owner;

	function owner() public view returns(address) {
		return _owner;
	}
}


contract SimpleNFT is
SimpleOwnable
{
	using SafeMath for uint256;
	using AddressUtils for address;

	function transfer(address _to) public returns(bool) {
		address sender = msg.sender;
		MiscOp.requireEx(_owner == sender);
		MiscOp.requireEx(_to != address(0));

		_owner = _to;
		
		emit Transfer(msg.sender, _to);
		return true;
	}
	event Transfer(address indexed from, address indexed to);

}


contract ApprovableNFT is 
SimpleNFT 
{

	address allowed;

	event Approval(address indexed owner, address indexed spender);


	function transfer(address _to) public returns(bool) {
		allowed = 0x0;
		return super.transfer(_to);
	}

	function transferFrom(
		address _from,
		address _to
	)
	public
	returns(bool)
	{ 
		address sender = msg.sender;
		MiscOp.requireEx(allowed == sender); 
		MiscOp.requireEx(_owner == _from); 
		MiscOp.requireEx(_to != 0x0);

		allowed = 0x0;
		_owner = _to;

		emit Transfer(_from, _to);
		return true;
	}

	function approve(address _spender) public returns(bool) {
		address sender = msg.sender;
		MiscOp.requireEx(_owner == sender);
		MiscOp.requireEx(_spender != address(0));

		allowed = _spender;
		emit Approval(msg.sender, _spender);
		return true;
	}

	function approved()
	public
	view
	returns(address)
	{
		return allowed;
	}

}


contract SimpleFT 
{
	using SafeMath for uint256;
	using AddressUtils for address;


	mapping(address => uint256) balances;
	uint256 total;

	function totalSupply() public view returns(uint256) {
		return total;
	}

	function transfer(address _to, uint256 _value) public returns(bool) {
		MiscOp.requireEx(_value <= balances[msg.sender]);
		MiscOp.requireEx(_to != address(0));

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns(uint256) {
		return balances[_owner];
	}
	event Transfer(address indexed from, address indexed to, uint256 value);

}

contract ApprovableFT is 
SimpleFT 
{

	mapping(address => mapping(address => uint256)) internal allowed;

	event Approval(address indexed owner, address indexed spender, uint256 value);


	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
	public
	returns(bool)
	{
		MiscOp.requireEx(_value <= balances[_from]);
		MiscOp.requireEx(_value <= allowed[_from][msg.sender]);
		MiscOp.requireEx(_to != address(0));

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
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

}




contract SimpleRecoverable
{
	address recoverAgent;
	function agentRecoverNFT(address _to, address _asset) public returns(bool) {
		address sender = msg.sender;
		MiscOp.requireEx(sender == recoverAgent);
		MiscOp.requireEx(_asset != address(0));
		MiscOp.requireEx(_to != address(0));

		SimpleNFT(_asset).transfer(_to);

		emit RecoverNFT(sender, _to, _asset);
		return true;
	}
	function agentRecoverFT(address _to, address _asset, uint256 _value) public returns(bool) {
		address sender = msg.sender;
		MiscOp.requireEx(sender == recoverAgent);
		MiscOp.requireEx(_asset != address(0));
		MiscOp.requireEx(_to != address(0));

		SimpleFT(_asset).transfer(_to, _value);

		emit RecoverFT(sender, _to, _asset, _value);
		return true;
	}
	event RecoverFT(address indexed sender, address indexed to, address indexed asset, uint256 value);
	event RecoverNFT(address indexed sender, address indexed to, address indexed asset);

}

contract DebtRecoverable is
SimpleRecoverable
{
	function agentAcceptDebt(address _to, address _asset, uint256 _value) public returns(bool) {
		address sender = msg.sender;
		MiscOp.requireEx(sender == recoverAgent);
		MiscOp.requireEx(_asset != address(0));
		MiscOp.requireEx(_to != address(0));

		SimpleBondFT(_asset).acceptDebt(_to, _value);

		emit AcceptDebt(sender, _to, _asset, _value);
		return true;
	}
	event AcceptDebt(address indexed sender, address indexed to, address indexed asset, uint256 value);

}


contract AllowRecoverable is
SimpleRecoverable
{
	function agentAllow(address _spender, address _asset, uint256 _value) public returns(bool) {
		address sender = msg.sender;
		MiscOp.requireEx(sender == recoverAgent);
		MiscOp.requireEx(_asset != address(0));
		MiscOp.requireEx(_spender != address(0));

		ApprovableFT(_asset).approve(_spender, _value);

		emit Allow(sender, _spender, _asset, _value);
		return true;
	}
	event Allow(address indexed sender, address indexed to, address indexed asset, uint256 value);

}



contract EthRecoverable is
SimpleRecoverable
{
	function agentRecoverEth(address _to, uint256 _value) public returns(bool) {
		address sender = msg.sender;
		MiscOp.requireEx(sender == recoverAgent);
		MiscOp.requireEx(_to != address(0));

		_to.transfer(_value);

		emit RecoverEth(sender, _to, _value);
		return true;
	}
	event RecoverEth(address indexed sender, address indexed to, uint256 value);

}



contract SimpleBondFT 
{
	using SafeMath for uint256;
	address mintAgent;

	SimpleFT currency;
	uint256 matureDate;
	uint256 bondTotal;
	mapping(address => int256) balances;
	
	function init( 		// used for constructor 
		address _from,	// debt, negative asset
		address _to,	// bond, positive asset
		uint256 _value) 
	internal 
	{ 
		MiscOp.requireEx(_from != address(0));
		MiscOp.requireEx(_to != address(0));
		MiscOp.requireEx(_value > 0);

		_add(_to, int256(_value)); 		// inc first
		_add(_from, -int256(_value)); 	// dec second
	}


	function totalSupply() public view returns(uint256) {
		return bondTotal;
	}

	function transfer(address _to, uint256 _value) public returns(bool) {
		int256 svalue = int256(_value); 
		MiscOp.requireEx(_to != address(0));
		MiscOp.requireEx(balances[msg.sender] > 0);
		MiscOp.requireEx(svalue > 0);
		MiscOp.requireEx(balances[msg.sender] >= svalue);


		_add(_to, int256(_value)); // inc first
		_add(msg.sender, -int256(_value)); // dec second

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function acceptDebt(address _to, uint256 _value) public returns(bool) {
		int256 svalue = int256(_value); 
		MiscOp.requireEx(_to != address(0)); 
		MiscOp.requireEx(svalue > 0); 


		_add(_to, int256(_value)); // inc first
		_add(msg.sender, -int256(_value)); // dec second

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function _add(address _to, int256 _value) internal returns(bool) {
		uint256 a = balances[_to] > 0 ? uint256(balances[_to]) : 0;
		balances[_to] += int256(_value);
		uint256 b = balances[_to] > 0 ? uint256(balances[_to]) : 0;
		bondTotal = bondTotal.add(b).sub(a);
	}

	function balanceOf(address _owner) public view returns(int256) {
		return balances[_owner];
	}
	event Transfer(address indexed from, address indexed to, uint256 value);

}

contract ApprovableBondFT is 
SimpleBondFT 
{

	mapping(address => mapping(address => uint256)) internal allowed;
	mapping(address => mapping(address => uint256)) internal debtAllowed;
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	)
	public
	returns(bool)
	{
		int256 svalue = int256(_value);
		MiscOp.requireEx(_to != address(0));
		MiscOp.requireEx(balances[_from] > 0);
		MiscOp.requireEx(svalue > 0);
		MiscOp.requireEx(balances[_from] >= svalue);


		_add(_to, int256(_value)); // inc first
		_add(_from, -int256(_value)); // dec second

		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	// function debtTransferFrom(
	// 	address _from,
	// 	address _to,
	// 	uint256 _value
	// )
	// public
	// returns(bool)
	// {
	// 	int256 svalue = int256(_value);
	// 	MiscOp.requireEx(_from != address(0));
	// 	MiscOp.requireEx(_to != address(0));
	// 	MiscOp.requireEx(svalue > 0);


	// 	_add(_from, int256(_value)); // inc first
	// 	_add(_to, -int256(_value)); // dec second

	// 	allowed[_to][msg.sender] = allowed[_to][msg.sender].sub(_value);
	// 	emit Transfer(_from, _to, _value);
	// 	return true;
	// }

	function approve(address _spender, uint256 _value) public returns(bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	// function debtApprove(address _spender, uint256 _value) public returns(bool) {
	// 	debtAllowed[msg.sender][_spender] = _value;
	// 	emit Approval(msg.sender, _spender, _value);
	// 	return true;
	// }

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

}


contract SimpleWallet is
SimpleOwnable, SimpleRecoverable
{
	
}


contract SimpleBond is 
ApprovableBondFT, SimpleRecoverable
{

}

contract SimpleOption is 
ApprovableFT, SimpleRecoverable
{

}

contract SimpleRightToken is // product and service token
ApprovableFT, SimpleRecoverable
{

}

contract SimpleServiceRightBond is 
ApprovableBondFT, SimpleRecoverable
{

}


contract MintableServiceFT is 
ApprovableFT, SimpleRecoverable
{
	
}
contract MintableServiceReceiptFT is 
ApprovableFT, SimpleRecoverable
{
	
}

contract SaleCurrency is 
ApprovableFT, SimpleRecoverable
{

}


contract SimpleSellerToken is 
ApprovableNFT, SimpleRecoverable
{

}

contract SimpleBuyerToken is
ApprovableNFT, SimpleRecoverable
{

}
contract DebtBuyerToken is
ApprovableNFT, DebtRecoverable
{

}


contract ShoppingMarket  
{

	function transferFromFT(
		address _from,
		address _to,
		ApprovableFT token, 
		uint256 _value) 
	public 
	{ 
		token.transferFrom(_from, _to, _value);
	}

}




contract SimpleIcoPreOption
{
	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;

	// Debenture debt bond


	struct ContractEntry {
		address id;
		uint256 productId;

		address seller;
		SimpleSellerToken sellerWorkingVault;
		SimpleSellerToken sellerFinalVault;
		

		ShoppingMarket market;
		SaleCurrency currency;

		SimpleOption optionToken;
		address targetToken;

		uint256 TokenPricePerGG;
		uint256 OptionPricePerGG;


		uint256 sellerAccount;

		uint256 buyerPrimary;

	

	}
	ContractEntry entry;

	uint256 constant GG = 10**18;

	function open() 
	internal 
	{ 			
		entry.sellerWorkingVault = new SimpleSellerToken();
	}
	
	
	function buyOption(address buyer, uint256 currencyAmount) 
	internal 
	{
		entry.market.transferFromFT(buyer, entry.sellerWorkingVault, 
			entry.currency, currencyAmount); // refundable
		entry.sellerWorkingVault.agentRecoverFT(buyer, 
			entry.optionToken, currencyAmount);
	}

	function refund(address buyer) 
	internal 
	{
		uint256 currencyAmount = entry.optionToken.balanceOf(buyer);
		entry.sellerWorkingVault.agentRecoverFT(buyer, entry.currency,
			currencyAmount); 
		entry.market.transferFromFT(buyer, entry.sellerFinalVault, entry.optionToken, 
			currencyAmount);
	}

	function executeOption(address buyer) 
	internal 
	{
		uint256 currencyAmount = entry.optionToken.balanceOf(buyer);
		uint256 tokenAmount = GG.mul(currencyAmount).div(entry.OptionPricePerGG);
		uint256 currencyAmount2 = tokenAmount.mul(entry.TokenPricePerGG).div(GG);
		
		entry.market.transferFromFT(buyer, entry.sellerFinalVault, 
			entry.currency, currencyAmount2);
		entry.sellerWorkingVault.agentRecoverFT(buyer, 
			entry.targetToken, tokenAmount);

		entry.sellerWorkingVault.agentRecoverFT(entry.sellerFinalVault, entry.currency,
			currencyAmount); 
		entry.market.transferFromFT(buyer, entry.sellerFinalVault, entry.optionToken,  
			currencyAmount);
			
	}
	function close() 
	internal pure
	{ 			
	}
}


contract LockedIcoSale
{
	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;

	// Debenture debt bond

	struct BuyerInfo {
		address lastOwner;
		uint256 currencyAmount;
		uint256 tokenAmount;
		
	}
	struct ContractEntry {
		address id;
		uint256 productId;

		address seller;
		SimpleSellerToken sellerInitialVault;
		SimpleSellerToken sellerWorkingVault;
		SimpleSellerToken sellerFinalVault;
		

		ShoppingMarket market;
		SaleCurrency currency;

		address targetToken;

		uint256 TokenPricePerGG;
		uint256 OptionPricePerGG;


		uint256 sellerAccount;

		uint256 buyerPrimary;

		// list_address.t nft;
		mapping(address => BuyerInfo) buyInfos; // SimpleBuyerToken -> BuyerInfo
		mapping(address => address) initialBuyers; // buyer -> SimpleBuyerToken
	

	}
	ContractEntry entry;

	uint256 constant GG = 10**18;

	function open() 
	internal 
	{ 			
		entry.sellerInitialVault = new SimpleSellerToken();
		entry.sellerWorkingVault = new SimpleSellerToken();
	}
	
	
	function buyToken(address buyer, uint256 currencyAmount) 
	internal 
	{
		SimpleBuyerToken buyerVault = new SimpleBuyerToken();
		uint256 tokenAmount = GG.mul(currencyAmount).div(entry.OptionPricePerGG);

		BuyerInfo memory bi = BuyerInfo({
			lastOwner : buyer, 
			currencyAmount : currencyAmount, 
			tokenAmount : tokenAmount
		});
		entry.buyInfos[address(buyerVault)] = bi;

		entry.market.transferFromFT(buyer, buyerVault, 
			entry.currency, bi.currencyAmount); // refundable
		entry.sellerInitialVault.agentRecoverFT(entry.sellerWorkingVault, 
			entry.targetToken, bi.tokenAmount);
	}

	function refund(address buyerVault) 
	internal 
	{
		SimpleBuyerToken bv = SimpleBuyerToken(buyerVault);
		address buyer = bv.owner();
		
		BuyerInfo storage bi = entry.buyInfos[buyerVault];


		bv.agentRecoverFT(buyer, entry.currency,
			bi.currencyAmount); 
		entry.sellerWorkingVault.agentRecoverFT(entry.sellerFinalVault, entry.targetToken, 
			bi.tokenAmount);
	}
	
	function finalize(address buyerVault) 
	internal 
	{
		SimpleBuyerToken bv = SimpleBuyerToken(buyerVault);
		address buyer = bv.owner();
		
		BuyerInfo storage bi = entry.buyInfos[buyerVault];


		bv.agentRecoverFT(entry.sellerFinalVault, entry.currency,
			bi.currencyAmount); 
		entry.sellerWorkingVault.agentRecoverFT(buyer, entry.targetToken, 
			bi.tokenAmount);
			
	}
	function close() 
	internal pure
	{ 			
	}
}


contract MarginBroke
{
	
	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;

	// Debenture debt bond


	struct BuyerInfo {
		address lastOwner;
		uint256 currencyAmount;
		uint256 tokenAmount;
		
	}

	struct ContractEntry {
		address id;
		uint256 productId;

		address seller;
		SimpleSellerToken sellerInitialVault;
		SimpleSellerToken sellerWorkingVault;
		SimpleSellerToken sellerFinalVault;
		

		ShoppingMarket market;
		SaleCurrency currency;

		SimpleBond bondToken;
		address targetToken;

		uint256 TokenPricePerGG;
		uint256 OptionPricePerGG;


		uint256 sellerAccount;

		uint256 buyerPrimary;

	
		mapping(address => BuyerInfo) buyInfos; // SimpleBuyerToken -> BuyerInfo
		mapping(address => address) initialBuyers; // buyer -> SimpleBuyerToken

	}
	ContractEntry entry;

	uint256 constant GG = 10**18;

	function open() 
	internal 
	{ 			
		entry.sellerWorkingVault = new SimpleSellerToken();
	}
	
	
	function borrow(address buyer, uint256 currencyAmount) 
	internal 
	{
		DebtBuyerToken buyerVault = new DebtBuyerToken();
		uint256 tokenAmount = GG.mul(currencyAmount).div(entry.OptionPricePerGG);

		BuyerInfo memory bi = BuyerInfo({
			lastOwner : buyer, 
			currencyAmount : currencyAmount, 
			tokenAmount : tokenAmount
		});
		entry.buyInfos[address(buyerVault)] = bi;


		buyerVault.agentAcceptDebt(entry.sellerInitialVault, entry.currency,
			bi.currencyAmount); 
		entry.sellerInitialVault.agentRecoverFT(buyerVault, 
			entry.currency, currencyAmount);
	}


	function close() 
	internal pure
	{ 			
	}
}


contract SimpleIcoOption
{
	
	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;

	// Debenture debt bond


	struct ContractEntry {
		address id;
		uint256 productId;

		address seller;
		SimpleSellerToken sellerInitialVault;
		SimpleSellerToken sellerWorkingVault;
		SimpleSellerToken sellerFinalVault;
		

		ShoppingMarket market;
		SaleCurrency currency;

		SimpleOption optionToken;
		address targetToken;

		uint256 TokenPricePerGG;
		uint256 OptionPricePerGG;


		uint256 sellerAccount;

		uint256 buyerPrimary;

	

	}
	ContractEntry entry;

	uint256 constant GG = 10**18;

	function open() 
	internal 
	{ 			
		entry.sellerWorkingVault = new SimpleSellerToken();
	}
	
	
	function buyOption(address buyer, uint256 currencyAmount) 
	internal 
	{
		entry.market.transferFromFT(buyer, entry.sellerWorkingVault, 
			entry.currency, currencyAmount); // refundable
		entry.sellerWorkingVault.agentRecoverFT(buyer, 
			entry.optionToken, currencyAmount);
	}

	function executeOption(address buyer) 
	internal 
	{
		uint256 currencyAmount = entry.optionToken.balanceOf(buyer);
		uint256 tokenAmount = GG.mul(currencyAmount).div(entry.OptionPricePerGG);
		uint256 currencyAmount2 = tokenAmount.mul(entry.TokenPricePerGG).div(GG);
		
		entry.market.transferFromFT(buyer, entry.sellerFinalVault, 
			entry.currency, currencyAmount2);
		entry.sellerWorkingVault.agentRecoverFT(buyer, 
			entry.targetToken, tokenAmount);

		entry.sellerWorkingVault.agentRecoverFT(entry.sellerFinalVault, entry.currency,
			currencyAmount); 
		entry.market.transferFromFT(buyer, entry.sellerFinalVault, entry.optionToken,  
			currencyAmount);
			
	}
	function close() 
	internal pure
	{ 			
	}
}


contract SimpleIcoSale
{
	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;

	// Debenture debt bond

	struct BuyerInfo {
		// address buyer;
		SimpleBuyerToken buyerVault;

		uint256 currencyAmount;
		uint256 tokenAmount;
		
	}
	struct ContractEntry {
		address id;
		uint256 productId;

		address seller;
		SimpleSellerToken sellerInitialVault;
		SimpleSellerToken sellerWorkingVault;
		SimpleSellerToken sellerFinalVault;
		

		ShoppingMarket market;
		SaleCurrency currency;

		address targetToken;

		uint256 TokenPricePerGG;
		uint256 OptionPricePerGG;


		uint256 sellerAccount;

		uint256 buyerPrimary;

		list_address.t buyers;
		mapping(address => BuyerInfo) buyInfos;
	

	}
	ContractEntry entry;

	uint256 constant GG = 10**18;

	function open() 
	internal 
	{ 			
		entry.sellerWorkingVault = new SimpleSellerToken();
	}
	
	
	function buyToken(address buyer, uint256 currencyAmount) 
	internal 
	{
		// SimpleBuyerToken buyerVault = new SimpleBuyerToken();
		uint256 tokenAmount = GG.mul(currencyAmount).div(entry.OptionPricePerGG); //TODO
		

		entry.market.transferFromFT(buyer, entry.sellerFinalVault, 
			entry.currency, currencyAmount); 
		entry.sellerWorkingVault.agentRecoverFT(buyer, 
			entry.targetToken, tokenAmount);
	}
	
	function close() 
	internal pure
	{ 			
	}
}


contract SimpleLoan
{
	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;

	// Debenture debt bond

	struct BuyerInfo {
		// address buyer;
		SimpleBuyerToken buyerVault;

		uint256 currencyAmount;
		uint256 tokenAmount;
		
	}
	struct ContractEntry {
		address id;
		uint256 productId;

		address seller;
		SimpleSellerToken sellerInitialVault;
		SimpleSellerToken sellerWorkingVault;
		SimpleSellerToken sellerFinalVault;
		

		ShoppingMarket market;
		SaleCurrency currency;

		address targetToken;

		uint256 TokenPricePerGG;
		uint256 OptionPricePerGG;


		uint256 sellerAccount;

		uint256 buyerPrimary;

		list_address.t buyers;
		mapping(address => BuyerInfo) buyInfos;
	

	}
	ContractEntry entry;

	uint256 constant GG = 10**18;

	function open() 
	internal 
	{ 			
		entry.sellerWorkingVault = new SimpleSellerToken();
	}
	
	
	function buyToken(address buyer, uint256 currencyAmount) 
	internal 
	{
		// SimpleBuyerToken buyerVault = new SimpleBuyerToken();
		uint256 tokenAmount = GG.mul(currencyAmount).div(entry.OptionPricePerGG); //TODO
		

		entry.market.transferFromFT(buyer, entry.sellerFinalVault, 
			entry.currency, currencyAmount); 
		entry.sellerWorkingVault.agentRecoverFT(buyer, 
			entry.targetToken, tokenAmount);
	}
	
	function close() 
	internal pure
	{ 			
	}
}


contract SimpleSaleOne  
{
	using SafeMath for uint256;
	

	struct ContractEntry { // todo comment
		address id;
		uint256 productId;
		address initialxSeller;	// the token owners can change 
		address initialxBuyer;

		address seller;
		SimpleSellerToken sellerWorkingVault;
		address buyer;
		SimpleBuyerToken buyerVault;

		ShoppingMarket market;
		SaleCurrency currency;
		
		string title;
		string url;
		string description;
		

		uint256 sellerDiscount;
		uint256 sellerGuarantee; // penality
		bool sellerGuaranteeToBuyer;

		uint256 buyerPrimary;
		uint256 buyerGuarantee; // penality
		bool buyerGuaranteeToSeller;

		uint256 createTime;
		uint256 closeDeadlineTime;
		// open, OKClosed, cancel, CancelClosed
		// cancel action, 2x2
	}
	ContractEntry entry;


	function buy() 
	internal 
	{ 
		// entry.buyer = msg.sender;
		entry.sellerWorkingVault = new SimpleSellerToken();
		entry.buyerVault = new SimpleBuyerToken();
		entry.market.transferFromFT(entry.seller, entry.sellerWorkingVault, 
			entry.currency, entry.sellerDiscount + entry.sellerGuarantee);
		entry.market.transferFromFT(entry.buyer, entry.buyerVault, 
			entry.currency, entry.buyerPrimary + entry.buyerGuarantee);
			
	}


	function okClose() 
	internal 
	{ 
		entry.sellerWorkingVault.agentRecoverFT(entry.seller, 
			entry.currency, entry.sellerDiscount + entry.sellerGuarantee);
		entry.buyerVault.agentRecoverFT(entry.seller, 
			entry.currency, entry.buyerPrimary + entry.buyerGuarantee);
			
	}

	function cancelByBuyer(bool requestGuarantee) 
	internal 
	{ 
		entry.sellerGuaranteeToBuyer = requestGuarantee;
	}

	function cancelBySeller(bool requestGuarantee) 
	internal 
	{ 
		entry.buyerGuaranteeToSeller = requestGuarantee;
	}

	function cancelClose()
	internal
	{
		entry.sellerWorkingVault.agentRecoverFT(entry.seller,
			entry.currency, entry.sellerDiscount);
		entry.sellerWorkingVault.agentRecoverFT(
			entry.sellerGuaranteeToBuyer ? entry.buyer : entry.seller,
			entry.currency, entry.sellerGuarantee);

		entry.buyerVault.agentRecoverFT(entry.buyer,
			entry.currency, entry.buyerPrimary);
		entry.buyerVault.agentRecoverFT(
			entry.buyerGuaranteeToSeller ? entry.seller : entry.buyer,
			entry.currency, entry.buyerGuarantee);
	}


}























contract DiscountStore is 
SimpleRecoverable
{
	using SafeMath for uint256;
	




}


contract DiscountToken is 
SimpleRecoverable
{
	using SafeMath for uint256;
	




}

contract SellerToken is 
SimpleRecoverable
{
	using SafeMath for uint256;
	




}

contract BuyerServiceToken is 
SimpleRecoverable
{
	using SafeMath for uint256;
	




}

library DiscountSchema 
{

	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;
	using one_many_address_uint256 for one_many_address_uint256.t;
	using one_many_uint256_uint256 for one_many_uint256_uint256.t;

	struct Person {
		address user;
		string aliasName;
		string url;
		string contact;
		string description;
		uint256 createTime;
		uint256 upVote;
		uint256 downVote;
	}

	struct Product {
		uint256 id;
		address user;
		string title;
		string url;
		string description;
		
		uint256 sellerDiscount;
		uint256 sellerGuarantee;

		uint256 buyerPrimary;
		uint256 buyerGuarantee;

		uint256 createTime;
		uint256 daysBeforeClose;
		uint256 upVote;
		uint256 downVote;
	}

	struct OrderEntry {
		uint256 id;
		uint256 productId;
		address seller;	// the token owners can change 
		address buyer;
		
		string title;
		string url;
		string description;
		
		uint256 sellerWorkingVault;
		uint256 buyerVault;

		uint256 sellerDiscount;
		uint256 sellerGuarantee;
		uint256 buyerPrimary;
		uint256 buyerGuarantee;

		uint256 createTime;
		uint256 closeDeadlineTime;
		// open, OKClosed, cancel, CancelClosed
		// cancel action, 2x2
	}

	struct OrderMessage {
		uint256 id;
		address seller;	
		uint256 productId;
		uint256 orderId;
		
		address from;	
		string description;
	}

	struct PersonInfo {
		
		mapping(address => Person) persons;
		list_address users;

	}
	struct ProductInfo {
		
		mapping(uint256 => Product) products;
		one_many_address_uint256.t userDic; // user <-> productId

	}
	struct OrderInfo {
		
		mapping(uint256 => OrderEntry) orders;
		one_many_address_uint256.t sellerDic; 
		one_many_address_uint256.t buyerDic; 	// user <-> orderId

	}

	struct MessageInfo {
		
		mapping(uint256 => OrderMessage) messages;	// messageId key
		one_many_address_uint256.t fromDic; 
		one_many_address_uint256.t sellerMessageDic; 
		one_many_address_uint256.t productDic; 
		one_many_address_uint256.t orderDic; 

	}

	struct OrderDb {
		PersonInfo persons;
		ProductInfo products;
		OrderInfo orders;
		MessageInfo messsages;

	}



}



// library TokenAddressLib 
// {

// /*
// asset has owner, owner can has asset
// owner -> asset

// no tokenId: 
// 	(POA, GCA, BCA) -> ...
// 	FT <- ...
// tokenId: 
// 	() -> ...
// 	(FT/amount) <- ...
// 	(NFT) <- ...
// 	(FT/amount) <- ... -> ...
// 	(NFT) <- ... -> ...

// */


// 	enum AddressNodeType {
// 		noTokenId_x_isOwner_x,
// 		hasTokenId_x_isOwner_x,

// 		noTokenId_POA_isOwner_notAsset,
// 		noTokenId_GCA_isOwner_notAsset,
// 		noTokenId_BCA_isOwner_notAsset,
// 		noTokenId_FT_notOwner_isAsset,
// 		hasTokenId_Owner_isOwner_notAsset,
// 		hasTokenId_FT_notOwner_isAsset,
// 		hasTokenId_FT_isOwner_isAsset,
// 		hasTokenId_NFT_notOwner_isAsset,
// 		hasTokenId_NFT_isOwner_isAsset

// 	}

// 	struct AddressNode {
// 		uint256 id; 
// 		address addr; 
// 		uint256 tokenId; 
// 		AddressNodeType nodeType; 
// 	}
	

// 	struct Owner {
// 		AddressNode node;
// 	} 

// 	struct Asset {
// 		AddressNode node;
// 	}


// }




// library DerivativeTokenLib 
// {


// 	struct DerivativeDb {
// 		uint256 nextId;
// 		address myAddress;
// 		// balances[asset] = owner
// 		mapping(uint256 => uint256) ownership;	// for NFT 
// 		mapping(uint256 => uint256) tokenApprovals;

// 		// subTotal[asset] = subTotalSupply
// 		mapping(uint256 => uint256) subTotal;
// 		// balances[asset][owner] = amount
// 		mapping(uint256 => mapping(uint256 => uint256)) balances;	// for FT asset
// 		mapping(address => uint256) anodes; 
// 		// inodes[tokenId] = nodeId
// 		// mapping(uint256 => uint256) inodes;	
// 		mapping(address => mapping(uint256 => uint256)) nodes;

// 		// balances[asset][owner][spender] = amount
// 		mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) allowed;

// 	}

// 	function approve(
// 		DerivativeDb storage db,
// 		TokenAddressLib.Owner sender, 
// 		TokenAddressLib.Owner _to,
// 		TokenAddressLib.Asset assetNFT) 
// 	internal returns(bool success)  
// 	{
// 		MiscOp.requireEx(db.ownership[assetNFT.node.id] == sender.node.id);
// 		db.tokenApprovals[assetNFT.node.id] = _to.node.id;
// 		return true;
// 	}

// 	function transferFrom(
// 		DerivativeDb storage db,
// 		TokenAddressLib.Owner _sender,
// 		TokenAddressLib.Owner _from,
// 		TokenAddressLib.Owner _to,
// 		TokenAddressLib.Asset assetNFT
// 	)
// 	internal returns(bool) 
// 	{
// 		// require from approval 
// 		MiscOp.requireEx(db.ownership[assetNFT.node.id] == _from.node.id);
// 		db.ownership[assetNFT.node.id] = _to.node.id;
// 		return true;
// 	}

// 	function balanceOf(
// 		DerivativeDb storage db,
// 		TokenAddressLib.Owner owner,
// 		TokenAddressLib.Asset assetFT) 
// 	internal view returns(uint256) 
// 	{ 
// 		return db.balances[assetFT.node.id][owner.node.id]; 
// 	}

// 	function totalSupply(
// 		DerivativeDb storage db,
// 		TokenAddressLib.Asset assetFT) 
// 	internal view returns(uint256) 
// 	{ 
// 		return db.subTotal[assetFT.node.id]; 
// 	}


// 	function approve(
// 		DerivativeDb storage db,
// 		TokenAddressLib.Owner sender, 
// 		TokenAddressLib.Owner _spender, 
// 		TokenAddressLib.Asset assetFT, uint256 _amount) 
// 	internal returns(bool success) 
// 	{
// 		db.allowed[assetFT.node.id][sender.node.id][_spender.node.id] = _amount;
// 		return true;
// 	}

// 	function transferFrom(
// 		DerivativeDb storage db,
// 		TokenAddressLib.Owner _sender,
// 		TokenAddressLib.Owner _from,
// 		TokenAddressLib.Owner _to,
// 		TokenAddressLib.Asset assetFT,
// 		uint256 amount
// 	)
// 	internal returns(bool) 
// 	{
// 		// require from approval
// 		db.balances[assetFT.node.id][_to.node.id] += amount;
// 		db.balances[assetFT.node.id][_from.node.id] -= amount;
// 		return true;
// 	}


// 	function allowance(
// 		DerivativeDb storage db, 
// 		TokenAddressLib.Owner sender, TokenAddressLib.Owner _spender,
// 		TokenAddressLib.Asset assetFT) 
// 	internal view returns (uint256) 
// 	{
// 		return db.allowed[assetFT.node.id][sender.node.id][_spender.node.id];
// 	}


// 	function nextId(
// 		DerivativeDb storage db) 
// 	internal returns(uint256) 
// 	{
// 		return db.nextId++;
// 	}

// 	function lookupAddressNode(
// 		DerivativeDb storage db,
// 		address owner)
// 	internal view returns(TokenAddressLib.AddressNode)
// 	{
// 		return TokenAddressLib.AddressNode({
// 			id: db.anodes[owner],
// 			addr: owner,
// 			tokenId: 0,
// 			nodeType: TokenAddressLib.AddressNodeType.noTokenId_x_isOwner_x
// 		});
// 	}

// 	function ensureAddressNode(
// 		DerivativeDb storage db,
// 		address owner)
// 	internal returns(TokenAddressLib.AddressNode)
// 	{
// 		if (db.anodes[owner] == 0x0) {
// 			db.anodes[owner] = nextId(db);
// 		}
// 		return TokenAddressLib.AddressNode({
// 			id: db.anodes[owner],
// 			addr: owner,
// 			tokenId: 0,
// 			nodeType: TokenAddressLib.AddressNodeType.noTokenId_x_isOwner_x
// 		});
// 	}


// 	function lookupAddressNode(
// 		DerivativeDb storage db,
// 		address owner, uint256 tokenId)
// 	internal view returns(TokenAddressLib.AddressNode)
// 	{
// 		return TokenAddressLib.AddressNode({
// 			id: db.anodes[owner],
// 			addr: owner,
// 			tokenId: tokenId,
// 			nodeType: TokenAddressLib.AddressNodeType.noTokenId_x_isOwner_x
// 		});
// 	}

// 	function ensureAddressNode(
// 		DerivativeDb storage db,
// 		address owner, uint256 tokenId)
// 	internal returns(TokenAddressLib.AddressNode)
// 	{
// 		if (db.nodes[owner][tokenId] == 0x0) {
// 			db.nodes[owner][tokenId] = nextId(db);
// 		}
// 		return TokenAddressLib.AddressNode({
// 			id: db.anodes[owner],
// 			addr: owner,
// 			tokenId: tokenId,
// 			nodeType: TokenAddressLib.AddressNodeType.hasTokenId_x_isOwner_x
// 		});
// 	}

// }


// contract DerivativeToken  
// {
// 	using DerivativeTokenLib for DerivativeTokenLib.DerivativeDb;
// 	DerivativeTokenLib.DerivativeDb db;


// 	function transferFrom(address from, address to, uint256 tokenId) public returns(bool) {
// 		TokenAddressLib.AddressNode memory senderAddressNode = db.ensureAddressNode(msg.sender);
// 		TokenAddressLib.Owner memory senderUser = TokenAddressLib.Owner({node : senderAddressNode});
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.ensureAddressNode(from);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory toAddressNode = db.ensureAddressNode(to);
// 		TokenAddressLib.Owner memory toUser = TokenAddressLib.Owner({node : toAddressNode});
// 		TokenAddressLib.AddressNode memory assetAddressNode = db.ensureAddressNode(address(this), tokenId);
// 		TokenAddressLib.Asset memory asset = TokenAddressLib.Asset({node : assetAddressNode});
// 		return db.transferFrom(senderUser, fromUser, toUser, asset);
// 	}

// 	function approve(address spender, uint256 tokenId) public returns(bool) {
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.ensureAddressNode(msg.sender);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory spenderAddressNode = db.ensureAddressNode(spender);
// 		TokenAddressLib.Owner memory spenderUser = TokenAddressLib.Owner({node : spenderAddressNode});
// 		TokenAddressLib.AddressNode memory assetAddressNode = db.ensureAddressNode(address(this), tokenId);
// 		TokenAddressLib.Asset memory asset = TokenAddressLib.Asset({node : assetAddressNode});
// 		return db.approve(fromUser, spenderUser, asset);
// 	}

// /**


// */
// 	function totalSupply(uint256 tokenId) public view returns (uint256) {
// 		TokenAddressLib.AddressNode memory assetAddressNode = db.lookupAddressNode(address(this), tokenId);
// 		TokenAddressLib.Asset memory asset = TokenAddressLib.Asset({node : assetAddressNode});
// 		return db.totalSupply(asset);
// 	}

// 	function balanceOf(address who, uint256 tokenId) public view returns (uint256) {
// 		TokenAddressLib.AddressNode memory node = db.lookupAddressNode(who);
// 		TokenAddressLib.Owner memory user = TokenAddressLib.Owner({node : node});
// 		TokenAddressLib.AddressNode memory assetAddressNode = db.lookupAddressNode(address(this), tokenId);
// 		TokenAddressLib.Asset memory asset = TokenAddressLib.Asset({node : assetAddressNode});
// 		return db.balanceOf(user, asset);
// 	}
// 	function transfer(address to, uint256 tokenId, uint256 value) public returns(bool) { 
// 		return transferFrom(msg.sender, to, tokenId, value);
// 	}
// 	event Transfer(address indexed from, address indexed to, uint256 value);
	
// 	function allowance(address from, address spender, uint256 tokenId) public view returns (uint256) {
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.lookupAddressNode(from);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory spenderAddressNode = db.lookupAddressNode(spender);
// 		TokenAddressLib.Owner memory spenderUser = TokenAddressLib.Owner({node : spenderAddressNode});
// 		TokenAddressLib.AddressNode memory assetAddressNode = db.lookupAddressNode(address(this), tokenId);
// 		TokenAddressLib.Asset memory asset = TokenAddressLib.Asset({node : assetAddressNode});
// 		return db.allowance(fromUser, spenderUser, asset);
// 	}

// 	function transferFrom(address from, address to, uint256 tokenId, uint256 value) public returns(bool) {
// 		TokenAddressLib.AddressNode memory senderAddressNode = db.ensureAddressNode(msg.sender);
// 		TokenAddressLib.Owner memory senderUser = TokenAddressLib.Owner({node : senderAddressNode});
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.ensureAddressNode(from);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory toAddressNode = db.ensureAddressNode(to);
// 		TokenAddressLib.Owner memory toUser = TokenAddressLib.Owner({node : toAddressNode});
// 		TokenAddressLib.AddressNode memory assetAddressNode = db.ensureAddressNode(address(this), tokenId);
// 		TokenAddressLib.Asset memory asset = TokenAddressLib.Asset({node : assetAddressNode});
// 		return db.transferFrom(senderUser, fromUser, toUser, asset, value);
// 	}

// 	function approve(address spender, uint256 tokenId, uint256 value) public returns(bool) {
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.ensureAddressNode(msg.sender);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory spenderAddressNode = db.ensureAddressNode(spender);
// 		TokenAddressLib.Owner memory spenderUser = TokenAddressLib.Owner({node : spenderAddressNode});
// 		TokenAddressLib.AddressNode memory assetAddressNode = db.ensureAddressNode(address(this), tokenId);
// 		TokenAddressLib.Asset memory asset = TokenAddressLib.Asset({node : assetAddressNode});
// 		return db.approve(fromUser, spenderUser, asset, value);
// 	}
// 	event Approval(address indexed owner, address indexed spender, uint256 value);

// }




// library PrimaryTokenLib 
// {


// 	struct PrimaryDb {
// 		uint256 nextId;
// 		address myAddress;
// 		uint256 total;
// 		// balances[owner] = amount
// 		mapping(uint256 => uint256) balances;	// for FT asset
// 		mapping(address => uint256) anodes; 
// 		mapping(address => mapping(uint256 => uint256)) nodes; 

// 		// balances[owner][spender] = amount
// 		mapping(uint256 => mapping(uint256 => uint256)) allowed;
// 	}

// 	function balanceOf(
// 		PrimaryDb storage db,
// 		TokenAddressLib.Owner owner) 
// 	internal view returns(uint256) 
// 	{ 
// 		return db.balances[owner.node.id]; 
// 	}

// 	function totalSupply(
// 		PrimaryDb storage db) 
// 	internal view returns(uint256) 
// 	{ 
// 		return db.total; 
// 	}
// 	function transferFrom(
// 		PrimaryDb storage db,
// 		TokenAddressLib.Owner _sender,
// 		TokenAddressLib.Owner _from,
// 		TokenAddressLib.Owner _to,
// 		uint256 amount
// 	)
// 	internal returns(bool) 
// 	{
// 		// require from approval
// 		db.balances[_to.node.id] += amount;
// 		db.balances[_from.node.id] -= amount;
// 		return true;
// 	}


// 	function approve(
// 		PrimaryDb storage db, 
// 		TokenAddressLib.Owner sender, TokenAddressLib.Owner _spender, uint256 _amount) 
// 	internal returns(bool success) 
// 	{
// 		db.allowed[sender.node.id][_spender.node.id] = _amount;
// 		return true;
// 	}

// 	function allowance(
// 		PrimaryDb storage db, 
// 		TokenAddressLib.Owner sender, TokenAddressLib.Owner _spender) 
// 	internal view returns (uint256) 
// 	{
// 		return db.allowed[sender.node.id][_spender.node.id];
// 	}

// 	function nextId(
// 		PrimaryDb storage db) 
// 	internal returns(uint256) 
// 	{
// 		return db.nextId++;
// 	}


// 	function lookupAddressNode(
// 		PrimaryDb storage db,
// 		address owner)
// 	internal view returns(TokenAddressLib.AddressNode)
// 	{
// 		return TokenAddressLib.AddressNode({
// 			id: db.anodes[owner],
// 			addr: owner,
// 			tokenId: 0,
// 			nodeType: TokenAddressLib.AddressNodeType.noTokenId_x_isOwner_x
// 		});
// 	}

// 	function ensureAddressNode(
// 		PrimaryDb storage db,
// 		address owner)
// 	internal returns(TokenAddressLib.AddressNode)
// 	{
// 		if (db.anodes[owner] == 0x0) {
// 			db.anodes[owner] = nextId(db);
// 		}
// 		return TokenAddressLib.AddressNode({
// 			id: db.anodes[owner],
// 			addr: owner,
// 			tokenId: 0,
// 			nodeType: TokenAddressLib.AddressNodeType.noTokenId_x_isOwner_x
// 		});
// 	}

// 	function ensureAddressNode(
// 		PrimaryDb storage db,
// 		address owner, uint256 tokenId)
// 	internal returns(TokenAddressLib.AddressNode)
// 	{
// 		if (db.nodes[owner][tokenId] == 0x0) {
// 			db.nodes[owner][tokenId] = nextId(db);
// 		}
// 		return TokenAddressLib.AddressNode({
// 			id: db.anodes[owner],
// 			addr: owner,
// 			tokenId: tokenId,
// 			nodeType: TokenAddressLib.AddressNodeType.hasTokenId_x_isOwner_x
// 		});
// 	}
// }

// contract PrimaryToken is 
// ERC20
// {
// 	using PrimaryTokenLib for PrimaryTokenLib.PrimaryDb;
// 	PrimaryTokenLib.PrimaryDb db;

// 	function totalSupply() public view returns (uint256) {
// 		return db.totalSupply();
// 	}

// 	function balanceOf(address who) public view returns (uint256) {
// 		TokenAddressLib.AddressNode memory node = db.lookupAddressNode(who);
// 		TokenAddressLib.Owner memory user = TokenAddressLib.Owner({node : node});
// 		return db.balanceOf(user);
// 	}
// 	function transfer(address to, uint256 value) public returns(bool) { 
// 		return transferFrom(msg.sender, to, value);
// 	}
// 	event Transfer(address indexed from, address indexed to, uint256 value);
	
// 	function allowance(address from, address spender) public view returns (uint256) {
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.lookupAddressNode(from);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory spenderAddressNode = db.lookupAddressNode(spender);
// 		TokenAddressLib.Owner memory spenderUser = TokenAddressLib.Owner({node : spenderAddressNode});
// 		return db.allowance(fromUser, spenderUser);
// 	}

// 	function transferFrom(address from, address to, uint256 value) public returns(bool) {
// 		TokenAddressLib.AddressNode memory senderAddressNode = db.ensureAddressNode(msg.sender);
// 		TokenAddressLib.Owner memory senderUser = TokenAddressLib.Owner({node : senderAddressNode});
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.ensureAddressNode(from);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory toAddressNode = db.ensureAddressNode(to);
// 		TokenAddressLib.Owner memory toUser = TokenAddressLib.Owner({node : toAddressNode});
// 		return db.transferFrom(senderUser, fromUser, toUser, value);
// 	}

// 	function approve(address spender, uint256 value) public returns(bool) {
// 		TokenAddressLib.AddressNode memory fromAddressNode = db.ensureAddressNode(msg.sender);
// 		TokenAddressLib.Owner memory fromUser = TokenAddressLib.Owner({node : fromAddressNode});
// 		TokenAddressLib.AddressNode memory spenderAddressNode = db.ensureAddressNode(spender);
// 		TokenAddressLib.Owner memory spenderUser = TokenAddressLib.Owner({node : spenderAddressNode});
// 		return db.approve(fromUser, spenderUser, value);
// 	}
// 	event Approval(address indexed owner, address indexed spender, uint256 value);

// }




// contract TokenHolder is 
// SupportsInterfaceWithLookup
// {
// 	function tokensToSend(
// 		address operator,	
// 		address from,	
// 		address to,
// 		uint256 amount,
// 		bytes userData,
// 		bytes operatorData
// 	) public {MiscOp.revertEx();}
	
// 	function tokensReceived(
// 		address operator,
// 		address from,
// 		address to,
// 		uint256 amount,
// 		bytes userData,
// 		bytes operatorData
// 	) public {MiscOp.revertEx();} 

// 	function onERC721Received(
// 		address _operator,
// 		address _from,
// 		uint256 _tokenId,
// 		bytes _data
// 	)
// 	public
// 	returns(bytes4) {MiscOp.revertEx();} 
// 	function onERC721ChildrenReceived(
// 		address _operator,
// 		address _from,
// 		uint256 _tokenId,
// 		uint256 amount,
// 		bytes _data
// 	)
// 	public
// 	returns(bytes4) {MiscOp.revertEx();} 
// }


// contract Derco is 
// ERC721, ERC721Token
// {
// 	struct BuyerFuture {
// 		uint256 id; // derivative id
// 		address derco;	
// 		address disco;	 
// 	}


// }

// library DiscountStoreOp 
// {

// 	struct t {
// 		uint256 nextId; // always > 0
		
// 	}

// }

/**
Financial derivative coin

ordco := discount + guarantee
pasco := left + guarantee
disco

Crowdsale
buy/mint disco


Exchange
exchange disco or pasco


Store:
deposit disco?
create pasco mint spec
buy pasco
refund pasco?



10% founders
10% business
10% company
10% new employee
60% crowdsale

*/