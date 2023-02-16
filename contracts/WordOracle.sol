// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./WordOracleAccess.sol";
import "./WordFactory.sol";

interface IWordOracle{
    function addProvider(address provider) external;
    function removeProvider(address provider) external;
    function setProvidersThreshold(uint threshold) external;
    function isValidProvider(address account) external view returns(bool);
    function isValidRequestId(uint requestId) external view returns(bool);
    function addOracleCaller(address caller) external;
    function removeOracleCaller(address caller) external;
    function requestValidation(uint256 requestId) external returns (bool);
    function addProviderVote(uint256 requestId, bool validationResult, uint wordId) external;
}

contract WordOracle is IWordOracle, WordOracleAccess {

    uint public numProviders = 0;
    uint public providersThreshold = 1;

    mapping(uint256=>bool) private pendingRequests;
    mapping(uint256=>address) private pendingAddress;

    mapping(uint256=>ProviderVote[]) private providersVotes;

    struct ProviderVote {
        address providerAddress;
        address callerAddress;
        bool validationResult;
        uint wordId;
    }

    struct ProvidersConsensus{
        uint wordSelected;
        bool isEstablished;
    }

    // Events
    event ValidationRequested(address callerAddress, uint requestId);
    event ValidationReturned(uint requestId, address returnerAddress, bool isChallengeValid, uint wordId);
    event ProviderAdded(address providerAddress);
    event ProviderRemoved(address providerAddress);
    event ProvidersThresholdChanged(uint threshold);

    constructor() {

    }

    modifier addProviderCheck(address account){
        require(_isAdmin(msg.sender), "NOT_ADMIN");
        require(!_isProvider(account), "ALREADY_PROVIDER");
        _;
    }

    function addProvider(address account) external override addProviderCheck(account){
         _grantProvider(account);
        numProviders++;
        emit ProviderAdded(account);
    }

    modifier removeProviderCheck(address account){
        require(_isAdmin(msg.sender), "NOT_ADMIN");
        require(!_isProvider(account), "NOT_PROVIDER");
        require (numProviders > 1, "LAST_PROVIDER");
        _;
    }

    function removeProvider(address account) external override removeProviderCheck(account) {      
        _revokeProvider(account);
        numProviders--;
        emit ProviderRemoved(account);
    }

    function isValidProvider(address account) external view override returns(bool){
        return _isProvider(account);
    }

    modifier setProvidersThresholdCheck(uint threshold){
        require(_isAdmin(msg.sender), "NOT_ADMIN");
        require(threshold > 0, "INVALID_THRESHOLD");
        _;
    }

    function setProvidersThreshold(uint threshold) external override setProvidersThresholdCheck(threshold) { 
        providersThreshold = threshold;
        emit ProvidersThresholdChanged(providersThreshold);
    }

    modifier addProviderVoteCheck(uint id){
        require(_isProvider(msg.sender), "NOT_PROVIDER");
        require(pendingRequests[id], "REQUEST_NOT_FOUND");
        _;
    }

    modifier requestValidationCheck(address caller){
        require(_callerApprove(caller), "INVALID_CALLER");
        _;
    }

    modifier removeOracleCallerCheck(address account){
        require(_isAdmin(msg.sender), "NOT_ADMIN");
        require(_isCaller(account), "NOT_CALLER");
        _;
    }

    function removeOracleCaller(address account) external override removeOracleCallerCheck(account){
        _revokeCaller(account);
    }

    modifier addOracleCallerCheck(address account){
        require(_isAdmin(msg.sender), "NOT_ADMIN");
        require(!_isCaller(account), "ALREADY_CALLER");
        _;
    }

    function addOracleCaller(address account) external override addOracleCallerCheck(account){
        _grantCaller(account);
    }

    function isValidRequestId(uint requestId) external view override returns(bool){
        return !pendingRequests[requestId]; 
    }

    function requestValidation(uint256 requestId) external override requestValidationCheck(msg.sender) returns(bool){
        if(pendingRequests[requestId]){
            return false;
        }
        pendingRequests[requestId] = true;
        pendingAddress[requestId] = msg.sender;
        emit ValidationRequested(msg.sender, requestId);
        return true;
    }

    function _endValidateChallenge(address callerAddress, bool validationResult, uint wordId, uint requestId) private {
         // Clean up
        delete pendingRequests[requestId];
        delete pendingAddress[requestId];

        emit ValidationReturned(requestId, callerAddress, validationResult, wordId);       

        // Fulfill request
        IWordFactory(callerAddress).fulfillRequest(requestId, wordId, validationResult);
    }

    function addProviderVote(uint256 requestId, bool validationResult, uint wordId) external override addProviderVoteCheck(requestId){
        address provider = msg.sender;
        address callerAddress = pendingAddress[requestId];
    
        // Add newest vote to list
        ProviderVote memory vote = ProviderVote(provider, callerAddress, validationResult, wordId);
        providersVotes[requestId].push(vote);

        // Check if we've received enough responses
        if(providersThreshold > providersVotes[requestId].length){
            return;
        }
        
        if((providersThreshold == 1)&&(numProviders == 1)){
            //No concensus needed
            _endValidateChallenge(callerAddress, validationResult, wordId, requestId);
        }

        ProviderVote[] memory votesReceived = providersVotes[requestId];
        uint qntVotes = votesReceived.length;
        uint qntApproved = 0;
        
        // Loop through the array and combine responses
        for (uint i=0; i < qntVotes; i++) {
            if(votesReceived[i].validationResult == true){
                qntApproved++;
            }
        }
        
        bool approvedResult = qntApproved > (qntVotes/2);
        if(!approvedResult){
            _endValidateChallenge(callerAddress, validationResult, 0, requestId);
            return;
        }
        
        ProvidersConsensus memory pullCosensus = _getWordConsensus(votesReceived);

        if(!pullCosensus.isEstablished){
            return;
        }
        
        _endValidateChallenge(callerAddress, approvedResult, pullCosensus.wordSelected, requestId);
    }

    function _getWordConsensus(ProviderVote[] memory votes) private pure returns(ProvidersConsensus memory consensus) {
        uint[] memory wordIds;
        uint[] memory wordIdFrequencies;
        uint maxFrequency = 0;
        uint maxFrequencyIndex = 0;

        for(uint i = 0; i < votes.length; i++){
            if(votes[i].validationResult != true){
                continue;
            }
            bool foundWordId = false;
            for (uint j = 0; j < wordIds.length; j++){
                if(votes[i].wordId == wordIds[j]){
                    foundWordId = true;
                    wordIdFrequencies[j]++;
                    if(wordIdFrequencies[j] > maxFrequency){
                        maxFrequency = wordIdFrequencies[j];
                        maxFrequencyIndex = j;
                    }
                    break;
                }
            }
            if(!foundWordId){
                uint arraySize = wordIds.length;
                wordIds[arraySize] = votes[i].wordId;
                wordIdFrequencies[arraySize] = 1;
                if(maxFrequency == 0){
                    maxFrequency = 1;
                    maxFrequencyIndex = arraySize;
                }
            }
        }

        //No votes found
        if(maxFrequency == 0){
            consensus.isEstablished = false;
            consensus.wordSelected = 0;
            return consensus;
        }

        for(uint i = 0; i < wordIds.length; i++){
            if(wordIdFrequencies[i] == maxFrequency){
                if(i != maxFrequencyIndex){
                    consensus.isEstablished = false;
                    consensus.wordSelected = 0;
                    return consensus;
                }
            }
        }
        consensus.isEstablished == true;
        consensus.wordSelected = votes[maxFrequencyIndex].wordId;
        return consensus;
    }
}
