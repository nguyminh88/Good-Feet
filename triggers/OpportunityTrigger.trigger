trigger OpportunityTrigger on Opportunity (before insert, before Update, after insert, after update, before delete, after delete) {
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
    
    if(trigger.isBefore){
        if(trigger.isInsert){
            handler.isBeforeInsert(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
        
    }
    else if(trigger.isAfter){
        if(trigger.isInsert){
            handler.isAfterInsert(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
        if(trigger.isUpdate){
            handler.isAfterUpdate(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
    } 

}