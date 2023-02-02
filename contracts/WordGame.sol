// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./WordFactory.sol";
import "./WordOracle.sol";

interface IWordGame{
    function newGuess(uint wordId) external ;
    function newTip(uint tipId) external;
    function setWinningWord(uint wordId) external;
    function reclaimChallenge(uint8[64] memory _key,  uint256 requestId) external;
    function invalidateGame() external;
}

contract WordGame is IWordGame {

    address public factory;
    address payable public owner;
    address public oracle;

    enum GameStatus{OPEN, CLOSE, PENDIND, USER_WON, OWNER_WON, INVALID}
    GameStatus private _status; 

    uint8[64] public secret;
    uint8[64] public key;
    bool private _isKeySetted;
    uint public lastBlockAlive;
    uint256 public premium;
    uint public winningWord;
    uint public numOfGuesses;

    mapping (address => bool) private _usersRewarded;
    mapping (address => mapping (uint => bool)) private _invalidGameRewarded;

    uint constant TIP_TIME = 2;
    uint constant GUESS_TIME = 3;
    uint constant LAST_WORD_ID = 245362;

    uint256 tipCost = 10;
    uint256 guessCost = 5;

    mapping(uint => address[]) private _guesses;
    mapping(uint => bool) private _tips;

    event OwnerTip(uint wordId);
    event UserGuess(uint wordId, address user);
    event UsersWonGame(uint wordId);
    event OwnerWonGame(uint wordId);
    event InvalidGame();
    event ClosedGame();

    // Payable constructor can receive Ether
    constructor(address _owner, uint8[64] memory _secret, uint256 _premium) payable{
        factory = msg.sender;
        owner = payable(_owner);
        secret = _secret;
        lastBlockAlive = block.number;
        premium = _premium;
        _status = GameStatus.OPEN;
        _isKeySetted = false;
    }

    modifier onlyFactory(){
        require(msg.sender == factory, "ONLY_FACTORY");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier newGuessCheck(uint wordId){
        require(_status == GameStatus.OPEN, "GAME_NOT_OPEN");
        require(block.number - lastBlockAlive <= GUESS_TIME, "GUESS_TIME_EXPIRED");
        require(wordId <= LAST_WORD_ID, "INVALID_WORD_ID");
        require(wordId > 0, "INVALID_WORD_ID");
        require(!hasUserGuessedWord(msg.sender, wordId), "ALREADY_GUESSED");
        require(_tips[wordId], "OWNER_NOT_SUBMITED");
        _;
    }

    modifier newTipCheck(uint wordId){
        require(msg.sender == owner, "ONLY_OWNER");
        require(_status == GameStatus.OPEN, "NOT_OPEN");
        require(block.number - lastBlockAlive <= TIP_TIME, "TIP_TIME_EXPIRED");
        require(_tips[wordId] == false, "TIP_ALREADY_GIVEN");
        require(wordId <= LAST_WORD_ID, "INVALID_WORD");
        require(wordId > 0, "INVALID_WORD");        
        _;
    }

    function newTip(uint wordId) external override newTipCheck(wordId) {
        _tips[wordId] = true;
        lastBlockAlive = block.number;
        emit OwnerTip(wordId);
    }

    function newGuess(uint wordId) external override newGuessCheck(wordId){
        IWordGameFactory(factory).charge(msg.sender, guessCost);
        premium += guessCost;
        _guesses[wordId].push(msg.sender);
        lastBlockAlive = block.number;
        numOfGuesses++;
        emit UserGuess(wordId, msg.sender);
    }

    modifier setWinnerCheck(){
        require(msg.sender == factory, "ONLY_FACTORY");
        require(_status != GameStatus.INVALID, "GAME_INVALID");
        _;
    }

    function setWinningWord(uint wordId) external override setWinnerCheck(){
        winningWord = wordId;
        if(wordId == 0){
             _status = GameStatus.OWNER_WON;
             emit UsersWonGame(wordId);
        }else{
            _status = GameStatus.USER_WON;
            emit OwnerWonGame(wordId);
        }
    }

    modifier closeGameCheck(){
        require(msg.sender == owner, "ONLY_OWNER");
        require(_status == GameStatus.OPEN, "NOT_OPEN");
        _;
    }

    function closedGame() external closeGameCheck(){
        _status = GameStatus.CLOSE;
        emit ClosedGame();
    }

    function invalidateGame() external override onlyFactory(){
        _status = GameStatus.INVALID;
        emit InvalidGame();
    }

    modifier reclaimCheck(){
        require(msg.sender == owner, "ONLY_OWNER");
        require(_status != GameStatus.INVALID, "INVALID_GAME");
        require(_status == GameStatus.CLOSE, "NOT_CLOSE");
        _;
    }

    function _setKey(uint8[64] memory _key) private {
        if(!_isKeySetted){
            key = _key;
            _isKeySetted = true;
        }
    }

    function reclaimChallenge(uint8[64] memory _key, uint256 requestId) external override reclaimCheck(){
        _setKey(_key);
        IWordGameFactory(factory).requestValidation(requestId);
        _status = GameStatus.PENDIND;
    }

    function hasUserGuessedWord(address user, uint wordId) public view returns(bool){
       address[] memory allUsers =  _guesses[wordId];
       for(uint i = 0; i < allUsers.length; i++){
            if(allUsers[i] == user){
                return true;
            }
       }
       return false; 
    }

    modifier onlyInvalidGame(){
        require(_status == GameStatus.INVALID, "GAME_NOT_INVALID");
        _;
    }

    function invalidGameReclaim(uint[] calldata wordIds) external onlyInvalidGame(){
        uint256 userReward = 0;
        uint256 rewardPerGuess = premium/numOfGuesses;
        for(uint i = 0; i < wordIds.length; i++){
            uint wordId = wordIds[i];
            if(_invalidGameRewarded[msg.sender][wordId]){
                continue;
            }
            address[] memory users = _guesses[wordId];
            for(uint j = 0; j < users.length; j++){
                if(users[j] == msg.sender){
                    userReward += rewardPerGuess;
                    _invalidGameRewarded[msg.sender][wordId] = true;
                    break;
                }
            }
        }
        IWordGameFactory(factory).reward(msg.sender, userReward);
    }

    modifier userReclaimCheck(){
        require(_status == GameStatus.USER_WON, "NO_USER_OWN");
        require(hasUserGuessedWord(msg.sender, winningWord), "NOT_WINNER");
        require(!_usersRewarded[msg.sender], "ALREADY_REWARDED");
        _;
    }
    
    function reclaimUserReward() external userReclaimCheck(){
        uint qntWinners = _guesses[winningWord].length;
        uint256 reward = premium/qntWinners;
        _usersRewarded[msg.sender] = true;
        IWordGameFactory(factory).reward(msg.sender, reward);
    }

    modifier ownerReclaimCheck(){
        require(_status == GameStatus.OWNER_WON, "OWNER_NOT_WON");
        require(msg.sender == owner, "ONLY_OWNER");
        require(!_usersRewarded[msg.sender], "ALREADY_REWARDED");
        _;
    }
    
    function reclaimOwnerReward() external ownerReclaimCheck(){
        _usersRewarded[msg.sender] = true;
        IWordGameFactory(factory).reward(msg.sender, premium);
    }

    fallback() external payable {
        owner.transfer(msg.value);
    }

    receive() external payable { 
        owner.transfer(msg.value);
    }

}
