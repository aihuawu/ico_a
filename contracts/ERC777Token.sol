
pragma solidity ^ 0.4.24;

import "./Util.sol";
import "./ERC20.sol";
import "./ERC777.sol";


contract ERC820Registry {
	function getManager(address _addr) public view returns(address);
	function setManager(address _addr, address _newManager) external;
	function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns(address);
	function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
}

contract ERC820Implementer {
	ERC820Registry erc820Registry = ERC820Registry(0xa691627805d5FAE718381ED95E04d00E20a1fea6);

	function setInterfaceImplementation(string _interfaceLabel, address impl) internal {
		bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
		erc820Registry.setInterfaceImplementer(this, interfaceHash, impl);
	}

	function interfaceAddr(address addr, string _interfaceLabel) internal constant returns(address) {
		bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
		return erc820Registry.getInterfaceImplementer(addr, interfaceHash);
	}

	function delegateManagement(address _newManager) internal {
		erc820Registry.setManager(this, _newManager);
	}
}
contract ERC777BaseToken is ERC777Token, ERC820Implementer {
	using SafeMath for uint256;

	string internal mName;
	string internal mSymbol;
	uint256 internal mGranularity;
	uint256 internal mTotalSupply;


	mapping(address => uint) internal mBalances;
	mapping(address => mapping(address => bool)) internal mAuthorized;

	address[] internal mDefaultOperators;
	mapping(address => bool) internal mIsDefaultOperator;
	mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;

	/* -- Constructor -- */
	//
	/// @notice Constructor to create a ReferenceToken
	/// @param _name Name of the new token
	/// @param _symbol Symbol of the new token.
	/// @param _granularity Minimum transferable chunk.
	constructor(string _name, string _symbol, uint256 _granularity, address[] _defaultOperators) internal {
		mName = _name;
		mSymbol = _symbol;
		mTotalSupply = 0;
		MiscOp.requireEx(_granularity >= 1);
		mGranularity = _granularity;

		mDefaultOperators = _defaultOperators;
		for (uint i = 0; i < mDefaultOperators.length; i++) { mIsDefaultOperator[mDefaultOperators[i]] = true; }

		setInterfaceImplementation("ERC777Token", this);
	}

	/* -- ERC777 Interface Implementation -- */
	//
	/// @return the name of the token
	function name() public constant returns(string) { return mName; }

	/// @return the symbol of the token
	function symbol() public constant returns(string) { return mSymbol; }

	/// @return the granularity of the token
	function granularity() public constant returns(uint256) { return mGranularity; }

	/// @return the total supply of the token
	function totalSupply() public constant returns(uint256) { return mTotalSupply; }

	/// @notice Return the account balance of some account
	/// @param _tokenHolder Address for which the balance is returned
	/// @return the balance of `_tokenAddress`.
	function balanceOf(address _tokenHolder) public constant returns(uint256) { return mBalances[_tokenHolder]; }

	/// @notice Return the list of default operators
	/// @return the list of all the default operators
	function defaultOperators() public view returns(address[]) { return mDefaultOperators; }

	/// @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
	/// @param _to The address of the recipient
	/// @param _amount The number of tokens to be sent
	function send(address _to, uint256 _amount, bytes _userData) public {
		doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
	}

	/// @notice Authorize a third party `_operator` to manage (send) `msg.sender`'s tokens.
	/// @param _operator The operator that wants to be Authorized
	function authorizeOperator(address _operator) public {
		MiscOp.requireEx(_operator != msg.sender);
		if (mIsDefaultOperator[_operator]) {
			mRevokedDefaultOperator[_operator][msg.sender] = false;
		} else {
			mAuthorized[_operator][msg.sender] = true;
		}
		emit AuthorizedOperator(_operator, msg.sender);
	}

	/// @notice Revoke a third party `_operator`'s rights to manage (send) `msg.sender`'s tokens.
	/// @param _operator The operator that wants to be Revoked
	function revokeOperator(address _operator) public {
		MiscOp.requireEx(_operator != msg.sender);
		if (mIsDefaultOperator[_operator]) {
			mRevokedDefaultOperator[_operator][msg.sender] = true;
		} else {
			mAuthorized[_operator][msg.sender] = false;
		}
		emit RevokedOperator(_operator, msg.sender);
	}

	/// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
	/// @param _operator address to check if it has the right to manage the tokens
	/// @param _tokenHolder address which holds the tokens to be managed
	/// @return `true` if `_operator` is authorized for `_tokenHolder`
	function isOperatorFor(address _operator, address _tokenHolder) public constant returns(bool) {
		return (_operator == _tokenHolder
			|| mAuthorized[_operator][_tokenHolder]
			|| (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
	}

	/// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
	/// @param _from The address holding the tokens being sent
	/// @param _to The address of the recipient
	/// @param _amount The number of tokens to be sent
	/// @param _userData Data generated by the user to be sent to the recipient
	/// @param _operatorData Data generated by the operator to be sent to the recipient
	function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
		MiscOp.requireEx(isOperatorFor(msg.sender, _from));
		doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
	}

	function burn(uint256 _amount, bytes _holderData) public {
		doBurn(msg.sender, msg.sender, _amount, _holderData, "");
	}

	function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData) public {
		MiscOp.requireEx(isOperatorFor(msg.sender, _tokenHolder));
		doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
	}

	/* -- Helper Functions -- */
	//
	/// @notice Internal function that ensures `_amount` is multiple of the granularity
	/// @param _amount The quantity that want's to be checked
	function requireMultiple(uint256 _amount) internal view {
		MiscOp.requireEx(_amount.div(mGranularity).mul(mGranularity) == _amount);
	}

	/// @notice Check whether an address is a regular address or not.
	/// @param _addr Address of the contract that has to be checked
	/// @return `true` if `_addr` is a regular address (not a contract)
	function isRegularAddress(address _addr) internal constant returns(bool) {
		if (_addr == 0) { return false; }
		uint size;
		// solium-disable-next-line security/no-inline-assembly
		assembly { size:= extcodesize(_addr) } // solhint-disable-line no-inline-assembly
		return size == 0;
	}

	/// @notice Helper function actually performing the sending of tokens.
	/// @param _operator The address performing the send
	/// @param _from The address holding the tokens being sent
	/// @param _to The address of the recipient
	/// @param _amount The number of tokens to be sent
	/// @param _userData Data generated by the user to be passed to the recipient
	/// @param _operatorData Data generated by the operator to be passed to the recipient
	/// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
	///  implementing `erc777_tokenHolder`.
	///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
	///  functions SHOULD set this parameter to `false`.
	function doSend(
		address _operator,
		address _from,
		address _to,
		uint256 _amount,
		bytes _userData,
		bytes _operatorData,
		bool _preventLocking
	)
	internal
	{
		requireMultiple(_amount);

		callSender(_operator, _from, _to, _amount, _userData, _operatorData);

		MiscOp.requireEx(_to != address(0));          // forbid sending to 0x0 (=burning)
		MiscOp.requireEx(mBalances[_from] >= _amount); // ensure enough funds

		mBalances[_from] = mBalances[_from].sub(_amount);
		mBalances[_to] = mBalances[_to].add(_amount);

		callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

		emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
	}

	/// @notice Helper function actually performing the burning of tokens.
	/// @param _operator The address performing the burn
	/// @param _tokenHolder The address holding the tokens being burn
	/// @param _amount The number of tokens to be burnt
	/// @param _holderData Data generated by the token holder
	/// @param _operatorData Data generated by the operator
	function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
	internal
	{
		requireMultiple(_amount);
		MiscOp.requireEx(balanceOf(_tokenHolder) >= _amount);

		mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
		mTotalSupply = mTotalSupply.sub(_amount);

		callSender(_operator, _tokenHolder, 0x0, _amount, _holderData, _operatorData);
		emit Burned(_operator, _tokenHolder, _amount, _holderData, _operatorData);
	}

	/// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
	///  May throw according to `_preventLocking`
	/// @param _operator The address performing the send or mint
	/// @param _from The address holding the tokens being sent
	/// @param _to The address of the recipient
	/// @param _amount The number of tokens to be sent
	/// @param _userData Data generated by the user to be passed to the recipient
	/// @param _operatorData Data generated by the operator to be passed to the recipient
	/// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
	///  implementing `ERC777TokensRecipient`.
	///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
	///  functions SHOULD set this parameter to `false`.
	function callRecipient(
		address _operator,
		address _from,
		address _to,
		uint256 _amount,
		bytes _userData,
		bytes _operatorData,
		bool _preventLocking
	)
	internal
	{
		address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
		if (recipientImplementation != 0) {
			ERC777TokensRecipient(recipientImplementation).tokensReceived(
				_operator, _from, _to, _amount, _userData, _operatorData);
		} else if (_preventLocking) {
			MiscOp.requireEx(isRegularAddress(_to));
		}
	}

	/// @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
	///  May throw according to `_preventLocking`
	/// @param _from The address holding the tokens being sent
	/// @param _to The address of the recipient
	/// @param _amount The amount of tokens to be sent
	/// @param _userData Data generated by the user to be passed to the recipient
	/// @param _operatorData Data generated by the operator to be passed to the recipient
	///  implementing `ERC777TokensSender`.
	///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
	///  functions SHOULD set this parameter to `false`.
	function callSender(
		address _operator,
		address _from,
		address _to,
		uint256 _amount,
		bytes _userData,
		bytes _operatorData
	)
	internal
	{
		address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
		if (senderImplementation == 0) { return; }
		ERC777TokensSender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
	}
}



contract ERC777ERC20BaseToken is ERC20, ERC777BaseToken {
	bool internal mErc20compatible;

	mapping(address => mapping(address => bool)) internal mAuthorized;
	mapping(address => mapping(address => uint256)) internal mAllowed;

	constructor(
		string _name,
		string _symbol,
		uint256 _granularity,
		address[] _defaultOperators
	)
	internal ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators)
	{
		mErc20compatible = true;
		setInterfaceImplementation("ERC20Token", this);
	}

	/// @notice This modifier is applied to erc20 obsolete methods that are
	///  implemented only to maintain backwards compatibility. When the erc20
	///  compatibility is disabled, this methods will fail.
	modifier erc20() {
		MiscOp.requireEx(mErc20compatible);
		_;
	}

	/// @notice For Backwards compatibility
	/// @return The decimls of the token. Forced to 18 in ERC777.
	function decimals() public erc20 constant returns(uint8) { return uint8(18); }

	/// @notice ERC20 backwards compatible transfer.
	/// @param _to The address of the recipient
	/// @param _amount The number of tokens to be transferred
	/// @return `true`, if the transfer can't be done, it should fail.
	function transfer(address _to, uint256 _amount) public erc20 returns(bool success) {
		doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
		return true;
	}

	/// @notice ERC20 backwards compatible transferFrom.
	/// @param _from The address holding the tokens being transferred
	/// @param _to The address of the recipient
	/// @param _amount The number of tokens to be transferred
	/// @return `true`, if the transfer can't be done, it should fail.
	function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns(bool success) {
		MiscOp.requireEx(_amount <= mAllowed[_from][msg.sender]);

		// Cannot be after doSend because of tokensReceived re-entry
		mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
		doSend(msg.sender, _from, _to, _amount, "", "", false);
		return true;
	}

	/// @notice ERC20 backwards compatible approve.
	///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
	/// @param _spender The address of the account able to transfer the tokens
	/// @param _amount The number of tokens to be approved for transfer
	/// @return `true`, if the approve can't be done, it should fail.
	function approve(address _spender, uint256 _amount) public erc20 returns(bool success) {
		mAllowed[msg.sender][_spender] = _amount;
		emit Approval(msg.sender, _spender, _amount);
		return true;
	}

	/// @notice ERC20 backwards compatible allowance.
	///  This function makes it easy to read the `allowed[]` map
	/// @param _owner The address of the account that owns the token
	/// @param _spender The address of the account able to transfer the tokens
	/// @return Amount of remaining tokens of _owner that _spender is allowed
	///  to spend
	function allowance(address _owner, address _spender) public erc20 constant returns(uint256 remaining) {
		return mAllowed[_owner][_spender];
	}

	function doSend(
		address _operator,
		address _from,
		address _to,
		uint256 _amount,
		bytes _userData,
		bytes _operatorData,
		bool _preventLocking
	)
	internal
	{
		super.doSend(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);
		if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
	}

	function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
	internal
	{
		super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
		if (mErc20compatible) { emit Transfer(_tokenHolder, 0x0, _amount); }
	}
}
