// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IWordOracle{
    function addProvider(address provider) external;
    function removeProvider(address provider) external;
    function setProvidersThreshold(uint threshold) external;
    function requestValidation() external returns (uint256);
    function addProviderVote(uint256 requestId, bool validationResult, uint wordId) external;
}

contract WordOracle {

    uint public numProviders = 0;
    mapping (address => bool) private _providersList; 
    uint public providersThreshold = 1;
    uint private generatedId = 0;

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

    function _generateNewRequestId() internal returns(bool){
        if(pendingRequests[generatedId] == false){
            return true;
        }
        generatedId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 1000;
        return pendingRequests[generatedId] == false;
    }

    function _requestValidation(address returnAddress) internal virtual returns(uint256){ 
        pendingRequests[generatedId] = true;
        pendingAddress[generatedId] = returnAddress;

        emit ValidationRequested(returnAddress, generatedId);
        return generatedId;
    }

    function _isPendingRequest(uint requestId) internal view returns(bool){
        return pendingRequests[requestId];
    }

    function _endValidateChallenge(address callerAddress, bool validationResult, uint wordId, uint requestId) private {
         // Clean up
        delete pendingRequests[requestId];
        delete pendingAddress[requestId];

        emit ValidationReturned(requestId, callerAddress, validationResult, wordId);       

        // Fulfill request
        _fulfillRequest(validationResult, callerAddress, wordId);
    }

    function _addProviderVote(uint256 requestId, bool validationResult, uint wordId) internal virtual{
        address provider = msg.sender;
        address callerAddress = pendingAddress[requestId];
    
        // Add newest vote to list
        ProviderVote memory vote = ProviderVote(provider, callerAddress, validationResult, wordId);
        providersVotes[requestId].push(vote);

        // Check if we've received enough responses
        if(providersThreshold > providersVotes[requestId].length){
            return;
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

    function _addProvider(address provider) internal virtual {
        require(_providersList[provider] == false, "ALREADY_PROVIDER");
        _providersList[provider] = true;
        numProviders++;
        emit ProviderAdded(provider);
    }

    function _removeProvider(address provider) internal virtual {
        require(_providersList[provider], "NOT_PROVIDER");
        require (numProviders > 1, "LAST_PROVIDER");
        delete _providersList[provider];
        numProviders--;
        emit ProviderRemoved(provider);
    }

    function _isProvider(address provider) internal view returns(bool){
        return _providersList[provider];
    }

    function _setProvidersThreshold(uint threshold) internal { 
        providersThreshold = threshold;
        emit ProvidersThresholdChanged(providersThreshold);
    }

    function _fulfillRequest(bool responseValue, address game, uint wordId) internal virtual {} 
}
