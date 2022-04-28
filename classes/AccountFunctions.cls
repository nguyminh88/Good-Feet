/* Developed by: Minh Nguyen      3/2021
   Description: Contains functions that are called from the accountTriggerHandler class
   
   Jira (SFSLII):
   -129 Account Object Revision
   -
   Update 09/20/2021: Refactored with comments and try/catches on DML statements.
*/

public class AccountFunctions {
    /*
    Jira: SFSLII-129: Account Object Revision
    Description: Queries all tasks related to the account and sets status to Completed after 'Do Not Check' set to true
    Parameter: Updated Account list from AccountTriggerHandler
    void action: Updates list of task 
    */
    public static void BeforeUpdateDoNotContact(list<account> accountList){
        list<account> DNCaccounts = new list<account>();
        for(account a : accountList){
            if(a.Do_Not_Contact__c)
                DNCaccounts.add(a); //Verify that list of account has 'do not checkbox' TRUE
        }

        //Get tasks related to contacts/opps/cases/accounts from accountlist
        list<contact> contacts = new list<contact>([select id from contact where accountid in : DNCaccounts limit 10000]);
        list<opportunity> opportunities = new list<opportunity>([select id from opportunity where accountid in : DNCaccounts limit 10000]);
        list<case> cases = new list<case>([select id from case where accountid in : DNCaccounts limit 10000]);
        list<task> tasks = new list<task>([select description, Status from task 
                                            where (status != 'Completed') AND 
                                            (whatid in :cases OR whoid in :contacts OR whatid in :opportunities OR whatid in :DNCaccounts) limit 10000]);
        for(task t : tasks){
            t.Status = 'Completed'; //set status to completed
        }
        if(!tasks.isEmpty()){
            Database.SaveResult [] SRes = Database.update(tasks, False);
            UtilityAndFactory.SaveResultErrorLog('AccountFunctions.BeforeUpdateDoNotContact()', SRes);
        }
            
    }
    
    /*
    Description: Update name of contact when name of customer is updated on account
    Parameter: old map and new map of accounts being updated
    Void action: Updates list of contact related to list of new map accounts with the updated name
    */
    public static void BeforeUpdateSync(map<id,account> oldMap, map<id,account> newMap){
        map<string, contact> accContactMap = new map<string, contact>();
        map<string, String> nameMap = new map<string, String>();
        set<contact> updateList = new set<contact>();
        list<contact> contactUpdateList = new list<contact>();
        for(account a : newMap.values()){
            if(oldMap.get(a.id).name != a.name){
                nameMap.put(a.id,a.name); //Build out map of names from id to name.  Calls NameSsplitter function to split name             
            }
        }
        
        if(!nameMap.isEmpty()){
            //Get list of contacts related to accounts and map out contact for object access.
            list<contact> contactList = new list<contact>([select accountid, firstname, lastname 
                                                           from contact where accountid in : nameMap.keySet() limit 1]);
            for(contact c : contactList){
                accContactMap.put(c.accountId, c);
            }
            
            if(!accContactMap.isEmpty()){
                for(contact c : contactList){
                	c.firstName = UtilityAndFactory.GetFirstName(nameMap.get(c.AccountId));
                    c.lastName = UtilityAndFactory.GetLastName(nameMap.get(c.AccountId));
                    contactUpdateList.add(c);
                }
                
                if(!contactUpdateList.isEmpty()){
                    Database.SaveResult [] SRes = Database.update(contactUpdateList, False);
                    UtilityAndFactory.SaveResultErrorLog('AccountFunctions.BeforeUpdateSync()', SRes);
                }
            }
        }
    }
    
    /*
    Jira: SFSLII-55 Customer Data - Salesforce -> RICS
    Description: On before insert of account, check if name + phone number combo exists, trigger.addError if so to prevent duplicate account
    Parameter: List of inserted accounts
    Void Action: AddError if duplicate is found
    */
    public static void beforeInsertPhoneDupeCheck(list<account> accountList){
        list<string> phoneList = new list<string>();
        list<string> nameList = new list<string>();
        map<string,boolean> phoneCheck = new map<string,boolean>();
        for(account a : accountList){
            //build out phone and name list to check against.  
            phoneList.add(UtilityAndFactory.phoneSimplify(a.phone));
            nameList.add(a.name);
        }
        map<id, Account> duplicateAccounts = new map<id, Account>([select phone, name from account where Phone in : phoneList 
                                                                   AND name in : nameList]);
        for(account a : duplicateAccounts.values()){
            phoneCheck.put(UtilityAndFactory.phoneSimplify(a.phone),true); //map out phone to account to check
        }
        for(account a :accountList){
            if(phoneCheck.containsKey(UtilityAndFactory.phoneSimplify(a.phone))) //if match is found, add trigger error.
                a.addError('Name and Phone Number Duplicate Detected. Unable to Create New Account');
        }
    }
    
    /*
    Jira: SFSLII-55 Customer Data - Salesforce -> RICS
    Description: On insert of account manually (no gf-app), create corresponding contact record
    parameter: List of accounts inserted
    Void action: Checks if clienteling id (from gf app) is null, then creates contact with information from account.  
    */
    public static void CreateContactAfterManualInsert(list<Account> accountList){
        list<account> accountWorkList = new list<account>();
        list<contact> contactInsertList = new list<contact>();
        for(account a : accountList){
            //check if from manually inserted (clienteling id would not be null from gf app)
            if(a.Clienteling_Id__c == null){
                accountWorkList.add(a);
            }            
        }
        //create contact for each account
        if(!accountWorkList.isEmpty()){
            for(account a : accountWorkList){
                contact c = new contact();
                c.firstName = UtilityAndFactory.GetFirstName(a.Name);
                c.lastName = UtilityAndFactory.GetLastName(a.Name);
                c.Phone = a.Phone;
                c.Email = a.ContactEmail__c;
                c.AccountId = a.Id;
                c.Sales_Representative__c = a.sales_representative__c;
                contactInsertList.add(c);
            }

            if(!contactInsertList.isEmpty()){
                Database.SaveResult [] SRes = Database.insert(contactInsertList, False);
                UtilityAndFactory.SaveResultErrorLog('AccountFunctions.CreateContactAfterManualInsert()', SRes);
            }
        }
    }
}