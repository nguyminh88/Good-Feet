/*
Developed by: Minh Nguyen           3/2021
Description: Called from RICSBatchPOSTransaction
-For Purchase History records that have an account, but do not have an opportunity, Job creates an opportunity for the purchase history 'ticket' and relates all other ticket line items
Query: All Purchase history with account but no opportunity

Execute: 
- Creates an opportunity (1 per ticket) and inserts opportunity.
- updates the remaining line items of the ticket to relate to the new opportunity
- If opportunity is found, then relate the purchase history - (queries using closeDate of opp vs transaction date of PH)

Finish: 
-Calls StoreSummaryBatch and PurchHistoryRICSCustCreatedDateBatch
-Contains logic for weekly/monthly 'migration' (checks if updated cashier for accounting/RICS PH)
*/

//Database.executeBatch(new CreateOpportunityOrphanPHBatch(), 100);

public class CreateOpportunityOrphanPHBatch implements Database.Batchable<sobject>{
    private static string apexClass = 'CreateOpportunityOrphanPHBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);

    public database.QueryLocator start(Database.BatchableContext BC){
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }
     
    
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        list<purchase_history__c> phList = new list<purchase_history__c>();
        list<purchase_history__c> PHWithMatchingOpportunity = new list<purchase_history__c>();
        list<purchase_history__c> PHWithNoMatchingOpp = new list<purchase_history__c>();
        list<purchase_history__c> PhUpdateNewOpportunity = new list<purchase_history__c>();
        list<opportunity> oppInsertList = new list<opportunity>();
        list<Id> accId = new list<Id>();
        
        map<string, String> dateAccIdOppMap = new map<string,string>();
        map<string, purchase_history__c> PhlistMap = new map<string,purchase_history__c>();
        map<Id, Id> AccContactMap = new map<Id, Id>();
        
        phList = (list<purchase_history__c>)scope;
        
        for(purchase_history__c p : phList){
            accId.add(p.Account__c);
        }
        
        //Map contact to account to populate contact on opportunity on insert
        list<contact> contactList = new list<contact>([select accountid from contact where accountid in : accId]);
        for(contact c : contactList){
            AccContactMap.put(c.accountId, c.Id);
        }
        
        //Get list of opportunities that exist, use accountid + closedate to map (only one opp per day)
        list<opportunity> oppList = new list<opportunity>([Select closeDate,accountId,account.name from Opportunity where accountid in : accId]);
        for(opportunity o : oppList){
            dateAccIdOppMap.put(o.accountId + ' ' + o.closeDate, o.Id);
        }
        for(purchase_history__c p : phList){
            if((dateAccIdOppMap != Null && !dateAccIdOppMap.containsKey(p.Account__c + ' ' + p.Transaction_Date__c)) || dateAccIdOppMap == Null){
               phlistMap.put(p.Account__c + ' ' + p.Transaction_Date__c, p); //only mapping per sales header (map key overwrites if same key in loop)
               PHWithNoMatchingOpp.add(p); //all of them later to update
                
            } else if(dateAccIdOppMap != Null && dateAccIdOppMap.containsKey(p.Account__c + ' ' + p.Transaction_Date__c)){
                //Opp was created from previous batch, Populate opp
                p.Opportunity__c = dateAccIdOppMap.get(p.Account__c + ' ' + p.Transaction_Date__c);
                PHWithMatchingOpportunity.add(p);
            }
        }
        
        //create opportunity for each header
        map<String, String> PHOppIdMap = new map<string, string>();
        for(purchase_history__c p : phlistMap.values()){
            Opportunity o = new opportunity();
            o.AccountId = p.Account__c;
            o.StageName = 'New';
            o.CloseDate = p.Transaction_Date__c;
            o.Sales_Representative__c = p.Sales_Representative__c;
            o.OwnerId = p.OwnerId;
            o.Auto_generated__c = TRUE; 
            o.initial_migration__c = p.initial_migration__c;
            o.name = p.account__r.name +  ' ' + p.Transaction_Date__c.format();
            o.Customer__c = AccContactMap != Null && AccContactMap.ContainsKey(p.Account__c) ? AccContactMap.get(p.Account__c) : Null;
            OppInsertList.add(o);
        }
        
        if(!OppInsertList.isEmpty()){
            Database.SaveResult [] SRes1 = Database.insert(OppInsertList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes1);
        }        
        
        list<opportunity> newInsertOpps = new list<opportunity>([select accountid, CloseDate from opportunity where id in : oppinsertList]);
        for(opportunity o : newInsertOpps){
            PHOppIdMap.put(o.AccountId + ' ' + o.CloseDate, o.Id);
        }
        
        //Update the rest of the line items of that ticket
        for(Purchase_history__c ph : PHWithNoMatchingOpp){
            ph.Opportunity__c = PhOppIdMap.get(ph.Account__c + ' ' + ph.Transaction_date__c);
            PhUpdateNewOpportunity.add(ph);
        }
        
        //List of remaining lines that have a new opportunity
        if(!PhUpdateNewOpportunity.isEmpty()){
            Database.SaveResult [] SRes2 = Database.update(PhUpdateNewOpportunity, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes2);
        } 

        //List of remaining lines that found an existing opportunity
        if(!PHWithMatchingOpportunity.isEmpty()){
            Database.SaveResult [] SRes3 = Database.update(PHWithMatchingOpportunity, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes3);
        } 
    }
    
    public void finish(Database.BatchableContext BC){
        string stopMigration = 'stopMigration ' + date.today();
        
        //Error logs are for weekly/monthly and initial migration
        list<error_log__c> quitMigration = new list<error_log__c>([select id from error_log__c where context_record__c =: stopMigration]);
        
        list<Error_log__c> el = new list<error_log__c>([select endDate__c from error_log__c 
                                                        where context_Record__c = 'Migration' limit 1]);
        list<Error_log__c> stop = new list<error_log__c>([select endDate__c from error_log__c 
                                                        where context_Record__c = 'stop' limit 1]);
        
        if(el.isEmpty()){
            UtilityAndFactory.ErrorLog('Successful - CreateOpportunityOrphanPH Batch ' + date.today().format(), 'Starting StoreSalesSummaryBatch, PurchHistoryRICSCustCreatedDateBatch');
            Database.ExecuteBatch(new StoreSalesSummaryBatch(date.today().addYears(-1), date.today()), 1);
        }
        
        if(el.isEmpty() && ![SELECT IsSandbox FROM Organization LIMIT 1].isSandbox)
            Database.executeBatch(new PurchHistoryRICSCustCreatedDateBatch(), 1);
        
        if(!el.isEmpty() && !stop.isEmpty() && el[0].endDate__c > stop[0].endDate__c){
            GetRICSPOSTransactionSchedulable abc = new GetRICSPOSTransactionSchedulable(); 
            abc.execute(null);
        } else if(!el.isEmpty() && !stop.isEmpty() && el[0].endDate__c <= stop[0].endDate__c){
            UtilityAndFactory.stopRICSMigration();
            GetRICSPOSTransactionSchedulable abc = new GetRICSPOSTransactionSchedulable(); //run once more to calculate new numbers after migration
            abc.execute(null);
        }
    }
}