trigger ChatterTrigger on FeedComment (before insert, after insert) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            ChatterTriggerHandler.beforeInsert(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
    }
}