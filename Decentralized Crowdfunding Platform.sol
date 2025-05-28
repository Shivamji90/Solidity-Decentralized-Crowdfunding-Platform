// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdfundingPlatform is ReentrancyGuard, Ownable {
    
    // Campaign structure
    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 raisedAmount;
        uint256 deadline;
        bool isActive;
        bool goalReached;
        bool fundsWithdrawn;
        uint256 contributorCount;
    }
    
    // Contribution structure
    struct Contribution {
        address contributor;
        uint256 amount;
        uint256 timestamp;
    }
    
    // State variables
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Contribution[]) public campaignContributions;
    mapping(uint256 => mapping(address => uint256)) public userContributions;
    
    uint256 public campaignCounter;
    uint256 public platformFeePercentage = 250; // 2.5% (250/10000)
    uint256 public constant MAX_FEE_PERCENTAGE = 1000; // 10% maximum
    
    // Events
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goalAmount,
        uint256 deadline
    );
    
    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount,
        uint256 totalRaised
    );
    
    event CampaignFunded(
        uint256 indexed campaignId,
        uint256 totalAmount
    );
    
    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount,
        uint256 platformFee
    );
    
    event RefundIssued(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    event CampaignCancelled(
        uint256 indexed campaignId,
        address indexed creator
    );
    
    // Modifiers
    modifier validCampaign(uint256 _campaignId) {
        require(_campaignId < campaignCounter, "Campaign does not exist");
        _;
    }
    
    modifier onlyCampaignCreator(uint256 _campaignId) {
        require(
            campaigns[_campaignId].creator == msg.sender,
            "Only campaign creator can perform this action"
        );
        _;
    }
    
    modifier campaignActive(uint256 _campaignId) {
        require(campaigns[_campaignId].isActive, "Campaign is not active");
        require(
            block.timestamp < campaigns[_campaignId].deadline,
            "Campaign deadline has passed"
        );
        _;
    }
    
    constructor() {}
    
    /**
     * @dev Create a new crowdfunding campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _goalAmount Funding goal in wei
     * @param _durationInDays Campaign duration in days
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationInDays
    ) external {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_goalAmount > 0, "Goal amount must be greater than 0");
        require(_durationInDays > 0 && _durationInDays <= 365, "Invalid duration");
        
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        campaigns[campaignCounter] = Campaign({
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            raisedAmount: 0,
            deadline: deadline,
            isActive: true,
            goalReached: false,
            fundsWithdrawn: false,
            contributorCount: 0
        });
        
        emit CampaignCreated(
            campaignCounter,
            msg.sender,
            _title,
            _goalAmount,
            deadline
        );
        
        campaignCounter++;
    }
    
    /**
     * @dev Contribute to a campaign
     * @param _campaignId ID of the campaign to contribute to
     */
    function contribute(uint256 _campaignId) 
        external 
        payable 
        validCampaign(_campaignId) 
        campaignActive(_campaignId) 
        nonReentrant 
    {
        require(msg.value > 0, "Contribution must be greater than 0");
        require(
            campaigns[_campaignId].creator != msg.sender,
            "Campaign creators cannot contribute to their own campaigns"
        );
        
        Campaign storage campaign = campaigns[_campaignId];
        
        // Track user contribution
        if (userContributions[_campaignId][msg.sender] == 0) {
            campaign.contributorCount++;
        }
        userContributions[_campaignId][msg.sender] += msg.value;
        
        // Add to campaign contributions array
        campaignContributions[_campaignId].push(Contribution({
            contributor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        // Update campaign
        campaign.raisedAmount += msg.value;
        
        // Check if goal is reached
        if (campaign.raisedAmount >= campaign.goalAmount && !campaign.goalReached) {
            campaign.goalReached = true;
            emit CampaignFunded(_campaignId, campaign.raisedAmount);
        }
        
        emit ContributionMade(_campaignId, msg.sender, msg.value, campaign.raisedAmount);
    }
    
    /**
     * @dev Withdraw funds from a successful campaign
     * @param _campaignId ID of the campaign
     */
    function withdrawFunds(uint256 _campaignId) 
        external 
        validCampaign(_campaignId) 
        onlyCampaignCreator(_campaignId) 
        nonReentrant 
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.goalReached, "Campaign goal not reached");
        require(!campaign.fundsWithdrawn, "Funds already withdrawn");
        require(campaign.raisedAmount > 0, "No funds to withdraw");
        
        campaign.fundsWithdrawn = true;
        campaign.isActive = false;
        
        uint256 totalAmount = campaign.raisedAmount;
        uint256 platformFee = (totalAmount * platformFeePercentage) / 10000;
        uint256 creatorAmount = totalAmount - platformFee;
        
        // Transfer funds to creator
        (bool success, ) = campaign.creator.call{value: creatorAmount}("");
        require(success, "Transfer to creator failed");
        
        // Transfer platform fee to owner (if any)
        if (platformFee > 0) {
            (bool feeSuccess, ) = owner().call{value: platformFee}("");
            require(feeSuccess, "Platform fee transfer failed");
        }
        
        emit FundsWithdrawn(_campaignId, campaign.creator, creatorAmount, platformFee);
    }
    
    /**
     * @dev Request refund from a failed campaign
     * @param _campaignId ID of the campaign
     */
    function requestRefund(uint256 _campaignId) 
        external 
        validCampaign(_campaignId) 
        nonReentrant 
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(
            block.timestamp > campaign.deadline || !campaign.isActive,
            "Campaign is still active"
        );
        require(!campaign.goalReached, "Campaign was successful, no refunds");
        require(!campaign.fundsWithdrawn, "Funds already withdrawn");
        
        uint256 contributionAmount = userContributions[_campaignId][msg.sender];
        require(contributionAmount > 0, "No contribution found");
        
        // Reset user contribution
        userContributions[_campaignId][msg.sender] = 0;
        campaign.raisedAmount -= contributionAmount;
        campaign.contributorCount--;
        
        // Transfer refund
        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        require(success, "Refund transfer failed");
        
        emit RefundIssued(_campaignId, msg.sender, contributionAmount);
    }
    
    /**
     * @dev Cancel a campaign (only creator, only if no contributions)
     * @param _campaignId ID of the campaign
     */
    function cancelCampaign(uint256 _campaignId) 
        external 
        validCampaign(_campaignId) 
        onlyCampaignCreator(_campaignId) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.isActive, "Campaign already inactive");
        require(campaign.raisedAmount == 0, "Cannot cancel campaign with contributions");
        
        campaign.isActive = false;
        
        emit CampaignCancelled(_campaignId, campaign.creator);
    }
    
    /**
     * @dev Get campaign details
     * @param _campaignId ID of the campaign
     */
    function getCampaign(uint256 _campaignId) 
        external 
        view 
        validCampaign(_campaignId) 
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 goalAmount,
            uint256 raisedAmount,
            uint256 deadline,
            bool isActive,
            bool goalReached,
            bool fundsWithdrawn,
            uint256 contributorCount
        ) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.raisedAmount,
            campaign.deadline,
            campaign.isActive,
            campaign.goalReached,
            campaign.fundsWithdrawn,
            campaign.contributorCount
        );
    }
    
    /**
     * @dev Get user's contribution to a specific campaign
     * @param _campaignId ID of the campaign
     * @param _contributor Address of the contributor
     */
    function getUserContribution(uint256 _campaignId, address _contributor) 
        external 
        view 
        validCampaign(_campaignId) 
        returns (uint256) 
    {
        return userContributions[_campaignId][_contributor];
    }
    
    /**
     * @dev Get all contributions for a campaign
     * @param _campaignId ID of the campaign
     */
    function getCampaignContributions(uint256 _campaignId) 
        external 
        view 
        validCampaign(_campaignId) 
        returns (Contribution[] memory) 
    {
        return campaignContributions[_campaignId];
    }
    
    /**
     * @dev Check if campaign deadline has passed
     * @param _campaignId ID of the campaign
     */
    function isDeadlinePassed(uint256 _campaignId) 
        external 
        view 
        validCampaign(_campaignId) 
        returns (bool) 
    {
        return block.timestamp > campaigns[_campaignId].deadline;
    }
    
    /**
     * @dev Get active campaigns count
     */
    function getActiveCampaignsCount() external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < campaignCounter; i++) {
            if (campaigns[i].isActive && block.timestamp < campaigns[i].deadline) {
                activeCount++;
            }
        }
        return activeCount;
    }
    
    /**
     * @dev Set platform fee percentage (only owner)
     * @param _feePercentage New fee percentage (in basis points, e.g., 250 = 2.5%)
     */
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= MAX_FEE_PERCENTAGE, "Fee too high");
        platformFeePercentage = _feePercentage;
    }
    
    /**
     * @dev Emergency withdraw (only owner, only for stuck funds)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Emergency withdrawal failed");
    }
    
    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Fallback functions
    receive() external payable {
        revert("Direct payments not allowed");
    }
    
    fallback() external payable {
        revert("Function not found");
    }
}
