// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ReentrancyGuard - Manual reentrancy protection
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * @title CredentialNFT
 * @dev NFT-based credential system with verified institutions and security measures
 */
contract CredentialNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 private _tokenIds;
    mapping(address => bool) public verifiedInstitutions;
    mapping(uint256 => bool) public isRevoked;

    event CredentialIssued(address indexed recipient, uint256 indexed tokenId, string metadataURI);
    event CredentialRevoked(uint256 indexed tokenId);
    event InstitutionRegistered(address indexed institution);
    event InstitutionUnregistered(address indexed institution);

    /// @notice Initializes the contract with name "CredentialNFT" and symbol "CRD"
    constructor() ERC721("CredentialNFT", "CRD") {}

    /// @notice Registers a verified institution, callable only by the owner
    /// @param institution The address of the institution to register
    function registerInstitution(address institution) external onlyOwner {
        require(institution != address(0), "Invalid institution address");
        require(!verifiedInstitutions[institution], "Institution already registered");

        verifiedInstitutions[institution] = true;
        emit InstitutionRegistered(institution);
    }

    /// @notice Unregisters an institution, callable only by the owner
    /// @param institution The address of the institution to unregister
    function unregisterInstitution(address institution) external onlyOwner {
        require(verifiedInstitutions[institution], "Institution not registered");

        verifiedInstitutions[institution] = false;
        emit InstitutionUnregistered(institution);
    }

    /// @notice Checks if a credential is valid (exists and not revoked)
    /// @param tokenId The ID of the credential to check
    /// @return True if the credential is valid, false otherwise
    function isCertificateValid(uint256 tokenId) external view returns (bool) {
        return _tokenExists(tokenId) && !isRevoked[tokenId];
    }

    /// @notice Retrieves all credential token IDs owned by a specific address
    /// @param owner The address to query credentials for
    /// @return An array of token IDs owned by the address
    function getCertificatesByOwner(address owner) external view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory ownedTokenIds = new uint256[](count);
        uint256 index = 0;

        for (uint256 i = 1; i <= _tokenIds; i++) {
            if (_tokenExists(i) && ownerOf(i) == owner) {
                ownedTokenIds[index++] = i;
            }
        }
        return ownedTokenIds;
    }

    /// @notice Issues a new credential to a recipient, callable only by verified institutions
    /// @param recipient The address receiving the credential
    /// @param metadataURI The URI pointing to the credential’s metadata
    function issueCredential(address recipient, string memory metadataURI) 
        external 
        nonReentrant 
    {
        require(verifiedInstitutions[msg.sender], "Only verified institutions can issue");
        require(recipient != address(0), "Invalid recipient address");
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");

        _tokenIds++;
        uint256 newItemId = _tokenIds;

        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);

        emit CredentialIssued(recipient, newItemId, metadataURI);
    }

    /// @notice Revokes a credential, callable only by verified institutions
    /// @param tokenId The ID of the credential to revoke
    function revokeCredential(uint256 tokenId) external {
        require(verifiedInstitutions[msg.sender], "Only verified institutions can revoke");
        require(_tokenExists(tokenId), "Credential does not exist");
        require(!isRevoked[tokenId], "Credential already revoked");

        isRevoked[tokenId] = true;
        emit CredentialRevoked(tokenId);
    }


    /// @notice Overrides token transfer to make credentials non-transferable
    /// @dev Only allows minting (from 0x0) or burning (to 0x0)
function _beforeTokenTransfer(
    address from, 
    address to, 
    uint256 tokenId,
    uint256 batchSize
) internal override(ERC721) {
    require(from == address(0) || to == address(0), "Credentials are non-transferable");
    ERC721._beforeTokenTransfer(from, to, tokenId, batchSize);
}

    /// @notice Checks if a token exists by attempting to retrieve its owner
    /// @param tokenId The ID of the token to check
    /// @return True if the token exists, false otherwise
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}