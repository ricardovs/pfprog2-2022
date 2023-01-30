// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordFactory.sol";

interface IWordGame{
    function makeGuess(string calldata word) external ;
    function setWordSize(uint8 size) external;
    function isStatusPending() external view returns(bool);
    function isWordGuessed(string calldata word) external view  returns(bool);
}

contract WordGame is IWordGame{

    WordFactory public factory;
    address payable public owner;

    enum GameStatus{OPEN, CLOSED, PENDIND, ENDED}
    GameStatus private _status; 
    
    uint8[64] public secret;
    uint8[64] public key;
    uint8 public word_size;
    uint256 public guess_counter;

    mapping(string => uint256) private words_taken;
    mapping(uint256 => address) private user_guessed;
    mapping(uint256 => string) private word_guessed;

    event UserGuess(uint256 id, address user);
    event ClosedGame(uint256 id);

    // Payable constructor can receive Ether
    constructor(address _owner, uint8[64] memory _secret) payable{
        factory = WordFactory(payable(msg.sender));
        owner = payable(_owner);
        secret = _secret;
        _status = GameStatus.OPEN;
        word_size = 0;        
        guess_counter = 0;
    }

    modifier onlyFactory(){
        require(msg.sender == address(factory), "ONLY_FACTORY");
        _;
    }

    modifier makeGuessCheck(string calldata word){
        require(_status == GameStatus.OPEN, "GAME_NOT_OPEN");
        require(words_taken[word] == 0, "WORD_ALREADY_TAKEN");
        _;

    }
    function makeGuess(string calldata word) external override makeGuessCheck(word){
        address user = msg.sender;
        factory.chargeGuess(user);
        guess_counter++;
        words_taken[word] = guess_counter;
        user_guessed[guess_counter] = user;
        word_guessed[guess_counter] = word;
        emit UserGuess(guess_counter, user);
    }

    function setWordSize(uint8 size) external override setWordSizeCheck(size){
        word_size = size;
    }

    function isWordGuessed(string calldata word) external view override returns(bool){
        return words_taken[word] != 0;
    }

    function isStatusPending() external override view returns(bool){
        return _status == GameStatus.PENDIND;
    }

    modifier setWordSizeCheck(uint8 size){
        require(msg.sender == owner, "NOT_AUTHORIZED");
        require(size > 1, "INVALID_WRD_SIZE");
        require(size < 50, "INVALID_WORD_SIZE");
        require(word_size == 0, "SIZE_ALREADY_SET");
        _;
    }

    fallback() external payable {
        owner.transfer(msg.value);
    }

    receive() external payable { 
        owner.transfer(msg.value);
    }

}
