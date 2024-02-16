// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract BrainBusterProfile is ERC721, AccessControl {
    error BrainBuster__UserAlreadyHasProfile();
    error BrainBuster__UserNameAlreadyTaken();
    error BrainBuster__UpdaterCannotBeZeroAddress();
    error BrainBuster__AddressAlreadyHasRoleUpdater();
    error ERC721Metadata__TokenDoesNotExist();

    struct ProfileData {
        string userName;
        uint256 wins;
        uint256 gamesPlayed;
    }

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    string private constant SVG_TEMPLATE_ONE =
        '<svg width="240" height="180" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#000000" /><text x="50%" y="40" font-family="Arial" font-size="20" fill="#ffffff" font-weight="bold" text-anchor="middle">';
    string private constant SVG_TEMPLATE_TWO =
        '</text><text x="10" y="80" font-family="Arial" font-size="16" fill="#ffffff">Games Played: ';
    string private constant SVG_TEMPLATE_THREE =
        '</text><text x="10" y="110" font-family="Arial" font-size="16" fill="#ffffff">Wins:';
    string private constant SVG_TEMPLATE_FOUR = "</text></svg>";

    uint256 private s_tokenId;
    mapping(uint256 => ProfileData) private s_tokenIdToProfileData;
    mapping(string => address) private s_userNameToOwner;

    event ProfileCreated(
        address indexed owner,
        uint256 indexed tokenId,
        string userName
    );
    event GamePlayed(uint256 indexed tokenId, bool gameWon);
    event UpdaterAdded(address indexed updater);

    constructor(address admin) ERC721("Brain Buster Profile", "BBP") {
        s_tokenId = 1;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPDATER_ROLE, admin);
    }

    function createProfile(string calldata userName) public {
        if (balanceOf(msg.sender) > 0)
            revert BrainBuster__UserAlreadyHasProfile();
        if (s_userNameToOwner[userName] != address(0))
            revert BrainBuster__UserNameAlreadyTaken();

        uint256 currentTokenId = s_tokenId;
        ProfileData memory newProfile = ProfileData(userName, 0, 0);
        s_tokenIdToProfileData[currentTokenId] = newProfile;
        s_userNameToOwner[userName] = msg.sender;

        _safeMint(msg.sender, currentTokenId);
        s_tokenId++;

        emit ProfileCreated(msg.sender, currentTokenId, userName);
    }

    function updateProfileGameRecord(
        uint256 tokenId,
        bool gameWon
    ) public onlyRole(UPDATER_ROLE) {
        if (ownerOf(tokenId) == address(0))
            revert ERC721Metadata__TokenDoesNotExist();

        s_tokenIdToProfileData[tokenId].gamesPlayed++;
        if (gameWon) {
            s_tokenIdToProfileData[tokenId].wins++;
        }

        emit GamePlayed(tokenId, gameWon);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0))
            revert ERC721Metadata__TokenDoesNotExist();

        bytes memory svg = generateSVG(
            s_tokenIdToProfileData[tokenId].userName,
            s_tokenIdToProfileData[tokenId].gamesPlayed,
            s_tokenIdToProfileData[tokenId].wins
        );

        string memory json = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name": "',
                    name(),
                    '", "description": "This NFT represents your profile in Brain Buster. You can use it to show off your wins and games played.", ',
                    '"attributes": [{"trait_type": "User Name", "value": "',
                    getUsername(tokenId),
                    '"}, {"trait_type": "Games Played", "value": "',
                    Strings.toString(
                        s_tokenIdToProfileData[tokenId].gamesPlayed
                    ),
                    '"}, {"trait_type": "Wins", "value": "',
                    Strings.toString(s_tokenIdToProfileData[tokenId].wins),
                    '"}], "image": "data:image/svg+xml;base64,',
                    Base64.encode(svg),
                    '"}'
                )
            )
        );

        return string(abi.encodePacked(_baseURI(), json));
    }

    function getUsername(uint256 tokenId) public view returns (string memory) {
        return s_tokenIdToProfileData[tokenId].userName;
    }

    function getGamesPlayed(uint256 tokenId) public view returns (uint256) {
        return s_tokenIdToProfileData[tokenId].gamesPlayed;
    }

    function getWins(uint256 tokenId) public view returns (uint256) {
        return s_tokenIdToProfileData[tokenId].wins;
    }

    function generateSVG(
        string memory userName,
        uint256 gamesPlayed,
        uint256 wins
    ) internal pure returns (bytes memory) {
        return
            bytes(
                abi.encodePacked(
                    SVG_TEMPLATE_ONE,
                    userName,
                    SVG_TEMPLATE_TWO,
                    Strings.toString(gamesPlayed),
                    SVG_TEMPLATE_THREE,
                    Strings.toString(wins),
                    SVG_TEMPLATE_FOUR
                )
            );
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function addUpdater(
        address newUpdater
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newUpdater == address(0))
            revert BrainBuster__UpdaterCannotBeZeroAddress();
        if (hasRole(UPDATER_ROLE, newUpdater))
            revert BrainBuster__AddressAlreadyHasRoleUpdater();

        grantRole(UPDATER_ROLE, newUpdater);

        emit UpdaterAdded(newUpdater);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
