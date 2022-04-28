/*
Developed by:  Minh Nguyen     5/2021
Description: -Queries for accounts with referrals, runs after AccountPurchasedStepsReportingBatch. 
             -rolls up referred accounts purchase, and also counts the correct number of referrals
Query: All accounts where Referred_By__c is populated
Execute: Updates account fields: SuccessfulReferrals__c, Referal_Purchase_total__c, Referral_MTD__C
Finish: Calls AccountPurchaseMCJourneyBatch.  

Update 09/21/2021: Refactored with comments, try/catch block for DML
Update 09/29/2021: Updated query to streamline - uses CMDT to easily update queries/opt in and out
*/
//Database.executeBatch(new AccountReferralBatch(), 2000);

public class AccountReferralBatch implements Database.Batchable<sObject>{
   private static string apexClass = 'AccountReferralBatch'; //var to pass to query and opt out MDT
   private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);

   public database.QueryLocator start(Database.BatchableContext BC){
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }
    
   public void execute(Database.BatchableContext BC, list<sObject> scope){
     	list<account> updateList = new list<account>();
      list<account> scopeAccounts = new list<account>();
      scopeAccounts = (list<account>)scope;
      set<Id> accIds = new set<Id>();
      for(account a1 : scopeAccounts){
         accIds.add(a1.Referred_By__c); //Populates list with all referral accounts from query
      }
         
      //Get all referral accounts
      for(account a : [select SuccessfulReferrals__c, Referral_MTD__c, Referral_Purchase_Total__c,(select net_purchase_total__c, purchase_total_MTD__c from accounts__r) 
                          from account where id in : accIds]){
               
         integer successfulRefs = 0; //reset with every new referral account iteration                
         a.Referral_MTD__c = 0;
         a.Referral_Purchase_Total__c = 0;
         for(account r : a.accounts__r){ //inner loop through each account to loop through referred accounts
            successfulRefs += 1;
               if(r.Purchase_Total_MTD__c != Null)
                	a.Referral_MTD__c += r.purchase_total_MTD__c; //add referred purchase total mtd to referral acc mtd
               if(r.Net_Purchase_Total__c != Null)
                	a.Referral_Purchase_Total__c += r.net_purchase_total__c; //add referred total to referrals purchase total
            }
            a.SuccessfulReferrals__c = successfulRefs;
            updateList.add(a);                   
         }
         
         if(!updateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog('AccountFunctions.BeforeUpdateDoNotContact()', SRes);
         }
     }
             
     public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - AccountReferralBatch ' + date.today().format(), null);
        Database.executeBatch(new AccountPurchaseMCJourneyBatch(), 2000);
   }    
}