//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {String} from "./libraries/String.sol";
import "./interfaces/IDevReg.sol";

// The data structure of individual developer
struct DevInfo {
    // Developer's username. This won't be touched after creation we're just keeping this field
    // to be able to return full info for all developers
    string username;
    // Developer's title (<= 50 characters) e.g "Fullstack developer"
    string title;
    // Developer's short bio (<= 100 characters)
    string bio;
    // Developer's reputation points
    uint256 reputationPoints;
    // Whether the developer is open to jobs or employment
    bool openToWork;
    // Developer's Github username
    string githubUsername;
    // Registeration date
    uint256 regDate;
    // Link to dev's pic
    string devPicUrl;
    // Developer's wallet address
    address payable walletAddress;
}

// This struct will be used for mapping from address.
// It will store the registered name of the address it maps from, along with the index of the name in
// names array for easy deletion
struct Username {
    uint256 index;
    string name;
}

/**
 * @author Devvie
 * @title DevReg - An info registry for software developers
 */
contract DevReg is IDevReg {
    using String for string;

    // contract owner's address
    address payable public immutable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    // This number will be used for indexing names
    uint256 private count;

    // mapping from username to developer info
    mapping(string => DevInfo) public developers;

    // mapping from developer address to Username struct
    mapping(address => Username) public namesByAddress;

    // mapping from username to addresses of its reputators
    mapping(string => address[]) public reputators;

    // arrays of addresses that has registered name
    // this array will be useful when returning all names or developers
    // since we cant return mapping
    string[] private names;

    /*/////////////////////////////////////////////////////////////////////////////////
     ** EVENTS
     */
    /////////////////////////////////////////////////////////////////////////////////

    event LogRegistered(string _username, address _owner);
    event LogUsernameUpdated(string _newUsername, address _owner);
    event LogInfoUpdated(address indexed _owner);
    event LogNameDisowned(string _disonwnedName, address indexed _disowner);
    event LogReputationGiven(string _reputedName, uint256 _newRepPoint);
    event LogWithdrawal(uint256 indexed _amount);

    /*/*********************************************************************************
     ** EVENTS END
     **********************************************************************************/

    /*/////////////////////////////////////////////////////////////////////////////////
     ** INPUT VALIDATORS
     */
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Handles common username validations
    function _usernameValidation(string memory username) private view {
        // make sure username is provided
        require(!(username).isEmptyOrSpace(), "provide a valid username");

        // make sure username is not taken
        require(developers[username].regDate == 0, "Username already taken");

        // make sure username doesn't have any space
        bytes memory strByt = bytes(username);
        for (uint256 char; char < strByt.length; char++) {
            if (
                keccak256(abi.encodePacked(strByt[char])) ==
                keccak256(abi.encodePacked(bytes1(" ")))
            ) revert("username can't contain spaces");
        }

        // make sure username > 1 and < 30 chars
        require(
            username.length() > 1 && username.length() < 30,
            "username should be less than 30 characters"
        );
    }

    /// @notice Handles validation for other registeration inputs apart from username
    function _otherInputsValidation(
        string memory title,
        string memory bio,
        string memory githubUsername,
        string memory devPicUrl
    ) private pure {
        // make sure title is < 50 chars
        require(
            title.length() > 0 && (title.length() < 50),
            "provide valid title, it should be less than 50 characters"
        );

        // make sure bio is < 130 chars
        require(bio.length() < 130, "bio should be less than 130 characters");

        // make sure github url is valid
        require(githubUsername.length() > 0, "provide a valid github username");

        // make sure dev pic url is valid
        require(
            devPicUrl.length() > 5,
            "provide a valid image url. It should end with an image extension"
        );
    }

    /**********************************************************************************
     ** INPUT VALIDATORS END
     **********************************************************************************/

    /// @notice See {IDevReg - register}
    function register(
        string memory username,
        string memory title,
        string memory bio,
        bool openToWork,
        string memory githubUsername,
        string memory devPicUrl
    ) public returns (bool __success) {
        address caller = msg.sender;
        // makes sure caller doesn't have a registered name already
        require(
            namesByAddress[caller].name.isEmpty(),
            "You can't register more than one name"
        );

        // handle common username validations
        _usernameValidation(username);
        // handle other inputs validations for: title, bio, githubUsername, devPicUrl
        _otherInputsValidation(title, bio, githubUsername, devPicUrl);

        // finally register name
        namesByAddress[caller] = Username(count++, username);
        developers[username] = DevInfo({
            username: username,
            title: title,
            bio: bio,
            reputationPoints: 0,
            openToWork: openToWork,
            githubUsername: githubUsername,
            regDate: block.timestamp,
            devPicUrl: devPicUrl,
            walletAddress: payable(caller)
        });
        // push to names array, we cant add array items by index e.g names[8] = value
        names.push(username);

        emit LogRegistered(username, caller);

        __success = true; // return bool
    }

    /// @notice See {IDevReg - updateUsername}
    function updateUsername(string memory newUsername)
        public
        returns (bool __success)
    {
        // validate new username
        _usernameValidation(newUsername);

        // make sure caller owns a valid name
        address caller = msg.sender;
        string memory oldName = namesByAddress[caller].name;
        require(oldName.length() > 0, "You don't own a name");

        // At this point, caller has a valid name and the new username is available
        // let's just move the caller's info to the new username and free up the old username's info
        DevInfo storage callerInfo = developers[oldName]; // old name info
        callerInfo.username = newUsername; // update username in old name info

        developers[newUsername] = callerInfo; // create new entry
        namesByAddress[caller].name = newUsername; // update info in `namesByAddress`

        delete developers[oldName]; // delete from developers mapping

        // replace oldname in names array
        uint256 nameIndex = namesByAddress[caller].index;
        names[nameIndex] = newUsername; // change username in names

        emit LogUsernameUpdated(newUsername, caller);
        __success = true;
    }

    /// @notice See {IDevReg - updateInfo}
    function updateInfo(
        string memory title,
        string memory bio,
        bool openToWork,
        string calldata githubUsername,
        string memory devPicUrl
    ) public returns (bool __success) {
        // assert caller has a registered name
        string memory callersName = namesByAddress[msg.sender].name;
        require(callersName.length() > 0, "You don't own a name");

        // handle other inputs validations for: title, bio, githubUsername, devPicUrl
        _otherInputsValidation(title, bio, githubUsername, devPicUrl);

        // At this point, everything is fine. Lets apply updates
        DevInfo storage devInfo = developers[callersName];
        devInfo.title = title;
        devInfo.bio = bio;
        devInfo.openToWork = openToWork;
        devInfo.githubUsername = githubUsername;
        devInfo.devPicUrl = devPicUrl;

        emit LogInfoUpdated(msg.sender);
        __success = true;
    }

    /// @notice See {IDevReg - disOwn}
    function disOwn() public returns (bool __success) {
        // assert caller has a registered name
        string memory callersName = namesByAddress[msg.sender].name;
        require(callersName.length() > 0, "You don't own a name");

        // delete name from developers entry
        delete developers[callersName];

        // delete name from names array
        uint256 nameIndex = namesByAddress[msg.sender].index;
        delete names[nameIndex];

        // delete name from namesByAddress and clear the reputations
        delete namesByAddress[msg.sender];
        delete reputators[callersName];

        emit LogNameDisowned(callersName, msg.sender);

        __success = true;
    }

    /// @notice See {IDevReg - giveReputation}
    function giveReputation(string memory username)
        public
        payable
        returns (uint256 __newRep)
    {
        // make sure username is provided
        require(!(username).isEmptyOrSpace(), "provide a valid username");

        // make sure username exists
        DevInfo storage devInfo = developers[username];
        require(devInfo.regDate != 0, "username is not owned by anyone");

        // make sure name is not owned by caller
        require(
            devInfo.walletAddress != msg.sender,
            "You can't give yourself reps"
        );

        // make sure reputator sends >= 10 wei for the reputation
        require(
            msg.value >= 10 wei,
            "you must pay atleast 10 wei to give reputations"
        );

        // make sure reputator haven't given name's owner reps before
        address[] memory _reputatorsArr = reputators[username];
        for (uint256 rep; rep < _reputatorsArr.length; rep++) {
            if (_reputatorsArr[rep] == msg.sender)
                revert("You have already given this user reps before");
        }

        // At this point everything is fine, let's give that name some reps
        reputators[username].push(msg.sender);
        devInfo.reputationPoints++;

        // The money part, lets keep 5 wei and give name owner the rest
        devInfo.walletAddress.transfer(msg.value - 5 wei);

        emit LogReputationGiven(username, devInfo.reputationPoints);
        __newRep = devInfo.reputationPoints;
    }

    /**
     * @notice Allows contract owner to withdraw from contract savings
     * @param _amount The desired amount to withdraw
     * @return __success true or false depending on whether the withdrawal was successful
     */
    function withdraw(uint256 _amount) public returns (bool __success) {
        // make caller is the owner
        require(
            msg.sender == owner,
            "Only owner of contract can withdraw from it"
        );

        // make sure owner doesn't withdraw nothing
        require(_amount > 0, "You can't withdraw nothing");

        // We'll give the owner everything if he requests for more than the contract has
        uint256 contractBal = address(this).balance;
        if (_amount > contractBal) {
            owner.transfer(contractBal);
            emit LogWithdrawal(contractBal);
        } else {
            owner.transfer(_amount);
            emit LogWithdrawal(_amount);
        }

        __success = true;
    }

    /// @notice Returns all registered developers
    /// @dev Returns all developers and their full info if they exist and empty zero-initialised list
    /// return Boolean indicating whether registered developers was found and will be returned.
    /// It will return false when no registered voter was found
    /// @return __allDevs A list of all developers with their full info if they exist,
    /// and a zero-initialised `DevInfo` array otherwise
    function getAllDevs() public view returns (DevInfo[] memory __allDevs) {
        __allDevs = new DevInfo[](names.length);

        // make sure there's registered names
        if (names.length != 0) {
            // construct array of devs from names array if there are names
            for (uint256 i; i < names.length; i++) {
                string memory name = names[i];
                DevInfo memory devInfo = developers[name];
                __allDevs[i] = devInfo;
            }
        }

        return __allDevs;
    }

    // we just return available function signatures when caller calls non-existent function
    fallback(bytes calldata _data) external returns(bytes memory) {
        bytes
            memory message = "Sorry, the function you called doesn't exist. Available function signatures are:"
            "1. function register(string memory username,string memory title,string memory bio,bool openToWork,"
            "string memory githubUsername,string memory devPicUrl) public returns (bool __success)"
            "2. function updateUsername(string memory newUsername) public returns (bool __success)"
            "3. function updateInfo(string memory title,string memory bio,bool openToWork,"
            "string calldata githubUsername,string memory devPicUrl) public returns (bool __success)"
            "4. function disOwn() public returns (bool __success)"
            "5. function giveReputation(string memory username) public payable returns (uint256 __newRep)"
            "6. function withdraw(uint256 _amount) public returns (bool __success)"
            "7. function getAllDevs() public view returns (DevInfo[] memory __allDevs)";
        return message;
    }
}
