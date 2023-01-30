// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./WordAccess.sol";

interface IWordOracle{
    function addProvider(address provider) external;
    function removeProvider(address provider) external;
    function setProvidersThreshold(uint threshold) external;
    function requestValidateChallenge() external returns (uint256);
    function returnValidateChallenge(bool validationResult, uint256 id) external;
}

contract WordOracle is IWordOracle, WordAccess {

    uint private numProviders = 0;
    uint private providersThreshold = 1;
    uint private generatedId = 0;

    mapping(uint256=>bool) private pendingRequests;
    mapping(uint256=>address) private pendingAddress;

    mapping(uint256=>ProviderVote[]) private providersVotes;

    struct ProviderVote {
        address providerAddress;
        address callerAddress;
        bool validationResult;
    }

    // Events
    event ValidationRequested(address callerAddress, uint id);
    event ValidationReturned(bool isChallengeValid, address returnerAddress, uint id);
    event ProviderAdded(address providerAddress);
    event ProviderRemoved(address providerAddress);
    event ProvidersThresholdChanged(uint threshold);

    constructor() {
        _grantRole(PROVIDER_ROLE, msg.sender);      // make deployer a provider
        numProviders = 1;
    }

    modifier requestValidateCheck(){
        require(isLocalGame(), "INVALID_GAME");
        require(numProviders > 0, "NO_PROVIDERS");
        generatedId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 1000;
        require(pendingRequests[generatedId] == false, "TRY_LATER");
        _;
    }

    function requestValidateChallenge() external override requestValidateCheck() returns(uint256){ 
        pendingRequests[generatedId] = true;
        pendingAddress[generatedId] = msg.sender;

        emit ValidationRequested(msg.sender, generatedId);
        return generatedId;
    }

    modifier returnValidateCheck(uint id){
        require(isProvider(), "NOT_PROVIDER");
        require(pendingRequests[id], "REQUEST_NOT_FOUND");
        _;
    }

    function returnValidateChallenge(bool validationResult, uint256 id) external override returnValidateCheck(id){
        // Add newest vote to list
        ProviderVote memory vote = ProviderVote(msg.sender, pendingAddress[id], validationResult);
        providersVotes[id].push(vote);

        // Check if we've received enough responses
        if (providersVotes[id].length >= providersThreshold) {
            uint approvedNumber = 0;
            uint  receivedAwnsers = providersVotes[id].length;

            // Loop through the array and combine responses
            for (uint i=0; i < receivedAwnsers; i++) {
                if(providersVotes[id][i].validationResult == true){
                    approvedNumber++;
                }
            }
          
            bool responseValue = approvedNumber > (receivedAwnsers/2);
            address callerAddress = pendingAddress[id];
    
            // Clean up
            delete pendingRequests[id];
            delete pendingAddress[id];

            emit ValidationReturned(responseValue, callerAddress, id);
            
            // Fulfill request
            _fulfillRequest(responseValue, callerAddress, id);
        }
    }

    // Admin functions

    modifier addProviderCheck(address provider){
        require(isAdmin(), "NOT_ADMIN");
        require(!hasRole(PROVIDER_ROLE, provider), "ALREADY_PROVIDER");
        _;
    }

    function addProvider(address provider) external override addProviderCheck(provider){
        _grantRole(PROVIDER_ROLE, provider);
        numProviders++;  
        emit ProviderAdded(provider);
    }

    modifier removeProviderCheck(address provider){
        require(isAdmin(), "NOT_ADMIN");
        require(!hasRole(PROVIDER_ROLE, provider), "NOT_PROVIDER");
        require (numProviders > 1, "Cannot remove the only provider.");
        _;
    }

    function removeProvider(address provider) external override removeProviderCheck(provider) {
        _revokeRole(PROVIDER_ROLE, provider);
        numProviders--;
        emit ProviderRemoved(provider);
    }

    modifier setProvidersThresholdCheck(uint threshold){
        require(isAdmin(), "NOT_ADMIN");
        require(threshold > 0, "INVALID_THRESHOLD");
        _;
    }

    function setProvidersThreshold(uint threshold) external override setProvidersThresholdCheck(threshold) { 
        providersThreshold = threshold;
        emit ProvidersThresholdChanged(providersThreshold);
    }
    function _fulfillRequest(bool responseValue, address game, uint request_id) internal virtual
    {} 
}
