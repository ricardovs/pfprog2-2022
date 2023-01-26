// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordFactory.sol";

contract WordGame {
    enum GameStatus{OPEN, CLOSED, PENDING, ENDED}

    // Payable address can receive Ether
    WordFactory public factory;
    address public owner;
    GameStatus public status;
    bytes[128] public secret;
    bytes[128] public key;
    uint public num_of_letters;

    // Payable constructor can receive Ether
    constructor(WordFactory _factory, address _owner, bytes[128] memory _secret, uint _num_of_letters) {
        factory = _factory;
        owner = _owner;
        status = GameStatus.OPEN;
        secret = _secret;
        num_of_letters = _num_of_letters;
    }
}
