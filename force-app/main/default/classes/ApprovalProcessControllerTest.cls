@isTest
private class ApprovalProcessControllerTest {

@isTest
    static void testApproveAction() {
        // Create a test ProcessInstanceWorkitem
        ProcessDefinition processDefinition = [SELECT Id FROM ProcessDefinition WHERE DeveloperName = 'Sample_Process' LIMIT 1];
        ProcessInstance processInstance = new ProcessInstance(
            TargetObjectId = createTestAccount().Id,
            ProcessDefinitionId = processDefinition.Id
        );
        insert processInstance;
        List<ProcessInstanceWorkitem> workitems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstance.Id];

        Test.startTest();

        // Call the approveAction method
        ApprovalProcessController.approveAction(workitems[0].Id);

        Test.stopTest();

        // Assert that the approval is successful
        System.assertEquals(1, [SELECT count() FROM ProcessInstance WHERE TargetObjectId = :processInstance.TargetObjectId AND Status = 'Approved']);
    }
@isTest
    static void testRejectAction() {
        // Create a test ProcessInstanceWorkitem
        ProcessInstance processInstance = [SELECT Id FROM ProcessInstance LIMIT 1];
        ProcessInstanceWorkitem workitem = new ProcessInstanceWorkitem(ProcessInstanceId = processInstance.Id);

        // Insert the record to populate the Id field
        insert workitem;

        // Call the rejectAction method
        Test.startTest();
        ApprovalProcessController.rejectAction(workitem.Id);
        Test.stopTest();

        // Retrieve the ProcessInstance record
        List<ProcessInstance> processInstances = [SELECT Id, Status FROM ProcessInstance WHERE Id = :processInstance.Id LIMIT 1];

        // Assert that the rejection was successful and the process instance status is "Rejected"
        System.assertEquals(1, processInstances.size(), 'Expected one ProcessInstance record');
        System.assertEquals('Rejected', processInstances[0].Status, 'Expected ProcessInstance status to be "Rejected"');
    }
}