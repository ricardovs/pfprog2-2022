// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract WordAccess is AccessControl {

    bytes32 public constant PROVIDER_ROLE = keccak256("PROVIDER_ROLE");
    bytes32 public constant LOCAL_GAMES_ROLE = keccak256("LOCAL_GAMES_ROLE");
    bytes32 public constant GAME_OWNER_ROLE = keccak256("GAME_OWNER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // make the deployer admin
    }

    function isLocalGame() internal view returns(bool){
        return hasRole(LOCAL_GAMES_ROLE, msg.sender);
    }

    function isAdmin() internal view returns(bool){
        return hasRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    function isProvider() internal view returns(bool){
        return hasRole(PROVIDER_ROLE, msg.sender);
    }

    function isGameOwner() internal view returns(bool){
        return hasRole(GAME_OWNER_ROLE, msg.sender);
    }

}
