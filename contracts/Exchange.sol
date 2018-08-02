

pragma solidity ^ 0.4.23;
// pragma experimental ABIEncoderV2;

import "./List.sol";
import "./Util.sol";



contract Exchange
{
	using ExchangeHelper for ExchangeHelper.t;
	ExchangeHelper.t infoOp;

	constructor() public {
		infoOp.init();
	}

	// function () // depositWei
	// external payable
	// {
	// 	address user = msg.sender;
	// 	uint256 weis = msg.value;
	// 	infoOp.depositWei(user, weis);
	// }

	// function withdrawWei(uint256 weis)
	// external
	// {
	// 	address user = msg.sender;
	// 	require(user != 0x0);
	// 	require(weis != 0x0);
	// 	infoOp.withdrawWei(user, weis);
	// }

	// function balanceOfWei()
	// external
	// view
	// returns(uint256)
	// {
	// 	address user = msg.sender;
	// 	require(user != 0x0);
	// 	return infoOp.balanceOfWei(user);
	// }

	function buy(address token, uint256 price, uint256 weis)
	external
	{
		address user = msg.sender;
		require(token != 0x0);
		require(user != 0x0);
		require(price != 0x0);
		require(weis != 0x0);
		infoOp.buy(token, user, price, weis);
	}




	// function depositToken(address token, uint256 amount)
	// external
	// {
	// 	address user = msg.sender;
	// 	require(token != 0x0);
	// 	require(user != 0x0);
	// 	require(amount != 0x0);
	// 	infoOp.depositToken(token, user, amount);
	// }

	// function withdrawToken(address token, uint256 amount)
	// external
	// {
	// 	address user = msg.sender;
	// 	require(token != 0x0);
	// 	require(user != 0x0);
	// 	require(amount != 0x0);
	// 	infoOp.withdrawToken(token, user, amount);
	// }

	// function balanceOfToken(address token)
	// external
	// view
	// returns(uint256)
	// {
	// 	address user = msg.sender;
	// 	require(token != 0x0);
	// 	require(user != 0x0);
	// 	return infoOp.balanceOfToken(token, user);
	// }

	function sell(address token, uint256 price, uint256 amount)
	external
	{
		address user = msg.sender;
		require(token != 0x0);
		require(user != 0x0);
		require(price != 0x0);
		require(amount != 0x0);
		infoOp.sell(token, user, price, amount);
	}

	// function cancelOrder(uint256 orderId)
	// external
	// {
	// 	address user = msg.sender;
	// 	require(user != 0x0);
	// 	infoOp.cancelOrder(user, orderId);
	// }


	// function orderList(address token)
	// external
	// view
	// {
	// 	infoOp.orderList(token);
	// }

	// function info()
	// external
	// view
	// returns(uint256 key, uint256 value, uint256[1] key2, uint256[1] value2)
	// {
	// 	mlist_keyvalue.keyvalue memory r = infoOp.info();
	// 	return (r.key, r.value, [r.key], [r.value]);
	// }

	function myOrderList()
	external
	pure
	returns(uint256[] key, uint256[] value)
	{
		uint256[] memory k = new uint256[](2);
		k[0] = 6;
		k[1] = 7;
		uint256[] memory v = new uint256[](3);
		v[0] = 16;
		v[1] = 17;
		v[2] = 18;
		return (k, v);
	}

	// function orderDetail(uint256 orderId) // status, transactions
	// external
	// view
	// {
	// 	infoOp.orderDetail(orderId);
	// }


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



	struct WeiEntry {
		uint256 amount;
	}

	struct WeiInfo {
		uint256 total;
		mapping(address => WeiEntry) table; /* key is accountId */
	}

	struct AccountEntry {
		uint256 amount;
	}

	struct AccountInfo {
		mapping(address => mapping(address => uint256)) token_user_id;
		mapping(uint256 => AccountEntry) table; /* key is accountId */
		one_many_address_uint256.t tokenDic; /* key is token address */
		one_many_address_uint256.t userDic; /* key is user address */
	}


	enum OrderStatus { Open, OpenPartDone, ClosedDone, ClosedPartDone, ClosedCancelled }

	struct BuyOrderEntry {
		// uint256 amount;	// in token unit e.g. tnano
		uint256 price; 	// in wei
		uint256 weis;	// in wei	weis = amount * price
		uint256 weisLeft;
		// uint256 cancelled_amount;
		// uint256 filled_amount;
		// uint256 filled_weis;
		// OrderStatus status;
		// uint256 create_time;
		// uint256 close_time;
	}
	struct SellOrderEntry {
		uint256 price; 	// in wei
		uint256 amount;	// in token unit e.g. tnano
		uint256 amountLeft;
		// uint256 weis;	// in wei	weis = amount * price
		// uint256 cancelled_amount;
		// uint256 filled_amount;
		// uint256 filled_weis;
		// OrderStatus status;
		// uint256 create_time;
		// uint256 close_time;
	}


	struct OneOrderInfo {
		one_many_address_uint256.t tokenDic; /* key is token address */
		one_many_address_uint256.t userDic; /* key is user address */
		one_many_address_uint256.t closedUserDic; /* key is user address */
	}


	struct OrderInfo {
		mapping(uint256 => BuyOrderEntry) buyTable; /* key is orderId */
		OneOrderInfo buy;
		mapping(uint256 => SellOrderEntry) sellTable; /* key is orderId */
		OneOrderInfo sell;
	}



	struct OrderTransactionEntry {
		uint256 amount;	// in token unit e.g. tnano
		uint256 price; 	// in wei
		uint256 weis;
		// uint256 create_time;
	}

	struct OrderTransactionInfo {

		mapping(uint256 => OrderTransactionEntry) transactions;

		one_many_address_uint256.t tokenDic; /* key is token address */
		one_many_address_uint256.t buyeruyDic; /* key is user address */
		one_many_address_uint256.t userSellDic; /* key is user address */
		one_many_uint256_uint256.t orderBuyDic; /* key is user address */
		one_many_uint256_uint256.t orderSellDic; /* key is user address */

	}

	struct t {
		uint256 nextId; // always > 0

		list_address.t tokens; /* key is token address */
		list_address.t users; /* key is user address */

		WeiInfo weis;
		AccountInfo accounts;
		OrderInfo orders;
		OrderTransactionInfo transactions;
	}


	///////////////////////////////////////////////////////////////////////////

	// function depositToken(t storage _this, address token, address user, uint256 amount)
	// internal
	// {
	// 	// VaultOp.transferERC20From(ERC20(token), user, address(vault), amount);
	// 	VaultOp.transferERC20From(ERC20(token), user, address(this), amount);
	// }


	// function withdrawToken(t storage _this, address token, address user, uint256 amount)
	// internal
	// {
	// 	// valult.transferERC20Basic(ERC20Basic(token), user, amount);
	// 	VaultOp.transferERC20Basic(ERC20(token), user, amount);
	// }

	// function balanceOfToken(t storage _this, address token, address user)
	// internal
	// view
	// returns(uint256)
	// {
	// 	return 0;
	// }


	// function depositWei(t storage _this, address user, uint256 weis)
	// internal
	// {
	// 	// VaultOp.transferWei(address(vault), weis);
	// 	VaultOp.transferWei(address(this), weis); // nothing
	// }

	// function withdrawWei(t storage _this, address user, uint256 weis)
	// internal
	// {
	// 	// valult.transferWei(user, weis);
	// 	VaultOp.transferWei(user, weis);
	// }

	// function balanceOfWei(t storage _this, address user)
	// internal
	// view
	// returns(uint256)
	// {
	// 	return 0;
	// }

	// function cancelOrder(t storage _this, address user, uint256 orderId)
	// internal
	// {

	// }

	// function orderList(t storage _this, address token)
	// internal
	// view
	// {

	// }

	// function info(t storage _this)
	// internal
	// view
	// returns(mlist_keyvalue.keyvalue memory)
	// {
	// 	mlist_keyvalue.keyvalue memory r;
	// 	return r;
	// }

	// function myOrderList(t storage _this, address user)
	// internal
	// view
	// {

	// }

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
	}
	function sell(t storage _this, address token, address user, uint256 price, uint256 amount)
	internal
	{
		uint256 sellOrderId = sellLimitPrice(_this, token, user, price, amount);
		OrderInfo storage oi = _this.orders;
		SellOrderEntry storage oe = oi.sellTable[buyOrderId];
		mlist_uint256.t memory ls = findBuyOrders(_this, token, price);
		for (uint256 i = 0; i < ls.size(); i++) {
			if (oe.amount <= 0) {
				break;
			}
			uint256 buyOrderId = ls.at(i);
			matchOrders(_this, sellOrderId, buyOrderId);
		}
	}

	///////////////////////////////////////////////////////////////////////////

	function nextId(t storage _this) 
	private returns(uint256)
	{
		return _this.nextId++;
	}


	// solium-disable-next-line indentation
	function createOrderPart(OneOrderInfo storage oi, address token, address user, uint256 orderId)
	private
	{
		oi.tokenDic.add(token, orderId);
		oi.userDic.add(user, orderId);
	}

	function closeOrder(OneOrderInfo storage oi, uint256 orderId)
	private
	{
		address user = oi.userDic.oneFor(orderId);
		oi.userDic.remove(user, orderId);
		oi.closedUserDic.add(user, orderId);
	}


	function safeAddAccount(t storage _this, address token, address user) private {
		_this.tokens.safeAdd(token);
		_this.users.safeAdd(user);
		uint256 accountId = _this.accounts.token_user_id[token][user];
		if (accountId == 0) {
			accountId = nextId(_this);
			_this.accounts.tokenDic.add(token, accountId);
			_this.accounts.userDic.add(user, accountId);

			_this.accounts.table[accountId] = AccountEntry({ amount: 0 });
			_this.accounts.token_user_id[token][user] = accountId;
		}
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
		OrderInfo storage oi = _this.orders;
		list_uint256.t storage ls = oi.sell.tokenDic.listAt(token);
		for (uint256 i = 0; i < ls.size(); i++) {
			uint256 oId = ls.at(i);
			SellOrderEntry storage oe = oi.sellTable[oId];
			if (oe.price <= price) {
				mls.add(oId);
			}
		}
		return mls;
	}

	function buyLimitPrice(t storage _this, address token, address user, uint256 price, uint256 weis)
	private
	returns(uint256)
	{
		safeAddAccount(_this, token, user);

		WeiEntry storage we = _this.weis.table[user];
		we.amount = we.amount.sub(weis);
		_this.weis.total = _this.weis.total.sub(weis);

		uint256 orderId = nextId(_this);
		createOrderPart(_this.orders.buy, token, user, orderId);
		_this.orders.buyTable[orderId] = BuyOrderEntry({
			price: price, weis: weis, weisLeft: weis
		});
		return orderId;
	}

	function sellLimitPrice(t storage _this, address token, address user, uint256 price, uint256 amount)
	private
	returns(uint256)
	{
		safeAddAccount(_this, token, user);

		uint256 accountId = _this.accounts.token_user_id[token][user];
		AccountEntry storage ae = _this.accounts.table[accountId];
		ae.amount = ae.amount.sub(amount);

		uint256 orderId = nextId(_this);
		createOrderPart(_this.orders.sell, token, user, orderId);
		_this.orders.sellTable[orderId] = SellOrderEntry({
			price: price, amount: amount, amountLeft: amount
		});
		return orderId;
	}

	function matchOrders(t storage _this, uint256 sellOrderId, uint256 buyOrderId)
	private
	{
		address token = _this.orders.sell.tokenDic.oneFor(sellOrderId);
		address tokenB = _this.orders.buy.tokenDic.oneFor(buyOrderId);
		require(token == tokenB);
		address seller = _this.orders.sell.userDic.oneFor(sellOrderId);
		address buyer = _this.orders.buy.userDic.oneFor(buyOrderId);
		SellOrderEntry storage oeSell = _this.orders.sellTable[sellOrderId];
		BuyOrderEntry storage oeBuy = _this.orders.buyTable[buyOrderId];
		require(oeSell.price <= oeBuy.price);
		uint256 price = (oeSell.price.add(oeBuy.price)).div(2);

		// maximize deal
		uint256 amount2 = oeSell.amountLeft; // match seller
		uint256 weis2 = amount2.mul(price);
		if (oeBuy.weis < weis2) { // match buyer  
			amount2 = oeBuy.weis.div(price);
			weis2 = amount2.mul(price);
		}
		if (amount2 > 0) {
			// solium-disable-next-line indentation
			makeTransaction(_this, token, seller, buyer, sellOrderId, buyOrderId,
				price, amount2, weis2);
			oeSell.amountLeft = oeSell.amountLeft.sub(amount2);
			oeBuy.weisLeft = oeBuy.weisLeft.sub(weis2);
			transactionUpdateSellerWeis(_this, seller, weis2);
			transactionUpdateBuyerAmount(_this, token, buyer, amount2);
		}
		if (oeBuy.weisLeft < oeBuy.price) {
			processBuyerFragWeis(_this, buyer, oeBuy.weisLeft);
			oeBuy.weisLeft = 0;
			closeOrder(_this.orders.buy, buyOrderId);
		}
		if (oeSell.amountLeft == 0) {
			closeOrder(_this.orders.sell, sellOrderId);
		}
	}



	function transactionUpdateSellerWeis(t storage _this, address user, uint256 weis2)
	private
	{

		WeiEntry storage we = _this.weis.table[user];
		we.amount = we.amount.add(weis2);
		_this.weis.total = _this.weis.total.add(weis2);

	}

	function transactionUpdateBuyerAmount(t storage _this, address token, address user, uint256 amount2)
	private
	{
		uint256 accountId = _this.accounts.token_user_id[token][user];
		AccountEntry storage ae = _this.accounts.table[accountId];
		ae.amount = ae.amount.add(amount2);

	}
	function processBuyerFragWeis(t storage _this, address user, uint256 weis2)
	private
	{

		WeiEntry storage we = _this.weis.table[user];
		we.amount = we.amount.add(weis2);
		_this.weis.total = _this.weis.total.add(weis2);
	}


	// solium-disable-next-line indentation
	function makeTransaction(t storage _this, address token, address seller, address buyer,
		uint256 sellOrderId, uint256 buyOrderId,
		uint256 price, uint256 amount, uint256 weis)
	private returns(uint256 transactionId)
	{
		uint256 xactId = nextId(_this);
		// TokenUserUtil.mintIndex(_this.transactions.iter, token, seller, buyer, xactId);
		// TokenUserUtil.mintIndex(_this.transactions.orderIter, sellOrderId, buyOrderId, xactId);
		_this.transactions.tokenDic.add(token, xactId);
		_this.transactions.userSellDic.add(seller, xactId);
		_this.transactions.buyeruyDic.add(buyer, xactId);
		_this.transactions.orderSellDic.add(sellOrderId, xactId);
		_this.transactions.orderBuyDic.add(buyOrderId, xactId);
		_this.transactions.transactions[xactId] = OrderTransactionEntry({
			price: price, amount: amount, weis: weis
		});
		return xactId;
	}


	// function buyMatchPrice(address token, address user, uint256 sellOrderId, uint256 weis) internal {
	// 	require(_this.orders.sell.tokenDic.oneFor(sellOrderId) == token);
	// 	address otherUser = _this.orders.sell.userDic.oneFor(sellOrderId);
	// 	SellOrderEntry storage oe = _this.orders.sellTable[sellOrderId];
	// 	uint256 amount2 = oe.amountLeft;
	// 	uint256 weis2 = amount2.mul(oe.price);
	// 	if (weis < weis2) {
	// 		amount2 = weis.div(oe.price);
	// 		weis2 = amount2.mul(oe.price);
	// 	}
	// 	oe.amountLeft = oe.amountLeft.sub(amount2);
	// 	// transactionUpdate buyer and seller account, then check fragment, transactionUpdate status
	// 	transactionUpdateBuyerWeis(user, weis2);
	// 	transactionUpdateBuyerAmount(token, user, amount2);
	// 	transactionUpdateSellerWeis(otherUser, weis2);
	// 	if (oe.amountLeft == 0) {
	// 		// close the order
	// 	}
	// }

	// function sellMatchPrice(address token, address user, uint256 buyOrderId, uint256 amount) internal {
	// 	require(_this.orders.buy.tokenDic.oneFor(buyOrderId) == token);
	// 	address otherUser = _this.orders.buy.userDic.oneFor(buyOrderId);
	// 	BuyOrderEntry storage oe = _this.orders.buyTable[buyOrderId];
	// 	uint256 amount2 = oe.weisLeft.div(oe.price);
	// 	uint256 weis2 = amount2.mul(oe.price);
	// 	if (amount < amount2) {
	// 		amount2 = amount;
	// 		weis2 = amount2.mul(oe.price);
	// 	}
	// 	oe.weisLeft = oe.weisLeft.sub(weis2);
	// 	// transactionUpdate buyer and seller account, then check fragment, transactionUpdate status
	// 	transactionUpdateSellerWeis(user, weis2);
	// 	transactionUpdateSellerAmount(token, user, amount2);
	// 	if (oe.weisLeft < oe.price) {
	// 		processBuyerFragWeis(otherUser, oe.weisLeft);
	// 		oe.weisLeft = 0;
	// 		// close the order
	// 	}
	// 	transactionUpdateBuyerAmount(token, otherUser, amount2);
	// }


	// // todo delete
	// function transactionUpdateSellerAmount(address token, address user, uint256 amount2)
	// internal
	// {

	// 	uint256 accountId = _this.accounts.token_user_id[token][user];
	// 	AccountEntry storage ae = _this.accounts.table[accountId];
	// 	ae.amount = ae.amount.sub(amount2);

	// }

	// // todo delete
	// function transactionUpdateBuyerWeis(address user, uint256 weis2)
	// internal
	// {

	// 	WeiEntry storage we = _this.weis.table[user];
	// 	we.amount = we.amount.sub(weis2);
	// 	_this.weis.total = _this.weis.total.sub(weis2);
	// }



	// // solium-disable-next-line indentation
	// function mint(address to, address token, OrderType orderType,
	// 	uint256 amount, uint256 price, uint256 weis)
	// internal returns(uint256 orderId)
	// {
	// 	uint256 ordId = _this.orders.nextId++;
	// 	mintIndex(_this.orders.buyKeyEnumerator, to, token, ordId);

	// 	// one_many_address_uint256.t storage lsAll = (orderType == OrderType.LimitBuy) ?
	// 	// 	_this.orders.buyKeyEnumerator.tokenDic : _this.orders.sellKeyEnumerator.tokenDic;
	// 	// one_many_address_uint256.t storage lsUser = (orderType == OrderType.LimitBuy) ?
	// 	// 	_this.orders.buyKeyEnumerator.userDic : _this.orders.sellKeyEnumerator.userDic;
	// 	// _this.orders.buyTable[ordId] = BuyOrderEntry({
	// 	// 	token: token, orderType: orderType, // solium-disable-line whitespace
	// 	// 	user: to, amount: amount, price: price, weis: weis, // solium-disable-line whitespace
	// 	// 	filled_amount: 0, filled_weis: 0
	// 	// });

	// 	return ordId;
	// }




	// function buyBurn(uint256 orderId) internal {

	// 	// BuyOrderEntry storage theEntry = _this.orders.buyTable[orderId];
	// 	// address to = theEntry.user;
	// 	// address token = theEntry.token;
	// 	// OrderType orderType = theEntry.orderType;




	// 	// one_many_address_uint256.t storage lsAll = _this.orders.buyKeyEnumerator.tokenDic;
	// 	// burnSubDic(lsAll,token,orderId);


	// 	// one_many_address_uint256.t storage lsUser = _this.orders.buyKeyEnumerator.userDic;
	// 	// burnSubDic(lsUser,to,orderId);


	// 	// delete _this.orders.buyTable[orderId];
	// }

	// function cancelOrder(uint256 orderId) internal {
	// 	// require (_this.orders.buyKeyEnumerator.buyTable[orderId].id == orderId);
	// 	// buyBurn(orderId);
	// }

	// function sellMatchPrice(uint256 buyOrderId, uint256 amount) internal {
	// 	require (_this.orders.buyKeyEnumerator.buyTable[buyOrderId].id == buyOrderId);
	// 	require (_this.orders.buyKeyEnumerator.buyTable[buyOrderId].orderType == OrderType.LimitBuy);

	// }

}

