// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";


contract WordGameFactoryAccess is AccessControl{
    bytes32 public constant ORACLE_ROLE = keccak256("PROVIDER_ROLE");
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");
    bytes32 public constant GAME_OWNER_ROLE = keccak256("GAME_OWNER_ROLE");

    
    bool private _restrictCallers;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // make the deployer admin
        _restrictCallers = true;
    }

    function _isOracle(address account) internal view returns(bool){
        return hasRole(ORACLE_ROLE, account);
    }

    function _isGame(address account) internal view returns(bool){
        return hasRole(GAME_ROLE, account);
    }

    function _isAdmin(address account) internal view returns(bool){
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }
    
    function _isGameOwner(address account) internal view returns(bool){
        return hasRole(GAME_OWNER_ROLE, account);
    }

    function _grantGame(address account) internal {
        _grantRole(GAME_ROLE, account);
    }
    
    function _grantOracle(address account) internal{
        _grantRole(ORACLE_ROLE, account);
    }

    modifier onlyAdmin(address account){
        require(_isAdmin(account), "NOT_ADMIN");
        _;
    }

    modifier onlyOracle(address account){
        require(_isOracle(account), "NOT_ORACLE");
        _;
    }

    modifier onlyGame(address account){
        require(_isGame(account), "NOT_GAME");
        _;
    }
    

}
