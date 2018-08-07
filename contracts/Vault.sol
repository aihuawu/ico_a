
pragma solidity ^ 0.4.24;

import "./ERC20.sol";
import "./Util.sol";
import "./ERC20Token.sol";
import "./Ownable.sol";


library VaultOp
{
	function transferERC20From(ERC20 token, address from, address to, uint256 amount) 
	internal  
	{
		token.transferFrom(from, to, amount);
	}


	function transferERC20Basic(ERC20Basic token, address to, uint256 amount) 
	internal  
	{
		token.transfer(to, amount);
	}


	function transferWei(address to, uint256 weis) 
	internal  
	{ // ether
		to.transfer(weis);
	}

}

library RecoverVaultOp
{
	using SafeMath for uint256; 

	function recoverVaultTokens(TokenVault holder, ERC20Basic token, address to, uint256 keep)
	internal 
	{
		uint256 amount = token.balanceOf(holder).sub(keep);
		holder.transferERC20Basic(token, to, amount);
	}

	function recoverVaultWeis(TokenVault holder, address to, uint256 keep)
	internal 
	{ // ether
		uint256 weis = address(holder).balance.sub(keep);
		holder.transferWei(to, weis);
	}

}


contract TokenVault
{
	address transferAgent;
	constructor(address _transferAgent)
	public
	{
		transferAgent = _transferAgent;
	}


	modifier fromTransferAgent() {
		MiscOp.requireEx(msg.sender == transferAgent);
		_;
	}
	function transferERC20Basic(ERC20Basic token, address to, uint256 amount) 
	public fromTransferAgent
	{
		VaultOp.transferERC20Basic(token, to, amount);
	}
	function transferWei(address to, uint256 weis) 
	public fromTransferAgent
	{ // ether
		VaultOp.transferWei(to, weis);
	}

	function() public payable {}

	// mapping(uint256 => uint256) dic; /* key is opId, value is index for ls[index] */

	// using Uint256List for Uint256List.t;
	// Uint256List.t all;

	// function test() public {

	// 	// all.add(3);
	// 	// dic[8]=8;

	// 	uint256 len = 93;
	// 	SortUtil.SimpleEntry[] memory ll=new SortUtil.SimpleEntry[](len);
	// 	for(uint256 i = 0; i<len; i++){
	// 	SortUtil.SimpleEntry memory a = SortUtil.SimpleEntry(i,i);
	// 	ll[i]=a;
	// 	}
	// 	// SortUtil.quickSort(ll,0,len-1,true);
	// 	// SortUtil.quickSort(ll,0,len-1,false);
	// 	SortUtil.quickSort(ll,0,len-1,true);
	// 	SortUtil.quickSort(ll,0,len-1,false);
	// 	SortUtil.quickSort(ll,0,len-1,true);
	// 	MiscOp.requireEx(ll[3].key==len-1-3);
	// 	SortUtil.quickSort(ll,0,len-1,false);
	// 	MiscOp.requireEx(ll[3].key==3);
	// }

	// 	// Uint256List.t all;

	// 	// AddressKeyUint256List.t userDic;
}




library VaultBalanceOp {
	using SafeMath for uint256; 
	using BalanceOp for BalanceOp.t; 

	struct t {
		BalanceOp.t account;
		TokenVault holder;
		ERC20 token;
	}

}




library FreezeBalanceOp {
	using SafeMath for uint256; 
	using BalanceOp for BalanceOp.t; 

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	event Mint(address indexed to, uint256 amount);
	event Burn(address indexed to, uint256 value);

	struct AddressInt {
		mapping(address => uint256) dic;
	}
	struct AddressAddressInt {
		mapping(address => mapping(address => uint256)) allowed;//dic2
	}


	struct t {
		BalanceOp.t account;
		AddressInt freezeEnds;
		TokenVault holder;
		ERC20Basic token;
	}



	// solium-disable-next-line indentation
	function lock(FreezeBalanceOp.t storage _this, 
		address to, uint256 amount, uint256 unlockedAt) 
	internal 
	{
		// MiscOp.requireEx(msg.sender == to);
		_this.account.mint(to, amount);
		_this.freezeEnds.dic[to] = unlockedAt;
		// VaultOp.transferERC20Basic(_this.token, _this.holder, amount);
	}


// needed for upgrade
	function forceUnlock(FreezeBalanceOp.t storage _this, address _to) 
	internal 
	{
		uint256 _amount = _this.account.balanceOf(_to);
		if (_amount > 0) {
			_this.account.burn(_to, _amount);
			_this.holder.transferERC20Basic(_this.token, _to, _amount);
		}
	}

	function unlock(FreezeBalanceOp.t storage _this, address _to) 
	internal 
	{
		uint256 unlockedAt = _this.freezeEnds.dic[_to]; 
	// solium-disable-next-line security/no-block-members
		if (now >= unlockedAt) { 
			forceUnlock(_this, _to);
		}
	}







}
