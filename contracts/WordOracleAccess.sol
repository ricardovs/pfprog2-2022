// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract WordOracleAccess {
    mapping(address=> bool) private _providers;
    mapping(address => bool) private _callers;
    address public owner;
    bool private _restrictCallers;

    constructor() {
        owner = msg.sender;
        _providers[msg.sender] = true; // make the deployer provider
        _restrictCallers = true;
    }

    function _isProvider(address account) internal view returns(bool){
        return _providers[account];
    }

    function _isCaller(address account) internal view returns(bool){
        return _callers[account];
    }

    function _isAdmin(address account) internal view returns(bool){
        return owner == account;
    }

    function _grantProvider(address account) internal {
        _providers[account] = true;
    }
    
    function _grantCaller(address account) internal{
        _callers[account] = true;
    }

    function _revokeCaller(address account) internal {
        delete _callers[account];
    }

    function _revokeProvider(address account) internal{
        delete _providers[account];
    }

    function _callerApprove(address account) internal view returns(bool){
        if(_restrictCallers){
            return _isCaller(account);
        }
        return true;
    }

    function _setCallerRestriction(bool restrictCallers) internal {
        _restrictCallers = restrictCallers;
    }

    modifier onlyProvider(address account){
        require(_isProvider(account), "NOT_PROVIDER");
        _;
    }

    modifier onlyAdmin(address account){
        require(_isAdmin(account), "NOT_ADMIN");
        _;
    }    
}
