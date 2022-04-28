/*
Developed by Minh Nguyen
Description: Handler class for FeedComment Trigger. Performs feed comment validation
Jira: SFSLII-213
*/

public class ChatterFeedCommentTriggerHandler {
    public static void beforeInsert(Map<id, FeedComment> oldMap, Map<id, FeedComment> newMap, list<FeedComment> oldList, list<FeedComment> newList){
        ChatterFunctions.containsPinFeedComment(newList);
    }
}