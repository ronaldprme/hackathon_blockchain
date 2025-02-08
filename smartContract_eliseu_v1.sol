// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SmartPayConstruction {
    string public agencyId = "agency";

    struct Stage {
        string stage_id;
        string title; // IPFS link ID that contains the description
        string description; // IPFS link ID that contains the description
        string validation_steps; // IPFS link ID that contains the description
        uint256 value; // value to pay based on currency
        string[] validators_ids; // List of validors that need to approve the milestone
        string[] validations; // List of validators that already validated
        uint256 totalValidators; // Number of validators for this stage
        uint256   amountToValidator; //The total ammount that we should pay to the validator
        bool completed;
    }

    /*


[[["stage1","Design Phase","QmHashDescription1","QmHashSteps1",1000,["Validator1","Validator2"],["Validator1"],2,500,false],["stage2","Implementation Phase","QmHashDescription2","QmHashSteps2",2000,["Validator3","Validator4"],[],2,1000,false]]

[["Design Phase","QmHashDescription1","QmHashSteps1",1000,["Validator1","Validator2"],["Validator1"],false],["Implementation Phase","QmHashDescription2","QmHashSteps2",2000,["Validator3","Validator4"],[],false]]

[["id1","Design Phase","QmHashDescription1","QmHashSteps1",1000,["Validator1","Validator2"],["Validator1"],false],["id2","Implementation Phase","QmHashDescription2","QmHashSteps2",2000,["Validator3","Validator4"],[],false]]
 */

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

    mapping(string => Project) public projects;
    string[] public projectIds;

    event StageAdded(
        uint256 projectId,
        uint256 stageId,
        string description,
        uint256 value
    );
    event StageValidated(
        uint256 projectId,
        uint256 stageId,
        string validatorID
    );
    event ProjectClosed(uint256 id);
    event PaymentProcessed(uint256 projectId, uint256 stageId, uint256 amount);

    function createProject(
        string memory _project_id,
        string memory _name,
        string memory _description,
        string memory _client_id,
        string memory _contractor,
        uint256 _startDate,
        uint256 _endDate,
        Stage[] memory _stages
    ) external {
        Project storage p = projects[_project_id];
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
        projectIds.push(_project_id);

        for (uint256 i = 0; i < _stages.length; i++) {
            p.stages.push(_stages[i]);
        }
    }

    function getStageById(string memory projectId, string memory stageId)
        public
        view
        returns (Stage memory s, bool found)
    {
        Project memory selectedProject = projects[projectId];

        Stage memory tmpStage;

        for (uint256 i = 0; i < selectedProject.stages.length; i++) {
            tmpStage = selectedProject.stages[i];

            if (compareStrings(stageId, tmpStage.stage_id)) {
                return (tmpStage, true);
            }
        }

        revert("Stage not found");
    }

    function getStagesCount(string memory projectId) external view returns(uint256) {
        return projects[projectId].stages.length;
    }

    function addStage(
        string memory projectId,
        Stage memory _stage
    ) external {
        projects[projectId].stages.push(_stage);
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function validateStage(
        uint256 projectId,
        uint256 stageId,
        string memory validatorID
    ) external {
        emit StageValidated(projectId, stageId, validatorID);
    }

    function processPendingPayments(uint256 projectId, uint256 stageId)
        external
    {}

    function closeProject(uint256 projectId) external {}

    function getProjectDetails(uint256 projectId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            bool
        )
    {}

    function getProjectWithStages(uint256 projectId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            bool,
            uint256[] memory,
            string[] memory
        )
    {}

    function getAllProjectIds() external view returns (string[] memory) {
        return projectIds;
    }

    function getProjectsCount() external view returns (uint256) {
        return projectIds.length;
    }
}