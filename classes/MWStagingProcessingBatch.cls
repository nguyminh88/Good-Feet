/*
Developed by Minh Nguyen 11/4/2021
Jira: FRN-35 GF Midwest data processing

Description: Master batch job to convert GF Midwest's staging data into formatted salesforce data
Query: All unprocessed staging data
Execute: Formats all fields, creates Account/purchase history, flag staging to delete
Finish:

==========================================================================================================
Execute Anonymous: Database.executeBatch(new MWStagingProcessingBatch(), 1);

---deleting acc/ph that was just created---
date d = date.newInstance(2021, 11, 1);
list<account> accList = [select id from account where createddate >: d limit 5000];
list<purchase_history__c> phlist = [select id from purchase_history__c where createddate >: d limit 5000];
//list<opportunity> opp = [select id from opportunity where createddate >: d];
//list<task> tasks = [select id from task where createddate >: d];
//delete tasks;
//database.delete(opp,false);
delete phlist;
database.delete(acclist,false);
==========================================================================================================
*/

public class MWStagingProcessingBatch implements Database.Batchable<sObject>{
    private static string apexClass = 'MWStagingProcessingBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    private static list<Support_SKUS__mdt> supportSKUs = [select masterLabel, type__c from Support_SKUS__mdt];
    
    public database.QueryLocator start(Database.BatchableContext BC){
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
    }

    public void execute(Database.BatchableContext BC, list<Mw_Staging__c> scope){
        list<purchase_history__c> phFinalInsertList = new list<purchase_history__c>();
        map<purchase_history__c, mw_staging__c> phInsertList = new map<purchase_history__c, mw_staging__c>();
        list<string> customerIdList = new list<string>();
        Mw_Staging__c mwAcc = scope[0];
        account a = new account();
        string failureDuplicate = 'Did not migrate: Duplicate Detected';
        string success = 'Successful Migration';
        string failureNoSalesData = 'Did not migrate: No Sales data found'; 

        list<Mw_Staging__c> mwPHList= new list<Mw_Staging__c>([Select Initial_Migration__c, Error__c, PostingClass__c, InventoryId__c, Sales_Customer_Name__c, 
        Sales_CustomerId__c, Phone__c, Customer_Name__c, 
        Type__c, TranType__c, BranchId__c, OrderNBR__c, OrderLineNbr__c, 
        NetSalesAmount__c, Quantity__c, SalesPersonId__c, DocumentDate__c from Mw_Staging__c 
        where type__c = 'Purchase History' AND Sales_CustomerId__c =: mwAcc.CustomerId__c 
        AND processed__c = FALSE AND trantype__c != 'DRM' AND inventoryId__c != 'INSTORE CHARGE'
        ]);

        if(!mwPHList.isEmpty()){
            list<account> dupeCheck = new list<account>([select Sales_Representative__c,OwnerId  from account where acumaticaId__c =: mwAcc.CustomerId__c limit 1]);
            list<date> transactionDatesList = new list<date>();
            list<string> phDupeCheckList = new list<string>();
            

            //duplicate check for account
            if(dupeCheck.size() < 1){
                a = ConvertToAccount(mwAcc);
                database.Insert(a,false);
                mwacc.Error__c = Success + '- Account Id:  ' + a.Id;
            }else{
                a = dupeCheck[0];
                mwacc.Error__c = failureDuplicate;
            }
            for(Mw_Staging__c m : mwPhList){
                phInsertList.put(ConvertToPurchaseHistory(m,a.Id), m);
            }

            //duplicate check for purchase history
            for(purchase_history__c ph : phInsertList.keySet()){
                transactionDatesList.add(ph.transaction_date__c);
            }
            list<purchase_history__c> existingPHList = new list<purchase_history__c>([select Transaction_type__c, transaction_date__c, store__c, ticket_number__c, ticket_line_number__c 
                                                                                       from purchase_history__c 
                                                                                    where franchise__c = 'Midwest' AND transaction_date__c in : transactionDatesList]);
            for(purchase_history__c p : existingPHList){
                phDupeCheckList.add(p.store__c + p.Transaction_type__c + p.transaction_date__c + p.ticket_number__c + (integer)p.ticket_line_number__c);
            }
            for(purchase_history__c p : phInsertList.keySet()){
                if((!phDupeCheckList.isEmpty() && !phDupeCheckList.contains(p.store__c + p.Transaction_type__c + p.transaction_date__c + p.ticket_number__c + (integer)p.ticket_line_number__c)) ||
                phDupeCheckList.isEmpty()){
                    PHfinalInsertList.add(p);
                    phInsertList.get(p).Error__c = success;
                } else {
                    phInsertList.get(p).Error__c = failureDuplicate;
                }
                phInsertList.get(p).Processed__c = TRUE;
            }
            
            //insert and get most earliest purchase history's sales rep and owner to populate on account
            if(!PHfinalInsertList.isEmpty()){
                database.Insert(PHfinalInsertList,false);
                List<purchase_history__c> phl = [select ownerId, Sales_Representative__c from purchase_history__c where id in : PHfinalInsertList ORDER BY transaction_date__c ASC limit 1];
                a.Sales_Representative__c = phl[0].Sales_Representative__c;
                a.OwnerId = phl[0].OwnerId;
                database.update(a,false);
            }
        } else {
            mwacc.Error__c = failureNoSalesData;
        }
		mwacc.processed__c = TRUE;
        Database.SaveResult SRes = database.update(mwacc,false);

        Database.SaveResult [] SRes2 = database.update(phInsertList.values(),false);
        UtilityAndFactory.SaveResultErrorLog(apexClass, SRes2);

    }

    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - MWStagingProcessingBatch Batch ' + date.today().format(), 'Starting MWPurchaseHistoryStagingBatch');
        Database.executeBatch(new MWPurchaseHistoryStagingBatch(), 100);
    }

    /*
    Description: Main function to converts MW staging object to account
    Parameter: A single MW staging record of type account.  
    Return: formats it to proper account fields, and returns new account
    */
    public static Account ConvertToAccount(Mw_Staging__c mw){
        Account a = new account();
        a.Name = NameFormat(mw.Customer_Name__c);
        a.Phone = mw.Phone__c != Null && UtilityAndFactory.PhoneSimplify(mw.Phone__c).isNumeric() ? UtilityAndFactory.PhoneSimplify(mw.Phone__c) : randomPhoneGenerator();
        a.ContactEmail__c = mw.Email__c;
        a.address__c = mw.AddressStreet__c;
        a.Zip_code__c = mw.Zip_Code__c;
        a.AcumaticaId__c = mw.customerId__c;
        return a;
    }

    /*
    Description: Main function to converts MW staging object to Purchase History
    Parameter: A single MW staging record of type purchase history.  
    Return: formats it to proper account fields, and returns new account
    */
    public static purchase_history__c ConvertToPurchaseHistory(MW_Staging__c mw, string accountId){
        purchase_history__c ph = new purchase_history__c();
        ph.FirstName__c = mw.Sales_Customer_Name__c != Null? UtilityAndFactory.GetFirstName(mw.Sales_Customer_Name__c) : Null;
        ph.LastName__c = mw.Sales_Customer_Name__c != Null? UtilityAndFactory.GetLastName(mw.Sales_Customer_Name__c) : Null;
        ph.Account__c = accountId;
        ph.Transaction_Type__c = mw.TranType__c == 'INV' ? 'Regular Sale' : 'Return';
        ph.Store__c = mw.BranchId__c != Null? mw.BranchId__c : Null;
        ph.Ticket_Number__c = mw.OrderNBR__c != Null? mw.OrderNBR__c : Null;
        ph.Ticket_Line_Number__c = mw.OrderLineNbr__c != Null? mw.OrderLineNbr__c : Null;
        ph.Price__c = mw.NetSalesAmount__c != Null? mw.NetSalesAmount__c : Null;
        ph.Quantity__c = mw.Quantity__c != Null? mw.Quantity__c : Null;
        ph.Salesperson_Number__c = mw.SalesPersonId__c != Null? mw.SalesPersonId__c : Null;
        ph.Transaction_date__c = mw.DocumentDate__c != Null? (date.parse(mw.DocumentDate__c.substring(0, mw.DocumentDate__c.length() - 4).deleteWhiteSpace())) : Null;
        ph.SKU__c = mw.InventoryId__c != Null ? mw.InventoryId__c : NULL;
        ph.Class__C = mw.PostingClass__c != Null ? mw.PostingClass__c : Null;
        ph.Initial_Migration__c = mw.Initial_Migration__c;
        
        return ph;
    }
    
    /*
    Description: Formats the name.  MW Midwest captures a full name field only and has two possible formats.
    format 1: 'LAST, FIRST'
    format 2: 'FIRST LAST'
    Paramteter: A string full name
    Return: a name string in the correct format for account (first last);
    */
    public static string NameFormat(String fullName){
        string Name = fullName;
        string tempName;
        list<string> SplitName = new list<string>();
        
        tempName = fullName.contains('MR.') ? fullName.remove('MR.') : tempName;
        tempName = fullName.contains('Mr.') ? fullName.remove('Mr.') : tempName;
        tempName = fullName.contains('MRS.') ? fullName.remove('MRS.') : tempName;
        tempName = fullName.contains('Mrs.') ? fullName.remove('Mrs.') : tempName;
        Name = tempName != Null && tempName.contains(',') ? tempName.remove(',') : Name;

        //Name is "LAST, FIRST"
        if(Name != Null && Name.contains(',')){
            SplitName = fullName.Split(',');
            Name = SplitName[1] + ' ' + SplitName[0].trim();
        }
        
        return Name;
    }

    /*
    Creates and returns a random phone number 
    GF Midwest requests that for all null phone numbers on accounts, populate with anything
    */
    public static string randomPhoneGenerator(){
        string randomPhoneNumber = '000';
        for(integer i = 0; i < 7; i++){
            string tempRandomNumb = string.valueOf(Integer.valueof((Math.random() * 9)));
            randomPhoneNumber = randomPhoneNumber + tempRandomNumb; 
        }
        return randomPhoneNumber;
    }
}