// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordGame.sol";
import "./WordToken.sol";
import "./WordOracle.sol";
import "./WordGameFactoryAccess.sol";

interface IWordGameFactory {
    function newGame(uint8[64] calldata secret) external payable returns(address);
    function charge(address user, uint256 amount) external;
    function reward(address user, uint256 amount) external;
    function getTokens(uint256 amount) external payable  returns(bool);
    function isChildGame(address game) external view returns(bool);
    function fulfillRequest(uint256 requestId, uint wordId, bool validationResult) external;
    function requestValidation(uint256 requestId) external;
}

contract WordGameFactory is IWordGameFactory, WordToken, WordGameFactoryAccess{

    // Payable address can receive Ether
    address payable public owner;
    address public oracle;
    address[] private _games;
    uint256 public gamesCounter;
    uint256 public newGameCost = 100;
    mapping(uint256 => address) private _validationRequest;

    // Payable constructor can receive Ether
    constructor(address _oracle) payable {
        owner = payable(msg.sender);
        oracle = _oracle;
        _grantOracle(oracle);
    }

    modifier rewardCheck(address user){
        require(_isGame(msg.sender), "NOT_AUTHORIZED");
        require(user != address(0), "INVALID_ADDRESS");
        _;
    }

    function reward(address user, uint256 amount) external rewardCheck(user) {
        _mint(user, amount);
    }

    modifier chargeCheck(address user, uint256 amount){
        require(_isGame(msg.sender), "NOT_AUTHORIZED");
        require(user != address(0), "INVALID_ADDRESS");
        require(balanceOf(user) >= amount, "FEW_TOKENS");
        _;
    }

    function charge(address user, uint256 amount) external chargeCheck(user, amount) {
        _burn(user, amount);
    }

    function getTokens(uint256 amount) external override payable getTokensCheck(amount) returns (bool){        
        _beforePayble();
        _mint(msg.sender, amount);    
        return true;
    }

    function isChildGame(address account) external view returns(bool){
        return _isGame(account);
    }

    function newGame(uint8[64] calldata secret) public override payable returns(address){
        _beforePayble();
        _burn(msg.sender, newGameCost);
        WordGame game = new WordGame(msg.sender, secret, newGameCost);
        IWordOracle(oracle).addOracleCaller(address(game));
        _addNewGameAddress(address(game));
        return  address(game);
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

    function fulfillRequest(uint256 requestId, uint wordId, bool validationResult) external onlyOracle(msg.sender){
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

    function requestValidation(uint256 requestId) external requestValidationCheck(msg.sender, requestId){
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
