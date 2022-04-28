/*
Developed by Minh Nguyen
Description: Called from Account Trigger.  Triages the account trigger DML to other account functions and integrations.
-Refer to the called static functions for more information

*/

public class AccountTriggerHandler {
    public void isBeforeInsert(map<id,account> oldMap, map<id,account> newMap, list<account> oldList,list<account> newList){
        AccountFunctions.beforeInsertPhoneDupeCheck(newList);
    }
    
    public void isafterInsert(map<id,account> oldMap, map<id,account> newMap, list<account> oldList,list<account> newList){
        AccountFunctions.CreateContactAfterManualInsert(newList);
    }
    
    public void isBeforeUpdate(map<id,account> oldMap, map<id,account> newMap, list<account> oldList,list<account> newList){
        AccountFunctions.BeforeUpdateDoNotContact(newList);
        AccountFunctions.BeforeUpdateSync(oldMap,newMap);
    }
    
    public void isAfterUpdate(map<id,account> oldMap, map<id,account> newMap, list<account> oldList,list<account> newList){
		RICSEnqueuer.AccountSalesRepPopulated(oldMap,newMap);
       	NetsuiteEnqueuer.RICSPopulatedOnUpdate(oldMap,newMap);
    }
}