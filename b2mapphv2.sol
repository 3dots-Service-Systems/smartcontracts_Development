// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

contract b2mapph {
    address superadmin;

    //The Super admin is the Contract Deployer.
    constructor() {
        superadmin = msg.sender;
        allAdmins.push(superadmin);
        isAdmin[superadmin] = true;
    }

    //Debuging start - vars
    address public lastPatient;
    uint public totalTestCount;
    bhData public lastTest;

    // Debug Functions

    function bulkdata(bhData[] memory data) public adminCheck {
        for (uint i = 0; i < data.length; i++) {
            userTests[msg.sender].push(data[i]);
        }
    }

    function bulk1PatientData(address patients, bhData[] memory data) public adminCheck {
        for (uint i = 0; i < data.length; i++) {
            userTests[patients].push(data[i]);
        }
    }

    function bulkPatientData(address[] memory patients, bhData[] memory data) public adminCheck {
        for (uint i = 0; i < patients.length; i++) {
            userTests[patients[i]].push(data[i]);
        }
    }

    // Debug Finish
    address[] public allDocs; //Lists all registerd Doc Ids
    address[] public allAdmins; //Lists all registerd Admin Ids
    address[] public allHIS; //Lists all registerd HIS Ids
    mapping(address => bool) isAdmin; // Sets the specified address to Admin, Only SuperAdmin Can Change.
    mapping(address => bool) isDoc; // Sets the specified address to Doc, Only Admin Can Change.
    mapping(address => bool) isUser; // Sets the specified address to Patient.
    mapping(address => bool) isHIS; // Sets the specified address to HIS, Only SuperAdmin Can Change.

    //Blockchain Healtha Data Storage Format
    struct bhData {
        string tName;
        string tValue;
        uint ttime;
    }

    mapping(address => bhData[]) userTests; //All Tests mapped to Patient ID
    mapping(address => mapping(address => bool)) addViewer; // List of IDS The patient has Shared Data with.
    mapping(address => mapping(address => bool)) trustedSource; // List of trusted HIS that can add results to Patient Account

    modifier patientCheck() {
        //Checks if the user is a Patient.
        require(isUser[msg.sender] == true, "Please Register as Patient.");
        _;
    }
    modifier docCheck() {
        //Checks if the user is a Doctor.
        require(isDoc[msg.sender] == true, "Please Register as a doctor.");
        _;
    }
    modifier adminCheck() {
        //Checks if the user is an Admin.
        require(
            isAdmin[msg.sender] == true,
            "This Feature is only for admins."
        );
        _;
    }
    modifier HISCheck() {
        //Checks if the user is a HIS.
        require(isHIS[msg.sender] == true, "This Feature is only for HIS.");
        _;
    }
    event newPatient(address indexed ke, uint kkhon);
    event newDoc(address indexed ke, uint kkhon, address indexed ApprovedBy);
    event newAdmin(address indexed ke, uint kkhon);
    event newHIS(address indexed ke, uint kkhon);
    event newTest(address indexed ke, uint kkhon);
    event wrongCall(address indexed ke, bytes ki);
    event dataShared(address indexed patient, address indexed doc);
    event dataViewedByDoc(address indexed doc, uint kokhon);
    event dataSharingTurnedOff(
        address indexed doc,
        address indexed patient,
        uint kokhon
    );

    //First Function called by Patient after registration before they can upload test data.
    function registerPatient() public {
        require(isAdmin[msg.sender] == false, "Admins cant be Patients!");
        require(isDoc[msg.sender] == false, "Docs Cant be Patients");
        isUser[msg.sender] = true;
        lastPatient = msg.sender;
        emit newPatient(msg.sender, block.timestamp);
    }

    // This function is called by SuperAdmin to set an ID to admin. (The Contract Deployer is the SuperAdmin).
    function addAdmin(address admin) public {
        require(msg.sender == superadmin,"Only Super Admin can approve Admin Accounts");
        require(isUser[admin] == false, "Patients cant be Admins!");
        require(isDoc[admin] == false, "Docs Cant be Patients");
        isAdmin[admin] = true;
        allAdmins.push(admin);
        emit newAdmin(admin, block.timestamp);
    }

    //Function to add a doctor. Only callable by Admin/SuperAdmin
    function registerDoc(address docid) public adminCheck {
        require(isAdmin[docid] == false, "Admins cant be Docs!");
        require(isUser[docid] == false, "Patients cant be Docs!");
        isDoc[docid] = true;
        allDocs.push(docid);
        emit newDoc(docid, block.timestamp, msg.sender);
    }

    //Function to add a Hospital. Only callable by Admin/SuperAdmin
    function addHIS(address HIS) public {
        require(msg.sender == superadmin,"Only Super Admin can approve HIS Accounts");
        require(isUser[HIS] == false, "Patients cant be HIS!");
        require(isDoc[HIS] == false, "Docs Cant be HIS");
        require(isAdmin[HIS] == false, "Admins cant be HIS!");
        isHIS[HIS] = true;
        allHIS.push(HIS);
        emit newHIS(HIS, block.timestamp);
    }

    //Function to add Test results. Only callable by Patient. The String will be processed on the front end.
    function addTest(string memory _tName, string memory _data, uint _time) public patientCheck {
        bhData memory nTest = bhData(_tName, _data, _time);
        userTests[msg.sender].push(nTest);
        lastTest = nTest;
        totalTestCount++;
        emit newTest(msg.sender, block.timestamp);
    }

    // This function is called by the Hospital to add a patient Health record to Patients Array of results.
    function HISaddTest(address patient,string memory _tName,string memory _data,uint _time) public HISCheck {
        require(isUser[patient] == true, "Invalid Patient ID Provided");
        require(trustedSource[patient][msg.sender] == true,"The Patient has not allowed you to post DATA");
        bhData memory nTest = bhData(_tName, _data, _time);
        userTests[patient].push(nTest);
        userTests[patient].push(nTest);
        lastTest = nTest;
        totalTestCount++;
        emit newTest(patient, block.timestamp);
    }

    // For Patient to see a single result using a result id.
    function seeAResult(uint Tid) public view patientCheck returns (bhData memory) {
        return userTests[msg.sender][Tid];
    }

    // For Patient to call his own all records
    function seeAllResults()public view patientCheck returns (bhData[] memory){
        return userTests[msg.sender];
    }

    // For Patient to see how many records he has in total.
    function toTalnumberOfResults() public view patientCheck returns (uint) {
        return userTests[msg.sender].length;
    }

    // For Patient to share data with viewer, viewer id mus be inseted.
    function addviewer(address docid) public patientCheck {
        require(isDoc[docid] == true, "The provided id is not a Doctor.");
        addViewer[msg.sender][docid] = true;
        emit dataShared(msg.sender, docid);
    }

    // For Patient to remove a viewer from allowed viewers;
    function removeViewer(address docid) public patientCheck {
        require(addViewer[msg.sender][docid] == true,"Doc is not in your share list.");
        addViewer[msg.sender][docid] = false;
        emit dataSharingTurnedOff(docid, msg.sender, block.timestamp);
    }

    // For Patient to allow a certain Source for posting on his behalf.
    function addTrustedSource(address his) public patientCheck {
        require(isHIS[his] == true, "The provided id is not a Hospital.");
        trustedSource[msg.sender][his] = true;
    }

    // For Patient to remove a certain Source for posting on his behalf.
    function removeTrustedSource(address his) public patientCheck {
        require(isHIS[his] == true, "The provided id is not a Hospital.");
        require(trustedSource[msg.sender][his] = true,"The Provide HIS Id is not in your Trusted List");
        trustedSource[msg.sender][his] = false;
    }

    // For Viewer to see patient record.
    function seePatientRecord(address patientId,uint testId) public docCheck returns (bhData memory) {
        require(addViewer[patientId][msg.sender] == true,"Patient hasn`t Shared.");
        emit dataViewedByDoc(msg.sender, block.timestamp);
        return userTests[patientId][testId];
    }

    //For Viewer to remove self from shared list of the patient.
    function removePatient(address patientId) public docCheck {
        require(addViewer[patientId][msg.sender] == true,"Patient has not shared data with you.");
        addViewer[patientId][msg.sender] = false;
        emit dataSharingTurnedOff(msg.sender, patientId, block.timestamp);
    }

    // For SuperAdmin to reset all status of a user to null.
    function resetUser(address id) public {
        require(msg.sender == superadmin,"Only Super Admin can Reset Accounts");
        if (isAdmin[id] = true) {
            isAdmin[id] = false;
        } else if (isDoc[id] = true) {
            isDoc[id] = false;
        } else {
            isUser[id] = false;
        }
    }

    // If anyone /or any function calles a awrong function then its handled by fall back function.
    fallback() external {
        emit wrongCall(msg.sender, msg.data);
    }

    receive() external payable {}
}
