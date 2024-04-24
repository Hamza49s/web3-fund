// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./MetadataURI.sol";

contract TestingContract is ERC1155PausableUpgradeable, UUPSUpgradeable {
    using TransferHelper for IERC20;
    using MetadataURI for string;

    //     State Varibles      //
   
    address public burnAddress;
    address public owner;
    address payable public fundsWallet;
    address public mintingTokenAddress;
    uint256 private _idCounter;
    string public name;
    string public symbol;
    string public baseURI;
    enum Phase {
        Whitelist,
        Public
    }
    Phase private currentPhase;
    //     Mapping      //
    mapping(uint256 => uint) public mintPrice;
    mapping(uint256 => MintingPeriod) public mintingPeriods;
    mapping(uint256 => address) private nftOwners;
    // mapping(uint256 => uint) public royaltyPercentageByID;
    mapping(uint256 => mapping(address => bool)) private whitelistByID;
    mapping(uint256 => mapping(address => bool)) private blacklistByID;

    //    Struct     //
    struct MintingPeriod {
        uint256 startDate;
        uint256 endDate;
        uint256 supply;
    }
    //    Events     //
    event NFTCreated(
        uint indexed newNFTiD,
        uint supply,
        uint price,
        uint startMintDate
    );
    event NFTAdded(uint indexed id);
    event RoyaltiesPaid(
        uint indexed id,
        address indexed recipient,
        uint amount
    );
    event FundsWalletUpdated(address indexed newFundsWallet);
    event TokensWithdrawn(
        address indexed tokenAddress,
        address indexed recipient,
        uint amount
    );
    // event RoyaltyPercentageUpdated(uint newRoyaltyPercentage);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event PhaseChanged(Phase newPhase);
    event MintingTokenAddressUpdated(address indexed newTokenAddress);
    event AddressAddedToWhitelist(uint indexed id, address indexed account);
    event AddressRemovedFromWhitelist(uint indexed id, address indexed account);
    event AddressAddedToBlacklist(uint indexed id, address indexed account);
    event AddressRemovedFromBlacklist(
        uint256 indexed id,
        address indexed account
    );
    event TokensTransferred(
        address from,
        address to,
        uint tokenId,
        uint amount
    );
    event Burned(uint indexed id, uint amount, address indexed burner);

    function initialize() public initializer {
        // ERC1155PausableUpgradeable.
        __ERC1155Pausable_init();
        // UUPSUpgradeable.
        __UUPSUpgradeable_init();
        owner = msg.sender;
        name = "TestingContract";
        symbol = "$TCW";
        currentPhase = Phase.Whitelist;
        _idCounter = 0; // Initialize the ID counter
    }

    function _authorizeUpgrade(address newimplementation) internal override onlyOwner {}

    // modifier//
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only owner can call this function");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    // main function //
    function addID(
        uint _price,
        uint _startMintDate,
        uint _endMintDate,
        uint _supply
    ) external onlyOwner {
        require(
            _startMintDate < _endMintDate,
            "End date must be after start date"
        );
        uint256 newId = _idCounter;
        _idCounter++;
        mintPrice[newId] = _price;
        mintingPeriods[newId] = MintingPeriod(
            _startMintDate,
            _endMintDate,
            _supply
        );
        emit NFTCreated(newId, _supply, _price, _startMintDate);
        emit NFTAdded(newId);
    }

    function mintWithToken(address to, uint256 id, uint amount) external {
        require(
            currentPhase == Phase.Whitelist,
            "Minting is not allowed in the current phase"
        );
        require(
            whitelistByID[id][to],
            "Address is not whitelisted for this ID"
        );
        require(!blacklistByID[id][to], "Address is blacklisted for this ID");
        require(
            block.timestamp >= mintingPeriods[id].startDate,
            "Minting not started yet"
        );
        require(
            block.timestamp <= mintingPeriods[id].endDate,
            "Minting has ended"
        );
        require(amount > 0, "Amount must be greater than 0");
        require(
            amount <= mintingPeriods[id].supply,
            "Exceeds available supply"
        );

        uint256 totalPrice = mintPrice[id] * amount;

        // IERC20 token = IERC20(mintingTokenAddress);
        TransferHelper.safeTransferFrom(
            address(mintingTokenAddress),
            msg.sender,
            fundsWallet,
            totalPrice
        ); // by Using Transfer helper libabry

        _mint(to, id, amount, "");
        mintingPeriods[id].supply -= amount;

        emit NFTCreated(id, amount, mintPrice[id], block.timestamp);
        emit NFTAdded(id);
    }

    function setMintingTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        mintingTokenAddress = _tokenAddress;
        emit MintingTokenAddressUpdated(_tokenAddress);
    }

    function switchPhase(uint _id) external onlyOwner {
        require(mintingPeriods[_id].supply > 0, "NFT ID does not exist");
        currentPhase = (currentPhase == Phase.Whitelist)
            ? Phase.Public
            : Phase.Whitelist;
        emit PhaseChanged(currentPhase);
    }

    function FundsWallet(
        address payable _newFundsWallet
    ) external onlyOwner {
        fundsWallet = _newFundsWallet;
        emit FundsWalletUpdated(_newFundsWallet);
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    // function setRoyaltyPercentage(
    //     uint _id,
    //     uint _royaltyPercentage
    // ) external onlyOwner {
    //     require(
    //         _royaltyPercentage <= 100,
    //         "Royalty percentage must be between 0 and 100"
    //     );
    //     royaltyPercentageByID[_id] = _royaltyPercentage;
    //     emit RoyaltyPercentageUpdated(_royaltyPercentage);
    // }

    function withdrawTokens(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit TokensWithdrawn(_token, owner, balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function changeOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < _idCounter, "Token ID does not exist");
        return baseURI.constructURI(tokenId);
    }

    function getCurrentPhaseWithID(
        uint _id
    ) external view returns (string memory) {
        require(mintingPeriods[_id].supply > 0, "NFT ID does not exist");
        return currentPhase == Phase.Whitelist ? "Whitelist" : "Public";
    }

    function addToWhitelist(uint id, address account) external onlyOwner {
        require(id < _idCounter, "Invalid ID");
        require(account != address(0), "Invalid account address");

        whitelistByID[id][account] = true;
        emit AddressAddedToWhitelist(id, account);
    }

    function removeFromWhitelist(uint id, address account) external onlyOwner {
        require(id < _idCounter, "Invalid ID");
        require(account != address(0), "Invalid account address");

        whitelistByID[id][account] = false;
        emit AddressRemovedFromWhitelist(id, account);
    }

    function addToBlacklist(uint id, address account) external onlyOwner {
        require(id < _idCounter, "Invalid ID");
        require(account != address(0), "Invalid account address");

        blacklistByID[id][account] = true;
        emit AddressAddedToBlacklist(id, account);
    }

    function removeFromBlacklist(uint id, address account) external onlyOwner {
        require(id < _idCounter, "Invalid ID");
        require(account != address(0), "Invalid account address");

        blacklistByID[id][account] = false;
        emit AddressRemovedFromBlacklist(id, account);
    }

    function Whitelisted(
        uint id,
        address account
    ) external view returns (bool) {
        require(id < _idCounter, "Invalid ID");
        return whitelistByID[id][account];
    }

    function Blacklisted(
        uint id,
        address account
    ) external view returns (bool) {
        require(id < _idCounter, "Invalid ID");
        return blacklistByID[id][account];
    }

    function isOwnerOf(uint256 tokenId) internal view returns (bool) {
        return nftOwners[tokenId] == msg.sender;
    }

    // Function to set the burn address (only by owner)
    function setBurnAddress(address _burnAddress) public onlyOwner {
        burnAddress = _burnAddress;
    }

    function burn(uint id, uint amount) public {
        require(
            (isOwnerOf(id) && msg.sender == nftOwners[id]) ||
                msg.sender == burnAddress,
            "Set Burn Address have no nft(id) and amount "
        );
        require(
            balanceOf(msg.sender, id) >= amount,
            "Insufficient balance to burn"
        );
        _burn(msg.sender, id, amount);
        emit Burned(id, amount, msg.sender);
    }

    // function _safeTransferFromWithRoyalty(
    //     address from,
    //     address to,
    //     uint id,
    //     uint amount,
    //     bytes memory data
    // ) internal {
    //     // Calculate total price based on amount being transferred
    //     uint256 totalPrice = mintPrice[id] * amount;

    //     // Calculate royalty amount
    //     uint256 royaltyPercentage = royaltyPercentageByID[id];
    //     uint256 royaltyAmount = (totalPrice * royaltyPercentage) / 100;

    //     // Deduct royalty from total price
    //     uint256 totalPriceAfterRoyalty = totalPrice - royaltyAmount;

    //     // Transfer tokens to funds wallet after deducting royalty
    //     IERC20 token = IERC20(mintingTokenAddress);
    //     require(
    //         token.transferFrom(from, fundsWallet, totalPriceAfterRoyalty),
    //         "Transfer failed"
    //     );

    //     // Call parent _safeTransferFrom function
    //     super._safeTransferFrom(from, to, id, amount, data);

    //     // Emit event for tokens transferred
    //     emit TokensTransferred(from, to, id, amount);

    //     // Emit event for royalties paid
    //     emit RoyaltiesPaid(id, to, royaltyAmount);
    // }
    function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
) internal override  {
    // Transfer tokens directly from 'from' to 'to'
    super._safeTransferFrom(from, to, id, amount, data);

    // Emit event for tokens transferred
    emit TokensTransferred(from, to, id, amount);
}

    function batchWhitelist(
        uint[] calldata ids,
        address[] calldata accounts
    ) external onlyOwner {
        require(ids.length > 0, "Empty IDs array");
        require(accounts.length > 0, "Empty accounts array");
        require(
            ids.length == accounts.length,
            "IDs and accounts length not match"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            address account = accounts[i];
            require(id < _idCounter, "Invalid ID");
            require(account != address(0), "Invalid account address");
            whitelistByID[id][account] = true;
            emit AddressAddedToWhitelist(id, account);
        }
    }

    function batchBlacklist(
        uint[] calldata ids,
        address[] calldata accounts
    ) external onlyOwner {
        require(ids.length > 0, "Empty IDs array");
        require(accounts.length > 0, "Empty accounts array");
        require(
            ids.length == accounts.length,
            "IDs and accounts length not match"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            address account = accounts[i];
            require(id < _idCounter, "Invalid ID");
            require(account != address(0), "Invalid account address");
            blacklistByID[id][account] = true;
            emit AddressAddedToBlacklist(id, account);
        }
    }
}
