// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IWordToken {
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function setFactory(address newFactory) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract WordToken is IWordToken{

    uint8 public constant decimals = 18;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    address public owner;
    address public factory;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
    }
    
    modifier mintChecker(address account){
        require(factory != address(0), "NO_FACTORY");
        require(factory == msg.sender, "ONLY_FACTORY");
        require(account != address(0), "INVALID_ADDRESS");
        _;
    }

    modifier burnChecker(address account, uint256 amount){
        require(factory != address(0), "NO_FACTORY");
        require(factory == msg.sender, "ONLY_FACTORY");
        require(account != address(0), "INVALID_ADDRESS");
        require( _balances[account] >= amount, "LACKS_BALANCE");
        _;
    }

    function mint(address account, uint256 amount) external override mintChecker(account){
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) external override burnChecker(account, amount){
        _burn(account, amount);
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }
    function setFactory(address newFactory) external override onlyOwner(){
        factory = newFactory;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    modifier transferCheck(address from, address to, uint256 amount){
        require(from != address(0), "ZERO_ADDRESS_FROM");
        require(to != address(0), "ZERO_ADDRESS_TO");
        require( _balances[from] >= amount, "AMOUNT_EXEEDS_BALANCE");
        _;
    }

    function transfer(address to, uint256 amount) external override transferCheck(msg.sender, to, amount) returns (bool){
        _transfer(msg.sender, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERROR: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERROR: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}
