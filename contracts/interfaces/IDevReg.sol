pragma solidity 0.8.15;
// SPDX-License-Identifier: MIT

/**
 * The interface describing necessary functions for the `DevReg` contract
 */
interface IDevReg {
    /**
     * Registers a new developer to the registry
     * Requirements:
     * - `username` must be unique, > 1 and < 30 chars
     * - `username` doesn't have spaces
     * - `title` must be < 50 chars
     * - `bio` must be < 130 chars
     * - `githubUrl` must be a valid github link to profile e.g https://github.com/stanleyugwu
     * - `devPicUrl` must start with "https://", and point to a valid image file e.g (.jpg | .png | .gif)
     *
     * @notice Registers the caller to the registry
     * @param username The unique username of the developer
     * @param title Devloper's title e.g "Blockchain developer"
     * @param bio Developer's short bio
     * @param openToWork Determines whether the developer is open to jobs
     * @param githubUrl Developer's Github profile url
     * @param devPicUrl External url to the developer's image. Must point to a valid image file
     * @return Boolean indicating whether the registration was successful or not
     */
    function register(
        string calldata username,
        string memory title,
        string memory bio,
        bool openToWork,
        string calldata githubUrl,
        string memory devPicUrl
    ) external returns (bool);

    /**
     * Updates the caller's username if it's not taken already
     * Requirements:
     * - caller must be the owner of the name
     * - `username` must be > 1 and < 30 chars
     *
     * @notice Updates the caller's username
     * @param newUsername The unique username of the developer
     * @return Boolean indicating whether the update was successful or not
     */
    function updateUsername(string calldata newUsername)
        external
        returns (bool);

    /**
     * Updates the caller's info
     * Requirements:
     * - caller must be the owner of the name
     * - `title` must be < 50 chars
     * - `bio` must be < 130 chars
     * - `devPicUrl` must start with "https://", and point to a valid image file e.g (.jpg | .png | .gif)
     *
     * @notice Updates the caller's info
     * @param title New title e.g "Blockchain developer"
     * @param bio New short bio
     * @param openToWork Whether developer is open to jobs
     * @param githubUrl New github profile URL
     * @param devPicUrl New developer pic URL
     * @return Boolean indicating whether the registration was successful or not
     */
    function updateInfo(
        string memory title,
        string memory bio,
        bool openToWork,
        string calldata githubUrl,
        string memory devPicUrl
    ) external returns (bool);

    /**
     * Disowns a username so that another developer can claim it
     * Requirements:
     * - caller must be the own a name
     *
     * @notice Disowns a name, making it free to be claimed by another person
     * @return Boolean indicating whether the relinquision was successful or not
     */
    function disOwn() external returns (bool);

    /**
     * Gives a developer reputation.
     * A particular address can only give a developer reps once, and must pay atleast 10Wei to do so.
     * The contract takes 5 Wei and sends the developer being reputed the remaining ethers.
     *
     * Requirements:
     * - caller must send at least 10wei with the call
     * - caller must not be owner of `username` being reputed.
     * - caller must not have given that particular `username` reps before
     *
     * @notice Gives reputation to a username
     * @param username Username of the developer to be given reps
     * @return The new reputation of the name's owner
     */
    function giveReputation(string memory username) external payable returns (uint);
}