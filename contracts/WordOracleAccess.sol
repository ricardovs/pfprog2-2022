// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";


contract WordOracleAccess is AccessControl{
    bytes32 public constant PROVIDER_ROLE = keccak256("PROVIDER_ROLE");
    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");
    bytes32 public constant CALLER_ADMIN_ROLE = keccak256("CALLER_ADMIN_ROLE");
    bool private _restrictCallers;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // make the deployer admin
        _grantRole(PROVIDER_ROLE, msg.sender); // make the deployer provider
        _restrictCallers = true;
    }

    function _isProvider(address account) internal view returns(bool){
        return hasRole(PROVIDER_ROLE, account);
    }

    function _isCaller(address account) internal view returns(bool){
        return hasRole(CALLER_ROLE, account);
    }
    function _isCallerAdm(address account) internal view returns(bool){
        return hasRole(CALLER_ADMIN_ROLE, account);
    }

    function _isAdmin(address account) internal view returns(bool){
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function _grantProvider(address account) internal {
        _grantRole(PROVIDER_ROLE, account);
    }
    
    function _grantCaller(address account) internal{
        _grantRole(CALLER_ROLE, account);
    }

    function _grantCallerAdm(address account) internal{
        _grantRole(CALLER_ADMIN_ROLE, account);
    }

    function _callerApprove(address caller) internal view returns(bool){
        if(_restrictCallers){
            return _isCaller(caller);
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
