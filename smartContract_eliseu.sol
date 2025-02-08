// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SmartPayConstruction {
    string public agencyId = "agency";
    uint256 numProjects= 0;

    struct Stage {
        string title; // IPFS link ID that contains the description
        string description; // IPFS link ID that contains the description
        string validation_steps; // IPFS link ID that contains the description
        uint256 value; // value to pay based on currency
        string[] validators_ids; // List of validors that need to approve the milestone
        string[] validations; // List of validators that already validated
        bool completed;
    }

    struct Project {
        string project_id;
        string name;
        string description;
        string client_id;
        string contractor;
        uint256 creationDate;
        uint256 startDate;
        uint256 endDate;
        uint256 actualCompletionDate;
        bool closed;
        Stage[] stages; // Modificado para array em vez de mapping
    }

    mapping(uint256 => Project) public projects;
    uint256[] public projectIds;

    event ProjectCreated(uint256 id, string name, string client, string contractor);
    event StageAdded(uint256 projectId, uint256 stageId, string description, uint256 value);
    event StageValidated(uint256 projectId, uint256 stageId, string validatorID);
    event ProjectClosed(uint256 id);
    event PaymentProcessed(uint256 projectId, uint256 stageId, uint256 amount);

    modifier onlyClient(uint256 projectId) {
        require(keccak256(bytes(projects[projectId].client_id)) == keccak256(bytes(agencyId)), "Only the client can perform this action");
        _;
    }

    modifier onlyValidator(uint256 projectId, uint256 stageId, string memory validatorID) {
        Stage storage stage = projects[projectId].stages[stageId];

        bool isValidator = false;
        for (uint256 i = 0; i < stage.validators_ids.length; i++) {
            if (keccak256(bytes(stage.validators_ids[i])) == keccak256(bytes(validatorID))) {
                isValidator = true;
                break;
            }
        }

        require(isValidator, "Not an authorized validator");
        _;
    }

    function createProject(
        string memory _project_id,
        string memory _name,
        string memory _description,
        string memory _client_id,
        string memory _contractor,
        uint256 _startDate,
        uint256 _endDate
        // Stage[] memory _stages
        ) external {
        uint256 projectId = numProjects++;
        Project storage p = projects[projectId];
        p.name = _name;
        p.description = _description;
        p.project_id = _project_id;
        p.client_id = _client_id;
        p.contractor = _contractor;
        p.creationDate = block.timestamp;
        p.startDate = _startDate;
        p.endDate = _endDate;
        p.closed = false;
        p.actualCompletionDate = 0;
        projectIds.push(projectId);

        /*for (uint256 i = 0; i < _stages.length; i++) {
            p.stages.push(_stages[i]);
        }*/

        emit ProjectCreated(projectId, _name, _client_id, _contractor);
    }

    function addStage(uint256 projectId, string memory _description, uint256 _value, string[] memory _validators_ids) external onlyClient(projectId) {
        Stage storage s = projects[projectId].stages.push();
        s.description = _description;
        s.value = _value;
        s.validators_ids = _validators_ids;
        s.completed = false;

        emit StageAdded(projectId, projects[projectId].stages.length - 1, _description, _value);
    }

    function validateStage(uint256 projectId, uint256 stageId, string memory validatorID)
        external
        onlyValidator(projectId, stageId, validatorID)
    {
 
        emit StageValidated(projectId, stageId, validatorID);
    }

    function processPendingPayments(uint256 projectId, uint256 stageId) external onlyClient(projectId) {
        Stage storage stage = projects[projectId].stages[stageId];
        require(stage.completed, "Stage is not completed");

        uint256 amount = stage.value;
        emit PaymentProcessed(projectId, stageId, amount);
    }

    function closeProject(uint256 projectId) external onlyClient(projectId) {
        projects[projectId].closed = true;
        emit ProjectClosed(projectId);
    }

    function getProjectDetails(uint256 projectId)
        external
        view
        returns (
            string memory, string memory, string memory, string memory, uint256, uint256, uint256, bool
        )
    {
        Project storage p = projects[projectId];
        return (p.name, p.description, p.client_id, p.contractor, p.creationDate, p.startDate, p.endDate, p.closed);
    }

    function getProjectWithStages(uint256 projectId)
        external
        view
        returns (
            string memory, string memory, string memory, string memory, uint256, uint256, uint256, bool, uint256[] memory, string[] memory
        )
    {
        Project storage p = projects[projectId];
        uint256 numStages = p.stages.length;
        uint256[] memory stageValues = new uint256[](numStages);
        string[] memory stageDescriptions = new string[](numStages);

        for (uint256 i = 0; i < numStages; i++) {
            stageValues[i] = p.stages[i].value;
            stageDescriptions[i] = p.stages[i].description;
        }

        return (p.name, p.description, p.client_id, p.contractor, p.creationDate, p.startDate, p.endDate, p.closed, stageValues, stageDescriptions);
    }

    function getAllProjectIds() external view returns (uint256[] memory) {
        return projectIds;
    }

    function getProjectsCount() external view returns (uint256) {
        return numProjects;
    }
}