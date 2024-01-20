// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Podfi Decentralized Marketplace Smart Contract
 * @dev This contract manages the interactions between advertisers and podcast creators in a decentralized marketplace.
 * It allows advertisers to create and manage ads, and podcast creators to approve or reject ads.
 */
contract PodfiAdsMarketplace {
  ///@dev contract owner
  address public owner;
  ///@dev advertisers ID
  uint public nextAdvertiserId;
  ///@dev podcast creator ID
  uint public nextPodcastCreatorId;

  ///@notice Adstatus to track adverts statues
  enum AdStatus {
    Pending,
    Approved,
    Rejected,
    Expired
  }

  /**
   * @dev Advertiser Structure
   * @param id Advertiser ID
   * @param account Advertiser account
   * @param name Advertiser name
   * @param isVerified Boolean to check if the Advertiser is verified
   * @param ads Mapping of ADs created by the Advertiser
   */
  struct Advertiser {
    uint id;
    address account;
    string name;
    bool isVerified;
    mapping(uint => Ad) ads;
  }

  /**
   * @dev PodcastCreator Structure
   * @param id PodcastCreator ID
   * @param account Account of the Podcaster
   * @param name Name of the Podcaster
   * @param isVerified Boolean to Check if the Podcaster is verified
   * @param averageEngagement Engagement data from the Podcaster channel (Number of Engagement/Listeners)
   * @param ads Amount of ads the Podcaster currently has on the channel (active and inactive)
   */
  struct PodcastCreator {
    uint id;
    address account;
    string channelName;
    string name;
    bool isVerified;
    uint averageEngagement;
    mapping(uint => Ad) ads;
  }

  /**
   * @dev Ad Structure
   * @param id Id of the advert
   * @param advertiser Creator of the advert
   * @param
   */
  struct Ad {
    uint id;
    address advertiser;
    string content; //url to ads vids
    string tag;
    uint minimumeTargetEngagement;
    uint cost;
    AdStatus status;
    uint numberOfDays;
    bool active;
  }

  mapping(address => Advertiser) public advertisers;
  mapping(address => PodcastCreator) public podcastCreators;

  event AdCreated(uint adId, address advertiser, address podcastCreator);
  event AdStatusChanged(uint adId, AdStatus status);
  event AdPaymentReceived(uint adId);

  /**
   * @dev Modifier to check if the caller is the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Not the contract owner");
    _;
  }

  /**
   * @dev Modifier to check if the caller is a registered advertiser.
   */
  modifier onlyAdvertiser() {
    require(advertisers[msg.sender].account == msg.sender, "Not an advertiser");
    _;
  }

  /**
   * @dev Modifier to check if the caller is a registered podcast creator.
   */
  modifier onlyPodcastCreator() {
    require(podcastCreators[msg.sender].account == msg.sender, "Not a podcast creator");
    _;
  }

  /**
   * @dev Modifier to check if the caller is a verified advertiser.
   */
  modifier onlyVerifiedAdvertiser() {
    require(advertisers[msg.sender].isVerified, "Advertiser not verified");
    _;
  }

  /**
   * @dev Modifier to check if the caller is a verified podcast creator.
   */
  modifier onlyVerifiedPodcastCreator() {
    require(podcastCreators[msg.sender].isVerified, "Podcast creator not verified");
    _;
  }

  /**
   * @dev Contract constructor. Sets the owner to the deployer's address.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Registers a new advertiser in the marketplace.
   * @param name The name of the advertiser.
   */
  function registerAdvertiser(string memory name) external {
    require(advertisers[msg.sender].account != msg.sender, "Already registered as an advertiser");
    advertisers[msg.sender] = Advertiser(nextAdvertiserId, msg.sender, name, false);
    nextAdvertiserId++;
  }

  /**
   * @dev Verifies an advertiser. Only the contract owner can call this function.
   * @param advertiser The address of the advertiser to be verified.
   */
  function verifyAdvertiser(address advertiser) external onlyOwner {
    advertisers[advertiser].isVerified = true;
  }

  /**
   * @dev Registers a new podcast creator in the marketplace.
   * @param name The name of the podcast creator.
   */
  function registerPodcastCreator(string memory name) external {
    require(podcastCreators[msg.sender].account != msg.sender, "Already registered as a podcast creator");
    podcastCreators[msg.sender] = PodcastCreator(nextPodcastCreatorId, msg.sender, name, false);
    nextPodcastCreatorId++;
  }

  /**
   * @dev Verifies a podcast creator. Only the contract owner can call this function.
   * @param podcastCreator The address of the podcast creator to be verified.
   */
  function verifyPodcastCreator(address podcastCreator) external onlyOwner {
    podcastCreators[podcastCreator].isVerified = true;
  }

  /**
   * @dev Creates a new ad in the marketplace.
   * @param podcastCreator The address of the podcast creator.
   * @param content The content of the ad.
   * @param cost The cost of the ad.
   * @param durationDays The duration of the ad in days.
   */
  function createAd(
    address podcastCreator,
    string memory content,
    uint cost,
    uint durationDays
  ) external onlyAdvertiser onlyVerifiedAdvertiser {
    require(podcastCreators[podcastCreator].account == podcastCreator, "Invalid podcast creator address");

    uint expirationTimestamp = block.timestamp + durationDays * 1 days;

    Ad memory newAd = Ad({
      id: advertisers[msg.sender].ads[nextAdvertiserId].id,
      advertiser: msg.sender,
      podcastCreator: podcastCreator,
      content: content,
      cost: cost,
      status: AdStatus.Pending,
      expirationTimestamp: expirationTimestamp,
      paymentReceived: false
    });

    advertisers[msg.sender].ads[nextAdvertiserId] = newAd;
    podcastCreators[podcastCreator].ads[nextAdvertiserId] = newAd;

    nextAdvertiserId++;

    emit AdCreated(newAd.id, msg.sender, podcastCreator);
  }

  /**
   * @dev Approves an ad by a podcast creator.
   * @param adId The ID of the ad to be approved.
   */
  function approveAd(uint adId) external onlyPodcastCreator onlyVerifiedPodcastCreator {
    Ad storage ad = podcastCreators[msg.sender].ads[adId];
    require(ad.status == AdStatus.Pending, "Ad is not pending approval");

    ad.status = AdStatus.Approved;
    emit AdStatusChanged(adId, AdStatus.Approved);
  }

  /**
   * @dev Rejects an ad by a podcast creator.
   * @param adId The ID of the ad to be rejected.
   */
  function rejectAd(uint adId) external onlyPodcastCreator onlyVerifiedPodcastCreator {
    Ad storage ad = podcastCreators[msg.sender].ads[adId];
    require(ad.status == AdStatus.Pending, "Ad is not pending approval");

    ad.status = AdStatus.Rejected;
    emit AdStatusChanged(adId, AdStatus.Rejected);
  }

  /**
   * @dev Receives payment for an approved ad by a podcast creator.
   * @param adId The ID of the ad for which payment is received.
   */
  function receivePayment(uint adId) external onlyPodcastCreator onlyVerifiedPodcastCreator {
    Ad storage ad = podcastCreators[msg.sender].ads[adId];
    require(ad.status == AdStatus.Approved, "Ad is not approved");

    require(!ad.paymentReceived, "Payment already received");

    // Assuming payment mechanism external to the contract, mark payment as received
    ad.paymentReceived = true;

    emit AdPaymentReceived(adId);
  }

  /**
   * @dev Expires an approved ad by the advertiser.
   * @param adId The ID of the ad to be expired.
   */
  function expireAd(uint adId) external {
    Ad storage ad = advertisers[msg.sender].ads[adId];
    require(ad.status == AdStatus.Approved, "Ad is not approved");
    require(block.timestamp >= ad.expirationTimestamp, "Ad has not expired yet");

    ad.status = AdStatus.Expired;
    emit AdStatusChanged(adId, AdStatus.Expired);
  }
}
