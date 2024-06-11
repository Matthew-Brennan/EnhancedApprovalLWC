@isTest
public class ApprovalCardTest {
    @testSetup
    static void setupTestData() {
        // Setup test data for approval processes
        List<ApprovalProcess> approvalProcesses = new List<ApprovalProcess>();
        
        // Add different cases for testing
        approvalProcesses.add(new ApprovalProcess(
            Id = 'a001234567890123456',
            recordName = 'Test Record 1',
            workItemId = '0011I000007ZXOQQA4',
            approvalProcessName = 'Margin Approval',
            submittedByName = 'Test User 1',
            comments = 'Test Comments 1',
            createdDate = Date.today()
        ));
        approvalProcesses.add(new ApprovalProcess(
            Id = 'a001234567890123457',
            recordName = 'Test Record 2',
            workItemId = '0011I000007ZXOQQA5',
            approvalProcessName = 'PO Approved to Send',
            submittedByName = 'Test User 2',
            comments = 'Test Comments 2',
            createdDate = Date.today()
        ));
        // Insert other test cases as needed

        insert approvalProcesses;
    }

    @isTest
    static void testGetApprovals() {
        // Mock the getApprovals method in the GetApprovals class
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ApprovalProcessMock());
        List<ApprovalProcess> approvalProcesses = [SELECT Id, recordName, workItemId, approvalProcessName, submittedByName, comments, createdDate FROM ApprovalProcess];
        System.assertEquals(2, approvalProcesses.size());
        Test.stopTest();
    }

    @isTest
    static void testHandleApprove() {
        Test.startTest();
        ApprovalProcessController.approveAction('0011I000007ZXOQQA4');
        ApprovalCard lwc = new ApprovalCard();
        lwc.handleApprove('0011I000007ZXOQQA4', 'Margin Approval');
        Test.stopTest();
    }

    @isTest
    static void testHandleReject() {
        Test.startTest();
        ApprovalProcessController.rejectAction('0011I000007ZXOQQA5');
        ApprovalCard lwc = new ApprovalCard();
        lwc.handleReject('0011I000007ZXOQQA5', 'PO Approved to Send');
        Test.stopTest();
    }

    @isTest
    static void testErrorHandlingApprove() {
        Test.startTest();
        try {
            ApprovalProcessController.approveAction('InvalidId');
            System.assert(false, 'Expected an exception to be thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('An error occurred while approving'), 'Unexpected error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testErrorHandlingReject() {
        Test.startTest();
        try {
            ApprovalProcessController.rejectAction('InvalidId');
            System.assert(false, 'Expected an exception to be thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('An error occurred while rejecting'), 'Unexpected error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testShowToast() {
        Test.startTest();
        ApprovalCard lwc = new ApprovalCard();
        lwc.showToast('Test Title', 'Test Message', 'success');
        Test.stopTest();
    }

    @isTest
    static void testRefreshData() {
        Test.startTest();
        ApprovalCard lwc = new ApprovalCard();
        lwc.refreshData();
        Test.stopTest();
    }
}
