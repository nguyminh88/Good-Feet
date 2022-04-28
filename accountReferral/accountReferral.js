import { LightningElement, wire, api} from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCOUNTID_FIELD from '@salesforce/schema/Account.Id';
import ACCOUNT_REFERREDBYID_FIELD from '@salesforce/schema/Account.Referred_By__c';
import ACCOUNT_REFERRALCODE_FIELD from '@salesforce/schema/Account.Referral_Code__c';
import ACCOUNT_SUCCESSFULREFERRAL_FIELD from '@salesforce/schema/Account.SuccessfulReferrals__c';
import ACCOUNT_TOTALSALESGENERATED_FIELD from '@salesforce/schema/Account.Referral_Purchase_Total__c';
import ACCOUNT_AVGREFTICKET_FIELD from '@salesforce/schema/Account.Average_Referred_Ticket_Amount__c';

const fields = [
    ACCOUNTID_FIELD,
    ACCOUNT_REFERREDBYID_FIELD,
    ACCOUNT_REFERRALCODE_FIELD,
    ACCOUNT_SUCCESSFULREFERRAL_FIELD,
    ACCOUNT_TOTALSALESGENERATED_FIELD,
    ACCOUNT_AVGREFTICKET_FIELD
];

export default class AccountReferral extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields:fields }) account;
    
    updateAccount(){
    // Create the recordInput object
                const fields = {};
                fields[ACCOUNTID_FIELD.fieldApiName] = this.recordId;
                fields[ACCOUNT_REFERREDBYID_FIELD.fieldApiName] = this.template.querySelector("[data-field='ReferredBy']").value;
    
                const recordInput = { fields };
    
                updateRecord(recordInput)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Account updated',
                                variant: 'success'
                            })
                        );
                        // Display fresh data in the form
                        return refreshApex(this.account);
                    })
    }

    get accountId(){
        return getFieldValue(this.account.data, ACCOUNTID_FIELD);
    }

    get referredById(){
        return getFieldValue(this.account.data, ACCOUNT_REFERREDBYID_FIELD);
    }

    get ReferredByName(){
        return getFieldValue(this.account.data, ACCOUNT_REFERREDBYNAME_FIELD);
    }

    get ReferralCode(){
        return getFieldValue(this.account.data, ACCOUNT_REFERRALCODE_FIELD);
    }

    get SuccessfulReferral(){
        return getFieldValue(this.account.data, ACCOUNT_SUCCESSFULREFERRAL_FIELD);
    }

    get TotalSales(){
        return getFieldValue(this.account.data, ACCOUNT_TOTALSALESGENERATED_FIELD);
    }

    get AVGticket(){
        return getFieldValue(this.account.data, ACCOUNT_AVGREFTICKET_FIELD);
    }
}
