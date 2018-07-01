pragma solidity ^ 0.4.23;

import "zeppelin/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "zeppelin/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "zeppelin/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "zeppelin/contracts/token/ERC20/MintableToken.sol";
import "zeppelin/contracts/token/ERC20/DetailedERC20.sol";
import "./CrowdsaleToken.sol";



contract TrancheCrowdsale is MintedCrowdsale {
	using SafeMath for uint256;
	uint256 public weiPerUSCent;
	uint256 public tokenSellTarget;
	uint256 public teamTokenSupply;
	TimeVault public teamTokenVault;

	constructor(
		CrowdsaleToken _token,
		address _fundMultisig,
		address _teamMultisig,
		uint256 _teamTokenSupply,
		uint256 _tokenSellTarget,
		uint256 _weiPerUSCent,
		uint256 _teamUnlockTime
	)
    public
    Crowdsale(1, _fundMultisig, _token)
    {
		teamTokenSupply = _teamTokenSupply;
		tokenSellTarget = _tokenSellTarget;
		weiPerUSCent = _weiPerUSCent;
		teamTokenVault = new TimeVault(_teamMultisig, UpgradeableToken(token), _teamUnlockTime);
		MintableToken(token).mint(teamTokenVault, teamTokenSupply);
    }

	function unlockTeamToken() public {
		teamTokenVault.unlock();
	}
	
	function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
	{
		require(tokensSold <= tokenSellTarget);
		uint256 tokensSold = token.totalSupply() - teamTokenSupply;
		uint256 price = getTokenPriceInWei(tokensSold);
		uint256 amount = _weiAmount / price;
		require(amount > 0);
		require(tokensSold + amount <= tokenSellTarget);
		return amount;
	}

	function getTokenPriceInWei(uint256 tokensSold) internal view returns (uint256) { 
		uint8 decimals = (CrowdsaleToken(token)).decimals();
		uint256 multiplier = 10 ** decimals;
		uint256 steps = 100;
		uint256 inc = tokenSellTarget / steps;
		uint256 n = tokensSold / inc;
		uint256 p = 50 + n; 			// USD $0.050, USD$0.149
		uint256 priceInWei = (weiPerUSCent * p / 10) / (multiplier);
		return priceInWei;
	}
}

// solium-disable-next-line max-len
contract RoundACrowdsale is CappedCrowdsale, RefundableCrowdsale, TrancheCrowdsale {

	constructor(
		CrowdsaleToken _token,
		address _fundMultisig,
		address _teamMultisig,
		uint256 _weiPerUSCent,
		uint256 _teamUnlockTime,
		uint256 _openingTime,
		uint256 _closingTime
	)
    public
    CappedCrowdsale(1000000 * 100 * _weiPerUSCent) // hard cap
    TimedCrowdsale(_openingTime, _closingTime)
    RefundableCrowdsale(1000000 * 100 * _weiPerUSCent / 10) // soft cap
    TrancheCrowdsale(_token, _fundMultisig, _teamMultisig,
		4000000 * (10 ** _token.decimals()), 1000000 * (10 ** _token.decimals()),
		_weiPerUSCent, _teamUnlockTime)
	{
		//As goal needs to be met for a successful crowdsale
		//the value needs to less or equal than a cap which is limit for accepted funds
		require(_token.owner() == msg.sender);
	}
}
