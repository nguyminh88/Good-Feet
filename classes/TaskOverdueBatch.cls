//Database.executeBatch(new TaskOverdueBatch(), 2000);
/*
Written by Minh Nguyen
Description: Batch class to change task status to Overdue if it's not completed by today's date if its due
Batch query: All Accounts
Batch execute: Subqueries for purchase_history__c in each accounts and roll up to account fields
Batch finish: Calls 'AccountReferralBatch' class.  

09/20/2021: Jira SFSLII-265: Refactor - Convert list of hard coded supports to Support_SKUS__mdt
09/29/2021 Update: Moved query to New custom metadata (Batch job breaker) for ease of accessibility
- New CMDT: Franchise Opt Out. Easy opt in and out of apex classes for records.
*/
public class TaskOverdueBatch implements Database.Batchable<sObject>{
    private static string apexClass = 'TaskOverdueBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    
    public database.QueryLocator start(Database.BatchableContext BC){
        date theDate = date.today();
        string Open = 'Open';
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
     }
    
    public void execute(Database.BatchableContext BC, list<Task> scope){
        list<task> updateList = new list<sObject>();
        for(task t : scope){
            t.status = 'Overdue';
            updateList.add(t);
        }
        if(!updateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - TaskOverdueBatch ' + date.today().format(), Null);
    }
}