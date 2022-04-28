/* Developed by: Minh Nguyen
 * Date: 02/2021
 * Description: Triage class to accept incoming triggerHandler lists/Maps from accounts,opps,contacts to handle RICS enqueueing. 
 * 
 * 12/28/2021: Update to make this class a customer/POS enqueuer.  Works for both RICS/Acumatica, depending on the franchise of the account. 
 */
public class RICSEnqueuer {
    
    //Enqueuer, all other functions call this as a null check to enqueue.  
    public static void Enqueue(list<account> accList, list<account> acuList){
        if(!accList.isEmpty()){ 
            RICSQueueableClass RICS = new RICSQueueableClass(acclist);
            system.enqueueJob(RICS);
        }
        if(!acuList.isEmpty()){
            AcumaticaAccQueueable Acu = new AcumaticaAccQueueable(acuList);
            //system.enqueueJob(Acu);
        }
    }
    
    //On New Opportunities, if return customer, then enqueue. This is for existing SF accounts that are not yet linked to RICS
    public static void OpportunityCreateEnqueue(list<Opportunity> OppList){
        list<string> queryAccs = new list<string>();
        list<account> enq = new list<account>();
        map<Id,Id> IdOppMap = new map<Id,Id>();
        for(opportunity o : opplist){
            IdOppMap.put(o.Id, o.AccountId);       
        }
        map<Id,Account> accountMap = new map<Id,Account>([select sales_Representative__c, owner.franchise__c from Account where id in : idOppMap.values()]);
        for(opportunity o : opplist){
            if((o.account.RICSId__c == Null && o.Is_Return_Customer__c == TRUE && o.StageName != 'Purchase Made' && o.Franchise__c == 'Northwest'))
                enq.add(accountMap.get(IdOppMap.get(o.Id)));
        }
        if(!enq.isEmpty()){ 
            RICSQueueableClass RICS = new RICSQueueableClass(enq, true);
            system.enqueueJob(RICS);
        } 
    }
    
    public static void AccountSalesRepPopulated(map<id,account> oldMap, map<id,account> newMap){
        list<account> enq = new list<account>();
        list<account> AcuEnq = new list<account>();
        for(account a : newMap.values()){
            if(oldMap.get(a.Id).Sales_Representative__c == Null && a.Sales_Representative__c != Null && a.RICSId__c == Null && a.franchise__c == 'Northwest')
                enq.add(a);
            else if(oldMap.get(a.Id).Sales_Representative__c == Null && a.Sales_Representative__c != Null && a.AcumaticaId__c == Null && a.franchise__c == 'Midwest')
                AcuEnq.add(a);
        }        
        RICSEnqueuer.Enqueue(enq,acuEnq);  
    }
    
    //ON Update Contacts, if critiera fields are updated, enqeueu to rics link or update
    public static void ContactsUpdatedEnqueue(map<id,contact> oldMap, map<id,contact> newMap){
        list<string> queryAccs = new list<string>();
        list<string> AcumaticaAccs = new list<string>();
        for(contact c : newMap.values()){
            if(c.franchise__c == 'Northwest' && c.Sales_Representative__c != Null && c.Phone != Null &&
               (oldMap.get(c.id).firstName != c.firstName ||
               oldMap.get(c.id).lastName != c.lastName ||
               oldMap.get(c.id).Email != c.Email ||
               oldmap.get(c.id).Phone != c.Phone ||
               oldMap.get(c.id).BirthDate != c.BirthDate ||
               oldMap.get(c.id).MailingStreet != c.MailingStreet ||
               oldMap.get(c.id).MailingCity != c.MailingCity ||
               oldMap.get(c.id).MailingState != c.MailingState ||
               oldMap.get(c.id).MailingPostalCode != c.MailingPostalCode)){
                queryAccs.add(c.AccountId);
            } 
            
            else if (c.AcumaticaId__c != Null && c.franchise__c == 'Midwest' && c.Phone != Null &&
            (oldMap.get(c.id).firstName != c.firstName ||
               oldMap.get(c.id).lastName != c.lastName ||
               oldMap.get(c.id).Email != c.Email ||
               oldmap.get(c.id).Phone != c.Phone || 
               oldMap.get(c.id).MailingStreet != c.MailingStreet ||
               oldMap.get(c.id).MailingPostalCode != c.MailingPostalCode)){
                AcumaticaAccs.add(c.AccountId);
            }
        }
        list<account> enq = new list<account>([select id from account where id in : queryAccs]);
        list<account> acuEnq = new list<account>([select id from account where id in : AcumaticaAccs]);
        if(!enq.isEmpty()){
            RICSQueueableClass RICS = new RICSQueueableClass(enq, true);
            system.enqueueJob(RICS);
        }
        
        if(!acuEnq.isEmpty()){
            RICSEnqueuer.Enqueue(enq,acuEnq);
        }   
    }
    
    //On New Contacts, Phone and Sales Rep must be populated 
    public static void ContactsCreatedEnqueue(list<contact> contactList){
        list<string> queryAccs = new list<string>();
        list<string> acuAccs = new list<string>();
        for(contact c : contactList){
            if(c.franchise__c == 'Northwest' && c.Phone != Null && c.sales_representative__c != Null && c.RICSId__c == Null)
                queryAccs.add(c.accountId);
            else if(c.franchise__c == 'Midwest' && c.Phone != Null && c.sales_representative__c != Null && c.AcumaticaId__c == Null)
                acuAccs.add(c.accountId);
        }
        list<account> enq = new list<account>([select id from account where id in : queryAccs]);
        list<account> acuEnq = new list<account>([select id from account where id in : acuAccs]);
        RICSEnqueuer.Enqueue(enq,acuEnq);
    }
}