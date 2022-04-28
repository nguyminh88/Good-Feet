//Database.executeBatch(new MWResetStagingBatch(), 2000);

public class MWResetStagingBatch implements Database.Batchable<sObject>{
	private static string apexClass = 'MWResetStagingBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    
    
    public database.QueryLocator start(Database.BatchableContext BC){
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }
    
    public void execute(Database.BatchableContext BC, list<Mw_Staging__c> scope){
        for(mw_staging__c mw : scope){
            mw.processed__c = FALSE;
            mw.error__c = NULL;
            mw.initial_migration__c = TRUE;
        }
        
        update scope;
    }
    
    public void finish(Database.BatchableContext BC){
    }
}