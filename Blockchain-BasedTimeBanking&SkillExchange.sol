// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Blockchain-Based Time Banking & Skill Exchange
 * @dev A decentralized platform for trading time and skills
 */
contract Project {
    
    // Struct to represent a user profile
    struct User {
        string name;
        string[] skills;
        uint256 timeBalance; // Time credits in minutes
        bool isRegistered;
        uint256 reputation; // Reputation score (0-100)
    }
    
    // Struct to represent a service offering
    struct ServiceOffer {
        uint256 offerId;
        address provider;
        string skillCategory;
        string description;
        uint256 timeRequired; // Time in minutes
        uint256 timeCost; // Cost in time credits
        bool isActive;
        uint256 createdAt;
    }
    
    // Struct to represent a service request
    struct ServiceRequest {
        uint256 requestId;
        address requester;
        address provider;
        uint256 offerId;
        string status; // "pending", "accepted", "completed", "cancelled"
        uint256 requestedAt;
        uint256 completedAt;
    }
    
    // State variables
    mapping(address => User) public users;
    mapping(uint256 => ServiceOffer) public serviceOffers;
    mapping(uint256 => ServiceRequest) public serviceRequests;
    
    uint256 public nextOfferId = 1;
    uint256 public nextRequestId = 1;
    uint256 public constant INITIAL_TIME_CREDITS = 100; // New users get 100 minutes
    
    // Events
    event UserRegistered(address indexed user, string name);
    event ServiceOfferCreated(uint256 indexed offerId, address indexed provider, string skillCategory);
    event ServiceRequested(uint256 indexed requestId, address indexed requester, uint256 indexed offerId);
    event ServiceCompleted(uint256 indexed requestId, address indexed provider, address indexed requester, uint256 timeCredits);
    
    // Modifiers
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User must be registered");
        _;
    }
    
    modifier offerExists(uint256 _offerId) {
        require(_offerId < nextOfferId && _offerId > 0, "Service offer does not exist");
        _;
    }
    
    modifier requestExists(uint256 _requestId) {
        require(_requestId < nextRequestId && _requestId > 0, "Service request does not exist");
        _;
    }
    
    /**
     * @dev Core Function 1: Register a new user and initialize their profile
     * @param _name User's display name
     * @param _skills Array of skills the user offers
     */
    function registerUser(string memory _name, string[] memory _skills) public {
        require(!users[msg.sender].isRegistered, "User already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        users[msg.sender] = User({
            name: _name,
            skills: _skills,
            timeBalance: INITIAL_TIME_CREDITS,
            isRegistered: true,
            reputation: 50 // Start with neutral reputation
        });
        
        emit UserRegistered(msg.sender, _name);
    }
    
    /**
     * @dev Core Function 2: Create a service offer
     * @param _skillCategory Category of skill being offered
     * @param _description Detailed description of the service
     * @param _timeRequired Time required to complete the service (in minutes)
     * @param _timeCost Cost in time credits
     */
    function createServiceOffer(
        string memory _skillCategory,
        string memory _description,
        uint256 _timeRequired,
        uint256 _timeCost
    ) public onlyRegistered {
        require(bytes(_skillCategory).length > 0, "Skill category cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_timeRequired > 0, "Time required must be greater than 0");
        require(_timeCost > 0, "Time cost must be greater than 0");
        
        serviceOffers[nextOfferId] = ServiceOffer({
            offerId: nextOfferId,
            provider: msg.sender,
            skillCategory: _skillCategory,
            description: _description,
            timeRequired: _timeRequired,
            timeCost: _timeCost,
            isActive: true,
            createdAt: block.timestamp
        });
        
        emit ServiceOfferCreated(nextOfferId, msg.sender, _skillCategory);
        nextOfferId++;
    }
    
    /**
     * @dev Core Function 3: Request and complete a service exchange
     * @param _offerId ID of the service offer to request
     */
    function requestService(uint256 _offerId) public onlyRegistered offerExists(_offerId) {
        ServiceOffer storage offer = serviceOffers[_offerId];
        require(offer.isActive, "Service offer is not active");
        require(offer.provider != msg.sender, "Cannot request your own service");
        require(users[msg.sender].timeBalance >= offer.timeCost, "Insufficient time credits");
        
        serviceRequests[nextRequestId] = ServiceRequest({
            requestId: nextRequestId,
            requester: msg.sender,
            provider: offer.provider,
            offerId: _offerId,
            status: "pending",
            requestedAt: block.timestamp,
            completedAt: 0
        });
        
        emit ServiceRequested(nextRequestId, msg.sender, _offerId);
        nextRequestId++;
    }
    
    /**
     * @dev Complete a service request and transfer time credits
     * @param _requestId ID of the service request to complete
     */
    function completeService(uint256 _requestId) public requestExists(_requestId) {
        ServiceRequest storage request = serviceRequests[_requestId];
        require(request.provider == msg.sender, "Only the service provider can complete this request");
        require(keccak256(bytes(request.status)) == keccak256(bytes("pending")), "Request is not pending");
        
        ServiceOffer storage offer = serviceOffers[request.offerId];
        
        // Transfer time credits from requester to provider
        users[request.requester].timeBalance -= offer.timeCost;
        users[request.provider].timeBalance += offer.timeCost;
        
        // Update request status
        request.status = "completed";
        request.completedAt = block.timestamp;
        
        // Update reputation (simple implementation)
        if (users[request.provider].reputation < 100) {
            users[request.provider].reputation += 1;
        }
        
        emit ServiceCompleted(_requestId, request.provider, request.requester, offer.timeCost);
    }
    
    // Utility functions
    
    /**
     * @dev Get user's time balance
     * @param _user Address of the user
     * @return Time balance in minutes
     */
    function getTimeBalance(address _user) public view returns (uint256) {
        return users[_user].timeBalance;
    }
    
    /**
     * @dev Get user's reputation score
     * @param _user Address of the user
     * @return Reputation score (0-100)
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return users[_user].reputation;
    }
    
    /**
     * @dev Get service offer details
     * @param _offerId ID of the service offer
     * @return All details of the service offer
     */
    function getServiceOffer(uint256 _offerId) public view offerExists(_offerId) returns (
        address provider,
        string memory skillCategory,
        string memory description,
        uint256 timeRequired,
        uint256 timeCost,
        bool isActive
    ) {
        ServiceOffer storage offer = serviceOffers[_offerId];
        return (
            offer.provider,
            offer.skillCategory,
            offer.description,
            offer.timeRequired,
            offer.timeCost,
            offer.isActive
        );
    }
    
    /**
     * @dev Get service request details
     * @param _requestId ID of the service request
     * @return All details of the service request
     */
    function getServiceRequest(uint256 _requestId) public view requestExists(_requestId) returns (
        address requester,
        address provider,
        uint256 offerId,
        string memory status,
        uint256 requestedAt
    ) {
        ServiceRequest storage request = serviceRequests[_requestId];
        return (
            request.requester,
            request.provider,
            request.offerId,
            request.status,
            request.requestedAt
        );
    }
    
    /**
     * @dev Deactivate a service offer
     * @param _offerId ID of the service offer to deactivate
     */
    function deactivateServiceOffer(uint256 _offerId) public offerExists(_offerId) {
        require(serviceOffers[_offerId].provider == msg.sender, "Only the provider can deactivate this offer");
        serviceOffers[_offerId].isActive = false;
    }
}
