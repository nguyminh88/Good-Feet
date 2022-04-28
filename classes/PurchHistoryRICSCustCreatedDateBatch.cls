/* Developed by: Minh Nguyen
 * Date: 3/2021
 * Description: Queries for purchase history without a customer created date and makes callout to RICS to populate.
 * Unbulked due to RICS limitation.  Run in batches of 1 only. Called automatically on RICSBatchPOSTransaction Finish()
 * Execute annon: id bpId = Database.executeBatch(new PurchHistoryRICSCustCreatedDateBatch(), 1);
 * */
public class PurchHistoryRICSCustCreatedDateBatch implements Database.Batchable<sobject>, Database.AllowsCallouts{
    private static string apexClass = 'PurchHistoryRICSCustCreatedDateBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    
    public database.QueryLocator start(Database.BatchableContext BC){
        date yest = date.today().addDays(-4);
        date tmr = date.today().addDays(1);
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
     }
    
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        list<purchase_history__c> phList = new list<purchase_history__c>();
        phList = (list<purchase_history__c>)scope;
        for(purchase_history__c ph : phList){
            PurchHistoryRICSCustCreatedDateBatch.GetCustomerCreatedDate(ph.Id);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        UtilityAndFactory.ErrorLog('Successful - PurchHistoryRICustCreatedDateBatch ' + date.today().format(), null);
    }
    
    /*
    Description: Builds a payload of just the RICS Id and makes RICS callout.
    -In response, get the Customer Created Date from RICS system for reporting purposes
    -Parameter: A single purchase history Id
    -Return: 
    */
    public static void GetCustomerCreatedDate(String PurchaseHistoryId) {
        purchase_history__c ph = [select Customer_Created_Date__c, CustomerId__c from purchase_history__c where id =: PurchaseHistoryId];
        String apiEndPoint = 'Customer/GetCustomerDetails';
        map < string, object > js = new map < string, object > ();
        js.put('CustomerId', ph.CustomerId__c);
        string JSONReq = JSON.serialize(js); //payload with just Rics Id
        system.debug(ph.customerId__c);
        
        //wait few seconds. RICS Endpoint limit, 5 per 5 seconds.  
        UtilityAndFactory.Wait(2000);
                
        //Callout       
        Map < String, Object > theReturn = (Map < String, Object > ) UtilityAndFactory.MakeRICSCallOut(apiEndPoint, JSONReq, Null);
        list < object > customers = new list < object > ();
        map<string,object> customerMap = new map<string,object>();
        
        if(test.isRunningTest()){
            list<object> Deets = new list<object>();
            theReturn.put('CustomerDetails', deets); //Save the response 'customerDetails' object 
        }
        
        customers = theReturn != Null && theReturn.containsKey('CustomerDetails') ? (list < object > ) theReturn.get('CustomerDetails') : Null;
        
        if(customers != Null){
            for(object o : customers){
                customerMap = (map<string,object>)o;
            }
            //populate customer created date on PH if createdOn is in response
            ph.Customer_Created_Date__c = customerMap != null && CustomerMap.containskey('CreatedOn') ? date.valueOf(customerMap.get('CreatedOn').toString().left(10)) : Null;
        
            if(ph.Customer_Created_Date__c != Null){
                try {
                    update ph; 
                } catch (DMLexception e){
                    UtilityAndFactory.ErrorLog('Failure - ph update in PurchHistoryRICSCustCreatedDateBatch', 'DMLException : ' + e);
                }
            }
                
        }
    }
}