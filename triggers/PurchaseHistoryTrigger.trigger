trigger PurchaseHistoryTrigger on Purchase_History__c (before insert, after Insert, before Update, after Update) {
	PurchaseHistoryTriggerHandler handler = new PurchaseHistoryTriggerHandler();
    
    if(trigger.isBefore){
        if(trigger.isInsert){
            handler.isBeforeInsert(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
    }
    
    if(trigger.isAfter){
        if(trigger.isInsert){
            handler.isAfterInsert(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
    }
}