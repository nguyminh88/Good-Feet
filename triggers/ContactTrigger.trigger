trigger ContactTrigger on Contact (before insert, before Update, after insert, after update, before delete, after delete) {
    ContactTriggerHandler handler = new ContactTriggerHandler();
    
    if(trigger.isAfter){
        if(trigger.isUpdate){
           handler.isAfterUpdate(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);  
        }
        if(trigger.isInsert){
           handler.isAfterInsert(trigger.newMap, trigger.New);
        }
    }
}