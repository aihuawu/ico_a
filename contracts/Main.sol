
pragma solidity ^ 0.4.24;

import "./ERC20.sol";
import "./Util.sol";
import "./List.sol";
import "./ERC20Token.sol";
import "./Proposal.sol";
import "./Ownable.sol";
import "./Vault.sol";
import "./CrowdsaleToken.sol";
import "./Crowdsale.sol";
import "./Exchange.sol";




contract Token is CrowdsaleToken {

	constructor(address _owner, address _master, //
		string _url, string _name, string _symbol, uint8 _decimals)
	public
	{
		owner = _owner;
		master = _master;

		tokenInfo.name = _name;
		tokenInfo.symbol = _symbol;
		tokenInfo.decimals = _decimals;
		tokenInfo.tokenURI = _url;

		// tokenInfo.voteLockSeconds = _voteLockSeconds;

	}

}


contract Exchange is SimpleExchange {

	constructor(address _owner, address _master)
	public
	{
		owner = _owner;
		master = _master;
	}
}

contract ProposalVoting is SimpleProposalVoting {

	constructor(address _owner, address _master,  
		uint256 _voteLockSeconds)
	public
	{
		owner = _owner;
		master = _master;
		proposalInfo.voteLockSeconds = _voteLockSeconds;
	}
}


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
		MiscOp.requireEx(_openingTime >= block.timestamp);// solium-disable-line security/no-block-members
		MiscOp.requireEx(_closingTime >= _openingTime);
		saleInfo.openingTime = _openingTime;
		saleInfo.closingTime = _closingTime;
		saleInfo.isFinalized = false;

		saleInfo.hardCap = 1000000 * 100 * _weiPerUSCent;// hard cap, $1 million
		MiscOp.requireEx(saleInfo.hardCap > 0);


		saleInfo.softCap = 1000000 * 100 * _weiPerUSCent / 10;// soft cap, 10%
		MiscOp.requireEx(saleInfo.softCap > 0);


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

	ProposalVoting proposalVoting;
	TokenVault voteVault;

	Sale sale;
	TokenVault refundVault;

	Exchange exchange;
	TokenVault exchangeVault;

	struct Combo {
		address master;
		address token;
		address sale;
		address exchange;
		address proposalVoting;

		address foundersVault;
		address voteVault;
		address refundVault;
		address exchangeVault;
	}
	Combo public combo;


	constructor(
		string _url,
		address _fundMultisig,
		address _foundersMultisig,
		address _tokenPrevious,
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
			"tlkma", "talkmap round a coin", _decimals);

		// proposalVoting = new ProposalVoting(owner, master, _voteLockSeconds);
		// voteVault = new TokenVault(proposalVoting);

		sale = new Sale(owner, master,
			_multiplier,
			_fundMultisig,
			_foundersTokens,
			_weiPerUSCent,
			_tokenSellTarget,
			_openingTime,
			_closingTime);
		refundVault = new TokenVault(sale);
		foundersVault = new TokenVault(sale);

		exchange = new Exchange(owner, master);
		exchangeVault = new TokenVault(exchange);

		token.link(sale);

		sale.link(token, foundersVault, _foundersTokens, refundVault);
		sale.link2(_tokenPrevious);
		sale.initFoundersTokens(_foundersMultisig, _foundersTokens, _foundersUnlockTime);

		exchange.link(exchangeVault);


		_voteLockSeconds = _voteLockSeconds; // just to shut up thw warning
		// proposalVoting.link(token, voteVault);


		combo.master = address(master);
		combo.token = address(token);
		combo.sale = address(sale);
		combo.exchange = address(exchange);
		combo.foundersVault = address(foundersVault);
		combo.voteVault = address(voteVault);
		combo.refundVault = address(refundVault);
		combo.exchangeVault = address(exchangeVault);
		combo.proposalVoting = address(proposalVoting);
	}

}

