// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordGame.sol";
import "./WordToken.sol";
import "./WordOracle.sol";
import "./WordFactoryAccess.sol";

interface IWordGameFactory {
    function newGame(uint8[64] calldata secret) external payable returns(address);
    function charge(address user, uint256 amount) external;
    function reward(address user, uint256 amount) external;
    function getTokens(uint256 amount) external payable  returns(bool);
    function isChildGame(address game) external view returns(bool);
    function fulfillRequest(uint256 requestId, uint wordId, bool validationResult) external;
    function requestValidation(uint256 requestId) external;
}

contract WordGameFactory is IWordGameFactory, WordGameFactoryAccess{

    // Payable address can receive Ether
    address payable public owner;
    address public oracle;
    address public token;
    address[] private _games;
    uint256 public gamesCounter;
    uint256 public newGameCost = 100;
    mapping(uint256 => address) private _validationRequest;

    event NewGame(address game, address owner);

    // Payable constructor can receive Ether
    constructor(address _oracle, address _token) payable {
        owner = payable(msg.sender);
        oracle = _oracle;
        token = _token;
        _grantOracle(oracle);
    }

    modifier rewardCheck(address user){
        require(_isGame(msg.sender), "NOT_AUTHORIZED");
        require(user != address(0), "INVALID_ADDRESS");
        _;
    }

    function reward(address user, uint256 amount) external override rewardCheck(user) {
        IWordToken(token).mint(user, amount);
    }

    modifier chargeCheck(address user, uint256 amount){
        require(_isGame(msg.sender), "NOT_AUTHORIZED");
        require(user != address(0), "INVALID_ADDRESS");
        require(IWordToken(token).balanceOf(user) >= amount, "FEW_TOKENS");
        _;
    }

    function charge(address user, uint256 amount) external override chargeCheck(user, amount) {
        IWordToken(token).burn(user, amount);
    }

    function getTokens(uint256 amount) external override payable getTokensCheck(amount) returns (bool){        
        _beforePayble();
        IWordToken(token).mint(msg.sender, amount);    
        return true;
    }

    function isChildGame(address account) external override view returns(bool){
        return _isGame(account);
    }

    function newGame(uint8[64] calldata secret) public override payable returns(address){
        _beforePayble();
        address gameOwner = msg.sender;
        IWordToken(token).burn(gameOwner, newGameCost);
        WordGame game = new WordGame(gameOwner, secret, newGameCost);
        address gameAddress = address(game);
        IWordOracle(oracle).addOracleCaller(gameAddress);
        _addNewGameAddress(gameAddress);
        emit NewGame(gameAddress, gameOwner);
        return gameAddress;
    }
    

    function _addNewGameAddress(address game) internal{
        _grantGame(game);
        _games[gamesCounter] = game;
        gamesCounter++;
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

    function fulfillRequest(uint256 requestId, uint wordId, bool validationResult) external override onlyOracle(msg.sender){
        address game = _validationRequest[requestId];
        delete _validationRequest[requestId];
        if(game != address(0)){
            _fulfillRequest(validationResult, game, wordId);
        }
    }

    modifier requestValidationCheck(address account, uint256 requestId){
        require(_isGame(account), "NOT_GAME");
        require(_validationRequest[requestId] == address(0), "INVALID_ID");
        _;
    }

    function requestValidation(uint256 requestId) external override requestValidationCheck(msg.sender, requestId){
        _validationRequest[requestId] = msg.sender;
        IWordOracle(oracle).requestValidation(requestId);
    }

    function _fulfillRequest(bool isValidGame, address game, uint wordId) internal {
        require(_isGame(game), "INVALID_GAME");
        if(!isValidGame){
            IWordGame(game).invalidateGame();
            return;
        }
        IWordGame(game).setWinningWord(wordId);
    }

    fallback() external payable {
        owner.transfer(msg.value);
    }

    receive() external payable { 
        owner.transfer(msg.value);
    }
}
