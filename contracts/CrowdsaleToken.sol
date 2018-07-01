
pragma solidity ^0.4.23;
import "zeppelin/contracts/ownership/Ownable.sol";
import "zeppelin/contracts/token/ERC20/ERC20Basic.sol";
import "zeppelin/contracts/token/ERC20/StandardToken.sol";
import "zeppelin/contracts/token/ERC20/DetailedERC20.sol";
import "zeppelin/contracts/token/ERC20/MintableToken.sol";
import "zeppelin/contracts/token/ERC20/PausableToken.sol";
/**
https://solidity.readthedocs.io/en/v0.4.24/contracts.html#inheritance
for multiple inheritance, pay attention to inheritance sequence, inheritance graph. 
*/
contract Recoverable is Ownable {
	constructor() public {
	}
	function recoverTokens(ERC20Basic token) onlyOwner public {
		token.transfer(owner, tokensToBeReturned(token));
	}
	function tokensToBeReturned(ERC20Basic token) public view returns (uint) {
		return token.balanceOf(this);
	}
}
contract StandardTokenExt is DetailedERC20, StandardToken, Recoverable, 
		PausableToken, MintableToken {
	function isToken() public constant returns (bool weAre) {
		return true;
	}
}
contract ReleasableToken is StandardTokenExt {
	address public releaseAgent;
	bool public released = false;
	mapping(address => bool) public transferAgents;
	modifier canTransfer(address _sender) {
		if (!released) {
			if (!transferAgents[_sender]) {
				revert();
			}
		}
		_;
	}
	function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
		releaseAgent = addr;
	}
	function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
		transferAgents[addr] = state;
	}
	function releaseTokenTransfer() public onlyReleaseAgent {
		released = true;
	}
	modifier inReleaseState(bool releaseState) {
		if (releaseState != released) {
			revert();
		}
		_;
	}
	modifier onlyReleaseAgent() {
		if (msg.sender != releaseAgent) {
			revert();
		}
		_;
	}
	function transfer(address _to, uint _value) canTransfer(msg.sender) public returns(bool success) {
		return super.transfer(_to, _value);
	}
	function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
		return super.transferFrom(_from, _to, _value);
	}
}
contract TimeVaultIndicator {
	bool public isTimeVault = true;
}

contract UpgradeAgent {
	uint public originalSupply;
	function isUpgradeAgent() public pure returns (bool) {
		return true;
	}
	function upgradeFrom(address _from, uint256 _value) public; 
	function vaultUpgradeFrom(address _from, uint256 _value) public; 
}
contract UpgradeableToken is StandardTokenExt {
	UpgradeAgent public upgradeAgent;
	uint256 public totalUpgraded;
	enum UpgradeState { Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading }
	event Upgrade(address indexed _from, address indexed _to, uint256 _value);
	event VaultUpgrade(address indexed _from, address indexed _to, uint256 _value);
	event UpgradeAgentSet(address agent);
	
	function _upgrade(uint256 value) internal {
		UpgradeState state = getUpgradeState();
		if (!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
			revert();
		}
		if (value == 0) revert();
		balances[msg.sender] = balances[msg.sender].sub(value);
		totalSupply_ = totalSupply_.sub(value);
		totalUpgraded = totalUpgraded.add(value);
	}
	function upgrade(uint256 value) public {
		_upgrade(value);
		upgradeAgent.upgradeFrom(msg.sender, value);
		emit Upgrade(msg.sender, upgradeAgent, value);
	}
	function vaultUpgrade(uint256 value) public {
		if(!TimeVaultIndicator(msg.sender).isTimeVault()) revert();
		_upgrade(value);
		upgradeAgent.vaultUpgradeFrom(msg.sender, value);
		emit VaultUpgrade(msg.sender, upgradeAgent, value);
	}
	function setUpgradeAgent(address agent) onlyOwner external {
		if (!canUpgrade()) {
			revert();
		}
		if (agent == 0x0) revert();
		if (getUpgradeState() == UpgradeState.Upgrading) revert();
		upgradeAgent = UpgradeAgent(agent);
		if (!upgradeAgent.isUpgradeAgent()) revert();
		if (upgradeAgent.originalSupply() != totalSupply_) revert();
		emit UpgradeAgentSet(upgradeAgent);
	}
	function getUpgradeState() public constant returns(UpgradeState) {
		if (!canUpgrade()) return UpgradeState.NotAllowed;
		else if (address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
		else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
		else return UpgradeState.Upgrading;
	}
	function canUpgrade() public view returns(bool) { 
		return true;
	}
}
contract CrowdsaleToken is ReleasableToken, UpgradeableToken {
	event UpdatedTokenInformation(string newName, string newSymbol);
	constructor(string _name, string _symbol, uint _initialSupply, uint8 _decimals)
	public {
		owner = msg.sender;
		name = _name;
		symbol = _symbol;
		totalSupply_ = _initialSupply;
		decimals = _decimals;
		balances[owner] = totalSupply_;
		if (totalSupply_ > 0) {
			emit Mint(owner, totalSupply_);
		}
	}
	function releaseTokenTransfer() public onlyReleaseAgent {
		mintingFinished = true;
		super.releaseTokenTransfer();
	}
	function canUpgrade() public view returns(bool) {
		return released && super.canUpgrade();
	}
	function setTokenInformation(string _name, string _symbol) public onlyOwner {
		name = _name;
		symbol = _symbol;
		emit UpdatedTokenInformation(name, symbol);
	}
}

contract TimeVault is TimeVaultIndicator {
	UpgradeableToken public token;
	address public teamMultisig;
	uint256 public unlockedAt;
	event Unlocked();
	constructor(address _teamMultisig, UpgradeableToken _token, uint256 _unlockedAt) public {
		teamMultisig = _teamMultisig;
		token = _token;
		unlockedAt = _unlockedAt;
		if (teamMultisig == 0x0) revert();
		if (address(token) == 0x0) revert();
	}
	function getTokenBalance() public constant returns (uint) {
		return token.balanceOf(address(this));
	}
	function unlock() public {
		if (now < unlockedAt) revert();
		token.transfer(teamMultisig, getTokenBalance());
		emit Unlocked();
	}
	function upgrade() public {
		token.vaultUpgrade(getTokenBalance());
	}
	function () public { revert(); }
}

