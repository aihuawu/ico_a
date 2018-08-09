

pragma solidity ^ 0.4.24;


contract ERC777 {
	function name() public view returns(string);
	function symbol() public view returns(string);
	function totalSupply() public view returns(uint256);
	function balanceOf(address owner) public view returns(uint256);
	function granularity() public view returns(uint256);

	function defaultOperators() public view returns(address[]);
	function isOperatorFor(address operator, address tokenHolder) public view returns(bool);
	function authorizeOperator(address operator) public;
	function revokeOperator(address operator) public;

	function send(address to, uint256 amount, bytes holderData) public;
	function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) public;

	function burn(uint256 amount, bytes holderData) public;
	function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) public;

	event Sent(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes holderData,
		bytes operatorData
	); // solhint-disable-next-line separate-by-one-line-in-contract
	event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
	event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
	event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
	event RevokedOperator(address indexed operator, address indexed tokenHolder);
}



contract ERC820Registry {
	function getManager(address _addr) public view returns(address);
	function setManager(address _addr, address _newManager) external;
	function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns(address);
	function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
}

contract ERC777TokensSender {
	function tokensToSend(
		address operator,
		address from,
		address to,
		uint amount,
		bytes userData,
		bytes operatorData
	) public;
}

contract ERC777TokensRecipient {
	function tokensReceived(
		address operator,
		address from,
		address to,
		uint amount,
		bytes userData,
		bytes operatorData
	) public;
}
