/*
Developed by Minh Nguyen
JIRA: SFSLII-255 Hourly retry job to catch any failed netsuite callouts
Description:about 1 in 100 accounts fail the netsuite integration due to HTTP readtimeout callout errors
-The account is created in netsuite, but the response (NSID) never makes it back to salesforce
-This job runs hourly and queries for those failed accounts and tries to get the NSID from netsuite

Query: All accounts created today whose account doesn't have a NSID, but has a RICS Id
Execute: Runs the NS queueable class for each account
Finish: N/A

Notes:
-Must run this class with batch size 1
-Database.executeBatch(new NetsuiteRetryFailedAccountsBatch(), 1);

*/


public class NetsuiteRetryFailedAccountsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    private static datetime August2nd = datetime.newInstance(2021,8,2,0,0,1);
    private static string apexClass = 'NetsuiteRetryFailedAccountsBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);

    public database.QueryLocator start(Database.BatchableContext BC){
        //use opportunities because created date or updated date on account is not sufficient
        list<Opportunity> Opp = new list<opportunity>([select accountId From Opportunity where createdDate >=: AUgust2nd AND auto_generated__c = False AND account.Netsuite_Id__c = Null AND account.RICSId__c != Null]);
        set<Id> Accid = new set<id>();
        for(opportunity o : opp){
            accid.add(o.AccountId);
        }

        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }
    
    public void execute(Database.BatchableContext BC, list<Account> scope){
            account a = scope[0];
            NetsuiteIntegratorQueueable NS = new NetsuiteIntegratorQueueable(a);
            system.enqueueJob(NS);
    }

    public void finish(Database.BatchableContext BC){

    }

}