/*
Written by Minh Nguyen
Description: Batch class that runs on account to calculate totals for purchase information 
Batch query: All Accounts
Batch execute: Subqueries for purchase_history__c in each accounts and roll up to account fields
Batch finish: Calls 'AccountReferralBatch' class.  

09/20/2021: Jira SFSLII-265: Refactor - Convert list of hard coded supports to Support_SKUS__mdt
09/29/2021 Update: Moved query to New custom metadata (Batch job breaker) for ease of accessibility
- New CMDT: Franchise Opt Out. Easy opt in and out of apex classes for records.
*/
//id bpId = Database.executeBatch(new AccountPurchasedStepsReportingBatch(), 2000);

public class AccountPurchasedStepsReportingBatch implements Database.Batchable<sObject>{
    private static string apexClass = 'AccountPurchasedStepsReportingBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    private static list<Support_SKUS__mdt> supportSKUs = [select masterLabel, type__c from Support_SKUS__mdt];
    
    public database.QueryLocator start(Database.BatchableContext BC){
        date varCreatedDate = date.today().addMonths(-1).toStartofMonth();
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }
    
    public void execute(Database.BatchableContext BC, list<Account> scope){
        set<string> lifeTime = new set<string>();
        set<String> nonLifeTime = new set<string>();
        set<String> nonAccessories = new set<string>();

        //Query for Support SKUS using custom meta data table and populate into lists
        for(Support_SKUS__mdt s : supportSKUs){
            if(s.type__c == 'Lifetime')
                lifeTime.add(s.masterLabel);
            else if(s.type__c == 'NonLifetime')
                nonLifeTime.add(s.masterLabel);
            else
                nonAccessories.add(s.masterLabel);
        }

        list<account> updateList = new list<account>(); //empty list to populate to update
        
        //Loop through every account, calculate steps and purchase information from purchase_history__c records
        for(account a : [select Accessories__c, Purchase_Total_MTD__c, Net_Purchase_Total__c, NonLifetime_Purchase__c, NonLifetime_Purchase_91_180__c,
			NonLifetime_Purchase_181__c,Latest_Opportunity_Date__c, Steps_Purchased__c, Steps_Purchased_181__c, Steps_Purchased_91_180__c,
			(select class__c, Franchise__c, Transaction_Type__c, SKU__C, Quantity__c, price__c, transaction_date__c from purchase_histories__r where ticket_voided__c = False),
			(select closeDate from Opportunities order by closeDate desc limit 1) from account where id in : scope]){
            a.Latest_Opportunity_Date__c = Null;
            a.Net_Purchase_Total__c = 0;
            a.Purchase_Total_MTD__c = 0;
            a.Steps_Purchased__c = 0;
            a.NonLifetime_Purchase__c = 0;
            a.Steps_Purchased_91_180__c = 0;
            a.NonLifetime_Purchase_91_180__c = 0;
            a.Steps_Purchased_181__c = 0;
            a.NonLifetime_Purchase_181__c = 0;
            a.Accessories__c = 0;
            /*
            Updated on 12/13/2021: Added new functions to calculate supports/accessories.  
            Jira: FRN-35 - processing SKU from different franchise to get correct support roll up
            */
            for(Purchase_History__c p : a.purchase_Histories__r){
                if(p.transaction_date__c >= date.today().addDays(-90)){
                    a.Steps_Purchased__c += LifeTime(p, lifeTime);
                    a.NonLifetime_Purchase__c += nonLifeTime(p, nonlifeTime);
                }
                else if(p.transaction_date__c >= date.today().addDays(-180)){
                    a.Steps_Purchased_91_180__c += LifeTime(p, lifeTime);
                    a.NonLifetime_Purchase_91_180__c += nonLifeTime(p, nonlifeTime);
                }
                else if(p.transaction_date__c < date.today().addDays(-180)){
                    a.Steps_Purchased_181__c += LifeTime(p, lifeTime);
                    a.NonLifetime_Purchase_181__c += nonLifeTime(p, nonlifeTime);
                }
                a.Accessories__c += Accessories(p, lifeTime, nonLifetime, nonAccessories);

                a.Net_Purchase_Total__c +=  p.Price__c;
                if(p.Transaction_Date__c >= date.today().toStartOfMonth())
                    a.Purchase_Total_MTD__c += p.Price__c;
            
            }
            //Queried from a single opportunity in the account, order by created date desc
            for(opportunity o : a.opportunities){
                a.Latest_Opportunity_Date__c = o.CloseDate;
            }                 
            updateList.add(a);
        }
        if(!updateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - AccountPurchasedStepsReportingBatch ' + date.today().format(), null);
        Database.executeBatch(new AccountReferralBatch(), 2000);
    }

    private static decimal LifeTime(purchase_history__c p, set<string> SKUset){
        switch on p.Franchise__c {
            when 'Northwest' {
                if(p.SKU__c != NULL && SKUset.contains(p.SKU__c.toUpperCase()))
                    return p.Quantity__c;
            }
            when 'Midwest' {
                if((p.class__c.toUpperCase() == 'SUPPORTS' || p.class__c.toUpperCase() == 'DEMOS') && math.abs(p.price__c) >= 250)
                    return p.Quantity__c;
            }
        }
        return 0;
    }

    private static decimal nonLifeTime(purchase_history__c p, set<string> SKUset){
        switch on p.Franchise__c {
            when 'Northwest' {
                if(p.SKU__c != NULL && SKUset.contains(p.SKU__c.toUpperCase()))
                    return p.Quantity__c;
            }
            when 'Midwest' {
                if((p.class__c.toUpperCase() == 'SUPPORTS' || p.class__c.toUpperCase() == 'DEMOS') && math.abs(p.price__c) < 250)
                    return p.Quantity__c;
            }
        }
        return 0;
    }

    private static decimal Accessories(purchase_history__c p, set<string> lifeTime, set<string> nonLifeTime, set<string> nonAccessories){
        switch on p.Franchise__c {
            when 'Northwest' {
                if(p.SKU__c != Null && !LifeTime.Contains(p.SKU__c.toUpperCase()) && 
                !nonLifeTime.Contains(p.SKU__c.toUpperCase()) && 
                !nonAccessories.Contains(p.SKU__c.toUpperCase()))
                    return p.Quantity__c;
            }
            when 'Midwest' {
                if(p.class__c.toUpperCase() != 'SUPPORTS' && p.class__c.toUpperCase() != 'DEMOS')
                    return p.Quantity__c;
            }
        }
        return 0;
    }
}