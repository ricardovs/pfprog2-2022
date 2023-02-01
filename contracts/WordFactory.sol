// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordGame.sol";
import "./WordOracle.sol";
import "./WordToken.sol";

interface IWordFactory {
    function newGame(uint8[64] calldata secret) external payable returns(address);
    function charge(address user, uint256 amount) external;
    function reward(address user, uint256 amount) external;
    function getTokens(uint256 amount) external payable  returns(bool);
    function isChildGame(address game) external view returns(bool);
}

contract WordFactory is IWordFactory, IWordToken, WordToken, IWordOracle, WordOracle {

    // Payable address can receive Ether
    address payable public owner;
    uint256 public gamesCounter;
    uint256 public newGameCost = 100;
    
    mapping(address => bool) private _gamesList;
    mapping(address => bool) private _gamesOwners;

    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
        gamesCounter = 0;
        _addProvider(msg.sender);      // make deployer a provider
    }

     function _isAdmin() internal view returns(bool){
        return msg.sender == owner;
    }

    function _isGameOwner() internal view returns(bool){
        return _gamesOwners[msg.sender];
    }

    //------------------
    //IWordToken functions
    function totalSupply() public view virtual override returns (uint256) {
        return _getTotalSupply();
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _getBalanceOf(account);
    }

    modifier transferCheck ( address to, uint256 amount){
        require(msg.sender != address(0), "ZERO_ADDRESS");
        require(to != address(0), "ZERO_ADDRESS");
        require(_getBalanceOf(msg.sender) >= amount, "EXCEEDS_BALANCE");
        _;
    }

    function transfer(address to, uint256 amount) external virtual transferCheck(to, amount) returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    //---------------------
    //WordFactory functions

    modifier rewardCheck(address user){
        require(_isLocalGame(msg.sender), "NOT_AUTHORIZED");
        require(user != address(0), "INVALID_ADDRESS");
        _;
    }

    function reward(address user, uint256 amount) external rewardCheck(user) {
        _mint(user, amount);
    }

    modifier chargeCheck(address user, uint256 amount){
        require(_isLocalGame(msg.sender), "NOT_AUTHORIZED");
        require(user != address(0), "INVALID_ADDRESS");
        require(_getBalanceOf(user) >= amount, "FEW_TOKENS");
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

    function isChildGame(address game) external view returns(bool){
        return _gamesList[game];
    }

    function newGame(uint8[64] calldata secret) public override payable returns(address){
        _beforePayble();
        _burn(msg.sender, newGameCost);
        WordGame game = new WordGame(msg.sender, secret, newGameCost);
        _addNewGameAddress(address(game));
        return  address(game);
    }
    
    function _isLocalGame(address game) internal view returns(bool){
        return _gamesList[game];
    }

    function _addNewGameAddress(address game) internal{
        _gamesList[game] = true;
        gamesCounter++;
    }

    //IWordOracle

    modifier addProviderCheck(address provider){
        require(_isAdmin(), "NOT_ADMIN");
        require(!_isProvider(provider), "ALREADY_PROVIDER");
        _;
    }

    function addProvider(address provider) external override addProviderCheck(provider){
        _addProvider(provider);
    }


    modifier removeProviderCheck(address provider){
        require(_isAdmin(), "NOT_ADMIN");
        require(!_isProvider(provider), "NOT_PROVIDER");
        _;
    }

    function removeProvider(address provider) external override removeProviderCheck(provider) {
        _removeProvider(provider);
    }

    modifier setProvidersThresholdCheck(uint threshold){
        require(_isAdmin(), "NOT_ADMIN");
        require(threshold > 0, "INVALID_THRESHOLD");
        _;
    }

    function setProvidersThreshold(uint threshold) external override setProvidersThresholdCheck(threshold) { 
        _setProvidersThreshold(threshold);
    }

    modifier addProviderVoteCheck(uint id){
        require(_isProvider(msg.sender), "NOT_PROVIDER");
        require(_isPendingRequest(id), "REQUEST_NOT_FOUND");
        _;
    }

    function addProviderVote(uint256 requestId, bool validationResult, uint wordId) external override addProviderVoteCheck(requestId){
        _addProviderVote(requestId, validationResult, wordId);
    }

    modifier requestValidationCheck(){
        require(_isLocalGame(msg.sender), "INVALID_GAME");
        require(!_generateNewRequestId(), "TRY_LATER");
        _;
    }

    function requestValidation() external override requestValidationCheck() returns(uint256){
        return _requestValidation(msg.sender); 
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

    function _fulfillRequest(bool isValidGame, address game, uint wordId) internal override {
        require(_isLocalGame(game), "INVALID_GAME");
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
