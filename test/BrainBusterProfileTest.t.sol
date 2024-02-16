// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {BrainBusterProfile} from "../src/BrainBusterProfile.sol";
import {BrainBusterDeploy} from "../script/BrainBusterDeploy.s.sol";

contract BrainBusterProfileTest is Test {
    // Set up values to be used throughout tests
    BrainBusterProfile public profileContract;
    address public constant OWNER = address(1);
    address public constant USER = address(2);

    // Expected values for tests
    string public constant NFT_NAME = "Brain Buster Profile";
    string public constant NFT_SYMBOL = "BBP";
    string public constant BASE_64_TOKEN_URI =
        "data:application/json;base64,eyJuYW1lIjogIkJyYWluIEJ1c3RlciBQcm9maWxlIiwgImRlc2NyaXB0aW9uIjogIlRoaXMgTkZUIHJlcHJlc2VudHMgeW91ciBwcm9maWxlIGluIEJyYWluIEJ1c3Rlci4gWW91IGNhbiB1c2UgaXQgdG8gc2hvdyBvZmYgeW91ciB3aW5zIGFuZCBnYW1lcyBwbGF5ZWQuIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogIlVzZXIgTmFtZSIsICJ2YWx1ZSI6ICJ1c2VyIn0sIHsidHJhaXRfdHlwZSI6ICJHYW1lcyBQbGF5ZWQiLCAidmFsdWUiOiAiMSJ9LCB7InRyYWl0X3R5cGUiOiAiV2lucyIsICJ2YWx1ZSI6ICIxIn1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTWpRd0lpQm9aV2xuYUhROUlqRTRNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y21WamRDQjNhV1IwYUQwaU1UQXdKU0lnYUdWcFoyaDBQU0l4TURBbElpQm1hV3hzUFNJak1EQXdNREF3SWlBdlBqeDBaWGgwSUhnOUlqVXdKU0lnZVQwaU5EQWlJR1p2Ym5RdFptRnRhV3g1UFNKQmNtbGhiQ0lnWm05dWRDMXphWHBsUFNJeU1DSWdabWxzYkQwaUkyWm1abVptWmlJZ1ptOXVkQzEzWldsbmFIUTlJbUp2YkdRaUlIUmxlSFF0WVc1amFHOXlQU0p0YVdSa2JHVWlQblZ6WlhJOEwzUmxlSFErUEhSbGVIUWdlRDBpTVRBaUlIazlJamd3SWlCbWIyNTBMV1poYldsc2VUMGlRWEpwWVd3aUlHWnZiblF0YzJsNlpUMGlNVFlpSUdacGJHdzlJaU5tWm1abVptWWlQa2RoYldWeklGQnNZWGxsWkRvZ01Ud3ZkR1Y0ZEQ0OGRHVjRkQ0I0UFNJeE1DSWdlVDBpTVRFd0lpQm1iMjUwTFdaaGJXbHNlVDBpUVhKcFlXd2lJR1p2Ym5RdGMybDZaVDBpTVRZaUlHWnBiR3c5SWlObVptWm1abVlpUGxkcGJuTTZNVHd2ZEdWNGRENDhMM04yWno0PSJ9";

    // Events
    event ProfileCreated(
        address indexed owner,
        uint256 indexed tokenId,
        string userName
    );
    event GamePlayed(uint256 indexed tokenId, bool gameWon);
    event UpdaterAdded(address indexed updater);

    function setUp() public {
        BrainBusterDeploy deploy = new BrainBusterDeploy();
        profileContract = deploy.run(OWNER);
    }

    function testInitialState() public view {
        assert(
            keccak256(abi.encodePacked(profileContract.name())) ==
                keccak256(abi.encodePacked(NFT_NAME))
        );
        assert(
            keccak256(abi.encodePacked(profileContract.symbol())) ==
                keccak256(abi.encodePacked(NFT_SYMBOL))
        );
    }

    function testNewUserCanCreateProfile() public {
        string memory userName = "user";
        uint256 expectedGamesPlayed = 0;
        uint256 expectedWins = 0;
        uint256 expectedTokenId = 1;

        vm.expectEmit(true, true, false, false, address(profileContract));
        emit ProfileCreated(USER, expectedTokenId, userName);
        vm.prank(USER);
        profileContract.createProfile(userName);

        assert(profileContract.balanceOf(USER) == 1);
        assert(profileContract.ownerOf(expectedTokenId) == USER);
        assert(
            keccak256(
                abi.encodePacked(profileContract.getUsername(expectedTokenId))
            ) == keccak256(abi.encodePacked(userName))
        );
        assert(
            profileContract.getGamesPlayed(expectedTokenId) ==
                expectedGamesPlayed
        );
        assert(profileContract.getWins(expectedTokenId) == expectedWins);
    }

    function testUserCannotCreateMoreThanOneProfile() public {
        vm.startPrank(USER);
        profileContract.createProfile("user");
        vm.expectRevert();
        profileContract.createProfile("user1");
        vm.stopPrank();
    }

    function testDuplicateUserNamesAreNotPermitted() public {
        string memory userName = "user";

        vm.prank(USER);
        profileContract.createProfile(userName);

        vm.prank(address(2));
        vm.expectRevert();
        profileContract.createProfile(userName);
    }

    modifier firstProfileCreated() {
        vm.prank(USER);
        profileContract.createProfile("user");
        _;
    }

    modifier firstGamePlayed() {
        vm.prank(OWNER);
        profileContract.updateProfileGameRecord(1, true);
        _;
    }

    function testProfileDataUpdatedCorrectlyAfterLoss()
        public
        firstProfileCreated
    {
        uint256 tokenId = 1;
        bool gameWon = false;

        vm.expectEmit(true, false, false, false, address(profileContract));
        emit GamePlayed(tokenId, gameWon);
        vm.prank(OWNER);
        profileContract.updateProfileGameRecord(tokenId, gameWon);

        assert(profileContract.getGamesPlayed(tokenId) == 1);
        assert(profileContract.getWins(tokenId) == 0);
    }

    function testProfileDataUpdatedCorrectlyAfterWin()
        public
        firstProfileCreated
    {
        uint256 tokenId = 1;
        bool gameWon = true;

        vm.expectEmit(true, false, false, false, address(profileContract));
        emit GamePlayed(tokenId, gameWon);
        vm.prank(OWNER);
        profileContract.updateProfileGameRecord(tokenId, gameWon);

        assert(profileContract.getGamesPlayed(tokenId) == 1);
        assert(profileContract.getWins(tokenId) == 1);
    }

    function testErrorThrownWhenProfileDoesNotExist() public {
        uint256 tokenId = 2;
        bool gameWon = true;

        vm.startPrank(OWNER);
        vm.expectRevert();
        profileContract.updateProfileGameRecord(tokenId, gameWon);
    }

    function testOnlyUpdaterCanUpdateProfile() public {
        uint256 tokenId = 1;
        bool gameWon = true;

        vm.startPrank(USER);
        vm.expectRevert();
        profileContract.updateProfileGameRecord(tokenId, gameWon);
    }

    function testCorrectTokenURI() public firstProfileCreated firstGamePlayed {
        string memory tokenURI = profileContract.tokenURI(1);

        assert(
            keccak256(abi.encodePacked(tokenURI)) ==
                keccak256(abi.encodePacked(BASE_64_TOKEN_URI))
        );
    }

    function testErrorThrownWhenTokenDoesNotExist() public firstProfileCreated {
        vm.expectRevert();
        profileContract.tokenURI(2);
    }

    function testAddingNewUpdater() public firstProfileCreated {
        uint256 tokenId = 1;
        bool gameWon = true;

        vm.prank(OWNER);
        vm.expectEmit(true, false, false, false, address(profileContract));
        emit UpdaterAdded(USER);
        profileContract.addUpdater(USER);

        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(profileContract));
        emit GamePlayed(tokenId, gameWon);
        profileContract.updateProfileGameRecord(tokenId, gameWon);

        assert(profileContract.getGamesPlayed(tokenId) == 1);
        assert(profileContract.getWins(tokenId) == 1);
    }

    function testErrorThrownWhenNonAdminTriesToAddUpdater() public {
        vm.startPrank(USER);
        vm.expectRevert();
        profileContract.addUpdater(USER);
    }

    function testErrorThrownWhenZeroAddressTriesToAddUpdater() public {
        vm.startPrank(OWNER);
        vm.expectRevert();
        profileContract.addUpdater(address(0));
    }

    function testErrorThrownWhenUpdaterAlreadyExists()
        public
        firstProfileCreated
    {
        vm.prank(OWNER);
        profileContract.addUpdater(USER);

        vm.startPrank(OWNER);
        vm.expectRevert();
        profileContract.addUpdater(USER);
    }
}
