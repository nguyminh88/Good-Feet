/*
Developed by Minh Nguyen
Description: Handler class for OpportunityTrigger Apex Trigger
-Calls OpportunityFactory for opportunity related functions
-Netsuite and RICSEnquer classes.  Insert opportunities generally trigger integration
*/

public class OpportunityTriggerHandler {
	public void isAfterInsert(map<id,opportunity> oldMap, map<id,opportunity> newMap, list<opportunity> oldList, list<opportunity> newList){
        RICSEnqueuer.OpportunityCreateEnqueue(newList);
        NetsuiteEnqueuer.OppCreated(newList);
        OpportunityFactory.OppToAccountLifestyleInformation(newList);
    }

    public void isAfterUpdate(map<id,opportunity> oldMap, map<id,opportunity> newMap, list<opportunity> oldList, list<opportunity> newList){
        OpportunityFactory.OppToAccountLifestyleInformation(newList);
    }

    public void isBeforeInsert(map<id,opportunity> oldMap, map<id,opportunity> newMap, list<opportunity> oldList, list<opportunity> newList){
        OpportunityFactory.isReturnCustomerCheck(newList);
    }

    /*
    public void isBeforeUpdate(map<id,opportunity> oldMap, map<id,opportunity> newMap, list<opportunity> oldList, list<opportunity> newList){
        
    }
    */
}