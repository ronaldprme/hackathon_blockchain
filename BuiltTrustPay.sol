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
        uint256 amountToValidator; //The total ammount that we should pay to the validator
        bool completed;
    }

    /*
    Exaple params stages:
    [[["stage1","Design Phase","QmHashDescription1","QmHashSteps1",1000,["Validator1","Validator2"],["Validator1"],2,500,false],["stage2","Implementation Phase","QmHashDescription2","QmHashSteps2",2000,["Validator3","Validator4"],[],2,1000,false]]
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

    event StageAdded(uint256 projectId, uint256 stageId, string description, uint256 value);
    event StageValidated(uint256 projectId, uint256 stageId, string validatorID);
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

            //by default the contractro is one of the entities allowed to validate
            //so techniclly the milestone / stages are validatd
            //when all the entities that are allowed to valdiate validate the stage
            p.stages[i].validators_ids.push(_contractor);
        }
    }

    function getStageById(string memory projectId, string memory stageId)
        public
        view
        returns (Stage memory s, bool found, uint256)
    {
        Project memory selectedProject = projects[projectId];

        Stage memory tmpStage;

        for (uint256 i = 0; i < selectedProject.stages.length; i++) {
            tmpStage = selectedProject.stages[i];

            if (compareStrings(stageId, tmpStage.stage_id)) {
                return (tmpStage, true, i);
            }
        }

        revert("Stage not found");
    }

    function getStagesCount(string memory projectId) external view returns (uint256) {
        return projects[projectId].stages.length;
    }

    function isStageValidatedByValidator(
        string memory _project_id,
        string memory _stage_id,
        string memory _validator_id
    ) public view returns (bool) {
        (Stage memory _stage,,) = getStageById(_project_id, _stage_id);

        for (uint256 i = 0; i < _stage.validations.length; i++) {
            //If already validated returns true
            if (compareStrings(_validator_id, _stage.validations[i])) {
                return true;
            }
        }

        return false;
    }

    function isValidatorAllowedToValidate(
        string memory _project_id,
        string memory _stage_id,
        string memory _validator_id
    ) public view returns (bool) {
        (Stage memory _stage,,) = getStageById(_project_id, _stage_id);

        for (uint256 i = 0; i < _stage.validators_ids.length; i++) {
            //If already validated returns true
            if (compareStrings(_validator_id, _stage.validators_ids[i])) {
                return true;
            }
        }

        return false;
    }

    function addValidator(string memory _project_id, string memory _stage_id, string memory _validator_id) public {
        Project storage _project = projects[_project_id];
        (,, uint256 stageIndex) = getStageById(_project_id, _project_id);

        Stage storage _stage = _project.stages[stageIndex];

        //vetify if the was already added
        require(isValidatorAllowedToValidate(_project_id, _stage_id, _validator_id), "validator was already added");

        //verify if we can still add validators if still there is not enough validators
        require(!isThereEnoughValidators(_project_id, _stage_id), "Already enough validators to validate the stage");

        _stage.validators_ids.push(_validator_id);
    }

    function isThereEnoughValidators(string memory _project_id, string memory _stage_id) public view returns (bool) {
        return getTotalValidators(_project_id, _stage_id) >= getMaxTotalValidators(_project_id, _stage_id);
    }

    function addValidators(string memory _project_id, string memory _stage_id, string[] memory _validators_ids)
        public
    {
        for (uint256 i = 0; i < _validators_ids.length; i++) {
            addValidator(_project_id, _stage_id, _validators_ids[i]);
        }
    }

    function validatorWasAlreadyAdded(string memory _project_id, string memory _stage_id, string memory _validator_id)
        public
        view
        returns (bool)
    {
        string[] memory valiators_ids = getValidatorsIds(_project_id, _stage_id);

        for (uint256 i = 0; i < valiators_ids.length; i++) {
            //If already validated returns true
            if (compareStrings(_validator_id, valiators_ids[i])) {
                return true;
            }
        }

        return false;
    }

    function getValidatorsIds(string memory _project_id, string memory _stage_id)
        public
        view
        returns (string[] memory)
    {
        (Stage memory _stage,,) = getStageById(_project_id, _stage_id);
        return _stage.validators_ids;
    }

    function getTotalValidators(string memory _project_id, string memory _stage_id) public view returns (uint256) {
        (Stage memory _stage,,) = getStageById(_project_id, _stage_id);
        return _stage.validations.length;
    }

    function getMaxTotalValidators(string memory _project_id, string memory _stage_id) public view returns (uint256) {
        (Stage memory _stage,,) = getStageById(_project_id, _stage_id);
        return _stage.totalValidators;
    }

    function addStage(string memory projectId, Stage memory _stage) external {
        projects[projectId].stages.push(_stage);
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function validateStage(string memory _project_id, string memory _stage_id, string memory _validator_id) external {
        Stage storage _stage;

        (,, uint256 stageIndex) = getStageById(_project_id, _stage_id);

        //get the proper stage from the selected project id
        _stage = projects[_project_id].stages[stageIndex];

        require(
            isValidatorAllowedToValidate(_project_id, _stage_id, _validator_id), "Validator is not allowed to validate"
        );

        // we add +1 because the contractor shoud validate a well
        require(_stage.validations.length < _stage.totalValidators + 1, "Already validated");

        //verify if validator alreadyvalidated the stage, if yes it should reert
        require(!isStageValidatedByValidator(_project_id, _stage_id, _validator_id), "Cant validate more than once");

        //validate the stage
        _stage.validations.push(_validator_id);
    }

    function processPendingPayments(uint256 projectId, uint256 stageId) external {}

    function closeProject(uint256 projectId) external {}

    function getAllProjectIds() external view returns (string[] memory) {
        return projectIds;
    }

    function getProjects() external view returns (Project[] memory) {
        Project[] memory _projects = new Project[](projectIds.length);
        for (uint256 i = 0; i < projectIds.length; i++) {
            _projects[i] = projects[projectIds[i]];
        }
        return _projects;
    }

    function getProjectsCount() external view returns (uint256) {
        return projectIds.length;
    }
}