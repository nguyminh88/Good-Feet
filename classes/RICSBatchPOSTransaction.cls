/*Developed by: Minh Nguyen
  Date: 2/2021
  Description: Batch job called from GetPOSSalesDataQueueable to insert Purchase history to avoid limit.
  -Queries for existing purchase history and compares date/ticket #/line # / store to make sure it is unique
  -RICS accounting may update their cashier code in accounting monthly fix, class includes functionality to check for update 

  Query: Purchase history constructed from GetPOSSalesDataQueueable 
  Execute: Queries for existing purchase history, checks if exists before insert, or cashier update
  Finish: Calls CreateOpportunityOrphanPHBatch()

  To run batch in execute annon: id bpId = Database.executeBatch(new RICSBatchPOSTransaction(), 1);
*/
public class RICSBatchPOSTransaction implements Database.Batchable<sobject>, Database.AllowsCallouts{
    private list<purchase_history__c> purchaseHistoryList;
    private date batchDay;
    private static string apexClass = 'RICSBatchPOSTransaction'; //var to pass to query and opt out MDT
    
    //Constructor requires end day of the batch
    public RICSBatchPOSTransaction(list<purchase_history__c> purchaseHistoryList, date batchDay){
        this.purchaseHistoryList = purchaseHistoryList;
        this.batchDay = batchDay;
    }
    
    public list<purchase_history__c> start(Database.BatchableContext BC){
        return purchaseHistoryList;
    }
    
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        list<Error_log__c> el = new list<error_log__c>([select endDate__c from error_log__c where context_Record__c = 'Migration' limit 1]);
        date start = batchDay.addDays(-4);
        date theEnd = batchDay.addDays(1);
        map<string,purchase_history__c> duplicateCheckMap = new map<string,purchase_history__c>();
        list<purchase_history__c> updateList = new list<purchase_history__c>();
        list<purchase_history__c> insertList = new list<purchase_history__c>();
        list<purchase_history__c> UnprocessedList = new list<purchase_history__c>();
        //Existing purchase history, very important to double check for duplicates and prevent insert
        list<purchase_history__c> ExistingList = new list<purchase_history__c>([select transaction_date__c, ticket_number__c, 
                                                                                ticket_line_number__c, store__c, salesperson_number__c
                                                                               from purchase_history__c 
                                                                                where transaction_date__c >=: start 
                                                                                AND transaction_date__c <=: theEnd]);
        
        //Populate unprocessed list from batch scope var                                                                    
        UnprocessedList = (list<purchase_history__c>)scope;
        
        //Map duplicate out with transaction date, ticket number, line number, store
        for(purchase_history__c p : ExistingList){
            duplicateCheckMap.put(p.transaction_date__c + p.ticket_number__c + p.ticket_line_number__c + p.store__c, p);
        }
        
        //VIP! Very important block of code below to ensure data integrity of purchase history!
        //Loop through the unprocessed list, and check against duplicate map.  
        //Either its new and goes to insert list, or exists and is updated with a new cashier code from RICS
        for(purchase_history__c p : UnprocessedList){
            if(!duplicateCheckMap.containsKey(p.transaction_date__c + p.ticket_number__c + p.ticket_line_number__c + p.store__c))
                insertList.add(p); //New
            
            //Cashier was updated in RICS (wrong person in RICS, accounting does manual edit in RICS)
            else if(duplicateCheckMap.containsKey(p.transaction_date__c + p.ticket_number__c + p.ticket_line_number__c + p.store__c) && 
                    duplicateCheckMap.get(p.transaction_date__c + p.ticket_number__c + p.ticket_line_number__c + p.store__c).salesperson_number__c != p.salesperson_number__c){
                    
                purchase_history__c udp = duplicateCheckMap.get(p.transaction_date__c + p.ticket_number__c + p.ticket_line_number__c + p.store__c);
                udp.salesperson_number__c = p.salesperson_number__c;
                updateList.add(udp);
            }
        }
        if(!insertList.isEmpty()){
            Database.SaveResult [] SRes = Database.insert(insertList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }     
        
        if(!updateList.isEmpty()){
            Database.SaveResult [] SRes2 = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes2);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        //Migration occurs on the 15th, or every saturday, with longer batch range depending on which.  
        list<Error_log__c> el = new list<error_log__c>([select endDate__c from error_log__c 
                                                        where context_Record__c = 'Migration' limit 1]);
        
        if(el.size() < 1)
            UtilityAndFactory.ErrorLog('Successful - RICSBatchPOSTransaction Successful ' + date.today().format(), 
                                   'Starting  CreateOpportunityOrphanPHBatch');
            
        Database.executeBatch(new CreateOpportunityOrphanPHBatch(), 100);
        
    }
}