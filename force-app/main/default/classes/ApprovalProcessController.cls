public with sharing class ApprovalProcessController {
    
    @AuraEnabled
    public static void approveAction(String processStepId) {
        try {
            // Retrieve the ProcessInstanceWorkitem record related to the ProcessInstanceStep
            ProcessInstanceWorkitem workitem = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE Id = :processStepId LIMIT 1];

            // Check if a work item was found
            if (workitem == null) {
                throw new AuraHandledException('No ProcessInstanceWorkitem found for the given ID');
            }

            // Approve the ProcessInstanceWorkitem
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments('Approved via Lightning');
            req.setAction('Approve');
            req.setWorkitemId(workitem.Id);
            Approval.ProcessResult result = Approval.process(req);

            // Check if the approval was successful
            if (result.isSuccess()) {
                System.debug('Approval successful');
            } else {
                System.debug('Approval failed: ' + result.getErrors()[0].getMessage());
            }
        } catch (Exception e) {
            System.debug('An error occurred while approving: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while approving: ' + e.getMessage());
        }
    }
    

    @AuraEnabled
    public static void rejectAction(String processStepId) {
        try {
            // Retrieve the ProcessInstanceWorkitem record related to the ProcessInstanceStep
            ProcessInstanceWorkitem workitem = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE Id = :processStepId LIMIT 1];

            // Reject the ProcessInstanceWorkitem
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments('Rejected via Lightning');
            req.setAction('Reject');
            req.setWorkitemId(workitem.Id);
            Approval.ProcessResult result = Approval.process(req);

            // Check if the rejection was successful
            if (result.isSuccess()) {
                // Log success message
                System.debug('Rejection successful');
            } else {
                // Log error message
                System.debug('Rejection failed: ' + result.getErrors()[0].getMessage());
                throw new AuraHandledException('Rejection failed: ' + result.getErrors()[0].getMessage());
            }
        } catch (Exception e) {
            // Log error message
            System.debug('An error occurred while rejecting: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while rejecting: ' + e.getMessage());
        }
    }
}