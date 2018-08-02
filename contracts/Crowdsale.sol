
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";
import "./Ownable.sol";
import "./Vault.sol";
import "./CrowdsaleToken.sol";




contract Crowdsale is Recoverable
{
	using SafeMath for uint256;
	using CrowdsaleHelper for CrowdsaleHelper.t;




	event Finalized();

	event TokenPurchase(
		address indexed purchaser,
		address indexed user,
		uint256 value,
		uint256 amount
	);

	event SoftCapReached();
	event RefundsEnabled();
	event Refunded(address indexed user, uint256 weis);


	CrowdsaleHelper.t saleInfo;








	function ()
	external payable
	{
		address user = msg.sender;
		uint256 weis = msg.value;
		require(isOpen());
		require(user != address(0));
		require(weis != 0);
		saleInfo.buyTokens(user, weis);
	}


	function beneficiaryWithdraw()
	external onlyOwner
	{
		require(saleInfo.state == CrowdsaleHelper.SaleState.SoftCapReached);
		saleInfo.beneficiaryWithdraw();
	}

	function tokenURI()
	external
	view
	returns(string)
	{
		return saleInfo.tokenURI();
	}

	function finalize()
	external
	onlyOwner
	{
		saleInfo.finalize();
	}


	function claimRefund()
	external
	{
		require(saleInfo.state == CrowdsaleHelper.SaleState.ClosedRefunding);
		return saleInfo.claimRefund(msg.sender);
	}


	function tokenPriceInMilliUSD()
	external view returns(uint256)
	{
		return saleInfo.tokenPriceInMilliUSD();
	}

	//////////////////////////////////////////////////////////////////
	function isOpen() 
	public view returns(bool)
	{
		return saleInfo.isOpen();
	}

	function softCapReached() 
	public view returns(bool)
	{
		return saleInfo.softCapReached();
	}

	function hardCapReached() 
	public view returns(bool)
	{
		return saleInfo.hardCapReached();
	}

	function link(CrowdsaleToken _token, TokenVault _refundVault)
	external onlyMaster
	{
		saleInfo.link(_token, _refundVault);
		require(saleInfo.token != address(0));
		require(saleInfo.refundVault != address(0));
	}



	function recoverTokens(ERC20Basic token) public onlyOwner  {
		super.recoverTokens(token);
		token.transfer(owner, token.balanceOf(this));
		RecoverVaultOp.recoverVaultTokens(saleInfo.refundVault, token, owner, 0);
	}
	function recoverWeis() public onlyOwner  { // ether
		super.recoverWeis();
		uint256 keep = saleInfo.weiBalance();
		RecoverVaultOp.recoverVaultWeis(saleInfo.refundVault, owner, keep);
	}

}



library CrowdsaleHelper
{

	using SafeMath for uint256;
	using BalanceOp for BalanceOp.t;


	enum SaleState { Active, ClosedRefunding, SoftCapReached, ClosedSuccess }

	struct t {

		uint256 initialAllocatedSupply;

		uint256 weiRaised;

		uint256 weiPerUSCent;

		uint256 tokenSellTarget;

		uint256 openingTime;
		uint256 closingTime;

		uint256 hardCap;

		uint256 softCap;

		bool isFinalized;

		uint256 fundWithdrawal;
		address fundWallet;
		SaleState state;


		TokenVault refundVault;
		BalanceOp.t refund_account;

		uint256 multiplier;

		ERC20 token;

	}




	event Finalized();

	event TokenPurchase(
		address indexed purchaser,
		address indexed user,
		uint256 value,
		uint256 amount
	);

	event SoftCapReached();
	event RefundsEnabled();
	event Refunded(address indexed user, uint256 weis);











	function beneficiaryWithdraw(t storage _this)
	internal
	{
		require(_this.state == SaleState.SoftCapReached);
		uint256 amount = weiBalance(_this);
		if (amount > 0) {
			_this.refundVault.transferWei(_this.fundWallet, amount);
			_this.fundWithdrawal = _this.fundWithdrawal.add(amount);
		}
	}

	function tokenURI(t storage _this)
	internal
	view
	returns(string)
	{
		return CrowdsaleToken(_this.token).tokenURI();
	}

	function finalize(t storage _this)
	internal

	{
		finishIt(_this);
	}



	function claimRefund(t storage _this, address investor)
	internal
	{
		require(_this.state == SaleState.ClosedRefunding);

		uint256 amount = _this.refund_account.balanceOf(investor);
		if (amount > 0) {
			_this.refund_account.burn(investor, amount);
			// investor.transfer(amount); 	// ether 
			_this.refundVault.transferWei(investor, amount);
			emit Refunded(investor, amount);
		}

	}

	function tokenPriceInMilliUSD(t storage _this)
	internal view returns(uint256)
	{
		uint256 tokensSold = _this.token.totalSupply() - _this.initialAllocatedSupply;
		uint256 price = getTokenPriceInMilliUSD(_this, tokensSold);
		return price;
	}

	//////////////////////////////////////////////////////////////////
	function isOpen(t storage _this)
	internal view returns(bool)
	{
		// solium-disable-next-line operator-whitespace
		return (_this.state != SaleState.ClosedRefunding) &&
			(_this.state != SaleState.ClosedSuccess) &&
			(!CrowdsaleToken(_this.token).paused());
	}

	function softCapReached(t storage _this)
	internal view returns(bool)
	{
		return _this.weiRaised >= _this.softCap;
	}

	function hardCapReached(t storage _this)
	internal view returns(bool)
	{
		return (_this.weiRaised >= _this.hardCap);
	}

	function link(t storage _this, CrowdsaleToken _token, TokenVault _refundVault)
	internal
	{
		_this.token = _token;
		_this.refundVault = _refundVault;
		require(_this.token != address(0));
		require(_this.refundVault != address(0));
	}


	function weisToBeReturned(t storage _this)
	internal view returns(uint256)
	{ // ether
		return address(this).balance.sub(weiBalance(_this));
	}


	function buyTokens(t storage _this, address user, uint256 weis)
	internal
	{
		address purchaser = user;

		// preValidatePurchase(user, weis);
		uint256 tokens = getTokenAmount(_this, weis);

		CrowdsaleToken(_this.token).deliverTokens(user, tokens);
		forwardFunds(_this, weis);
		depositVault(_this, user, weis);

		_this.weiRaised = _this.weiRaised.add(weis);
		emit TokenPurchase(
			purchaser,
			user,
			weis,
			tokens
		);
		updateState(_this);
	}


	//////////////////////////////////////////////////////////////////

	function finishIt(t storage _this)
	private
	{
		if (!softCapReached(_this)) {
			_this.state = SaleState.ClosedRefunding;
			CrowdsaleToken(_this.token).enableRefunds();
		} else {
			_this.state = SaleState.ClosedSuccess;
		}
	}

	function updateState(t storage _this)
	private
	{

		if (_this.state == SaleState.Active) {
			if (softCapReached(_this)) {
				_this.state = SaleState.SoftCapReached;
				emit SoftCapReached();
			}
		} else if (_this.state == SaleState.SoftCapReached) {
			if (hardCapReached(_this)) {
				_this.state = SaleState.ClosedSuccess;
			}
		}
		if (timeEnded(_this)) {
			finishIt(_this);
		}
	}

	function timeEnded(t storage _this) 
	private view returns(bool)
	{
		uint256 ts = MiscOp.currentTime();
		return (ts >= _this.closingTime);
	}





	function forwardFunds(t storage _this, uint256 weis)
	private
	{
		VaultOp.transferWei(address(_this.refundVault), weis); // ether transfer
	}


	function depositVault(t storage _this, address investor, uint256 weis)
	private
	{
		require(_this.state == SaleState.Active);
		_this.refund_account.mint(investor, weis);
	}



	function getTokenAmount(t storage _this, uint256 weis)
	private view returns(uint256)
	{
		uint256 tokensSold = _this.token.totalSupply() - _this.initialAllocatedSupply;

		uint256 price = getTokenPriceInWei(_this, tokensSold);
		uint256 amount = weis / price;
		require(amount > 0);
		return amount;
	}

	function getTokenPriceInWei(t storage _this, uint256 tokensSold) 
	private view returns(uint256)
	{
		uint256 p = getTokenPriceInMilliUSD(_this, tokensSold);
		uint256 priceInWei = (_this.weiPerUSCent * p / 10) / (_this.multiplier);
		return priceInWei;
	}
	function getTokenPriceInMilliUSD(t storage _this, uint256 tokensSold) 
	private view returns(uint256)
	{
		uint256 steps = 100;
		uint256 inc = _this.tokenSellTarget / steps;
		uint256 n = tokensSold / inc;
		uint256 p = 50 + n; 			// USD $0.050, USD$0.149
		return p;
	}


	function weiBalance(t storage _this) 
	internal view returns(uint256)
	{ // ether
		return _this.refund_account.totalSupply().sub(_this.fundWithdrawal);
	}



}




