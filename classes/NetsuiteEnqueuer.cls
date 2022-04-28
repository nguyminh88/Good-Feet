public class NetsuiteEnqueuer {
    //Unbulkified Account update NS callout.  Set bulk to 1 on any updates
    public static void RICSPopulatedOnUpdate(map<id, account> oldMap, map<id, account> newMap){
        for(account a : newMap.values()){
            //New Customer or Customer updating ns related information with NSID
            if((oldMap.get(a.Id).RICSId__c == NULL && a.RICSId__c != NULL && a.Netsuite_Id__c == Null) ||
                (a.Netsuite_Id__c != Null && a.RICSId__c != Null &&
                    (oldMap.get(a.Id).Address__c != a.Address__c || 
                    oldMap.get(a.Id).Zip_Code__c != a.Zip_Code__c ||
                    oldMap.get(a.Id).Phone != a.Phone || 
                    oldMap.get(a.Id).ContactEmail__c != a.ContactEmail__c ||
                    oldMap.get(a.Id).Name != a.Name)) && a.franchise__c == 'Northwest'){
                NetsuiteIntegratorQueueable NS = new NetsuiteIntegratorQueueable(a);
                system.enqueueJob(NS);
            } 
        }
    }

    //Not bulkified! NS Callout 1 at a time.  Never bulk create Opportunities. Set bulk to 1 if s
    public static void OppCreated(list<Opportunity> oppList){
        opportunity o = [select Franchise__c, account.RICSId__c, Auto_Generated__c from opportunity where id =: oppList[0].Id];
        list<Opportunity> opporList = new list<Opportunity>([select id from opportunity where accountid =: oppList[0].accountId]);
        
        //only do it on more than 1 opp, prevents duplicate
        if(opporList.size() > 1 && o.Auto_Generated__c == False && o.account.RICSId__c != Null && o.Franchise__c == 'Northwest'){
            account a = [select id from account where id = :oppList[0].accountId];
            NetsuiteIntegratorQueueable NS = new NetsuiteIntegratorQueueable(a);
            system.enqueueJob(NS);
        }
    }
}