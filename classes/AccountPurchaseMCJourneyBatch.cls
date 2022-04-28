/*
Written by Minh Nguyen
Description: Called from AccountReferralBatch.cls to update accounts Marketing_Status__c based on steps purchased to enter into
marketing journey depending on the marketing status.  
Dependencies: Requires AccountPurchasedStepsReportingBatch to run prior.

Query: Accounts where marketing status is 'New' (defaulted status on create)
Execute: Loops through accounts, and updates marketing status depending on steps_purchased__c & nonlifetime_purchase__c 
Finish: Calls TaskOverDueBatch class

09/29/2021 Update: Moved query to New custom metadata (Batch job breaker) for ease of accessibility
- New CMDT: Franchise Opt Out. Easy opt in and out of apex classes for records. 
*/
//Database.executeBatch(new AccountPurchaseMCJourneyBatch(), 2000);

public with sharing class AccountPurchaseMCJourneyBatch implements Database.Batchable<sObject>{
    private static string apexClass = 'AccountPurchaseMCJourneyBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);     
    public database.QueryLocator start(Database.BatchableContext BC){
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }

    public void execute(Database.BatchableContext BC, list<Account> scope){
        list<account> updateList = new list<account>(); //empty list to populate

        for(account a : scope){
            //If either steps are purchased
            if(a.Steps_Purchased__c > 0 || a.NonLifetime_Purchase__c > 0){
                a.Marketing_Status__c = 'Supports First Send';
                updateList.add(a);
            }
            //If only accessories is purchased
            else if(a.Accessories__c > 0){
                a.Marketing_Status__c = 'Accessories First Send';
                updateList.add(a);
            }
            //If no supp/accessories purchased
            else {
                a.Marketing_Status__c = 'Did Not Buy First Send';
                updateList.add(a);
            }
                
        }

        if(!updateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
        
    }
 
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - AccountPurchaseMCJourneyBatch ' + date.today().format(), Null);
        UtilityAndFactory.LastBatchMigrationCheck();
        Database.executeBatch(new TaskOverdueBatch(), 2000);
    }
}