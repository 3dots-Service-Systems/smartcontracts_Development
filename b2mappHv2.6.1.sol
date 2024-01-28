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
    hdata public lastTest;

    // Debug Finish
    address[] public allDocs; //Lists all registerd Doc Ids
    address[] public allAdmins; //Lists all registerd Admin Ids
    address[] public allHIS; //Lists all registerd HIS Ids
    mapping(address => bool) isAdmin; // Sets the specified address to Admin, Only SuperAdmin Can Change.
    mapping(address => bool) isDoc; // Sets the specified address to Doc, Only Admin Can Change.
    mapping(address => bool) isUser; // Sets the specified address to Patient.
    mapping(address => bool) isHIS; // Sets the specified address to HIS, Only SuperAdmin Can Change.

    struct hdata {
        string ttype;
        string data;
        uint ttime;
    }
    mapping(address => hdata[]) userTests; //All Tests mapped to Patient ID
    mapping(address => mapping(address => bool)) sharedTests; // List of IDS The patient has Shared Data with.
    mapping(address => mapping(address => bool)) trustedHIS; // List of trusted HIS that can add results to Patient Account

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
        require(isAdmin[msg.sender] == true,"This Feature is only for admins.");
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
    event dataSharingTurnedOff(address indexed doc,address indexed patient,uint kokhon);

    // 01 First Function called by Patient after registration before they can upload test data.
    function registerPatient() public {
        require(isAdmin[msg.sender] == false, "Admins cant be Patients!");
        require(isDoc[msg.sender] == false, "Docs Cant be Patients");
        require(isHIS[msg.sender] == false, "Sources cant be Patients");
        isUser[msg.sender] = true;
        lastPatient = msg.sender;
        emit newPatient(msg.sender, block.timestamp);
    }

    // 02 This function is called by SuperAdmin to set an ID to admin. (The Contract Deployer is the SuperAdmin).
    function addAdmin(address admin) public {
        require(msg.sender == superadmin, "Only Super Admin can approve Admin Accounts");
        require(isUser[admin] == false, "Patients cant be Admins!");
        require(isDoc[admin] == false, "Docs Cant be Patients");
        require(isHIS[msg.sender] == false, "Sources cant be Admins");
        isAdmin[admin] = true;
        allAdmins.push(admin);
        emit newAdmin(admin, block.timestamp);
    }

    // 03 Function to add a doctor. Only callable by Admin/SuperAdmin
    function registerDoc(address docid) public adminCheck {
        require(isAdmin[docid] == false, "Admins cant be Docs!");
        require(isUser[docid] == false, "Patients cant be Docs!");
        require(isHIS[msg.sender] == false, "Sources cant be Docs");
        isDoc[docid] = true;
        allDocs.push(docid);
        emit newDoc(docid, block.timestamp, msg.sender);
    }

    // 04 Function to add a Hospital. Only callable by Admin/SuperAdmin
    function addHIS(address HIS) public {
        require(msg.sender == superadmin,"Only Super Admin can approve HIS Accounts");
        require(isUser[HIS] == false, "Patients cant be HIS!");
        require(isDoc[HIS] == false, "Docs Cant be HIS");
        require(isAdmin[HIS] == false, "Admins cant be HIS!");
        isHIS[HIS] = true;
        allHIS.push(HIS);
        emit newHIS(HIS, block.timestamp);
    }

    // 05 Function to add Test results. Only callable by Patient. The String will be processed on the front end.
    function addTest(string memory _ttype,string memory _data,uint _time) public patientCheck {
        hdata memory nTest = hdata(_ttype, _data, _time);
        userTests[msg.sender].push(nTest);
        lastTest = nTest;
        totalTestCount++;
        emit newTest(msg.sender, block.timestamp);
    }

    // 06 This function is called by the Hospital to add a patient Health record to Patients Array of results.
    function HISaddTest(address patient,string memory _ttype,string memory _data,uint _time) public HISCheck {
        require(isUser[patient] == true, "Invalid Patient ID Provided");
        require(trustedHIS[patient][msg.sender] == true, "The Patient has not allowed you to post DATA");
        hdata memory nTest = hdata(_ttype, _data, _time);
        userTests[patient].push(nTest);
        userTests[patient].push(nTest);
        lastTest = nTest;
        totalTestCount++;
        emit newTest(patient, block.timestamp);
    }

    // 07 For Patient to see a single result using a result id.
    function seeAResult(
        uint Tid
    ) public view patientCheck returns (hdata memory) {
        return userTests[msg.sender][Tid];
    }

    // 08 For Patient to call his own all records
    function seeAllResults() public view patientCheck returns (hdata[] memory) {
        return userTests[msg.sender];
    }

    // 09 For Patient to see how many records he has in total.
    function toTalnumberOfResults() public view patientCheck returns (uint) {
        return userTests[msg.sender].length;
    }

    // 10 For Patient to share data with viewer, viewer id mus be inseted.
    function shareTest(address docid) public patientCheck {
        require(isDoc[docid] == true, "The provided id is not a Doctor.");
        sharedTests[msg.sender][docid] = true;
        emit dataShared(msg.sender, docid);
    }

    // 11 For Patient to allow a certain Source for posting on his behalf.
    function addTrustedHIS(address his) public patientCheck {
        require(isHIS[his] == true, "The provided id is not a Hospital.");
        trustedHIS[msg.sender][his] = true;
    }

    // 12 For Patient to remove a certain Source for posting on his behalf.
    function removeTrustedHIS(address his) public patientCheck {
        require(isHIS[his] == true, "The provided id is not a Hospital.");
        require(trustedHIS[msg.sender][his] = true,"The Provide HIS Id is not in your Trusted List");
        trustedHIS[msg.sender][his] = false;
    }

    // 13 For Viewer to see patient record.
    function seePatientRecord(address patientId,uint testId) public docCheck returns (hdata memory) {
        require(sharedTests[patientId][msg.sender] == true,"Patient has not Shared.");
        emit dataViewedByDoc(msg.sender, block.timestamp);
        return userTests[patientId][testId];
    }

    // 14 for patient to remove a viewer from allowed viewers;
    function removeDoc(address docid) public patientCheck {
        require(sharedTests[msg.sender][docid] == true,"Doc is not in your share list.");
        sharedTests[msg.sender][docid] = false;
        emit dataSharingTurnedOff(docid, msg.sender, block.timestamp);
    }

    // 15 For Viewer to remove self from shared list of the patient.
    function removePatient(address patientId) public docCheck {
        require(sharedTests[patientId][msg.sender] == true,"Patient has not shared data with you.");
        sharedTests[patientId][msg.sender] = false;
        emit dataSharingTurnedOff(msg.sender, patientId, block.timestamp);
    }

    // 16 For SuperAdmin to reset all status of a user to null.
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

    // 17 If anyone /or any function calles a awrong function then its handled by fall back function.
    fallback() external {
        emit wrongCall(msg.sender, msg.data);
    }
    // 18 
    receive() external payable {}
}
