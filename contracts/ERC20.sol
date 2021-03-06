
pragma solidity ^ 0.4.24;


contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns(bool);
	function approve(address spender, uint256 value) public returns(bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

// https://eips.ethereum.org/EIPS/eip-1046
contract ERC20Ex is ERC20 {
	function tokenURI() external view returns (string);
}

