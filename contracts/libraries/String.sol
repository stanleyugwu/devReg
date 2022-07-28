//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library String {
    /**
    * @notice Returns the length of a string
    */
     function length(string calldata self) pure public returns(uint){
        return bytes(self).length;
     }

    /**
    * @notice Returns whether a given string is empty ("")
    */
     function isEmpty(string calldata self) pure public returns(bool ){
        return bytes(self).length == 0;
     }

    /**
     * @notice Checks whether given string is an empty space (" ")
     */
     function isSpace(string calldata str) public pure returns(bool){
         if(isEmpty(str)){
             return false;
         }
         
         return isSameAs(str, string(" "));
     }

    /**
    * @notice Returns whether a given string is of a given length
    */
     function isLength(string calldata self, uint _length) pure public returns(bool){
        return length(self) == _length;
     }
     
    /**
    * @notice Returns whether a given string is empty ("") or space (" ")
    */
     function isEmptyOrSpace(string calldata self) pure public returns(bool ){
        return isEmpty(self) || isSpace(self);
     }

    /**
    * @notice Compares two string. Returns true if they're same, and false otherwise
    */
     function isSameAs(string memory self, string memory str2) pure public returns(bool){
        return keccak256(abi.encodePacked(self)) == keccak256(abi.encodePacked(str2));
     }

    /**
    * @notice Checks if first string match any of the last two strings. Returns true if they're same, and false otherwise
    */
     function isSameAs(string memory self, string memory str2, string memory str3) pure public returns(bool){
        return 
        keccak256(abi.encodePacked(self)) == keccak256(abi.encodePacked(str2)) || 
        keccak256(abi.encodePacked(self)) == keccak256(abi.encodePacked(str3));
     }

    /**
    * Returns a substring from `start` to `end` within `self`
    */
    function subString(string calldata self, uint start, uint end) public pure returns(string memory){
        return self[start:end];
    }

}