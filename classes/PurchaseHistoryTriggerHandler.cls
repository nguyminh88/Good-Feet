/*
Developed by Minh Nguyen
Description: Handles purchase history trigger calls. 
-Populates account and opportunity on purchase history
*/

public class PurchaseHistoryTriggerHandler {

    public void isBeforeInsert(Map<Id, Purchase_History__c> oldMap, Map<Id, Purchase_History__c> newMap, list<Purchase_History__c> oldList, list<Purchase_History__c> newList){
        PurchaseHistoryFunctions.PopulateAccount(newList);
    }
    
    public void isAfterInsert(Map<Id, Purchase_History__c> oldMap, Map<Id, Purchase_History__c> newMap, list<Purchase_History__c> oldList, list<Purchase_History__c> newList){
        PurchaseHistoryFunctions.PopulateOpportunity(newList);
    }
    
    
}