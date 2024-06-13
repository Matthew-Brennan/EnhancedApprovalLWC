import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApprovals from '@salesforce/apex/GetApprovals.getApprovalProcesses';
import approveAction from '@salesforce/apex/ApprovalProcessController.approveAction';
import rejectAction from '@salesforce/apex/ApprovalProcessController.rejectAction';
import { refreshApex } from '@salesforce/apex';

export default class ApprovalCard extends LightningElement {
    @track approvalProcesses = [];
    wiredApprovalProcessesResult;

    @wire(getApprovals)
    wiredApprovalProcesses(result) {
        this.wiredApprovalProcessesResult = result;
        const { error, data } = result;
        if (data) {
            this.approvalProcesses = data.map(process => {
                const formattedDate = new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                }).format(new Date(process.createdDate));
                
                let { recordName, workItemUrl, workItemId, approvalProcessName, submittedByName, comments, ...rest } = process;
                let customData = {};
                console.log(approvalProcessName);
                switch (approvalProcessName) {
                    case 'Margin Approval':
                        customData = {
                            recordName,
                            approvalProcessName,
                            submittedByName,
                            comments,
                            workItemId,
                            workItemUrl,
                            createdDate: formattedDate,
                            customField1: 'Margin',
                            customField2: 'psas',
                        };
                        break;
                    case 'PO Approved to Send':
                        customData = {
                            recordName,
                            approvalProcessName,
                            submittedByName,
                            comments,
                            workItemId,
                            workItemUrl,
                            createdDate: formattedDate,
                            customField1: 'PO',
                            customField2: rest.anotherPOSpecificField,
                        };
                        break;
                    case 'Revert Sales Order to Sales Opp':
                        customData = {
                            recordName,
                            approvalProcessName,
                            submittedByName,
                            comments,
                            workItemId,
                            workItemUrl,
                            createdDate: formattedDate,
                            customField1: 'Revert',
                            customField2: rest.anotherRevertSpecificField,
                        };
                        break;
                    default:
                        customData = {
                            recordName,
                            approvalProcessName,
                            submittedByName,
                            comments,
                            workItemId,
                            workItemUrl,
                            createdDate: formattedDate,
                            customField1: 'Default',
                            customField2: rest.defaultField2,
                        };
                        break;
                }
                return customData;
            });
        } else if (error) {
            this.approvalProcesses = [];
            console.error('Error fetching approval processes:', error);
        }
    }

    handleButtonClick(event) {
        const actionName = event.target.name;
        const workItemId = event.target.dataset.workItemId;
        const approvalProcessName = event.target.dataset.processName;
        if (actionName === 'approve') {
            this.handleApprove(workItemId, approvalProcessName);
        } else if (actionName === 'reject') {
            this.handleReject(workItemId, approvalProcessName);
        }
    }

    handleApprove(workItemId, approvalProcessName) {
        approveAction({ processStepId: workItemId })
            .then(() => {
                this.showToast('Success', `${approvalProcessName} approved successfully`, 'success');
                return refreshApex(this.wiredApprovalProcessesResult);
            })
            .catch(error => {
                console.error(`Error approving ${approvalProcessName}:`, error);
                this.showToast('Error', `An error occurred while approving ${approvalProcessName}: ${error.body.message}`, 'error');
            });
    }

    handleReject(workItemId, approvalProcessName) {
        rejectAction({ processStepId: workItemId })
            .then(() => {
                this.showToast('Success', `${approvalProcessName} rejected successfully`, 'success');
                return refreshApex(this.wiredApprovalProcessesResult);
            })
            .catch(error => {
                console.error(`Error rejecting ${approvalProcessName}:`, error);
                this.showToast('Error', `An error occurred while rejecting ${approvalProcessName}: ${error.body.message}`, 'error');
            });
    }

    //requery for to refresh the data
    refreshData() {
        return refreshApex(this.wiredApprovalProcessesResult);
    }

    //Display the pop-up (toast) message with the success or error details
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}
