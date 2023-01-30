// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordGame.sol";
import "./WordOracle.sol";
import "./WordToken.sol";

contract WordFactory is WordToken, WordOracle{

    // Payable address can receive Ether
    address payable public owner;
    uint256 public gamesCounter;

    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
        gamesCounter = 0;
    }

    function newGame(uint8[64] calldata secret) public payable returns(address){
        _beforePayble();
        chargeNewGame(msg.sender);
        WordGame game = new WordGame(msg.sender, secret);
        gamesCounter++;
        _addGameAddress(address(game));
        return address(game);
    }

    function _addGameAddress(address game) internal{
        _grantRole(LOCAL_GAMES_ROLE, game);
    }

    function getTokens(uint256 amount) external payable getTokensCheck(amount) returns (bool){        
        _beforePayble();
        _mint(msg.sender, amount);    
        return true;
    }

    function isChildGame(address game) external view returns(bool){
        return hasRole(LOCAL_GAMES_ROLE, game);
    }
    
    function _beforePayble() internal virtual {
        if(msg.value > 0){
            owner.transfer(msg.value);
        }
    }

    modifier getTokensCheck(uint256 amount){
        uint256 MAX_AMOUNT = 1000*msg.value;
        require(amount <= MAX_AMOUNT, "PAYMENT_TOO_LOW");
        _;
    }

    fallback() external payable {
        owner.transfer(msg.value);
    }

    receive() external payable { 
        owner.transfer(msg.value);
    }
}
