//Database.ExecuteBatch(new PurchaseHistoryStoreRecordsBatch(0), 2000);

public with sharing class PurchaseHistoryStoreRecordsBatch implements Database.Batchable<sObject>, Database.Stateful{
    private final integer Order;
    private final string storeNumber;
    private map<string,integer> storeMap;

    public PurchaseHistoryStoreRecordsBatch(integer Order) {
        this.Order = Order;
        list<User> stores = [select lastName, RICS_Store_Number__c from User where RICS_Store_Number__c != Null AND isActive = TRUE Order By lastName ASC];
        this.storeNumber = stores[Order].RICS_Store_Number__c;
        
    }

    public database.QueryLocator start(Database.BatchableContext BC){
        string RICSStore = this.storeNumber;
        
        return database.getQueryLocator('select Sales_Representative__r.Name, Ticket_Number__c, Price__c, Store__c, transaction_date__c from Purchase_History__c where Store__c =: RICSStore AND Ticket_Voided__c = False');
     }

     public void execute(Database.BatchableContext BC, list<sObject> scope){
         integer tt = scope.size();
         integer temp;
         if(this.storeMap.containsKey(this.storeNumber)){
            temp = this.storeMap.get(this.storeNumber) +  tt;
            this.storeMap.put(this.StoreNumber, temp);
        }
         else 
            this.storeMap.put(this.storeNumber, tt);

        string numb = string.valueof(this.storeMap.get(this.storeNumber));
        UtilityAndFactory.errorLog(this.storeNumber, numb);
     }

     public void finish(Database.BatchableContext BC){
        list<User> stores = [select RICS_Store_Number__c from User where RICS_Store_Number__c != Null AND isActive = TRUE Order By lastName ASC];
        integer Next = this.Order + 1;
        if(Next < stores.Size()){
            Database.ExecuteBatch(new PurchaseHistoryStoreRecordsBatch(Next), 2000);
        }

     }

}