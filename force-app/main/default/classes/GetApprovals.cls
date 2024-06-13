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

        // Get ProcessInstances and Steps with Workitems where the approver is the current user
        List<ProcessInstance> processInstances = [
            SELECT Id, TargetObjectId, Status, CreatedDate, ProcessDefinitionId, SubmittedById,
                   (SELECT Id, StepStatus, OriginalActorId, ActorId, Comments, CreatedDate 
                    FROM Steps),
                   (SELECT Id, ProcessInstanceId 
                    FROM Workitems 
                    WHERE ActorId = :UserInfo.getUserId())
            FROM ProcessInstance
            WHERE Status IN ('Pending') AND Id IN (SELECT ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ActorId = :UserInfo.getUserId())
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


                Id recordId = processInstance.TargetObjectId;

                //get and build the data for an opportunity
                if (recordId != null && recordId.getSObjectType() == Opportunity.SObjectType) {
                    // Query the Name field from the record's object This works for Opps and Accounts
                   Opportunity opp = [SELECT Name, Total_Client_Sales_Price__c, Total_Actual_Margin__c, Total_Eastbay_Cost_New__c  FROM Opportunity  WHERE Id = :recordId LIMIT 1];

                   Map<String, Object> flattenedRecord = new Map<String, Object>{
                    'id' => step.Id,
                    'approvalProcessName' => processDefinitionName,
                    'recordName' => opp.Name,
                    'recordCost' => opp.Total_Eastbay_Cost_New__c,
                    'recordClientCost' => opp.Total_Client_Sales_Price__c,
                    'recordMargin' => opp.Total_Actual_Margin__c,
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

                 //get and build the data for an Case
                if (recordId != null && recordId.getSObjectType() == Case.SObjectType) {
                    // Query the Case
                    Case cs = [SELECT Subject FROM Case  WHERE Id = :recordId LIMIT 1];

                    Map<String, Object> flattenedRecord = new Map<String, Object>{
                        'id' => step.Id,
                        'approvalProcessName' => processDefinitionName,
                        'recordName' => cs.Subject,
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
        }
        return flattenedData;
    }

    // Method to get the name of the record based on its object type
    public static String getRecordName(Id recordId) {
        if (recordId != null && recordId.getSObjectType() != Case.SObjectType) {
            // Query the Name field from the record's object This works for Opps and Accounts
            String nameQuery = 'SELECT Name FROM ' + recordId.getSObjectType() + ' WHERE Id = \'' + recordId + '\' LIMIT 1';
            SObject record = Database.query(nameQuery);
            if (record != null && record.get('Name') != null) {
                return String.valueOf(record.get('Name'));
            }
        } 
        //Cases dont have the name field so they need to be handled using Subject
        else if (recordId.getSObjectType() == Case.SObjectType) { 
            // Query the Subject field from the Case object
            Case record = [SELECT Subject FROM Case WHERE Id = :recordId LIMIT 1];
            if (record != null && record.Subject != null) {
                return record.Subject;
            }
        }
        return '';
    }
}
