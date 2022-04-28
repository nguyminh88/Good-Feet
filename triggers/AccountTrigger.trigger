trigger AccountTrigger on Account (before insert, before Update, after insert, after update, before delete, after delete) {
	AccountTriggerHandler handler = new AccountTriggerHandler();
    
    if(trigger.isBefore){
        if(trigger.isInsert){
            handler.isBeforeInsert(trigger.oldMap, trigger.NewMap, trigger.old, trigger.New);
        }
        if(trigger.isUpdate){
            handler.isBeforeUpdate(trigger.oldMap, trigger.NewMap, trigger.old, trigger.New);
        }
    }
    
    if(trigger.isAfter){
        if(trigger.isInsert){
           handler.isAfterInsert(trigger.oldMap, trigger.NewMap, trigger.old, trigger.New);  
        }
        if(trigger.isUpdate){
            handler.isAfterUpdate(trigger.oldMap, trigger.NewMap, trigger.old, trigger.New);
        }
    }
}