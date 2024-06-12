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

        // Create Opportunities
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            CloseDate = Date.today() + 30,
            StageName = 'Quote Generated',
            OwnerId = submittedByUser.Id
        );
        insert opp1;

        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            CloseDate = Date.today() + 30,
            StageName = 'Vendor PO Generated',
            OwnerId = submittedByUser.Id
        );
        insert opp2;

        // Submit the first approval process
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(opp1.Id);
        req1.setSubmitterId(submittedByUser.Id);
        req1.setSkipEntryCriteria(true);
        req1.setProcessDefinitionNameOrId('Margin_Approval');
        

        Approval.ProcessResult result1 = Approval.process(req1);

        
        System.assert(result1.isSuccess(), 'First approval request failed: ' + result1.getErrors());

        // Submit the second approval process
        Approval.ProcessSubmitRequest req2 = new Approval.ProcessSubmitRequest();
        req2.setComments('Submitting request for approval2.');
        req2.setObjectId(opp2.Id);
        req2.setSubmitterId(submittedByUser.Id);
        req2.setSkipEntryCriteria(true);
        req2.setProcessDefinitionNameOrId('PO_Approved_to_Send');
        

        Approval.ProcessResult result2 = Approval.process(req2);


        System.assert(result2.isSuccess(), 'Second approval request failed: ' + result2.getErrors());

        // Retrieve and set the current user as the approver for both approval requests
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ActorId, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :new Set<Id>{result1.getInstanceId(), result2.getInstanceId()}];

        for (ProcessInstanceWorkitem workItem : workItems) {
            workItem.ActorId = UserInfo.getUserId(); // Set to the current test running user
        }
        update workItems;

        // Ensure the work items are updated correctly
        workItems = [SELECT Id, ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :new Set<Id>{result1.getInstanceId(), result2.getInstanceId()}];
        for (ProcessInstanceWorkitem workItem : workItems) {
            System.assertEquals(UserInfo.getUserId(), workItem.ActorId, 'Work item actor ID was not updated correctly.');
        }
    }

    @isTest
    static void testGetApprovalProcesses() {
        Test.startTest();
        List<Map<String, Object>> results = GetApprovals.getApprovalProcesses();
        Test.stopTest();

        System.debug('Approval Processes: ' + results);

        // Verify results
        System.assertEquals(8, results.size(), 'Expected 8 approval processes');

        // Map<String, Object> result1 = results[0];
        // Map<String, Object> result2 = results[1];

        // // Check first result
        // System.assertEquals('Margin Approval', result1.get('approvalProcessName'), 'Approval process name mismatch');
        // System.assertEquals('Test User', result1.get('submittedByName'), 'Submitted by name mismatch');
        // System.assertNotEquals('', result1.get('workItemUrl'), 'Work item URL should not be empty');

        // // Check second result
        // System.assertEquals('PO Approved to Send', result2.get('approvalProcessName'), 'Approval process name mismatch');
        // System.assertEquals('Test User', result2.get('submittedByName'), 'Submitted by name mismatch');
        // System.assertNotEquals('', result2.get('workItemUrl'), 'Work item URL should not be empty');
    }

    @isTest
    static void testGetRecordName() {
        // Use an existing User record to test getRecordName
        User testUser = [SELECT Id, Name FROM User LIMIT 1];

        String recordName = GetApprovals.getRecordName(testUser.Id);
        System.assertEquals(testUser.Name, recordName, 'Record name mismatch');
    }
}
