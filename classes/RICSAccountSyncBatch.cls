/*Developed by: Minh Nguyen
  Date: 2/2021
  Batch job that wraps RICSqueueable class for easy data migration
  To run batch in execute annon: id bpId = Database.executeBatch(new RICSAccountSyncBatch(), 1);
*/
global class RICSAccountSyncBatch implements Database.Batchable<sobject>, Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC){
        //'SELECT RICS_Account_Number__c,Name,Phone,ContactEmail__c,RICSid__c from account WHERE RICSId__c = Null AND phone != Null AND Sales_Representative__c != null'
        return Database.getQueryLocator(
            'SELECT RICS_Account_Number__c,Name,Phone,ContactEmail__c,RICSid__c from account WHERE RICSId__c = Null AND phone != Null'
        );
    }
    
    global void execute(Database.BatchableContext BC, list<sObject> scope){
        update RICSQueueableClass.MainProcessor(scope);
    }
    
    global void finish(Database.BatchableContext BC){
    }
    
}