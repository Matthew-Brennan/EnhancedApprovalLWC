public with sharing class GetApprovals {


    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getApprovalProcesses() {
        // Get the base URL from custom label
        String baseUrl = System.Label.BaseURL;

        // Get all ProcessDefinitions
        Map<Id, ProcessDefinition> processDefinitionMap = new Map<Id, ProcessDefinition>(
            [SELECT Id, Name FROM ProcessDefinition]
        );

        // Get all Users
        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, Name FROM User]
        );


        // Get ProcessInstances and Steps with Workitems
        List<ProcessInstance> processInstances = [
            SELECT Id, TargetObjectId, Status, CreatedDate, ProcessDefinitionId, SubmittedById,
                   (SELECT Id, StepStatus, OriginalActorId, ActorId, Comments, CreatedDate 
                    FROM Steps),
                   (SELECT Id, ProcessInstanceId  FROM Workitems)
            FROM ProcessInstance
            WHERE Status IN ('Pending')
        ];

        List<Map<String, Object>> flattenedData = new List<Map<String, Object>>();

        for (ProcessInstance processInstance : processInstances) {
            String processDefinitionName = processDefinitionMap.get(processInstance.ProcessDefinitionId).Name;
            String submittedByName = userMap.get(processInstance.SubmittedById) != null ? userMap.get(processInstance.SubmittedById).Name : '';


            for (ProcessInstanceStep step : processInstance.Steps) {
                // Handle Workitems
                String workItemId = '';
                if (processInstance.Workitems != null && !processInstance.Workitems.isEmpty()) {
                    for (ProcessInstanceWorkitem workitem : processInstance.Workitems) {
                        if (workitem.ProcessInstanceId == processInstance.Id) {
                            workItemId = workitem.Id;
                            break;
                        }
                    }
                }

                String recordName = getRecordName(processInstance.TargetObjectId);

                Map<String, Object> flattenedRecord = new Map<String, Object>{
                    'id' => step.Id,
                    'approvalProcessName' => processDefinitionName,
                    'recordName' => recordName,
                    'targetObjectId' => processInstance.TargetObjectId,
                    'status' => processInstance.Status,
                    'createdDate' => processInstance.CreatedDate,
                    'stepStatus' => step.StepStatus,
                    'originalActorId' => step.OriginalActorId,
                    'actorId' => step.ActorId,
                    'comments' => step.Comments,
                    'stepCreatedDate' => step.CreatedDate,
                    'submittedByName' => submittedByName,
                    'workItemId' => workItemId,
                    'workItemUrl' => workItemId != '' ? baseUrl + '/' + workItemId : ''
                };
                flattenedData.add(flattenedRecord);
            }
        }

        return flattenedData;
    }
        // Method to get the name of the record based on its object type
        public static String getRecordName(Id recordId) {
            if (recordId != null) {
                // Query the Name field from the record's object
                String nameQuery = 'SELECT Name FROM ' + recordId.getSObjectType() + ' WHERE Id = \'' + recordId + '\' LIMIT 1';
                SObject record = Database.query(nameQuery);
                if (record != null && record.get('Name') != null) {
                    return String.valueOf(record.get('Name'));
                }
            }
            return '';
        }
    }