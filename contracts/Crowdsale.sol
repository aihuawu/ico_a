
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";
import "./Ownable.sol";
import "./Vault.sol";
import "./CrowdsaleToken.sol";



contract CrowdsaleBase is Recoverable
{
	using SafeMath for uint256;

	ERC20 token;
	RefundVault vault;

	Util.SaleInfo public saleInfo;



	event TokenPurchase(
		address indexed purchaser,
		address indexed beneficiary,
		uint256 value,
		uint256 amount
	);

	function tokenURI()
	external
	view
	returns(string)
	{
		return UnionCrowdsaleToken(token).tokenURI();
	}



	function ()
	external payable
	{
		buyTokens(msg.sender);
	}
	function buyTokens(address _beneficiary) 
	public payable
	{
		uint256 weiAmount = msg.value;

		preValidatePurchase(_beneficiary, weiAmount);
		uint256 tokens = getTokenAmount(weiAmount);

		UnionCrowdsaleToken(token).deliverTokens(_beneficiary, tokens);
		forwardFunds();

		saleInfo.weiRaised = saleInfo.weiRaised.add(weiAmount);
		checkCap();
		emit TokenPurchase(
			msg.sender,
			_beneficiary,
			weiAmount,
			tokens
		);
	}
	function preValidatePurchase(
		address _beneficiary,
		uint256 _weiAmount
	) internal view; // solium-disable-line indentation



	function getTokenAmount(uint256 _weiAmount) internal view returns(uint256);
	function forwardFunds() internal;
	function checkCap() internal;
}


contract TrancheCrowdsale is CrowdsaleBase {

	function tokenPriceInMilliUSD() 
	public view returns(uint256)
	{
		uint256 tokensSold = token.totalSupply() - saleInfo.initialAllocatedSupply;
		uint256 price = getTokenPriceInMilliUSD(tokensSold);
		return price;
	}



	function getTokenAmount(uint256 _weiAmount)
	internal view returns(uint256)
	{
		uint256 tokensSold = token.totalSupply() - saleInfo.initialAllocatedSupply;

		uint256 price = getTokenPriceInWei(tokensSold);
		uint256 amount = _weiAmount / price;
		require(amount > 0);
		return amount;
	}

	function getTokenPriceInWei(uint256 tokensSold) 
	private view returns(uint256)
	{
		uint256 p = getTokenPriceInMilliUSD(tokensSold);
		uint256 priceInWei = (saleInfo.weiPerUSCent * p / 10) / (saleInfo.multiplier);
		return priceInWei;
	}
	function getTokenPriceInMilliUSD(uint256 tokensSold) 
	private view returns(uint256)
	{
		uint256 steps = 100;
		uint256 inc = saleInfo.tokenSellTarget / steps;
		uint256 n = tokensSold / inc;
		uint256 p = 50 + n; 			// USD $0.050, USD$0.149
		return p;
	}
}

contract CappedTimedCrowdsale is CrowdsaleBase {

	function preValidatePurchase(
		address _beneficiary,
		uint256 _weiAmount
	)
    internal view
	{
		require(isOpen());
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
		require(!UnionCrowdsaleToken(token).paused());
	}

	function softGoalReached() 
	public view returns(bool)
	{
		return saleInfo.weiRaised >= saleInfo.softGoal;
	}

	function hardCapReached() 
	public view returns(bool)
	{
		return (saleInfo.weiRaised >= saleInfo.hardCap);
	}

	function isOpen() 
	public view returns(bool)
	{
		// solium-disable-next-line security/no-block-members
		uint256 ts = block.timestamp;
		return (!saleInfo.isFinalized) && (ts >= saleInfo.openingTime) && (ts <= saleInfo.closingTime);
	}

}

contract RefundableCrowdsale is CappedTimedCrowdsale {
	event Finalized();

	function checkCap()
	internal
	{
		if (hardCapReached()) {
			finalization();
		}
		if (softGoalReached()) {
			vault.softGoalReached();
		}
	}
	function finalization()
	internal
	{
		if (!saleInfo.isFinalized) {
			if (softGoalReached()) {
				vault.softGoalReached();
			} else {
				UnionCrowdsaleToken(token).enableRefunds();
				vault.enableRefunds();
			}
			emit Finalized();
			saleInfo.isFinalized = true;
		}
	}
	function forwardFunds()
	internal
	{
		vault.deposit.value(msg.value)(msg.sender);	// ether transfer
	}



	function finalize()
	external
	onlyOwner
	{
		finalization();
	}

	function claimRefund()
	external
	{
		require(saleInfo.isFinalized);
		require(!softGoalReached());
		vault.refund(msg.sender);
	}

}






contract UnionCrowdsale is RefundableCrowdsale, TrancheCrowdsale
{

	function link(UnionCrowdsaleToken _token, RefundVault _vault)
	external fromOwnerOrMaster
	{
		token = _token;
		vault = _vault;
		require(token != address(0));
		require(vault != address(0));
	}


}




