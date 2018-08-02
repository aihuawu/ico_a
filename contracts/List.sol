
pragma solidity ^ 0.4.23;

import "./ERC20.sol";
import "./Util.sol";
import "./StandardToken.sol";
import "./Ownable.sol";
import "./Vault.sol";
import "./CrowdsaleToken.sol";
import "./Crowdsale.sol";




library CommonUtil {
	using SafeMath for uint256;

	struct IndexRef {
		uint256 index;
	}

}


// mlist<address>
library mlist_address { // memory list
	
	struct t {
		address[] ls;
		uint256 len;
		uint256 capacity;
	}

	function size(t memory _this)
	internal
	pure
	returns(uint256)
	{
		return _this.ls.length;
	}

	function at(t memory _this, uint256 idx)
	internal
	pure
	returns(address)
	{
		return _this.ls[idx];
	}

	function add(t memory _this, address val)
	internal
	pure
	{
		ensureCapacity(_this);
		_this.ls[_this.len++] = val;
	}

	function clear(t memory _this)
	internal
	pure
	{
		_this.len = 0;
		_this.capacity = 0;
		delete _this.ls;
	}

	function ensureCapacity(t memory _this)
	private
	pure
	{
		uint256 len = _this.len;
		uint256 capacity = _this.capacity;
		if(!(len < capacity)) {
			capacity = capacity*3/2+8;
			address[] memory ls = _this.ls;
			address[] memory ls2 = new address[](capacity);
			for(uint256 i = 0; i < len; i++) {
				ls2[i] = ls[i];
			}
			_this.ls = ls2;
			_this.capacity = capacity;
			delete ls;
		}
	}
}

library mlist_uint256 { // memory list
	
	struct t {
		uint256[] ls;
		uint256 len;
		uint256 capacity;
	}

	function size(t memory _this)
	internal
	pure
	returns(uint256)
	{
		return _this.ls.length;
	}

	function at(t memory _this, uint256 idx)
	internal
	pure
	returns(uint256)
	{
		return _this.ls[idx];
	}

	function add(t memory _this, uint256 val)
	internal
	pure
	{
		ensureCapacity(_this);
		_this.ls[_this.len++] = val;
	}

	function clear(t memory _this)
	internal
	pure
	{
		_this.len = 0;
		_this.capacity = 0;
		delete _this.ls;
	}

	function ensureCapacity(t memory _this)
	private
	pure
	{
		uint256 len = _this.len;
		uint256 capacity = _this.capacity;
		if(!(len < capacity)) {
			capacity = capacity*3/2+8;
			uint256[] memory ls = _this.ls;
			uint256[] memory ls2 = new uint256[](capacity);
			for(uint256 i = 0; i < len; i++) {
				ls2[i] = ls[i];
			}
			_this.ls = ls2;
			_this.capacity = capacity;
			delete ls;
		}
	}
}

library mlist_keyvalue { // memory list
	
	struct keyvalue {
		uint256 key;
		uint256 value;
	}
	struct t {
		keyvalue[] ls;
		uint256 len;
		uint256 capacity;
	}

	function size(t memory _this)
	internal
	pure
	returns(uint256)
	{
		return _this.ls.length;
	}

	function at(t memory _this, uint256 idx)
	internal
	pure
	returns(keyvalue)
	{
		return _this.ls[idx];
	}

	function add(t memory _this, keyvalue memory val)
	internal
	pure
	{
		ensureCapacity(_this);
		_this.ls[_this.len++] = val;
	}

	function clear(t memory _this)
	internal
	pure
	{
		_this.len = 0;
		_this.capacity = 0;
		delete _this.ls;
	}

	function ensureCapacity(t memory _this)
	private
	pure
	{
		uint256 len = _this.len;
		uint256 capacity = _this.capacity;
		if(!(len < capacity)) {
			capacity = capacity*3/2+8;
			keyvalue[] memory ls = _this.ls;
			keyvalue[] memory ls2 = new keyvalue[](capacity);
			for(uint256 i = 0; i < len; i++) {
				ls2[i] = ls[i];
			}
			_this.ls = ls2;
			_this.capacity = capacity;
			delete ls;
		}
	}
}


// list<address>
library list_address { // an enumerable set, can delete
// https://www.pivotaltracker.com/n/projects/1189488/stories/89907258
// https://bitcoinsaltcoins.com/library-driven-development-in-solidity-aragon-medium/
// https://github.com/aragon/zeppelin-solidity/blob/master/contracts/token/ERC20Lib.sol

	struct t {
		mapping(address => CommonUtil.IndexRef) dic; /* key is user address, value is index for ls */
		address[] ls;
	}

	function size(t storage _this)
	internal
	view
	returns(uint256)
	{
		return _this.ls.length;
	}

	function at(t storage _this, uint256 idx)
	internal
	view
	returns(address)
	{
		return _this.ls[idx];
	}

	function exists(t storage _this, address val)
	internal view returns(bool)
	{
		uint256 idx = _this.dic[val].index;
		return (idx < _this.ls.length && _this.ls[idx] == val);
	}

	/** check not exists before add */
	function add(t storage _this, address val)
	internal
	{
		_this.dic[val].index = _this.ls.length;
		_this.ls.push(val);
	}

	function safeAdd(t storage _this, address val)
	internal
	{
		if (!exists(_this, val)) {
			add(_this.ls, val, _this.dic[val]);
		}
	}

	/** check exists before remove */
	function remove(t storage _this, address val)
	internal
	{
		uint256 last = _this.ls.length-1;
		address lastVal = _this.ls[last];
		remove(_this.ls, _this.dic[val], _this.dic[lastVal]);
	}

	function safeRemove(t storage _this, address val)
	internal
	{
		if (exists(_this, val)) {
			remove(_this, val);
		}
	}

	/////////////////////////////////////////////////
	function add(address[] storage ls, address val, CommonUtil.IndexRef storage index)
	private
	{
		index.index = ls.length;
		ls.push(val);
	}

	// solium-disable-next-line indentation
	function remove(address[] storage ls,
		CommonUtil.IndexRef storage current, CommonUtil.IndexRef storage last)
	private
	{
		// make sure: it works if order is last entry 
		ls[current.index] = ls[last.index];
		ls[last.index] = 0;	// orderId > 0
		ls.length--;
		last.index = current.index;
	}

	// solium-disable-next-line indentation
	function swap(address[] storage ls,
		CommonUtil.IndexRef storage a, CommonUtil.IndexRef storage b)
	private
	{
		address v = ls[a.index];
		uint256 i = a.index;
		ls[a.index] = ls[b.index];
		ls[b.index] = v;
		a.index = b.index;
		b.index = i;
	}

}

// list<uint256>
library list_uint256 { // an enumerable set

	struct t {
		mapping(uint256 => CommonUtil.IndexRef) dic; /* key is user uint256, value is index for ls */
		uint256[] ls;
	}

	function size(t storage _this)
	internal
	view
	returns(uint256)
	{
		return _this.ls.length;
	}

	function at(t storage _this, uint256 idx)
	internal
	view
	returns(uint256)
	{
		return _this.ls[idx];
	}

	function exists(t storage _this, uint256 val)
	internal view returns(bool)
	{
		uint256 idx = _this.dic[val].index;
		return (idx < _this.ls.length && _this.ls[idx] == val);
	}

	/** check not exists before add */
	function add(t storage _this, uint256 val)
	internal
	{
		_this.dic[val].index = _this.ls.length;
		_this.ls.push(val);
	}

	function safeAdd(t storage _this, uint256 val)
	internal
	{
		if (!exists(_this, val)) {
			add(_this.ls, val, _this.dic[val]);
		}
	}

	/** check exists before remove */
	function remove(t storage _this, uint256 val)
	internal
	{
		uint256 last = _this.ls.length-1;
		uint256 lastVal = _this.ls[last];
		remove(_this.ls, _this.dic[val], _this.dic[lastVal]);
	}

	function safeRemove(t storage _this, uint256 val)
	internal
	{
		if (exists(_this, val)) {
			remove(_this, val);
		}
	}

	/////////////////////////////////////////////////
	function add(uint256[] storage ls, uint256 val, CommonUtil.IndexRef storage index)
	private
	{
		index.index = ls.length;
		ls.push(val);
	}

	// solium-disable-next-line indentation
	function remove(uint256[] storage ls,
		CommonUtil.IndexRef storage current, CommonUtil.IndexRef storage last)
	private
	{
		// make sure: it works if order is last entry 
		ls[current.index] = ls[last.index];
		ls[last.index] = 0;	// orderId > 0
		ls.length--;
		last.index = current.index;
	}

	// solium-disable-next-line indentation
	function swap(uint256[] storage ls,
		CommonUtil.IndexRef storage a, CommonUtil.IndexRef storage b)
	private
	{
		uint256 v = ls[a.index];
		uint256 i = a.index;
		ls[a.index] = ls[b.index];
		ls[b.index] = v;
		a.index = b.index;
		b.index = i;
	}

}


// one_many<address,uint256>
library one_many_address_uint256 {
	using list_uint256 for list_uint256.t;
	struct t {
		mapping(address => list_uint256.t) dic_ls;
		mapping(uint256 => address) dic;
	}

	function exists(t storage _this, address key, uint256 val)
	internal
	view
	returns(bool)
	{
		return _this.dic_ls[key].exists(val);
	}

	function oneFor(t storage _this, uint256 val)
	internal
	view
	returns(address)
	{
		return _this.dic[val];
	}

	function listAt(t storage _this, address key)
	internal
	view
	returns(list_uint256.t storage)
	{
		return _this.dic_ls[key];
	}

	function add(t storage _this, address key, uint256 val)
	internal
	{
		_this.dic_ls[key].add(val);
		_this.dic[val] = key;
	}

	function safeAdd(t storage _this, address key, uint256 val)
	internal
	{
		if(!_this.dic_ls[key].exists(val)) {
			_this.dic_ls[key].add(val);
			_this.dic[val] = key;
		}
	}

	function remove(t storage _this, address key, uint256 val)
	internal
	{
		_this.dic_ls[key].remove(val);
		delete _this.dic[val];
	}
	function safeRemove(t storage _this, address key, uint256 val)
	internal
	{
		if(_this.dic_ls[key].exists(val)) {
			_this.dic_ls[key].remove(val);
			delete _this.dic[val];
		}
	}
}

// one_many<uint256,uint256>
library one_many_uint256_uint256 {
	using list_uint256 for list_uint256.t;
	struct t {
		mapping(uint256 => list_uint256.t) dic_ls;
		mapping(uint256 => uint256) dic;
	}

	function exists(t storage _this, uint256 key, uint256 val)
	internal
	view
	returns(bool)
	{
		return _this.dic_ls[key].exists(val);
	}

	function oneFor(t storage _this, uint256 val)
	internal
	view
	returns(uint256)
	{
		return _this.dic[val];
	}

	function listAt(t storage _this, uint256 key)
	internal
	view
	returns(list_uint256.t storage)
	{
		return _this.dic_ls[key];
	}

	function add(t storage _this, uint256 key, uint256 val)
	internal
	{
		_this.dic_ls[key].add(val);
		_this.dic[val] = key;
	}

	function safeAdd(t storage _this, uint256 key, uint256 val)
	internal
	{
		if(!_this.dic_ls[key].exists(val)) {
			_this.dic_ls[key].add(val);
			_this.dic[val] = key;
		}
	}

	function remove(t storage _this, uint256 key, uint256 val)
	internal
	{
		_this.dic_ls[key].remove(val);
		delete _this.dic[val];
	}
	function safeRemove(t storage _this, uint256 key, uint256 val)
	internal
	{
		if(_this.dic_ls[key].exists(val)) {
			_this.dic_ls[key].remove(val);
			delete _this.dic[val];
		}
	}
}

