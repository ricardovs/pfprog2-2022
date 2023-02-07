// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract WordFactoryAccess {
    mapping(address => bool) private _games;
    mapping(address => address) private _game_owner;
    address public oracle;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function _isOracle(address account) internal view returns(bool){
        return account == oracle;
    }

    function _isGame(address account) internal view returns(bool){
        return _games[account];
    }

    function _isAdmin(address account) internal view returns(bool){
        return account == owner;
    }
    
    function _isGameOwner(address game, address account) internal view returns(bool){
        return _game_owner[game] == account;
    }

    function _grantGame(address account) internal {
        _games[account] = true;
    }
    
    function _grantOracle(address account) internal{
        oracle = account;
    }

    function _grantGameOwner(address game, address account) internal{
        _game_owner[game] = account;
    }

    modifier onlyAdmin(address account){
        require(owner == account, "NOT_ADMIN");
        _;
    }

    modifier onlyOracle(address account){
        require(oracle == account, "NOT_ORACLE");
        _;
    }

    modifier onlyGame(address account){
        require(_games[account], "NOT_GAME");
        _;
    }

    modifier onlyGameOwner(address game, address account){
        require(_game_owner[game] == account, "NOT_GAME_OWNER");
        _;
    }

}
