/*Developed by: Minh Nguyen      3/2021
  Description: Class to hold all purchase history related functions from triggers/handlers
 
*/
public class PurchaseHistoryFunctions {
    
    /*Description: On inserto f purchase history, attempt to populate the account__c field with RICSId or name/phone from the Purchase history.
     *Paramter: List of inserted purchase history
	 *Void action: Attempts to query for account related to the purchase history given the RICSId or name/phone combination.
    */
    public static void PopulateAccount(list<Purchase_History__C> PurchaseHistoryList){
        list<String> CustomerIdList = new list<String>();
        list<string> NameList = new list<string>();
        map<string, Id> RICSIdMap = new Map<string, Id>();
        map<String, Id> NameMap = new map<string, Id>();
        map<string, Id> PhoneMap = new map<string,Id>();
        for(Purchase_History__C ph : PurchaseHistoryList){
            CustomerIdList.add(ph.CustomerId__c != null? ph.CustomerId__c : null); //create RICS Id list
            NameList.add(ph.firstName__c != Null && ph.lastName__c != Null ? ph.FirstName__c + ' ' + ph.LastName__c : Null); //create Name list
        }
        
        //Query for accounts with name and RICS Id
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
            //if RICS Id finds match in accounts, then use that account.  
            if(ph.CustomerId__c != Null && RICSIdMap != Null && RICSIdMap.ContainsKey(ph.CustomerId__c)){
                ph.Account__c = RICSIdMap.get(ph.CustomerId__c);
                continue;
            }  
            
            //else use first/last/phone to find a match
            if(ph.FirstName__c != Null && ph.lastName__c != Null && ph.Phone__c != Null && 
               NameMap != Null && PhoneMap != Null && NameMap.ContainsKey(ph.FirstName__c.toLowerCase() + ' ' + ph.LastName__c.toLowerCase()) && 
               PhoneMap.ContainsKey(UtilityAndFactory.PhoneSimplify(ph.Phone__c))){
            	ph.Account__c = PhoneMap.get(UtilityAndFactory.PhoneSimplify(ph.Phone__c));
            }              
        }
    }
    
    
    /*Description: On newly Inserted Purchase history, attempt to find an opportunity on the given account, match transaction date to closedate of opp
      parameter: list of inserted purchase history
	  void action: Only purchase histories with account meets criteria.  Finds opportunity on account with transaction date = close date, and populate opportunity__c on 
				   on the purchase history. 
    */
    public static void PopulateOpportunity(list<Purchase_History__c> newList){
        list<Purchase_History__c> workList = new list<Purchase_History__c>([Select Account__c, Transaction_date__c from Purchase_History__c where id in : newList]);
        list<Id> AccId = new list<Id>();
        list<Purchase_History__c> PHAccountPopulated = new list<Purchase_History__c>(); 
		list<Purchase_History__c> PhUpdateList = new list<Purchase_History__c>();       
        for(Purchase_History__c ph : workList){
            if(ph.Account__c != Null){
                PHAccountPopulated.add(ph);  
                AccId.add(ph.Account__c); //get account id from purchase history
            }
        }
        if(!AccId.isEmpty()){  //find opportunity using account id
        	list<Opportunity> Opplist = new list<Opportunity>([Select CloseDate,AccountId from Opportunity where AccountId in : AccId]);
        
            for(Purchase_History__c ph : PHAccountPopulated){//find opportunity with closedate = transaction date. 
            	for(Opportunity o : OppList){
                	if(ph.Transaction_Date__c == o.CloseDate && ph.Account__c == o.AccountId){
                    	Ph.Opportunity__c = o.Id;
                    	PhUpdateList.add(Ph);
                		break;
                	}
            	}
        	}
            	if(!PhUpdateList.isEmpty()){
                	try{
            		update PhUpdateList;
            	} catch (dmlException e){
                	UtilityAndFactory.ErrorLog('Failure - PHAttemptPopulateAccountBatch on OppInsertList insert', 'Exception ' + e);
            	}
            }
        }
    }
}