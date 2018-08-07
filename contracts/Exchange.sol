
pragma solidity ^ 0.4.24;
// pragma experimental ABIEncoderV2;

import "./List.sol";
import "./Util.sol";



contract SimpleExchange is
Recoverable
{
	using ExchangeHelper for ExchangeHelper.t;
	ExchangeHelper.t infoOp;

	constructor() public {
		infoOp.init();
	}


	function link(TokenVault vault)
	external onlyMaster
	{
		MiscOp.requireEx(vault != address(0));
		infoOp.vault = vault;
	}



	///////////////////////////////////////////////////////////////////////////
	function () // depositWei
	external payable
	{
		address user = msg.sender;
		uint256 weis = msg.value;
		infoOp.depositWei(user, weis);
	}

	function withdrawWei(uint256 weis)
	external
	{
		address user = msg.sender;
		MiscOp.requireEx(user != 0x0);
		MiscOp.requireEx(weis != 0x0);
		infoOp.withdrawWei(user, weis);
	}

	function balanceOfWei(address user)
	external
	view
	returns(uint256)
	{ 
		MiscOp.requireEx(user != 0x0);
		return infoOp.balanceOfWei(user);
	}

	function findWeiTransactionList(address _user) 
	external view
	returns(uint256[] transactionType, uint256[] weis, uint256[] createTime)
	{
		return infoOp.findWeiTransactionList(_user);
	}

	///////////////////////////////////////////////////////////////////////////




	function depositToken(address token, uint256 tokenAmount)
	external
	{
		address user = msg.sender;
		MiscOp.requireEx(token != 0x0);
		MiscOp.requireEx(user != 0x0);
		MiscOp.requireEx(tokenAmount != 0x0);
		infoOp.depositToken(token, user, tokenAmount);
	}

	function withdrawToken(address token, uint256 tokenAmount)
	external
	{
		address user = msg.sender;
		MiscOp.requireEx(token != 0x0);
		MiscOp.requireEx(user != 0x0);
		MiscOp.requireEx(tokenAmount != 0x0);
		infoOp.withdrawToken(token, user, tokenAmount);
	}

	function balanceOfToken(address token, address user)
	external
	view
	returns(uint256)
	{
		MiscOp.requireEx(token != 0x0);
		MiscOp.requireEx(user != 0x0);
		return infoOp.balanceOfToken(token, user);
	}


	function findTokenTransactionList(address token, address user) 
	external view
	returns(uint256[] transactionType, uint256[] tokenAmount, uint256[] createTime)
	{
		return infoOp.findTokenTransactionList(token, user);
	}





	///////////////////////////////////////////////////////////////////////////

	function sell(address token, uint256 price, uint256 tokenAmount)
	external
	returns(uint256)
	{
		address user = msg.sender;
		MiscOp.requireEx(token != 0x0);
		MiscOp.requireEx(user != 0x0);
		MiscOp.requireEx(price != 0x0);
		MiscOp.requireEx(tokenAmount != 0x0);
		return infoOp.sell(token, user, price, tokenAmount);
	}

	function buy(address token, uint256 price, uint256 weis)
	external
	returns(uint256)
	{
		address user = msg.sender;
		MiscOp.requireEx(token != 0x0);
		MiscOp.requireEx(user != 0x0);
		MiscOp.requireEx(price != 0x0);
		MiscOp.requireEx(weis != 0x0);
		return infoOp.buy(token, user, price, weis);
	}


	function cancelOrder(uint256 orderId)
	external
	{
		address user = msg.sender;
		MiscOp.requireEx(user != 0x0);
		infoOp.cancelOrder(user, orderId);
	}


	function orderList(address _token)
	external
	view
	returns (
		uint256[] id,
		address[] token,
		address[] user,
		// uint256[] orderType,
		// uint256[] weis,
		// uint256[] weisLeft,
		// uint256[] tokenAmount,
		uint256[] tokenAmountLeft
	) 
	{
		return infoOp.orderList(_token);
	}

	// function info()
	// external
	// view
	// returns(uint256 key, uint256 value, uint256[1] key2, uint256[1] value2)
	// {
	// 	mlist_keyvalue.keyvalue memory r = infoOp.info();
	// 	return (r.key, r.value, [r.key], [r.value]);
	// }

	
	enum How {a,b,cc,dd}
	function myOrderList()
	external
	pure
	returns (
		// uint256[] id,
		// address[] token,
		// address[] user,
		// uint256[] orderType,
		// uint256[] weis,
		// uint256[] weisLeft,
		uint256[1] tokenAmount,
		How[1] tokenAmountLeft
	) 
	{ 
		tokenAmount[0] = 5;
		tokenAmountLeft[0] = How.dd;
	}
 
	function myxOrderList()
	external
	view
	returns (
		uint256[] id,
		address[] token,
		address[] user,
		// uint256[] orderType,
		// uint256[] weis,
		// uint256[] weisLeft,
		// uint256[] tokenAmount,
		uint256[] tokenAmountLeft
	) 
	{
		address _user = msg.sender;
		MiscOp.requireEx(_user != 0x0);
		return infoOp.myOrderList(_user);
	}
 
// order detail, account detail, wei detail

	// // function orderDetail(uint256 orderId) // status, transactions
	// // external
	// // view
	// // {
	// // 	infoOp.orderDetail(orderId);
	// // }




}




library ExchangeHelper
{ 

	using SafeMath for uint256;
	using mlist_address for mlist_address.t;
	using mlist_uint256 for mlist_uint256.t;
	using list_address for list_address.t;
	using list_uint256 for list_uint256.t;
	using one_many_address_uint256 for one_many_address_uint256.t;
	using one_many_uint256_uint256 for one_many_uint256_uint256.t;


	uint256 constant kOrderSell = 1;
	uint256 constant kOrderBuy = 2;
	
	uint256 constant kTransaction_weiWithdrawal = 111;
	uint256 constant kTransaction_weiDeposit = 112;
	uint256 constant kTransaction_weiToOrder = 121;
	uint256 constant kTransaction_weiFromOrder = 122;

	uint256 constant kTransaction_tokenWithdrawal = 211;
	uint256 constant kTransaction_tokenDeposit = 212;
	uint256 constant kTransaction_tokenToOrder = 221;
	uint256 constant kTransaction_tokenFromOrder = 222;
	uint256 constant kTransaction_orderMatch = 300;


	struct WeiAccountEntry {
		uint256 weis;
	}

	struct WeiAccountInfo {
		uint256 total;
		mapping(address => WeiAccountEntry) table; /* key is accountId */
	}

	struct TokenAccountEntry {
		uint256 tokenAmount;
	}

	struct TokenAccountInfo {
		mapping(address => mapping(address => uint256)) token_user_id;
		mapping(uint256 => TokenAccountEntry) table; /* key is accountId */
		one_many_address_uint256.t tokenDic; /* key is token address */
		one_many_address_uint256.t userDic; /* key is user address */
	}



	struct FullOrderEntry {
		uint256 id;
		address token;
		address user;
		uint256 orderType;	 // 11 for sell, 11 for sellClosed, 21 for buy, 22 for buyClosed
		uint256 weis;
		uint256 weisLeft;
		uint256 tokenAmount;
		uint256 tokenAmountLeft;
		// uint256 createTime; 
	}
	struct BuyOrderEntry {
		// uint256 tokenAmount;	// in token unit e.g. tnano
		uint256 price; 	// in wei
		uint256 weis;	// in wei	weis = tokenAmount * price
		uint256 weisLeft;
		// uint256 cancelled_tokenAmount;
		// uint256 filled_tokenAmount;
		// uint256 filled_weis;
		// OrderStatus status;
		uint256 createTime;
		uint256 closeTime;
	}
	struct SellOrderEntry {
		uint256 price; 	// in wei
		uint256 tokenAmount;	// in token unit e.g. tnano
		uint256 tokenAmountLeft;
		// uint256 weis;	// in wei	weis = tokenAmount * price
		// uint256 cancelled_tokenAmount;
		// uint256 filled_tokenAmount;
		// uint256 filled_weis;
		// OrderStatus status;
		uint256 createTime;
		uint256 closeTime;
	}


	struct OneOrderInfo {
		one_many_address_uint256.t tokenDic; /* key is token address */
		one_many_address_uint256.t userDic; /* key is user address */
		// one_many_address_uint256.t closedUserDic; /* key is user address */
	}


	struct OrderInfo {
		mapping(uint256 => BuyOrderEntry) buyTable; /* key is orderId */
		OneOrderInfo buy;
		OneOrderInfo buyClosed;
		mapping(uint256 => SellOrderEntry) sellTable; /* key is orderId */
		OneOrderInfo sell;
		OneOrderInfo sellClosed;
	}


	// toOrder, fromOrder, deposit, withdrawal

	struct WeiTransactionEntry {
 

		uint256 transactionType;
		uint256 weis;
		uint256 createTime;
	}

	struct WeiTransactionInfo {

		mapping(uint256 => WeiTransactionEntry) transactions;

		one_many_address_uint256.t userDic; /* key is user address */
		one_many_uint256_uint256.t orderDic; /* key is orderId */

	}

	struct FullWeiTransactionEntry {
		uint256 id; 
		address user; 
		uint256 orderId;
		uint256 transactionType;
		uint256 weis;
		uint256 createTime;
	}


	struct TokenTransactionEntry {
		uint256 transactionType;
		uint256 tokenAmount;
		uint256 createTime;
	}

	struct TokenTransactionInfo {

		mapping(uint256 => TokenTransactionEntry) transactions;

		one_many_address_uint256.t tokenDic; /* key is token address */
		one_many_address_uint256.t userDic; /* key is user address */
		one_many_uint256_uint256.t orderDic; /* key is orderId */
		one_many_uint256_uint256.t accountDic; /* key is orderId */

	}

	struct FullTokenTransactionEntry {
		uint256 id;
		address token;
		address user;
		uint256 orderId;
		uint256 transactionType;
		uint256 tokenAmount;
		uint256 createTime;
	}

	struct OrderTransactionEntry {
		uint256 tokenAmount;
		uint256 price; 	// in wei
		uint256 weis;
		uint256 createTime;
	}

	struct OrderTransactionInfo {

		mapping(uint256 => OrderTransactionEntry) transactions;

		one_many_address_uint256.t tokenDic; /* key is token address */
		one_many_address_uint256.t userBuyDic; /* key is user address */
		one_many_address_uint256.t userSellDic; /* key is user address */
		one_many_uint256_uint256.t orderBuyDic; /* key is orderId */
		one_many_uint256_uint256.t orderSellDic; /* key is orderId */

	}

	struct FullOrderTransactionEntry {
		uint256 id;
		address token;
		address userSell;
		address userBuy;
		uint256 orderIdSell;
		uint256 orderIdBuy;
		uint256 transactionType;
		uint256 weis;
		uint256 price; 	// in wei
		uint256 tokenAmount;
		uint256 createTime;
	}

	struct t {
		uint256 nextId; // always > 0

		list_address.t tokenAmount; /* key is token address */
		list_address.t users; /* key is user address */

		WeiAccountInfo weis;
		TokenAccountInfo accounts;
		OrderInfo orders;
		OrderTransactionInfo transactions;

		WeiTransactionInfo transactions_wei;
		TokenTransactionInfo transactions_token;

		TokenVault vault;
	}


	///////////////////////////////////////////////////////////////////////////




	function findWeiTransactionList(t storage _this, address user) 
	internal view
	returns(uint256[] transactionType, uint256[] weis, uint256[] createTime)
	{
		FullWeiTransactionEntry[] memory ls = _findWeiTransactionList(_this, user);
		transactionType = new uint256[]( ls.length);
		weis = new uint256[]( ls.length);
		createTime = new uint256[]( ls.length);
		for (uint256 i = 0; i < ls.length; i++) {
			transactionType[i] = ls[i].transactionType;
			weis[i] = ls[i].weis;
			createTime[i] = ls[i].createTime; 
		}
	}

	function _findWeiTransactionList(t storage _this, address user) 
	private view
	returns(FullWeiTransactionEntry[] memory)
	{
		FullWeiTransactionEntry[] memory mls = new FullWeiTransactionEntry[](19);
		WeiTransactionInfo storage oi = _this.transactions_wei;
		list_uint256.t storage ls = oi.userDic.listAt(user);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 transactionId = ls.at(i);
			WeiTransactionEntry storage e = oi.transactions[transactionId];
			mls[i] = FullWeiTransactionEntry({
				id : transactionId,
				user : user,
				orderId : 0,
				transactionType : e.transactionType,
				weis : e.weis,
				createTime : e.createTime});
		}
		return mls;
	}
	
	
	function findTokenTransactionList(t storage _this, address token, address user) 
	internal view
	returns(uint256[] transactionType, uint256[] tokenAmount, uint256[] createTime)
	{
		FullTokenTransactionEntry[] memory ls = _findTokenTransactionList(_this, token, user);
		transactionType = new uint256[]( ls.length);
		tokenAmount = new uint256[]( ls.length);
		createTime = new uint256[]( ls.length);
		for (uint256 i = 0; i < ls.length; i++) {
			transactionType[i] = ls[i].transactionType;
			tokenAmount[i] = ls[i].tokenAmount;
			createTime[i] = ls[i].createTime; 
		}
	}

	function _findTokenTransactionList(t storage _this, address token, address user) 
	private view
	returns(FullTokenTransactionEntry[] memory)
	{
		uint256 accountId = _this.accounts.token_user_id[token][user];
		return findTokenTransactionListByAccount(_this, accountId);
	}

	function findTokenTransactionListByAccount(t storage _this, uint256 accountId) 
	private view
	returns(FullTokenTransactionEntry[] memory)
	{ 
		FullTokenTransactionEntry[] memory mls = new FullTokenTransactionEntry[](19);
		TokenTransactionInfo storage oi = _this.transactions_token;
		list_uint256.t storage ls = oi.accountDic.listAt(accountId);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 transactionId = ls.at(i);
			TokenTransactionEntry storage e = oi.transactions[transactionId];
			mls[i] = FullTokenTransactionEntry({
				id : transactionId,
				token : oi.tokenDic.oneAt(transactionId),
				user : oi.userDic.oneAt(transactionId),
				orderId : 0,
				transactionType : e.transactionType,
				tokenAmount : e.tokenAmount,
				createTime : e.createTime});
		}
		return mls;
	}

	function findOrderTransactionList(t storage _this, uint256 orderIdSell) 
	private view
	returns(FullOrderTransactionEntry[] memory)
	{
		FullOrderTransactionEntry[] memory mls = new FullOrderTransactionEntry[](19);
		OrderTransactionInfo storage oi = _this.transactions;
		list_uint256.t storage ls = oi.orderSellDic.listAt(orderIdSell);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 transactionId = ls.at(i);
			OrderTransactionEntry storage e = oi.transactions[transactionId]; 
			mls[i] = FullOrderTransactionEntry({
				id : transactionId,
				token : oi.tokenDic.oneAt(transactionId),
				userSell : oi.userSellDic.oneAt(transactionId),
				userBuy : oi.userBuyDic.oneAt(transactionId),
				orderIdSell : oi.orderSellDic.oneAt(transactionId),
				orderIdBuy : oi.orderBuyDic.oneAt(transactionId),
				transactionType : kTransaction_orderMatch,
				tokenAmount : e.tokenAmount,
				price : e.price,
				weis : e.weis,
				createTime : e.createTime});
		} 
		
		return mls;
	}

	///////////////////////////////////////////////////////////////////////////

	function depositToken(t storage _this, address token, address user, uint256 tokenAmount)
	internal
	{
		mintTokens(_this, token, user, tokenAmount);
		makeTokenTransaction(_this, token, user, tokenAmount, kTransaction_tokenDeposit);
		VaultOp.transferERC20From(ERC20(token), user, address(_this.vault), tokenAmount);
		// VaultOp.transferERC20From(ERC20(token), user, address(this), tokenAmount); 
	}


	function withdrawToken(t storage _this, address token, address user, uint256 tokenAmount)
	internal
	{
		burnTokens(_this, token, user, tokenAmount);
		makeTokenTransaction(_this, token, user, tokenAmount, kTransaction_tokenWithdrawal);
		_this.vault.transferERC20Basic(ERC20Basic(token), user, tokenAmount);
		// VaultOp.transferERC20Basic(ERC20(token), user, tokenAmount);
	}

	function balanceOfToken(t storage _this, address token, address user)
	internal
	view
	returns(uint256)
	{
		uint256 accountId = _this.accounts.token_user_id[token][user];
		TokenAccountEntry storage ae = _this.accounts.table[accountId];
		return ae.tokenAmount;
	}


	function depositWei(t storage _this, address user, uint256 weis)
	internal
	{
		mintWeis(_this, user, weis);
		makeWeiTransaction(_this, user, weis, kTransaction_weiDeposit);
		VaultOp.transferWei(address(_this.vault), weis);


		// // VaultOp.transferWei(address(this), weis); // nothing
	}

	function withdrawWei(t storage _this, address user, uint256 weis)
	internal
	{
		burnWeis(_this, user, weis);
		makeWeiTransaction(_this, user, weis, kTransaction_weiWithdrawal);
		_this.vault.transferWei(user, weis);
		// VaultOp.transferWei(user, weis);
	}

	function balanceOfWei(t storage _this, address user)
	internal
	view
	returns(uint256)
	{
		return _this.weis.table[user].weis;
	}

	function cancelOrder(t storage _this, address user, uint256 orderId)
	internal
	{
		closeUserOrder(_this, user, orderId); 
	}

	function orderList(t storage _this, address _token)
	internal
	view
	returns (
		uint256[] id,
		address[] token,
		address[] user,
		// uint256[] orderType,
		// uint256[] weis,
		// uint256[] weisLeft,
		// uint256[] tokenAmount,
		uint256[] tokenAmountLeft
	)
	{
		FullOrderEntry[] memory ls = findBuyOrders_t(_this, _token);
		return flat(ls); 
	}

	// function info(t storage _this)
	// internal
	// view
	// returns(mlist_keyvalue.keyvalue memory)
	// {
	// 	mlist_keyvalue.keyvalue memory r;
	// 	return r;
	// }

	function myOrderList(t storage _this, address _user)
	internal
	view
	returns (
		uint256[] id,
		address[] token,
		address[] user,
		// uint256[] orderType,
		// uint256[] weis,
		// uint256[] weisLeft,
		// uint256[] tokenAmount,
		uint256[] tokenAmountLeft
	)
	{
		FullOrderEntry[] memory ls = findBuyOrders_u(_this, _user);
		return flat(ls); 
	}
  
	function flat(FullOrderEntry[] memory ls)
	private
	pure
	returns (
		uint256[] id,
		address[] token,
		address[] user,
		// uint256[] orderType,
		// uint256[] weis,
		// uint256[] weisLeft,
		// uint256[] tokenAmount,
		uint256[] tokenAmountLeft
	)
	{ 
		id = new uint256[]( ls.length);
		token = new address[]( ls.length);
		user = new address[]( ls.length);
		// orderType = new uint256[]( ls.length);
		// weis = new uint256[]( ls.length);
		// weisLeft = new uint256[]( ls.length);
		// tokenAmount = new uint256[]( ls.length);
		tokenAmountLeft = new uint256[]( ls.length);
		for(uint256 i = 0; i < ls.length; i++){
			id[i] = ls[i].id;
			token[i] = ls[i].token;
			user[i] = ls[i].user;
			// orderType[i] = ls[i].orderType;
			// weis[i] = ls[i].weis;
			// weisLeft[i] = ls[i].weisLeft;
			// tokenAmount[i] = ls[i].tokenAmount;
			tokenAmountLeft[i] = ls[i].tokenAmountLeft;
		}
	}

	// function orderDetail(t storage _this, uint256 orderId) // status, transactions
	// internal
	// view
	// {

	// }


	function init(t storage _this)
	internal
	{
		_this.nextId = 1;	// always > 0
	}
	function buy(t storage _this, address token, address user, uint256 price, uint256 weis)
	internal
	returns(uint256)
	{
		uint256 buyOrderId = buyLimitPrice(_this, token, user, price, weis);
		OrderInfo storage oi = _this.orders;
		BuyOrderEntry storage oe = oi.buyTable[buyOrderId];
		mlist_uint256.t memory ls = findSellOrders(_this, token, price); 
		for (uint256 i = 0; i < ls.size(); i++) {
			if (oe.weis <= 0) {
				break;
			}
			uint256 sellOrderId = ls.at(i); 
			matchOrders(_this, sellOrderId, buyOrderId);
		}
		return buyOrderId;
	}
	function sell(t storage _this, address token, address user, uint256 price, uint256 tokenAmount)
	internal
	returns(uint256)
	{
		uint256 sellOrderId = sellLimitPrice(_this, token, user, price, tokenAmount);
		OrderInfo storage oi = _this.orders;
		SellOrderEntry storage oe = oi.sellTable[buyOrderId];
		mlist_uint256.t memory ls = findBuyOrders(_this, token, price);
		for (uint256 i = 0; i < ls.size(); i++) {
			if (oe.tokenAmount <= 0) {
				break;
			}
			uint256 buyOrderId = ls.at(i);
			matchOrders(_this, sellOrderId, buyOrderId);
		}
		return sellOrderId;
	}

	///////////////////////////////////////////////////////////////////////////

	function nextId(t storage _this) 
	private returns(uint256)
	{
		return _this.nextId++;
	}

	function mintWeis(t storage _this, address user, uint256 weis2)
	private
	{
		WeiAccountEntry storage we = _this.weis.table[user];
		we.weis = we.weis.add(weis2);
		_this.weis.total = _this.weis.total.add(weis2);
	}

	function mintTokens(t storage _this, address token, address user, uint256 tokenAmount2)
	private
	{
		uint256 accountId = safeAddTokenAccount(_this, token, user);
		TokenAccountEntry storage ae = _this.accounts.table[accountId];
		ae.tokenAmount = ae.tokenAmount.add(tokenAmount2);
	}
	function burnWeis(t storage _this, address user, uint256 weis2)
	private
	{
		WeiAccountEntry storage we = _this.weis.table[user];
		we.weis = we.weis.sub(weis2);
		_this.weis.total = _this.weis.total.sub(weis2);
	}

	function burnTokens(t storage _this, address token, address user, uint256 tokenAmount2)
	private
	{
		uint256 accountId = safeAddTokenAccount(_this, token, user);
		TokenAccountEntry storage ae = _this.accounts.table[accountId];
		ae.tokenAmount = ae.tokenAmount.sub(tokenAmount2);
	}



	function moveCloseOrder(OneOrderInfo storage oi, OneOrderInfo storage oiClosed, uint256 orderId)
	private
	{
		address token = oi.tokenDic.oneAt(orderId);
		address user = oi.userDic.oneAt(orderId);
		oi.tokenDic.remove(token, orderId);
		oiClosed.tokenDic.add(token, orderId);
		oi.userDic.remove(user, orderId);
		oiClosed.userDic.add(user, orderId);
	}


	function safeAddTokenAccount(t storage _this, address token, address user) 
	private returns(uint256)
	{
		uint256 accountId = _this.accounts.token_user_id[token][user];
		if (accountId == 0) {
			accountId = nextId(_this);
			_this.tokenAmount.safeAdd(token);
			_this.users.safeAdd(user);
			_this.accounts.tokenDic.add(token, accountId);
			_this.accounts.userDic.add(user, accountId);

			_this.accounts.table[accountId] = TokenAccountEntry({ tokenAmount: 0 });
			_this.accounts.token_user_id[token][user] = accountId;
		}
		return accountId;
	}

	function findBuyOrders(t storage _this, address token, uint256 price) 
	private view
	returns(mlist_uint256.t memory)
	{
		mlist_uint256.t memory mls;
		OrderInfo storage oi = _this.orders;
		list_uint256.t storage ls = oi.buy.tokenDic.listAt(token);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 oId = ls.at(i);
			BuyOrderEntry storage oe = oi.buyTable[oId];
			if (oe.price >= price) {
				mls.add(oId);
			}
		}
		return mls;
	}
	
	function findSellOrders(t storage _this, address token, uint256 price) 
	private view
	returns(mlist_uint256.t memory)
	{ 
		mlist_uint256.t memory mls;
		mls.clear();
		MiscOp.requireEx(mls.size() == 0);
		OrderInfo storage oi = _this.orders;
		list_uint256.t storage ls = oi.sell.tokenDic.listAt(token);
		MiscOp.requireEx(ls.size() == 1);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 oId = ls.at(i); 
			SellOrderEntry storage oe = oi.sellTable[oId]; 
			if (oe.price <= price) {
				mls.add(oId);
			}
		} 
		return mls;
	}

	function findBuyOrders_t(t storage _this, address token) 
	private view
	returns(FullOrderEntry[] memory)
	{
		FullOrderEntry[] memory mls = new FullOrderEntry[](19);
		OrderInfo storage oi = _this.orders;
		list_uint256.t storage ls = oi.buy.tokenDic.listAt(token);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 orderId = ls.at(i);
			BuyOrderEntry storage e = oi.buyTable[orderId]; 
			mls[i] = FullOrderEntry({
				id : orderId,
				token : oi.sell.tokenDic.oneAt(orderId),
				user : oi.sell.userDic.oneAt(orderId),
				orderType : kOrderBuy,
				weis : e.weis,
				weisLeft : e.weisLeft,
				tokenAmount : 0,
				tokenAmountLeft : 0});
		}
		return mls;
	}
	
	function findSellOrders_t(t storage _this, address token) 
	private view
	returns(FullOrderEntry[] memory)
	{
		FullOrderEntry[] memory mls = new FullOrderEntry[](19);
		OrderInfo storage oi = _this.orders;
		list_uint256.t storage ls = oi.sell.tokenDic.listAt(token);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 orderId = ls.at(i); 
			SellOrderEntry storage e = oi.sellTable[orderId]; 
			mls[i] = FullOrderEntry({
				id : orderId,
				token : oi.sell.tokenDic.oneAt(orderId),
				user : oi.sell.userDic.oneAt(orderId),
				orderType : kOrderSell,
				weis : 0,
				weisLeft : 0,
				tokenAmount : e.tokenAmount,
				tokenAmountLeft : e.tokenAmountLeft});
		}
		return mls;
	}

	function findBuyOrders_u(t storage _this, address user) 
	private view
	returns(FullOrderEntry[] memory)
	{
		FullOrderEntry[] memory mls = new FullOrderEntry[](19);
		OrderInfo storage oi = _this.orders;
		list_uint256.t storage ls = oi.buy.userDic.listAt(user);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 orderId = ls.at(i);
			BuyOrderEntry storage e = oi.buyTable[orderId]; 
			mls[i] = FullOrderEntry({
				id : orderId,
				token : oi.sell.tokenDic.oneAt(orderId),
				user : oi.sell.userDic.oneAt(orderId),
				orderType : kOrderBuy,
				weis : e.weis,
				weisLeft : e.weisLeft,
				tokenAmount : 0,
				tokenAmountLeft : 0});
		}
		return mls;
	}
	
	function findSellOrders_u(t storage _this, address user) 
	private view
	returns(FullOrderEntry[] memory)
	{
		FullOrderEntry[] memory mls = new FullOrderEntry[](19);
		OrderInfo storage oi = _this.orders;
		list_uint256.t storage ls = oi.sell.userDic.listAt(user);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 orderId = ls.at(i);
			SellOrderEntry storage e = oi.sellTable[orderId]; 
			mls[i] = FullOrderEntry({
				id : orderId,
				token : oi.sell.tokenDic.oneAt(orderId),
				user : oi.sell.userDic.oneAt(orderId),
				orderType : kOrderSell,
				weis : 0,
				weisLeft : 0,
				tokenAmount : e.tokenAmount,
				tokenAmountLeft : e.tokenAmountLeft});
		}
		return mls;
	}



	// solium-disable-next-line indentation
	function createOrderIndex(OneOrderInfo storage oi, address token, address user, uint256 orderId)
	private
	{
		oi.tokenDic.add(token, orderId);
		oi.userDic.add(user, orderId);
	}

	// solium-disable-next-line indentation
	function createOrderTransactionIndex(t storage _this, address token,
		address userSell, address userBuy, uint256 orderIdSell, uint256 orderIdBuy,
		uint256 transactionId)
	private
	{
		_this.transactions.tokenDic.add(token, transactionId);
		_this.transactions.userSellDic.add(userSell, transactionId);
		_this.transactions.orderSellDic.add(orderIdSell, transactionId);
		_this.transactions.userBuyDic.add(userBuy, transactionId);
		_this.transactions.orderBuyDic.add(orderIdBuy, transactionId);
	}

	function createTokenTransactionIndex(t storage _this, address token, address user, uint256 orderId, uint256 transactionId)
	private
	{
		_this.transactions_token.tokenDic.add(token, transactionId);
		_this.transactions_token.userDic.add(user, transactionId);
		_this.transactions_token.orderDic.add(orderId, transactionId);
	}

	function createWeiTransactionIndex(t storage _this, address user, uint256 orderId, uint256 transactionId)
	private
	{
		_this.transactions_wei.userDic.add(user, transactionId);
		_this.transactions_wei.orderDic.add(orderId, transactionId);
	}

	function buyLimitPrice(t storage _this, address token, address user, uint256 price, uint256 weis)
	private
	returns(uint256)
	{
		MiscOp.requireEx(price != 0);
		safeAddTokenAccount(_this, token, user);
		uint256 orderId = nextId(_this);

		burnWeis(_this, user, weis);
		uint256 transactionId = makeWeiTransaction(_this, user, weis, kTransaction_weiToOrder);
		createWeiTransactionIndex(_this, user, orderId, transactionId);

		uint256 ts = MiscOp.currentTime();
		_this.orders.buyTable[orderId] = BuyOrderEntry({
			price: price, weis: weis, weisLeft: weis,
			createTime: ts, closeTime: 0
		});
		createOrderIndex(_this.orders.buy, token, user, orderId);
		return orderId;
	}

	function sellLimitPrice(t storage _this, address token, address user, uint256 price, uint256 tokenAmount)
	private
	returns(uint256)
	{
		MiscOp.requireEx(price != 0);
		safeAddTokenAccount(_this, token, user);
		uint256 orderId = nextId(_this);

		burnTokens(_this, token, user, tokenAmount);
		uint256 transactionId = makeTokenTransaction(_this, token, user, tokenAmount, kTransaction_tokenToOrder);
		createTokenTransactionIndex(_this, token, user, orderId, transactionId);

		uint256 ts = MiscOp.currentTime();
		_this.orders.sellTable[orderId] = SellOrderEntry({
			price: price, tokenAmount: tokenAmount, tokenAmountLeft: tokenAmount,
			createTime: ts, closeTime: 0
		});
		createOrderIndex(_this.orders.sell, token, user, orderId);
		return orderId;
	}

	function closeUserOrder(t storage _this, address user, uint256 orderId)
	private
	{
		bool b = _this.orders.sell.userDic.exists(user, orderId);
		if (b) {
			closeSellOrder(_this, orderId);
		}
		b = _this.orders.buy.userDic.exists(user, orderId);
		if (b) {
			closeBuyOrder(_this, orderId);
		}
	}

	function closeOrder(t storage _this, uint256 orderId)
	private
	{
		address token = _this.orders.sell.tokenDic.oneAt(orderId);
		if (token != 0x0) {
			closeSellOrder(_this, orderId);
		}
		token = _this.orders.buy.tokenDic.oneAt(orderId);
		if (token != 0x0) {
			closeBuyOrder(_this, orderId);
		}
	}

	function closeSellOrder(t storage _this, uint256 sellOrderId)
	private
	{
		address token = _this.orders.sell.tokenDic.oneAt(sellOrderId);
		address seller = _this.orders.sell.userDic.oneAt(sellOrderId);
		SellOrderEntry storage oeSell = _this.orders.sellTable[sellOrderId];
		uint256 tokenAmount = oeSell.tokenAmountLeft;
		if (tokenAmount > 0) {
			oeSell.tokenAmountLeft = 0;
			mintTokens(_this, token, seller, tokenAmount);
			makeTokenTransaction(_this, token, seller, tokenAmount, kTransaction_tokenFromOrder);
		}

		if (oeSell.closeTime == 0) {
			moveCloseOrder(_this.orders.sell, _this.orders.sellClosed, sellOrderId);
			uint256 ts = MiscOp.currentTime();
			oeSell.closeTime = ts;
		}
	}

	function closeBuyOrder(t storage _this, uint256 buyOrderId)
	private
	{
		address buyer = _this.orders.buy.userDic.oneAt(buyOrderId);
		BuyOrderEntry storage oeBuy = _this.orders.buyTable[buyOrderId];
		uint256 weis = oeBuy.weisLeft;
		if (weis > 0) {
			oeBuy.weisLeft = 0;
			mintWeis(_this, buyer, weis);
			makeWeiTransaction(_this, buyer, weis, kTransaction_weiFromOrder);
		}

		if (oeBuy.closeTime == 0) {
			moveCloseOrder(_this.orders.buy, _this.orders.buyClosed, buyOrderId);
			uint256 ts = MiscOp.currentTime();
			oeBuy.closeTime = ts;
		}
	}

	function matchOrders(t storage _this, uint256 sellOrderId, uint256 buyOrderId)
	private
	{
		uint256 transactionId = matchOrders_1(_this, sellOrderId, buyOrderId);
		matchOrders_2(_this, sellOrderId, buyOrderId, transactionId);
		matchOrders_3(_this, sellOrderId, buyOrderId);
	}
	function matchOrders_1(t storage _this, uint256 sellOrderId, uint256 buyOrderId)
	private
	returns(uint256 transactionId)
	{
		address token = _this.orders.sell.tokenDic.oneAt(sellOrderId);
		address tokenB = _this.orders.buy.tokenDic.oneAt(buyOrderId); 
		MiscOp.requireEx(token == tokenB);
		SellOrderEntry storage oeSell = _this.orders.sellTable[sellOrderId];
		BuyOrderEntry storage oeBuy = _this.orders.buyTable[buyOrderId];
		MiscOp.requireEx(oeSell.price <= oeBuy.price);
		uint256 price = (oeSell.price.add(oeBuy.price)).div(2);

		// maximize deal
		uint256 tokenAmount2 = oeSell.tokenAmountLeft; // match seller
		uint256 weis2 = tokenAmount2.mul(price);
		if (oeBuy.weis < weis2) { // match buyer  
			tokenAmount2 = oeBuy.weis.div(price);
			weis2 = tokenAmount2.mul(price);
		}
		if (tokenAmount2 > 0) {
			// solium-disable-next-line indentation
			transactionId = makeTransaction(_this,
				price, tokenAmount2, weis2);

			address seller = _this.orders.sell.userDic.oneAt(sellOrderId);
			address buyer = _this.orders.buy.userDic.oneAt(buyOrderId);

			oeSell.tokenAmountLeft = oeSell.tokenAmountLeft.sub(tokenAmount2);
			oeBuy.weisLeft = oeBuy.weisLeft.sub(weis2);
			mintWeis(_this, seller, weis2);
			mintTokens(_this, token, buyer, tokenAmount2);
		}

		return transactionId;
	}


	function matchOrders_2(t storage _this, uint256 sellOrderId, uint256 buyOrderId, uint256 transactionId)
	private
	{
		if (transactionId > 0) {
			address token = _this.orders.sell.tokenDic.oneAt(sellOrderId);

			address seller = _this.orders.sell.userDic.oneAt(sellOrderId);
			address buyer = _this.orders.buy.userDic.oneAt(buyOrderId);

			// solium-disable-next-line indentation
			createOrderTransactionIndex(_this, token,
				seller, buyer, sellOrderId, buyOrderId,
				transactionId);

		}
	}

	function matchOrders_3(t storage _this, uint256 sellOrderId, uint256 buyOrderId)
	private
	{
		SellOrderEntry storage oeSell = _this.orders.sellTable[sellOrderId];
		BuyOrderEntry storage oeBuy = _this.orders.buyTable[buyOrderId];

		if (oeBuy.weisLeft < oeBuy.price) {
			closeBuyOrder(_this, buyOrderId);
		}
		if (oeSell.tokenAmountLeft == 0) {
			closeSellOrder(_this, sellOrderId);
		}
	}




	// solium-disable-next-line indentation
	function makeTransaction(t storage _this,
		// address token, address seller, address buyer,
		// 	uint256 sellOrderId, uint256 buyOrderId,
		uint256 price, uint256 tokenAmount, uint256 weis)
	private returns(uint256 transactionId)
	{
		transactionId = nextId(_this);
		
		uint256 ts = MiscOp.currentTime();
		_this.transactions.transactions[transactionId] = OrderTransactionEntry({
			price: price, tokenAmount: tokenAmount, weis: weis, createTime: ts
		});
		return transactionId;
	}


	// solium-disable-next-line indentation
	function makeWeiTransaction(t storage _this, address user,
		uint256 weis, uint256 _type)
	private returns(uint256 transactionId)
	{
		transactionId = nextId(_this);
		_this.transactions_wei.userDic.add(user, transactionId);

		uint256 ts = MiscOp.currentTime();
		_this.transactions_wei.transactions[transactionId] = WeiTransactionEntry({
			transactionType: _type, weis: weis, createTime: ts
		});
		return transactionId;
	}


	// solium-disable-next-line indentation
	function makeTokenTransaction(t storage _this, address token, address user,
		uint256 tokenAmount, uint256 _type)
	private returns(uint256 transactionId)
	{
		transactionId = nextId(_this);
		uint256 accountId = safeAddTokenAccount(_this, token, user);
		_this.transactions_token.tokenDic.add(token, transactionId);
		_this.transactions_token.userDic.add(user, transactionId);
		_this.transactions_token.accountDic.add(accountId, transactionId);

		uint256 ts = MiscOp.currentTime();
		_this.transactions_token.transactions[transactionId] = TokenTransactionEntry({
			transactionType: _type, tokenAmount: tokenAmount, createTime: ts
		});
		return transactionId;
	}



}

