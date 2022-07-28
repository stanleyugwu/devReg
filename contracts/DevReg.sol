//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import * as Lib from './libraries/String.sol';
import './interfaces/IDevReg.sol';

// The data structure of individual developer
struct DevInfo {
    // Developer's title (<= 50 characters) e.g "Fullstack developer"
    string title;
    // Developer's short bio (<= 100 characters)
    string bio;
    // Developer's reputation points
    uint256 reputationPoints;
    // Whether the developer is open to jobs or employment
    bool openToWork;
    // Developer's Github profile URL
    string githubUrl;
    // Registeration date
    uint256 regDate;
    // Link to dev's pic
    string devPicUrl;
    // Developer's wallet address
    address payable walletAddress;
}

/**
 * @author Devvie
 * @title DevReg - An info registry for software developers
 */
contract DevReg is IDevReg {
    using Lib.String for string;

    // contract owner's address
    address payable public immutable owner;

    constructor(){owner = payable(msg.sender);}

    // mapping from username to developer info
    mapping(string => DevInfo) public developers;

    // mapping from developer address to username
    mapping(address => string) public namesByAddress;

    // mapping from username to addresses of its reputators
    mapping(string => address[]) public reputators;


    /*/////////////////////////////////////////////////////////////////////////////////
    ** EVENTS
    *//////////////////////////////////////////////////////////////////////////////////
    event LogRegistered(string indexed _username, address indexed _owner);
    event LogUsernameUpdated(string indexed _newUsername, address indexed _owner);
    event LogInfoUpdated(address indexed _owner);
    event LogNameDisowned(string indexed _disonwnedName, address indexed _disowner);
    event LogReputationGiven(string indexed _reputedName, uint _newRepPoint);
    event LogWithdrawal(uint indexed _amount);
    /*/*********************************************************************************
    ** EVENTS END
    **********************************************************************************/


    
    /*/////////////////////////////////////////////////////////////////////////////////
    ** INPUT VALIDATORS
    *//////////////////////////////////////////////////////////////////////////////////

    /// @notice Handles common username validations
    function _usernameValidation(string memory username) private view {
        // make sure username is provided
        require(
            !(username).isEmptyOrSpace(),
            "provide a valid username"
        );

        // make sure username is not taken
        require(developers[username].regDate == 0, "Username already taken");

        // make sure username doesn't have any space
        bytes memory strByt = bytes(username);
        for(uint char; char < strByt.length;char++){
            if(
                keccak256(abi.encodePacked(strByt[char])) == keccak256(abi.encodePacked(bytes1(" ")))
            ) revert("username can't contain spaces");
        }

        // make sure username > 1 and < 30 chars
        require(username.length() > 1 && username.length() < 30, "username should be less than 30 characters");
    }

    /// @notice Handles validation for other registeration inputs apart from username
    function _otherInputsValidation(
        string memory title,
        string memory bio,
        string memory githubUrl,
        string memory devPicUrl
    ) private pure {

        // make sure title is < 50 chars
        require(title.length() < 50, "title should be less than 50 characters");
        
        // make sure bio is < 130 chars
        require(bio.length() < 130, "bio should be less than 130 characters");

        // make sure github url is valid
        require(githubUrl.length() > 11 && githubUrl.subString(0, 11).isSameAs("github.com/"), "github url should start with 'github.com/'");

        // make sure dev pic url is valid i.e points to an image
        require(devPicUrl.length() > 5, "provide a valid image url");
        require(
            devPicUrl.subString(devPicUrl.length() - 4, devPicUrl.length()).isSameAs(".jpg",".JPG") ||
            devPicUrl.subString(devPicUrl.length() - 4, devPicUrl.length()).isSameAs(".png",".PNG") ||
            devPicUrl.subString(devPicUrl.length() - 4, devPicUrl.length()).isSameAs(".gif", ".GIF") ||
            devPicUrl.subString(devPicUrl.length() - 5, devPicUrl.length()).isSameAs(".jpeg", ".JPEG"),
            "Image URL should point to a valid image file with case-insensitive .jpg, .png, .gif, or .jpeg extension"
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
        string memory githubUrl,
        string memory devPicUrl
    ) public returns (bool) {
        // makes sure caller doesn't have a registered name already
        require(namesByAddress[msg.sender].isEmpty(),
            "You can't register more than one name"
        );

        // require provision of all parameters
        require(
            !(title).isEmptyOrSpace() &&
            !(bio).isEmptyOrSpace() &&
            !(githubUrl).isEmptyOrSpace() &&
            !(devPicUrl).isEmptyOrSpace(),
            "Please provide all paramters"
        );
        
        // handle common username validations
        _usernameValidation(username);
        // handle other inputs validations for: title, bio, githubUrl, devPicUrl
        _otherInputsValidation(title, bio, githubUrl, devPicUrl);

        // finally register name
        namesByAddress[msg.sender] = username;
        developers[username] = DevInfo({
            title: title,
            bio:bio,
            reputationPoints:0,
            openToWork:openToWork,
            githubUrl:githubUrl,
            regDate:block.timestamp,
            devPicUrl:devPicUrl,
            walletAddress:payable(msg.sender)
        });

        emit LogRegistered(username, msg.sender);
        return true;
    }

    /// @notice See {IDevReg - updateUsername}
    function updateUsername(string memory newUsername) public returns (bool) {
        // validate new username
        _usernameValidation(newUsername);

        // make sure caller owns a valid name
        address caller = msg.sender;
        string memory oldName = namesByAddress[caller];
        require(oldName.length() > 0, "You don't own a name");
        
        // At this point, caller has a valid name and the new username is available
        // let's just move the caller's info to the new username and free up the old username's info
        DevInfo memory callerInfo = developers[oldName];
        developers[newUsername] = callerInfo;
        namesByAddress[caller] = newUsername;

        delete developers[oldName];

        emit LogUsernameUpdated(newUsername, caller);
        return true;
    }

    /// @notice See {IDevReg - updateInfo}
    function updateInfo(
        string memory title,
        string memory bio,
        bool openToWork,
        string calldata githubUrl,
        string memory devPicUrl
    ) public returns (bool){
        // assert caller has a registered name
        string memory callersName = namesByAddress[msg.sender];
        require(callersName.length() > 0, "You don't own a name");

        // require provision of all parameters
        require(
            !(title).isEmptyOrSpace() &&
            !(bio).isEmptyOrSpace() &&
            !(githubUrl).isEmptyOrSpace() &&
            !(devPicUrl).isEmptyOrSpace(),
            "Please provide all paramters"
        );

        // handle other inputs validations for: title, bio, githubUrl, devPicUrl
        _otherInputsValidation(title, bio, githubUrl, devPicUrl);

        // At this point, everything is fine. Lets apply updates
        DevInfo storage devInfo = developers[callersName];
        devInfo.title = title;
        devInfo.bio = bio;
        devInfo.openToWork = openToWork;
        devInfo.githubUrl = githubUrl;
        devInfo.devPicUrl = devPicUrl;

        emit LogInfoUpdated(msg.sender);
        return true;
    }

    /// @notice See {IDevReg - disOwn}
    function disOwn() public returns (bool) {
        // assert caller has a registered name
        string memory callersName = namesByAddress[msg.sender];
        require(callersName.length() > 0, "You don't own a name");

        // delete caller's name, info, and reputators
        delete developers[callersName];
        delete namesByAddress[msg.sender];
        delete reputators[callersName];

        emit LogNameDisowned(callersName, msg.sender);
        return true;
    }

    /// @notice See {IDevReg - giveReputation}
    function giveReputation(string memory username) public payable returns (uint){
        // make sure username is provided
        require(
            !(username).isEmptyOrSpace(),
            "provide a valid username"
        );

        // make sure username exists
        DevInfo memory devInfo = developers[username];
        require(devInfo.regDate != 0, "username is not owned by anyone");

        // make sure name is not owned by caller
        require(
            devInfo.walletAddress != msg.sender, 
            "You can't give yourself reps"
        );

        // make sure reputator sends >= 10 wei for the reputation
        require(msg.value >= 10 wei, "you must pay atleast 10 wei to give reputations");

        // make sure reputator haven't given name's owner reps before
        address[] memory _reputatorsArr = reputators[username];
        for(uint rep; rep < _reputatorsArr.length; rep++){
            if(_reputatorsArr[rep] == msg.sender) revert("You have already given this user reps before");
        }

        // At this point everything is fine, let's give that user some reps
        devInfo.reputationPoints++;
        reputators[username].push(msg.sender);

        // The money part, lets keep 5 wei and give name owner the rest
        devInfo.walletAddress.transfer(msg.value-5);

        emit LogReputationGiven(username, devInfo.reputationPoints);
        return devInfo.reputationPoints;
    }

    /**
    * @notice Allows contract owner to withdraw from contract savings
    * @param _amount The desired amount to withdraw
    * @return true or false depending on whether the withdrawal was successful
    */
    function withdraw(uint _amount) public returns(bool) {
        // make caller is the owner
        require(msg.sender == owner, "Only owner of contract can withdraw from it");

        // We'll give the owner everything if he requests for more than the contract has
        uint contractBal = address(this).balance;
        if(_amount > contractBal){
            owner.transfer(contractBal);
            emit LogWithdrawal(contractBal);
        } else {
            owner.transfer(_amount);
            emit LogWithdrawal(_amount);
        }

        return true;
    }
    
}
