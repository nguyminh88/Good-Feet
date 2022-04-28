trigger ChatterFeedCommentTrigger on FeedComment (before insert, after insert) {
    if(trigger.isBefore){
        if(trigger.isInsert){
            ChatterFeedCommentTriggerHandler.beforeInsert(trigger.oldMap, trigger.newMap, trigger.Old, trigger.New);
        }
    }
}
