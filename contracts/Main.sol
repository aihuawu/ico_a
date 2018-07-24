
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";
import "./Ownable.sol";
import "./Vault.sol";
import "./CrowdsaleToken.sol";
import "./Crowdsale.sol";




contract Token is UnionCrowdsaleToken {

	constructor(address _owner, address _master, //
		string _url, string _name, string _symbol, uint8 _decimals,  //
		uint256 _voteLockSeconds)
	public
	{
		owner = _owner;
		master = _master;

		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		url = _url;

		tokenInfo.voteLockSeconds = _voteLockSeconds;
	}

}



// solium-disable-next-line max-len
contract Sale is UnionCrowdsale {

	constructor(address _owner, address _master,
		uint256 _multiplier,
		uint256 _foundersTokens,
		uint256 _weiPerUSCent,
		uint256 _tokenSellTarget,
		uint256 _openingTime,
		uint256 _closingTime
	)
	public
	{
		owner = _owner;
		master = _master;

		saleInfo.initialAllocatedSupply = _foundersTokens;

		// solium-disable-next-line security/no-block-members
		require(_openingTime >= block.timestamp);// solium-disable-line security/no-block-members
		require(_closingTime >= _openingTime);
		saleInfo.openingTime = _openingTime;
		saleInfo.closingTime = _closingTime;
		saleInfo.isFinalized = false;

		saleInfo.cap = 1000000 * 100 * _weiPerUSCent;// hard cap, $1 million
		require(saleInfo.cap > 0);


		saleInfo.goal = 1000000 * 100 * _weiPerUSCent / 10;// soft cap, 10%
		require(saleInfo.goal > 0);


		saleInfo.multiplier = _multiplier;
		saleInfo.tokenSellTarget = _tokenSellTarget;
		saleInfo.weiPerUSCent = _weiPerUSCent;


	}


}




/*



weiPerUSCent = (10^18)/(100*USDPerEther)
js: e.g. $452.00 for 1 ether
weiPerUSCent=Math.floor(Math.pow(10,18)/(45200)) = 22.123*(10^12)

priceInWei = (weiPerUSCent * 50 / 10) / (10^9) = 110K

amount = (10^18) / priceInWei = 10^13



*/

contract Master
is Recoverable
{ 
	Token public token;
	FoundersTokenVault public foundersVault;
	VotableTokenVault public voteVault;

	Sale public sale;
	RefundVault public refundVault;

	struct Combo {
		address master; 
		address token;
		address sale;

		address foundersVault;
		address voteVault;
		address refundVault;
	}
	Combo public combo;


	constructor(
		string _url,
		address _fundMultisig,
		address _foundersMultisig,
		uint256 _weiPerUSCent,
		uint256 _foundersUnlockTime,
		uint256 _openingTime,
		uint256 _closingTime,
		uint256 _voteLockSeconds)
	public
	{
		address master = this;

		uint8 _decimals = 9;
		uint256 _multiplier = uint256(10 ** 9);

		uint256 _tokenSellTarget = 10 * 1000 * 1000 * _multiplier;
		uint256 _foundersTokens = 40 * 1000 * 1000 * _multiplier;

		token = new Token(owner, master, _url,
			"tlkma", "talkmap round a coin", _decimals,
			_voteLockSeconds);
		voteVault = new VotableTokenVault(owner, master, UnionCrowdsaleToken(token));
		foundersVault = new FoundersTokenVault(owner, master, token);

		sale = new Sale(owner, master, 
			_multiplier,
			_foundersTokens, 
			_weiPerUSCent,
			_tokenSellTarget,
			_openingTime,
			_closingTime);
		refundVault = new RefundVault(owner, master, sale, _fundMultisig);

		token.link(sale, voteVault, foundersVault);
		sale.link(token, refundVault);

		token.initFoundersTokens(_foundersMultisig, _foundersTokens, _foundersUnlockTime);

		combo.master = address(master);
		combo.token = address(token);
		combo.sale = address(sale);
		combo.foundersVault = address(foundersVault);
		combo.voteVault = address(voteVault);
		combo.refundVault = address(refundVault);
	}


}
