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

	function url()
	external 
	view
	returns (string)
	{
		return UnionCrowdsaleToken(token).url();
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

		_preValidatePurchase(_beneficiary, weiAmount);
		uint256 tokens = _getTokenAmount(weiAmount);

		UnionCrowdsaleToken(token).deliverTokens(_beneficiary, tokens);
		_forwardFunds();

		saleInfo.weiRaised = saleInfo.weiRaised.add(weiAmount);
		emit TokenPurchase(
			msg.sender,
			_beneficiary,
			weiAmount,
			tokens
		);
	}
	function _preValidatePurchase(
		address _beneficiary,
		uint256 _weiAmount
	) internal view; // solium-disable-line indentation
	
	
	
	function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256);
	function _forwardFunds() internal;
}


contract TrancheCrowdsale is CrowdsaleBase {
	using SafeMath for uint256;

	function tokenPriceInMilliUSD() 
	public view returns(uint256) 
	{
		uint256 tokensSold = token.totalSupply() - saleInfo.initialAllocatedSupply;
		uint256 price = _getTokenPriceInMilliUSD(tokensSold);
		return price;
	}



	function _getTokenAmount(uint256 _weiAmount)
	internal view returns(uint256)
	{
		uint256 tokensSold = token.totalSupply() - saleInfo.initialAllocatedSupply;
		
		uint256 price = _getTokenPriceInWei(tokensSold);
		uint256 amount = _weiAmount / price;
		require(amount > 0);
		require(tokensSold + amount <= saleInfo.tokenSellTarget);
		return amount;
	}

	function _getTokenPriceInWei(uint256 tokensSold) 
	private view returns(uint256) 
	{
		uint256 p = _getTokenPriceInMilliUSD(tokensSold);
		uint256 priceInWei = (saleInfo.weiPerUSCent * p / 10) / (saleInfo.multiplier);
		return priceInWei;
	}
	function _getTokenPriceInMilliUSD(uint256 tokensSold) 
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
	using SafeMath for uint256;
	

	modifier onlyWhileOpen {
		// solium-disable-next-line security/no-block-members
		require(block.timestamp >= saleInfo.openingTime && block.timestamp <= saleInfo.closingTime);
		_;
	}
	function _preValidatePurchase(
		address _beneficiary,
		uint256 _weiAmount
	)
    internal view
    onlyWhileOpen
	{
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
		require(!goalReached());
		require(!UnionCrowdsaleToken(token).paused());
	}

	function goalReached() 
	public view returns (bool) 
	{
		return saleInfo.weiRaised >= saleInfo.goal;
	}

	function softCapReached() 
	public view returns (bool) 
	{
		return saleInfo.weiRaised >= saleInfo.cap;
	}

	function hasClosed() 
	public view returns (bool) 
	{
		// solium-disable-next-line security/no-block-members
		return block.timestamp > saleInfo.closingTime;
	}

}

contract RefundableCrowdsale is CappedTimedCrowdsale {
	using SafeMath for uint256;
	
	event Finalized();
	
	function finalization() 
	internal 
	{
		if (goalReached()) {
			vault.close();
		} else {
			UnionCrowdsaleToken(token).enableRefunds();
			vault.enableRefunds();
		}
	}
	function _forwardFunds() 
	internal 
	{
		vault.deposit.value(msg.value)(msg.sender);	// ether transfer
	}



	function finalize() 
	external 
	onlyOwner  
	{

		require(!saleInfo.isFinalized);
		require(hasClosed());
		finalization();
		emit Finalized();
		saleInfo.isFinalized = true;
	}
	
	function claimRefund() 
	external 
	{
		require(saleInfo.isFinalized);
		require(!goalReached());
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




