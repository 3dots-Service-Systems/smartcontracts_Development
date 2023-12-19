// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

contract b2mapp{
    
    mapping (address => bool) isUser;
    mapping (address => string[]) userTests;
    mapping (address => bool) isDoc;
    mapping (address => mapping (address => bool)) sharedTests;
    modifier patientCheck{
        require(isUser[msg.sender] == true, "Please Register as Patient.");
        _;
    }
    modifier docCheck{
        require(isDoc[msg.sender] == true, "Please Register as a doctor.");
        _;
    }
    event newUser(address indexed ke, uint kkhon);
    event newTest(address indexed ke, uint kkhon);
    event wrongCall(address indexed ke, bytes ki);

    function register() public {
        isUser[msg.sender] = true;
        emit newUser(msg.sender, block.timestamp);
    }
    
    function addTest(string memory _val) patientCheck public {
        userTests[msg.sender].push(_val);
        emit newTest(msg.sender, block.timestamp);
    }

    function seeResults(uint Tid) patientCheck public view returns (string memory) {
        return string(userTests[msg.sender][Tid]);
    }

    function seeAllResults() patientCheck public view returns (string[] memory) {
        return userTests[msg.sender];
    }

    function toTalnumberOfResults() patientCheck public view returns (uint) {
        return userTests[msg.sender].length;
    }

    function shareTest (address docid) patientCheck public {
        sharedTests[msg.sender][docid] = true;
    }

    function seePatientRecord (address patientId, uint testId) docCheck public view returns (string memory) {
        return string(userTests[patientId][testId]);
    }
    function removeDoc (address docid) patientCheck public {
        sharedTests[msg.sender][docid] = false;
    }
    function removePatient (address patientId) docCheck public {
        sharedTests[patientId][msg.sender] = false;
    }

    
    fallback() external {
        emit wrongCall(msg.sender, msg.data);
     }

    receive() external payable { }

}
