/*
=====For developing purposes========================================================================
Execute Anon: Database.executeBatch(new MWPurchaseHistoryStagingBatch(), 100);
*/


public class MWPurchaseHistoryStagingBatch implements Database.Batchable<sObject>{
    private static string apexClass = 'MWPurchaseHistoryStagingBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    
    public database.QueryLocator start(Database.BatchableContext BC){
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }

    public void execute(Database.BatchableContext BC, list<Mw_Staging__c> scope){
        list<string> customerIds = new list<string>();
        map<string,string> AcumaticaToAccountMap = new map<string,string>();
        set<date> transactionDatesList = new set<date>();
        map<string,purchase_history__c> phDupeCheckList = new map<string,purchase_history__c>();
        list<purchase_history__c> PHfinalInsertList = new list<purchase_history__c>();
        map<purchase_history__c, mw_staging__c> phInsertList = new map<purchase_history__c,mw_staging__c>();

        for(Mw_Staging__c m1 : scope){
            customerIds.add(m1.Sales_CustomerId__c);
        }

        list<account> existingAccounts = new list<account>([select acumaticaId__c from account where acumaticaId__c in : customerIds]);
        for(account a : existingAccounts){
            AcumaticaToAccountMap.put(a.acumaticaId__c, a.Id);
        }


        for(Mw_Staging__c m : scope){
            if(!AcumaticaToAccountMap.isEmpty() && AcumaticaToAccountMap.containskey(m.Sales_CustomerId__c))
                phInsertList.put(MWStagingProcessingBatch.ConvertToPurchaseHistory(m,AcumaticaToAccountMap.get(m.Sales_CustomerId__c)), m);
            else 
                phInsertList.put(MWStagingProcessingBatch.ConvertToPurchaseHistory(m,null), m);
            
        }

        //duplicate check for purchase history
        for(purchase_history__c ph : phInsertList.keySet()){
            transactionDatesList.add(ph.transaction_date__c);
        }
        
        list<purchase_history__c> existingPHList = new list<purchase_history__c>([select Transaction_type__c, transaction_date__c, store__c, ticket_number__c, ticket_line_number__c 
                                                                                       from purchase_history__c 
                                                                                    where franchise__c = 'Midwest' AND transaction_date__c in : transactionDatesList]);
        for(purchase_history__c p : existingPHList){
            string key = p.store__c + p.Transaction_type__c + p.transaction_date__c + p.ticket_number__c + (integer)p.ticket_line_number__c;
            phDupeCheckList.put(key,p);
        }
        
        for(purchase_history__c p : phInsertList.keySet()){
            string key = p.store__c + p.Transaction_type__c + p.transaction_date__c + p.ticket_number__c + (integer)p.ticket_line_number__c;
            if((!phDupeCheckList.isEmpty() && !phDupeCheckList.containskey(key)) || phDupeCheckList.isEmpty()){
                PHfinalInsertList.add(p);
                phInsertList.get(p).Error__c = 'Migration Successful';
            } else {
                phInsertList.get(p).Error__c = 'Did not migrate: Duplicate Detected';
            }
            phInsertList.get(p).Processed__c = TRUE;
        }
            

        if(!PHfinalInsertList.isEmpty()){
            database.Insert(PHfinalInsertList,false);
        }
        database.update(phInsertList.values(),false);

    }

    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - MWStagingProcessingBatch Batch ' + date.today().format(), 'Starting GetPOSSalesDataQueueable');
    	GetPOSSalesDataQueueable RICS = new GetPOSSalesDataQueueable();
        system.enqueueJob(RICS);
    }
}