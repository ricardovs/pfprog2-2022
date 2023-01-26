// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordGame.sol";

contract WordFactory{
    // Payable address can receive Ether
    address payable private _owner;
    mapping(address => uint256) private _balances;
    WordGame[] public _games;
 
    // Payable constructor can receive Ether
    constructor() payable {
        _owner = payable(msg.sender);
    }

    function newGame(bytes[128] calldata secret, uint num_of_letters) public returns(address){
        WordGame game = new WordGame(this, msg.sender, secret, num_of_letters);
        _games.push(game);
        return address(game);
    }

    function emitToken(uint256 tokens) public payable{
        _owner.transfer(msg.value);
        _balances[msg.sender] = _balances[msg.sender] + tokens;
    }

}