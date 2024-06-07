import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApprovals from '@salesforce/apex/GetApprovals.getApprovalProcesses';
import approveAction from '@salesforce/apex/ApprovalProcessController.approveAction';
import rejectAction from '@salesforce/apex/ApprovalProcessController.rejectAction';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';
//import reassignAction from '@salesforce/apex/ApprovalProcessController.reassignAction';

const actions = [
    { label: 'Approve', name: 'approve' },
    { label: 'Reject', name: 'reject' },
   // { label: 'Reassign', name: 'reassign' }
];

const columns = [
    { label: 'Approval Process Name', fieldName: 'approvalProcessName' },
    {
        label: 'Work Item Link',
        fieldName: 'workItemUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'recordName' },
            target: '_blank'
        }
    },
    { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
    { label: 'Comments', fieldName: 'comments' },
    { label: 'Submitted By', fieldName: 'submittedByName' },
    {
        label: 'Action',
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];


export default class ApprovalList extends LightningElement {
        approvalProcesses = [];
        columns = columns;
    
        @wire(getApprovals)
        wiredApprovalProcesses({ error, data }) {
            if (data) {
                this.approvalProcesses = data;
                console.log(data[0]);
            } else if (error) {
                this.approvalProcesses = error;
                console.error('Error fetching approval processes:', error);
            }
        }
        handleRowAction(event) {
            const action = event.detail.action;
            const row = event.detail.row;
            switch (action.name) {
                case 'approve':
                    this.handleApprove(row);
                    break;
                case 'reject':
                    this.handleReject(row);
                    break;
                case 'reassign':
                    this.handleReassign(row);
                    break;
                default:
                    break;
            }
        }
    
        
    handleApprove(row) {
        approveAction({ processStepId: row.workItemId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Process step approved successfully',
                        variant: 'success'
                    })
                );
                // Refresh the data after approval
                return refreshApex(this.wiredApprovalProcesses);
            })
            .catch(error => {
                console.error('Error approving process step:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An error occurred while approving: ' + error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    handleReject(row) {
        rejectAction({ processStepId: row.workItemId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Process step rejected successfully',
                        variant: 'success'
                    })
                );
                // Refresh the data after rejection
                return refreshApex(this.wiredApprovalProcesses);
            })
            .catch(error => {
                console.error('Error rejecting process step:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An error occurred while rejecting: ' + error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    refreshData() {
        return refreshApex(this.approvalProcesses);
    }
        
        // handleReassign(row) {
        //     reassignAction({ processStepId: row.workItemId })
        //         .then(() => {
        //             console.log('Process step reassigned successfully');
        //             // Refresh the data after reassignment
        //             return refreshApex(this.wiredApprovalProcesses);
        //         })
        //         .catch(error => {
        //             console.error('Error reassigning process step:', error);
        //         });
        // }
    }