/*
Developed by Minh Nguyen
Description: Handler class for FeedItem Trigger. Performs feed item validation
Jira: SFSLII-213
*/

public class ChatterFeedItemTriggerHandler {
    public static void beforeInsert(Map<id, FeedItem> oldMap, Map<id, FeedItem> newMap, list<FeedItem> oldList, list<FeedItem> newList){
        ChatterFunctions.containsPinFeedItem(newList);
    }
}