/*Developed by: Minh Nguyen  4/2021
  Description: After RICS Sale data is inserted via RICSPOSTransactionBatch, this job attempts to populate the account using RICS Id, name/phone combo
  -Also creates opportunity
  
  Query:  All purchase history with no accounts and transaction date of starting from 1st of last month. 
  Execute: Attempts to matches RICS Id or name/phone combo with an account
  Finish: Calls OpportunityPHSummarybatch() 
 
  //To Run in Execute Annonymous
  Database.ExecuteBatch(new PHAttemptPopulateAccountBatch(), 100);
*/
public class PHAttemptPopulateAccountBatch implements Database.batchable<sObject>{
    private static string apexClass = 'PHAttemptPopulateAccountBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);

    public Database.QueryLocator start(Database.BatchableContext BC){
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        Date start = date.today().addmonths(-1).toStartOfMonth();
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        PHAttemptPopulateAccountBatch.CreateAccount(scope);
    }
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - PHAttemptPopulateAccountBatch ' + date.today().format(), 'Starting OpportunityPHSummaryBatch');
        Database.executeBatch(new OpportunityPHSummaryBatch(), 1000);
    }
    
    public static void CreateAccount(list<purchase_history__c> scope){
        list<String> CustomerIdList = new list<String>();
        list<string> NameList = new list<string>();
        map<string, Id> RICSIdMap = new Map<string, Id>();
        map<String, Id> NameMap = new map<string, Id>();
        map<string, Id> PhoneMap = new map<string,Id>();
        list<Purchase_History__c> UpdateList= new list<Purchase_History__c>();
        list<Purchase_History__c> PurchaseHistoryList= new list<Purchase_History__c>();
        PurchaseHistoryList = (list<Purchase_History__c>)scope;
        for(Purchase_History__C ph : PurchaseHistoryList){
            CustomerIdList.add(ph.CustomerId__c != null? ph.CustomerId__c : null); //Gets RICS Id of customer from Purchase history
            NameList.add(ph.firstName__c != Null && ph.lastName__c != Null ? ph.FirstName__c + ' ' + ph.LastName__c : Null); //Create a name string for comparison
        }
        list<Account> AccWithName = new list<account>([select Phone, Name from account where Name in : NameList and phone != Null and name != Null]);
        list<Account> AccWithCustomerId = new list<account>([select RICSId__c from account where RICSId__c in : CustomerIdList]);
        for(account a : AccWithCustomerId){
            RICSIdMap.put(a.RICSId__C, a.Id);
        }
        for(account a : AccWithName){
            NameMap.put(a.Name.toLowerCase(), a.Id);
            PhoneMap.put(UtilityAndFactory.PhoneSimplify(a.Phone), a.Id);
        }
        for(Purchase_History__c ph : PurchaseHistoryList){
            if(ph.CustomerId__c != Null && RICSIdMap != Null && RICSIdMap.ContainsKey(ph.CustomerId__c)){
                ph.Account__c = RICSIdMap.get(ph.CustomerId__c);
                updateList.add(ph);
                continue; //if found via rics id, then go to next iteration of PH
            }  
            
            //use name/phone number if RICSId is not in Salesforce. 
            if(ph.FirstName__c != Null && ph.lastName__c != Null && ph.Phone__c != Null && 
               NameMap != Null && PhoneMap != Null && NameMap.ContainsKey(ph.FirstName__c.toLowerCase() + ' ' + ph.LastName__c.toLowerCase()) && 
               PhoneMap.ContainsKey(UtilityAndFactory.PhoneSimplify(ph.Phone__c))){
               ph.Account__c = PhoneMap.get(UtilityAndFactory.PhoneSimplify(ph.Phone__c));
               updateList.add(ph);
            }              
        }
        if(!updateList.isEmpty()){
            try{
              update updateList;
              PHAttemptPopulateAccountBatch.createOpportunity(updateList); //call createOpportunity to create opportunities
            } catch (exception e){
                UtilityAndFactory.ErrorLog('Failure - PHAttemptPopulateAccountBatch', 'Exception ' + e);
            }
        }
        
    }
    
    //Similar function to CreateOpportunityOrphanPHBatch
    public static void createOpportunity(list<purchase_history__c> scope){
        list<purchase_history__c> phList = new list<purchase_history__c>();
        list<purchase_history__c> PHWithMatchingOpportunity = new list<purchase_history__c>();
        list<purchase_history__c> PHWithNoMatchingOpp = new list<purchase_history__c>();
        list<purchase_history__c> PhUpdateNewOpportunity = new list<purchase_history__c>();
        list<opportunity> oppInsertList = new list<opportunity>();
        list<Id> accId = new list<Id>();
        map<string, String> dateAccIdOppMap = new map<string,string>();
        map<string, purchase_history__c> PhlistMap = new map<string,purchase_history__c>();
        map<Id, Id> AccContactMap = new map<Id, Id>();
        
        phList = [Select Account__c, Account__r.name, Opportunity__c, Ownerid, Sales_Representative__c, firstName__c, 
                  lastName__c, CustomerId__c, Phone__c,transaction_date__c from purchase_history__c where id in : scope];
        
        for(purchase_history__c p : phList){
            accId.add(p.Account__c);
        }
        
        list<contact> contactList = new list<contact>([select accountid from contact where accountid in : accId]);
        for(contact c : contactList){
            AccContactMap.put(c.accountId, c.Id);
        }
        
        list<opportunity> oppList = new list<opportunity>([Select closeDate,accountId,account.name from Opportunity where accountid in : accId]);
        for(opportunity o : oppList){
            dateAccIdOppMap.put(o.accountId + ' ' + o.closeDate, o.Id);
        }
        for(purchase_history__c p : phList){
            if(dateAccIdOppMap != Null && !dateAccIdOppMap.containsKey(p.Account__c + ' ' + p.Transaction_Date__c)){
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
            o.is_return_customer__c = True;
            o.StageName = 'Purchase Made';
            o.CloseDate = p.Transaction_Date__c;
            o.Sales_Representative__c = p.Sales_Representative__c;
            o.OwnerId = p.OwnerId;
            o.name = p.account__r.name +  ' ' + p.Transaction_Date__c.format();
            o.Customer__c = AccContactMap != Null && AccContactMap.ContainsKey(p.Account__c) ? AccContactMap.get(p.Account__c) : Null;
            OppInsertList.add(o);
        }
        if(!OppInsertList.isEmpty()){
            Database.SaveResult [] SRes = Database.insert(OppInsertList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }

        list<opportunity> newInsertOpps = new list<opportunity>([select accountid from opportunity where id in : oppinsertList]);
        for(opportunity o : newInsertOpps){
            PHOppIdMap.put(o.AccountId, o.Id);
        }
        
        //Update the rest of the line items of that ticket
        for(Purchase_history__c ph : PHWithNoMatchingOpp){
            ph.Opportunity__c = PhOppIdMap.get(ph.Account__c);
            PhUpdateNewOpportunity.add(ph);
        }

        if(!PhUpdateNewOpportunity.isEmpty()){
            Database.SaveResult [] SRes2 = Database.update(PhUpdateNewOpportunity, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes2);
        }

        if(!PHWithMatchingOpportunity.isEmpty()){
            Database.SaveResult [] SRes3 = Database.update(PHWithMatchingOpportunity, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes3);
        }
    }
    
}