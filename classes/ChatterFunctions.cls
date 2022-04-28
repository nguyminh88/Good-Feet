/*
Developed by Minh Nguyen
Jira: SFSLII-213 Activiate Chatter
Description: Called from triggerhandlers of feedcomment and feeditem. Runs as beforeinserts so addError is available
-Checks for comment convention (*pin message)
-Add errors to guide users to comment correctly
-Auto append sales rep names with pin.  
*/

public class ChatterFunctions {
    private static Id profileId = userinfo.getProfileId();
    private static String profileName=[Select Id,Name from Profile where Id =: profileId].Name;

    /*
    Description: When a feed comment is inserted, validate the comment body for *pin, then find the rep that belongs to that pin 
                 and append reps name to message
    */
    public static void containsPinFeedComment(list<FeedComment> commentList){
        map<id, string> commentPinMap = new map<id, string>();
        map<string, string> srPinNameMap = new map<string, string>();
        for(FeedComment f : commentList){
                if(f.CommentBody.remove('<p>').left(5).contains('*')){
                    string tmp = f.CommentBody.remove('<p>').left(5); //lighting auto prepends <p> to messages, must remove
                    string pin = tmp.remove('*');
                    commentPinMap.put(f.Id, Pin);
                } else {
                    if(profileName != 'System Administrator') //bypass if admin, else addError with help message
                        f.addError('Please begin your message with *[GF-APP pin]. Ex: *1234 Hello There!');
                }
        }

        //Find sales rep and append sales rep name. Adderror if no pin exists
        if(!commentPinMap.isEmpty()){
            //get Sales rep from PIN string
            list<Sales_Representative__c> srList = new List<Sales_Representative__c>([Select Pin__c,name from sales_representative__c where pin__c in : commentPinMap.Values()]);
            for(sales_representative__c sr : srList){
                srPinNameMap.put(sr.Pin__c, sr.Name);
            }

            for(FeedComment f : commentList){
                if(srPinNameMap.containsKey(commentPinMap.get(f.Id))){
                    string pinRemove = f.CommentBody.substring(3,8); //Removes pin from the message itself and append sales rep name
                    f.CommentBody = f.CommentBody.remove(pinRemove) + '\n- ' + srPinNameMap.get(commentPinMap.get(f.Id));
                } else {
                    if(profileName != 'System Administrator') //bypass if admin, else addError with invalid pin
                        f.addError('Invalid Pin. Please enter GF-App Pin');
                }
            }
        }
    }

    /*
    Description: When a feed item is inserted, validate the comment body for *pin, then find the rep that belongs to that pin 
                 and append reps name to message
    */
    public static void containsPinFeedItem(list<FeedItem> commentList){
        map<id, string> commentPinMap = new map<id, string>();
        map<string, string> srPinNameMap = new map<string, string>();
        for(FeedItem f : commentList){
                if(f.Body.remove('<p>').left(5).contains('*')){
                    string tmp = f.Body.remove('<p>').left(5); //lighting auto prepends <p> to messages, must remove
                    string pin = tmp.remove('*');
                    commentPinMap.put(f.Id, Pin);
                } else {
                    if(profileName != 'System Administrator') //bypass if admin, else addError with help message
                        f.addError('Please begin your message with *[GF-APP pin]. Ex: *1234 Hello There!');
                }
        }

        //Find sales rep and append sales rep name. Adderror if no pin exists
        if(!commentPinMap.isEmpty()){
            //get Sales rep from PIN string
            list<Sales_Representative__c> srList = new List<Sales_Representative__c>([Select Pin__c,name from sales_representative__c where pin__c in : commentPinMap.Values()]);
            for(sales_representative__c sr : srList){
                srPinNameMap.put(sr.Pin__c, sr.Name);
            }

            for(FeedItem f : commentList){
                if(srPinNameMap.containsKey(commentPinMap.get(f.Id))){
                    string pinRemove = f.Body.substring(3,8); //Removes pin from the message itself and append sales rep name
                    f.Body = f.Body.remove(pinRemove) + '\n- ' + srPinNameMap.get(commentPinMap.get(f.Id));
                } else {
                    if(profileName != 'System Administrator') //bypass if admin, else addError with invalid pin
                        f.addError('Invalid Pin. Please enter GF-App Pin');
                }
            }
        }
    }
}

/*  Execute Anon to make all active users follow each other 

list<entitySubscription> elist = new list<entitySubscription>();
list<user> allUsers = new list<user>([select id from user where isactive = TRUE]);

for(user u : allUsers){
    for(user s : allUsers){
        entitySubscription e = new entitySubscription();
		e.parentId = u.id;
		e.subscriberid = s.id;
        elist.add(e);
    }
}

database.insert(elist, false);
*/