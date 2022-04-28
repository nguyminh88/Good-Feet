/*
Developed by Minh Nguyen
Description: Called from Contact Trigger. 
-Refer to the called static functions for more information
JIRA: SFSLII-II 55 RICS integration
*/

public class ContactTriggerHandler {
	public void isafterUpdate(map<id,contact> oldMap, map<id,contact> newMap, list<contact> oldList, list<contact> newList){
        RICSEnqueuer.ContactsUpdatedEnqueue(oldMap,newMap);
    }
    public void isAfterInsert(map<id,contact> newMap, list<contact> newList){
        RICSENqueuer.ContactsCreatedEnqueue(newList);
    }
}