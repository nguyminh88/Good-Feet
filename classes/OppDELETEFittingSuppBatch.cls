//Database.executeBatch(new OppDELETEFittingSuppBatch(), 2000);

public class OppDELETEFittingSuppBatch {/* implements Database.Batchable<sObject>{
    public database.QueryLocator start(Database.BatchableContext BC){
        String Sales = '0121N000001fsks';
        date start = date.today().addMonths(-1).toStartOfMonth();
        return database.getQueryLocator('Select id from Opportunity where (select opportunity__c from purchase_history__c where lastModifiedDate >=: start)');
    }
    
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        list<Fitting_Product__c> insertList = new list<Fitting_Product__c>();
        list<Fitting_Product__c> deleteList = new list<Fitting_Product__c>([Select id from Fitting_Product__c where opportunity__c in : scope]);
        if(!deleteList.isEmpty())
            delete deleteList;
        
        
        
        for(opportunity o : [select Styles_Exerciser__c, Styles_Maintainer__c, Styles_Relaxer__c, Style_Other__c,
                             Sizes_Exerciser__c, Sizes_Maintainer__c, Sizes_Relaxer__c, Sizes_Other__c
                             From Opportunity where id in : scope]){
                                 
                                 if(o.Styles_Exerciser__c != Null){
                                     fitting_product__c SE = new fitting_product__c();
                                     SE.Product__c = 'Strengthener';
                                     SE.Style__c = o.Styles_Exerciser__c;
                                     SE.Size__c = o.Sizes_Exerciser__c;
                                     SE.Opportunity__c = o.Id;
                                     insertList.add(SE);
                                 } 
                                 
                                 if(o.Styles_Maintainer__c != Null){
                                     fitting_product__c SM = new fitting_product__c();
                                     SM.Product__c = 'Maintainer';
                                     SM.Style__c = o.Styles_Maintainer__c;
                                     SM.Size__c = o.Sizes_Maintainer__c;
                                     SM.Opportunity__c = o.Id;
                                     insertList.add(SM);
                                 }
                                 
                                 if(o.Styles_Relaxer__c != Null){
                                     fitting_product__c SR = new fitting_product__c();
                                     SR.Product__c = 'Relaxer';
                                     SR.Style__c = o.Styles_Relaxer__c;
                                     SR.Size__c = o.Sizes_Relaxer__c;
                                     SR.Opportunity__c = o.Id;
                                     insertList.add(SR);
                                 }
                                 
                                 if(o.Style_Other__c != Null){
                                     fitting_product__c SO = new fitting_product__c();
                                     SO.Product__c = 'Other';
                                     SO.Style__c = o.Style_Other__c;
                                     SO.Size__c = o.Sizes_Other__c;
                                     SO.Opportunity__c = o.Id;
                                     insertList.add(SO);
                                 }
        }
        
        if(!insertList.isEmpty())
            database.insert(insertList, FALSE);
    }
        
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - OppDELETEFittingSuppBatch ' + date.today().format(), null);
    }*/

}