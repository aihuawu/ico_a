
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./List.sol";
import "./StandardToken.sol";
import "./Ownable.sol";
import "./Vault.sol";
import "./CrowdsaleToken.sol";
import "./Crowdsale.sol";
import "./Exchange.sol";




contract Token is CrowdsaleToken {

	constructor(address _owner, address _master, //
		string _url, string _name, string _symbol, uint8 _decimals,  //
		uint256 _voteLockSeconds)
	public
	{
		owner = _owner;
		master = _master;

		tokenInfo.name = _name;
		tokenInfo.symbol = _symbol;
		tokenInfo.decimals = _decimals;
		tokenInfo.tokenURI = _url;

		tokenInfo.voteLockSeconds = _voteLockSeconds;

	}

}



// solium-disable-next-line max-len
contract Sale is Crowdsale {

	constructor(address _owner, address _master,
		uint256 _multiplier,
		address _wallet,
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

		saleInfo.hardCap = 1000000 * 100 * _weiPerUSCent;// hard cap, $1 million
		require(saleInfo.hardCap > 0);


		saleInfo.softCap = 1000000 * 100 * _weiPerUSCent / 10;// soft cap, 10%
		require(saleInfo.softCap > 0);


		saleInfo.multiplier = _multiplier;
		saleInfo.tokenSellTarget = _tokenSellTarget;
		saleInfo.weiPerUSCent = _weiPerUSCent;


		// refundInfo.sale = this;
		saleInfo.fundWallet = _wallet;
		saleInfo.state = CrowdsaleHelper.SaleState.Active;
	}


}





contract Master
is Recoverable
{
	Token token;
	TokenVault foundersVault;
	TokenVault voteVault;

	Sale sale;
	TokenVault refundVault;

	Exchange exchange;

	struct Combo {
		address master;
		address token;
		address sale;
		address exchange;

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
		voteVault = new TokenVault(CrowdsaleToken(token));
		foundersVault = new TokenVault(token);

		sale = new Sale(owner, master,
			_multiplier,
			_fundMultisig,
			_foundersTokens,
			_weiPerUSCent,
			_tokenSellTarget,
			_openingTime,
			_closingTime);
		refundVault = new TokenVault(sale);

		exchange = new Exchange();

		token.link(sale, voteVault, foundersVault);
		sale.link(token, refundVault);

		token.initFoundersTokens(_foundersMultisig, _foundersTokens, _foundersUnlockTime);

		combo.master = address(master);
		combo.token = address(token);
		combo.sale = address(sale);
		combo.exchange = address(exchange);
		combo.foundersVault = address(foundersVault);
		combo.voteVault = address(voteVault);
		combo.refundVault = address(refundVault);
	}

}

