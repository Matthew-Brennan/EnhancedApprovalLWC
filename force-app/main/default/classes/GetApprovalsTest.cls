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
            StageName = 'Quote Generated',
            OwnerId = submittedByUser.Id // to enter the approval process the ownerID  should be the created temp user

        );
        insert opp;

        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity',
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
    static void testGetApprovalProcesses() {
        Test.startTest();
        List<Map<String, Object>> results = GetApprovals.getApprovalProcesses();
        Test.stopTest();

        System.debug('Approval Processes: ' + results);

        // Verify results
        System.assertEquals(1, results.size(), 'Expected 1 approval processes');

        Map<String, Object> result1 = results[0];


        // Check first result
        System.assertEquals('PO Approved to Send', result1.get('approvalProcessName'), 'Approval process name mismatch');
        System.assertEquals('Test User', result1.get('submittedByName'), 'Submitted by name mismatch');
        System.assertNotEquals('', result1.get('workItemUrl'), 'Work item URL should not be empty');
    }

    @isTest
    static void testGetRecordName() {
        // Use an existing User record to test getRecordName
        User testUser = [SELECT Id, Name FROM User LIMIT 1];

        String recordName = MockGetApprovals.getRecordNameWrapper(testUser.Id);
        System.assertEquals(testUser.Name, recordName, 'Record name mismatch');
    }

}