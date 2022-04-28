//Developed by: Minh Nguyen       4/2021
//id bpId = Database.executeBatch(new OpportunityPHSummaryBatch(), 1000);
/* Description:
 * #1 Summarizes Opportunities based on purchase history
 * #2 Creates tasks depending on purchase history
 *
 09/09/2021 - Updated for JIRA: SFSLII-267
 09/16/2021 - Updated for Jira: SFSLII-265: Refactored to use Custom meta data to control auto generated tasks
 09/20/2021 - updated for Jira: SFSLII-265: Refactor using custom meta data for support skus
 * */

public class OpportunityPHSummaryBatch implements Database.Batchable<sObject>{
    static list<Auto_Generated_Tasks__mdt> autoGenTasks = [Select Franchise__c, Add_Days__c, Use_in_OPPPHSummaryBatch__c, PurchasedSupports__c, Purchase_Made__c, is_return_customer__c, Task_Subject__c from Auto_Generated_Tasks__mdt];
    static list<Support_SKUS__mdt> supportSKUs = [select masterLabel, type__c from Support_SKUS__mdt where type__c = 'Lifetime' OR type__c = 'NonLifetime'];
    private static string apexClass = 'OpportunityPHSummaryBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);

    public database.QueryLocator start(Database.BatchableContext BC){
        date start = date.today().addMonths(-1).toStartOfMonth();
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }
    
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        Boolean purchasedSupports;
        map<string,string> taskDupeCheckMap = new map<string,string>();
        list<task> taskInsertList = new list<task>();
        set<string> supportsList = new set<string>();
        list<string> AutoGenTaskFranchise = new list<string>();

        //Query for Support SKUS using custom meta data table and populate into list
        for(Support_SKUS__mdt s : supportSKUs){
            supportsList.add(s.masterLabel);
        }
        
        //Query for any open tasks on opportunity to ensure no duplications
        list<task> taskDupeCheck = new list<task>([select activityDate, Subject, whatId from Task where whatid in : scope]);
        for(task t : taskDupeCheck){
            taskDupeCheckMap.put(t.whatId, t.whatId);
        }
        
        list<opportunity> updateList = new list<opportunity>();
        for(opportunity o : [Select initial_migration__c, Franchise__c, stageName, Previous_Stage__c, Auto_Generated__c, Account.Do_Not_Contact__c, Is_Return_Customer__c, Purchase_Total__c, Purchase_Made__c, Number_Of_Steps__c, OwnerId, Sales_Representative__c,CloseDate,
                             (select Franchise__c, class__c, price__c, transaction_type__c, SKU__c, quantity__c from Purchase_Histories__r where ticket_voided__c = False) 
                             from Opportunity where id in : scope]){
            o.Purchase_Total__c = 0;
            Decimal lifeTimePositive = 0;
            Decimal lifeTimeNegative = 0;
            o.Number_of_Steps__c = 0;

            //loop through purchase history and total up number of steps, purchase total, and set purchase made TRUE/FALSE
            for(Purchase_History__c p : o.Purchase_Histories__r){
                o.Number_Of_Steps__c += AddOrSubtractStep(p, supportsList);
                o.Purchase_Total__c += p.Price__c;
            }
            
            o.Purchase_Made__c = o.Purchase_Total__c > 0 ? TRUE : FALSE;

            //Jira ticket SFSLII-267 - Capture last stage, then close out opp
            o.Previous_Stage__c = o.stageName;
            o.stageName = o.Purchase_Made__c ? 'Purchase Made' : 'No Purchase';
            //

            updatelist.add(o);
            
            //Refactored on 09/16/2021 to use CMDT
            //Loops through CMDT and compares value with opportunity values and creates task with subject from CMDT
            if(!o.initial_migration__c && !o.account.Do_not_contact__c && !taskDupeCheckMap.containsKey(o.Id)){
                purchasedSupports = o.Number_of_Steps__c > 0 ? TRUE : FALSE;
                for(Auto_Generated_Tasks__mdt ag : autoGenTasks){
                    if(ag.PurchasedSupports__c == PurchasedSupports &&
                       ag.Purchase_Made__c == o.Purchase_Made__c &&
                       ag.is_Return_Customer__c == o.Is_Return_Customer__c &&
                       (ag.Franchise__c != Null && ag.Franchise__c.split(',').Contains(o.Franchise__c)) &&
                       ag.Use_in_OPPPHSummaryBatch__c){
                           task AutoGenerate = CreateTask(ag, o);
                           TaskInsertList.add(autoGenerate);
                       }
                }
            }
        }
        if(!updateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
        if(!taskInsertList.isEmpty()){
            Database.SaveResult [] SRes2 = Database.insert(taskInsertList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes2);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - OpportunityPHSummaryBatch ' + date.today().format(), 'Starting AccountPurchasedStepsReportingBatch');
        Database.executeBatch(new AccountPurchasedStepsReportingBatch(), 200);
    }
    
    /*
    Description: Creates a single task record in memory based on parameters
    Parameters (2): Subject name of the task, Opportunity that task is related to
    Returns: New task
    */
    @TestVisible
    private Task CreateTask(Auto_Generated_Tasks__mdt ag, Opportunity o){
        Task t = new task();
        t.ActivityDate = o.CloseDate + integer.valueOf(ag.Add_Days__c);
        t.WhatId = o.Id;
        t.OwnerId = o.OwnerId;
        t.Sales_Representative__c = o.Sales_Representative__c;
        t.Status = 'Open';
        t.Subject = ag.Task_Subject__c;
        return t;
    }

    /*
    Description: Depending on franchise, returns quantity of lifetime support for a single purchase history 
    Jira: FRN-13 Data migration.  Added ability to change rules of what is a lifetime support depending on franchise  
    */
    private static Decimal AddOrSubtractStep(purchase_history__c p, set<string> skuSet){
        switch on p.Franchise__c {
            when 'Northwest' {
                if(p.SKU__c != NULL && skuSet.contains(p.SKU__c.toUpperCase()))
                    return p.Quantity__c;
            }
            when 'Midwest' {
                if(p.class__c.toUpperCase() == 'SUPPORTS' || p.class__c.toUpperCase() == 'DEMOS')
                    return p.Quantity__c;
            }
        }
        return 0;
    }
}