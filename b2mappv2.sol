// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

contract b2mapp{
    
    address superadmin;
    constructor () {
        superadmin = msg.sender;
    }
    
    address [] allDocs;
    address [] allAdmins;
    mapping (address => bool) isAdmin;
    mapping (address => bool) isDoc;
    mapping (address => bool) isUser;
    
    mapping (address => string[]) userTests;
    mapping (address => mapping (address => bool)) sharedTests;
    
    modifier patientCheck{
        require(isUser[msg.sender] == true, "Please Register as Patient.");
        _;
    }
    modifier docCheck{
        require(isDoc[msg.sender] == true, "Please Register as a doctor.");
        _;
    }
    modifier adminCheck{
        require(isAdmin[msg.sender] == true, "This Feature is only for admins.");
        _;
    }
    event newPatient(address indexed ke, uint kkhon);
    event newDoc(address indexed ke, uint kkhon);
    event newAdmin(address indexed ke, uint kkhon);
    event newTest(address indexed ke, uint kkhon);
    event wrongCall(address indexed ke, bytes ki);
    event dataShared (address indexed patient, address indexed doc);
    event dataViewedByDoc (address indexed doc, uint kokhon);
    event dataSharingTurnedOff (address doc, address patient, uint kokhon);

    function registerPatient() public {
        isUser[msg.sender] = true;
        emit newPatient(msg.sender, block.timestamp);
    }
    function addAdmin (address admin) public {
        require(msg.sender == superadmin, "Only Super Admin can approve Admin Accounts");
        isAdmin[admin] = true;
        emit newAdmin(admin, block.timestamp);
    }
    function registerDoc(address docid) adminCheck public {
        isDoc[docid] = true;
        emit newDoc(msg.sender, block.timestamp);
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
        emit dataShared(msg.sender, docid);
    }

    function seePatientRecord (address patientId, uint testId) docCheck public returns (string memory) {
        emit dataViewedByDoc(msg.sender, block.timestamp);
        return string(userTests[patientId][testId]);
    }
    function removeDoc (address docid) patientCheck public {
        sharedTests[msg.sender][docid] = false;
        emit dataSharingTurnedOff(docid, msg.sender, block.timestamp);
    }
    function removePatient (address patientId) docCheck public {
        sharedTests[patientId][msg.sender] = false;
        emit dataSharingTurnedOff(msg.sender, patientId, block.timestamp);
    }
    
    fallback() external {
        emit wrongCall(msg.sender, msg.data);
    }

    receive() external payable { }
}
