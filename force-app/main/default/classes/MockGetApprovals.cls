@isTest
global class MockGetApprovals {
    @AuraEnabled(cacheable=true)
    global static List<Map<String, Object>> getApprovalProcessesMock() {
        List<Map<String, Object>> mockedData = new List<Map<String, Object>>();

        Map<String, Object> mockApproval1 = new Map<String, Object>{
            'id' => 'MockStepId1',
            'approvalProcessName' => 'Margin Approval',
            'recordName' => 'Mock Record 1',
            'targetObjectId' => '001000000000000AAA',
            'status' => 'Pending',
            'createdDate' => Date.today(),
            'stepStatus' => 'Pending',
            'originalActorId' => 'MockOriginalActorId1',
            'actorId' => 'MockActorId1',
            'comments' => 'Mock Comment 1',
            'stepCreatedDate' => Date.today(),
            'submittedByName' => 'Test User',
            'workItemId' => 'MockWorkItemId1',
            'workItemUrl' => 'https://mockurl.com/MockWorkItemId1'
        };

        Map<String, Object> mockApproval2 = new Map<String, Object>{
            'id' => 'MockStepId2',
            'approvalProcessName' => 'PO Approved to Send',
            'recordName' => 'Mock Record 2',
            'targetObjectId' => '001000000000001BBB',
            'status' => 'Pending',
            'createdDate' => Date.today(),
            'stepStatus' => 'Pending',
            'originalActorId' => 'MockOriginalActorId2',
            'actorId' => 'MockActorId2',
            'comments' => 'Mock Comment 2',
            'stepCreatedDate' => Date.today(),
            'submittedByName' => 'Test User',
            'workItemId' => 'MockWorkItemId2',
            'workItemUrl' => 'https://mockurl.com/MockWorkItemId2'
        };

        mockedData.add(mockApproval1);
        mockedData.add(mockApproval2);

        return mockedData;
    }

    // Wrapper for the getRecordName method to make it accessible in tests
    @TestVisible
    global static String getRecordNameWrapper(Id recordId) {
        return GetApprovals.getRecordName(recordId);
    }
}
