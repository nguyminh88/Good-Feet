//Database.executeBatch(new OpportunityPurchaseJourneyBatch(), 2000);

public class OpportunityPurchaseJourneyBatch implements Database.Batchable<sObject>{
    public database.QueryLocator start(Database.BatchableContext BC){
        date start = date.today().addDays(-1);
        return database.getQueryLocator('Select Account.Purchase_Journey_Run_Once__c, AccountId, Opp_Purchase_Journey__c FROM Opportunity where closeDate =: start AND Opp_Purchase_Journey__c = FALSE AND Auto_Generated__c = FALSE AND is_return_customer__c = FALSE AND Customer__c != NULL AND Sales_Representative__c != NULL AND account.Purchase_Journey_Run_Once__c = FALSE');
    }

    public void execute(Database.BatchableContext BC, list<sObject> scope){
        list<Opportunity> updateList = new list<Opportunity>();
        list<Opportunity> oppList = new list<Opportunity>();
        set<Id> dupeAccountSet = new Set<Id>();
        oppList = (list<Opportunity>)scope;
        list<account> accountUpdateList = new list<account>();

        for(Opportunity o : oppList){
            if(!dupeAccountSet.contains(o.AccountId)){
                o.Opp_Purchase_Journey__c = TRUE;
                updateList.add(o);
                dupeAccountSet.add(o.AccountId);
                o.Account.Purchase_Journey_Run_Once__c = TRUE;
                accountUpdateList.add(o.Account);
            }
        }

        if(!updateList.isEmpty())
            update updateList;

        if(!accountUpdateList.isEmpty())
            update accountUpdateList;
    }
 
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - OpportunityPurchaseJourneyBatch ' + date.today().format(), Null);
        UtilityAndFactory.LastBatchMigrationCheck();
        Database.executeBatch(new TaskOverdueBatch(), 2000);
    }
}