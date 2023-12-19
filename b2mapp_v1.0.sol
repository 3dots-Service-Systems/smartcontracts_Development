// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

contract b2mapp{
    
    mapping (address => bool) isUser;
    mapping (address => string[]) public userTests;
    modifier UserCheck{
        require(isUser[msg.sender] == true, "Please Register");
        _;
    }
    event newUser(address indexed ke, uint kkhon);
    event newTest(address indexed ke, uint kkhon);
    event wrongCall(address indexed ke, bytes ki);

    function register() public {
        isUser[msg.sender] = true;
        emit newUser(msg.sender, block.timestamp);
    }
    
    function addTest(string memory _val)public {
        userTests[msg.sender].push(_val);
        emit newTest(msg.sender, block.timestamp);
    }

    function seeResults(uint Tid) UserCheck public view returns (string memory) {
        return string(userTests[msg.sender][Tid]);
    }

    function seeAllResults() UserCheck public view returns (string[] memory) {
        return userTests[msg.sender];
    }

    function toTalnumberOfResults() UserCheck public view returns (uint) {
        return userTests[msg.sender].length;
    }
    fallback() external {
        emit wrongCall(msg.sender, msg.data);
     }

    receive() external payable { }

}
