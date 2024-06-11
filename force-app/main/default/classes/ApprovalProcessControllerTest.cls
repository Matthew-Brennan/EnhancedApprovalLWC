@isTest
private class ApprovalProcessControllerTest {

    @TestSetup
    static void createTestData(){
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
            Name = 'Test1 Opportunity',
            CloseDate = Date.today() + 30,
            StageName = 'Quote Generated',
            OwnerId = submittedByUser.Id // to enter the approval process the ownerID  should be the created temp user

        );
        insert opp;

        Opportunity opp2 = new Opportunity(
            Name = 'Test2 Opportunity',
            CloseDate = Date.today() + 30,
            StageName = 'Vendor PO Generated',
            OwnerId = submittedByUser.Id
        );
        insert opp2;


        Approval.ProcessSubmitRequest req1 = 
        new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(opp.Id);
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(submittedByUser.Id); 

        // Skip the criteria evaluation for the specified process
        req1.setSkipEntryCriteria(true);
        
        // Submit the record to the existing process named PTO_Reqwuest_Process
        req1.setProcessDefinitionNameOrId('Margin_Approval');
           
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        //create second approval
        Approval.ProcessSubmitRequest req2 = 
        new Approval.ProcessSubmitRequest();

        req2.setComments('Submitting request for approval2.');
        req2.setObjectId(opp2.Id);
        
        // Submit on behalf of a specific submitter
        req2.setSubmitterId(submittedByUser.Id); 

        // Skip the criteria evaluation for the specified process
        req2.setSkipEntryCriteria(true);
        
        // Submit the record to the existing process named PTO_Reqwuest_Process
        req2.setProcessDefinitionNameOrId('PO_Approved_to_Send');
        
        
        // Submit the approval request for the account
        Approval.ProcessResult result2 = Approval.process(req2);

        //submit the first approval request
        System.assert(result.isSuccess(), 'First approval request failed: ' + result.getErrors());

    }

   

@isTest
    static void testApproveAction() {
        createTestData();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test2 Opportunity' LIMIT 1];
        ProcessInstance processInstance = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opp.Id LIMIT 1];
        Id workItemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstance.Id LIMIT 1].Id;
        

        
        Test.startTest();
        // Call the approveAction method
        ApprovalProcessController.approveAction(workItemId);
        Test.stopTest();

        List<ProcessInstance> processInstances = [SELECT Id, Status FROM ProcessInstance WHERE Id = :processInstance.Id LIMIT 1];

        // Assert that the rejection was successful and the process instance status is "Approved"
        System.assertEquals(1, processInstances.size(), 'Expected one ProcessInstance record');
        System.assertEquals('Approved', processInstances[0].Status, 'Expected ProcessInstance status to be "Approved"');
    }


@isTest
    static void testRejectAction() {
        createTestData();
        // Create a test ProcessInstanceWorkitem
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test2 Opportunity' LIMIT 1];
        ProcessInstance processInstance = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opp.Id LIMIT 1];
        Id workItemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstance.Id LIMIT 1].Id;
        
        // Call the rejectAction method
        Test.startTest();
        ApprovalProcessController.rejectAction(workItemId);
        Test.stopTest();

        // Retrieve the ProcessInstance record
        List<ProcessInstance> processInstances = [SELECT Id, Status FROM ProcessInstance WHERE Id = :processInstance.Id LIMIT 1];

        // Assert that the rejection was successful and the process instance status is "Rejected"
        System.assertEquals(1, processInstances.size(), 'Expected one ProcessInstance record');
        System.assertEquals('Rejected', processInstances[0].Status, 'Expected ProcessInstance status to be "Rejected"');
    }
}