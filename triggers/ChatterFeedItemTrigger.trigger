trigger ChatterFeedItemTrigger on FeedItem (before insert, after insert) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            ChatterFeedItemTriggerHandler.beforeInsert(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
    }
}