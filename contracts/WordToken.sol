// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./WordAccess.sol";

interface IWordToken {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function chargeGuess(address user) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract WordToken is WordAccess, IWordToken{

    uint8 public constant decimals = 18;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    uint256 public userGuessCost;
    uint256 public userNewGameCost;
    uint256 public userPremium;
    uint256 public ownerPremium;

    constructor() {
        userGuessCost = 50;
        userPremium = 50;
        ownerPremium = 50;
        ownerPremium = 100;
    }
    
    function chargeGuess(address user) external override onlyRole(LOCAL_GAMES_ROLE) returns(bool){
        _burn(user, userGuessCost);
        return true;
    }

    function chargeNewGame(address user) internal virtual returns(bool){
        _burn(user, ownerPremium);
        return true;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    modifier transferCheck ( address to, uint256 amount){
        address from = msg.sender; 
        require(from != address(0), "ERROR_ZERO_ADDRESS_FROM");
        require(to != address(0), "ERROR_ZERO_ADDRESS_TO");
        require(_balances[from] >= amount, "ERROR_AMOUNT_EXCEEDS_BALANCE");
        _;
    }

    function transfer(address to, uint256 amount) public virtual override transferCheck(to, amount) returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERROR_ZERO_ADDRESS_FROM");
        require(to != address(0), "ERROR_ZERO_ADDRESS_TO");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERROR: transfer amount exceeds balance");
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
