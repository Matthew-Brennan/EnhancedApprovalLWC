@isTest
public class GetApprovalsTest {
    @testSetup
    static void setupTestData() {
        // Create a unique username by appending a timestamp
        String uniqueUsername = 'testuser_' + DateTime.now().getTime() + '@example.com';

        // Create Users
        User submittedByUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = uniqueUsername,
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert submittedByUser;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today() + 30,
            StageName = 'Quote Generated'
        );
        insert opp;

        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today() + 30,
            StageName = 'Vendor PO Generated'
        );
        insert opp2;


        Approval.ProcessSubmitRequest req1 = 
        new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(opp.id);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(submittedByUser.Id); 

        // Skip the criteria evaluation for the specified process
        req1.setSkipEntryCriteria(true);
        
        // Submit the record to the existing process named PTO_Reqwuest_Process
        req1.setProcessDefinitionNameOrId('Margin_Approval');
        

        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        // Verify the result
        System.assert(result.isSuccess());


        Approval.ProcessSubmitRequest req2 = 
        new Approval.ProcessSubmitRequest();

        req2.setComments('Submitting request for approval2.');
        req2.setObjectId(opp2.id);
        
        // Submit on behalf of a specific submitter
        req2.setSubmitterId(submittedByUser.Id); 

        // Skip the criteria evaluation for the specified process
        req2.setSkipEntryCriteria(true);
        
        // Submit the record to the existing process named PTO_Reqwuest_Process
        req2.setProcessDefinitionNameOrId('PO_Approved_to_Send');
        
        
        // Submit the approval request for the account
        Approval.ProcessResult result2 = Approval.process(req2);
        
        // Verify the result
        System.assert(result.isSuccess());

//         //dynamically get a processDefinitionID
//         Id processDefinitionId = [SELECT Id FROM ProcessDefinition LIMIT 1].Id;
//         Id processDefinitionId2 = [SELECT Id FROM ProcessDefinition LIMIT 1].Id;


//         // Create ProcessInstances without ProcessDefinitionId
//         ProcessInstance processInstance1 = new ProcessInstance(
//             TargetObjectId = opp.Id,
//             Status = 'Pending',
//             ProcessDefinitionId = processDefinitionId, // Add Process Definition Id here
//             //CurrentNodeId = 'DummyNodeId1', // Add a dummy value for CurrentNodeId
//             SubmittedById = submittedByUser.Id
//         );
//         ProcessInstance processInstance2 = new ProcessInstance(
//             TargetObjectId = opp.Id,
//             Status = 'Pending',
//             ProcessDefinitionId = processDefinitionId, // Add Process Definition Id here
//             //CurrentNodeId = 'DummyNodeId2', // Add a dummy value for CurrentNodeId
//             SubmittedById = submittedByUser.Id
// );
//         insert new List<ProcessInstance>{processInstance1, processInstance2};

//         // Create ProcessInstanceSteps
//         ProcessInstanceStep step1 = new ProcessInstanceStep(
//             ProcessInstanceId = processInstance1.Id,
//             StepStatus = 'Pending',
//             OriginalActorId = submittedByUser.Id,
//             ActorId = submittedByUser.Id,
//             Comments = 'Test Comment 1'
//            // 
            
//         );
//         ProcessInstanceStep step2 = new ProcessInstanceStep(
//             ProcessInstanceId = processInstance2.Id,
//             StepStatus = 'Pending',
//             OriginalActorId = submittedByUser.Id,
//             ActorId = submittedByUser.Id,
//             Comments = 'Test Comment 2'
//            // CurrentNodeId = [SELECT Id FROM ProcessNode LIMIT 1].Id
//         );
//         insert new List<ProcessInstanceStep>{step1, step2};

//         // Create ProcessInstanceWorkitems
//         ProcessInstanceWorkitem workitem1 = new ProcessInstanceWorkitem(
//             ProcessInstanceId = processInstance1.Id
//         );
//         ProcessInstanceWorkitem workitem2 = new ProcessInstanceWorkitem(
//             ProcessInstanceId = processInstance2.Id
//         );
//         insert new List<ProcessInstanceWorkitem>{workitem1, workitem2};
    }

    @isTest
    static void testGetApprovalProcesses() {
        Test.startTest();
        List<Map<String, Object>> results = GetApprovals.getApprovalProcesses();
        Test.stopTest();

        System.debug(results);
        // Verify results
        System.assertEquals(2, results.size(), 'Expected 2 approval processes');

        Map<String, Object> result1 = results[0];
        Map<String, Object> result2 = results[1];

        // Check first result
        System.assertEquals('Margin Approval', result1.get('approvalProcessName'), 'Approval process name mismatch');
        System.assertEquals('Test User', result1.get('submittedByName'), 'Submitted by name mismatch');
        System.assertNotEquals('', result1.get('workItemUrl'), 'Work item URL should not be empty');

        // Check second result
        System.assertEquals('PO Approved to Send', result2.get('approvalProcessName'), 'Approval process name mismatch');
        System.assertEquals('Test User', result2.get('submittedByName'), 'Submitted by name mismatch');
        System.assertNotEquals('', result2.get('workItemUrl'), 'Work item URL should not be empty');
    }

    @isTest
    static void testGetRecordName() {
        // Use an existing User record to test getRecordName
        User testUser = [SELECT Id, Name FROM User LIMIT 1];

        String recordName = MockGetApprovals.getRecordNameWrapper(testUser.Id);
        System.assertEquals(testUser.Name, recordName, 'Record name mismatch');
    }

    // @isTest
    // static void testGetRecordNameWithInvalidId() {
    //     // Testing getRecordName with null Id
    //     String recordName = MockGetApprovals.getRecordNameWrapper(null);
    //     System.assertEquals('', recordName, 'Expected empty string for null Id');
    // }

    // @isTest
    // static void testGetRecordNameWithNonExistentRecord() {
    //     // Testing getRecordName with non-existent Id
    //     Id nonExistentId = Id.valueOf('001000000000000AAA'); // Assuming this ID does not exist
    //     String recordName = MockGetApprovals.getRecordNameWrapper(nonExistentId);
    //     System.assertEquals('', recordName, 'Expected empty string for non-existent Id');
    // }

}