/*
Developed by: Minh Nguyen - 6/2/2021 WARNING: NOT BULKIFIED
Jira: NSRICS-7 SF-NS Customer Data Integration
Description: Called from NetsuiteEnqueuer class
-Builds out a JSON payload from the account/contact objects
-calls out to Netsuite Post endpoint created by Mark Robinson
-Either creates, or updates a new customer in NS, returns NS Id and populates Ns Id field on account
*/

public class NetsuiteIntegratorQueueable implements Queueable, Database.AllowsCallouts{
    private static string apexClass = 'NetsuiteIntegratorQueueable';
    private account unProcessedAccount;
    private static boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].isSandbox;
    private static boolean isTest = test.isRunningTest();
    private static Netsuite_API__mdt NSAPI = [Select Sandbox_Realm__c, Production_Realm__c, Https__c, URL__c, URLDeploy__c, Production_ConsumerKey__c,Production_ConsumerSecret__c,Production_Deploy__c,Production_Prefix__c,Production_Script__c,
                                               Production_TokenId__c,Production_TokenSecret__c,Sandbox_ConsumerKey__c,Sandbox_ConsumerSecret__c,
                                               Sandbox_Deploy__c,Sandbox_Prefix__c,Sandbox_Script__c,
                                               Sandbox_TokenId__c,Sandbox_TokenSecret__c from Netsuite_API__mdt	
                                               where masterlabel = 'Netsuite' limit 1];
    private static string script = isSandbox? NSAPI.Sandbox_Script__c : NSAPI.Production_Script__c;
    private static string deploy = isSandbox? NSAPI.Sandbox_Deploy__c : NSAPI.Production_Deploy__c;
    private static string netsuitePrefix = isSandbox? NSAPI.Sandbox_Prefix__c : NSAPI.Production_Prefix__c;
    private static string consumerKey = isSandbox? NSAPI.Sandbox_ConsumerKey__c : NSAPI.Production_ConsumerKey__c;
    private static string consumerSecret = isSandbox? NSAPI.Sandbox_ConsumerSecret__c : NSAPI.Production_ConsumerSecret__c;
    private static string tokenId = isSandbox? NSAPI.Sandbox_TokenId__c : NSAPI.Production_TokenId__c;
    private static string tokenSecret = isSandbox? NSAPI.Sandbox_TokenSecret__c : NSAPI.Production_TokenSecret__c;
    private static string https = NSAPI.Https__c;
    private static string URL = NSAPI.URL__c;
    private static string URLDep = NSAPI.URLDeploy__c;
    private static string consumerAndToken = consumerSecret + '&' + tokenSecret;
    private static string realm = isSandbox ? NSAPI.Sandbox_realm__c : NSAPI.Production_Realm__c;
    private static string FinalURL = https + netsuitePrefix + URL + script + URLDep + deploy;

    //Constructor
    public NetsuiteIntegratorQueueable(account a){
        this.unProcessedAccount = a;
    }

    //NOT BULKIFIED
    public void execute(QueueableContext context){
        MainProcessor(unProcessedAccount);
    }

    /*
    Description: Requeries account passed in from enqueuer class, Makes callout and stamps Nsid on account
    Paramter: Single account
    Void action: updates account with returned NSID response. 
    */
    public static void MainProcessor(account preAcc){
        account a = [select Phone, ContactEmail__c, Address__c, Zip_Code__c, Name, RICS_Account_Number__c, RICSid__c, Netsuite_Id__c from account where id =: preAcc.Id];
        ResponseHandler(NetsuitePOST(a), a); //Nested function calls, attemps to update account with NsId
    }

    /*
    Description: Builds out the JSON payload, sends payload with a callout and returns a mapped response payload
    Parameter: Account
    Return: Deserialized JSON response
    */
    public static Map<String, Object> NetsuitePOST(account a){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(FinalURL); //FinalURL is from static member variable
        req.setMethod('POST');
        req = NetsuiteConnector.signRequest(realm, req, consumerKey, tokenId, consumerAndToken); //Oauth 1.0 functions
        map<string, object> address = new map<string, object>();
        map <string, object> js = new map <string, object> ();
        list<contact> c = new list<contact>([Select firstname, lastname from contact where accountid =: a.Id limit 1]);
        string addr1 = a.address__c != Null? a.address__c : 'No Address';
        string zipCode = a.Zip_Code__c != Null? a.Zip_Code__c : Null;
        string phone = UtilityAndFactory.PhoneSimplify(a.Phone);
        string firstName = !c.isEmpty()? c[0].firstName : 'NoFirstName';
        string lastName = !c.isEmpty()? c[0].lastName : 'NoLastName';

        address.put('country', 'US');
        address.put('addr1', addr1);
        address.put('city', Null);
        address.put('state', Null);
        address.put('zip', zipCode);
        
        if(a.Netsuite_Id__c != Null)
            js.put('id', a.Netsuite_Id__c);
        js.put('firstname', firstName);
        js.put('lastname', lastName);
        js.put('email', a.contactEmail__c);
        js.put('phone', phone);
        js.put('custentity_celigo_sfnc_salesforce_id', a.Id);
        js.put('custentity_gf_rics_customer_id', a.RICSId__c);
        js.put('custentity_gf_rics_cust_acct_number', a.RICS_Account_Number__c);
        js.put('address', address);
        req.setBody(JSON.serialize(js));
    
        return MakeNSCallout(req,a);
    }

    /*
    Desc
    */
    public static void ResponseHandler(map<string, object> response, account a){
        if(response.containsKey('id')){
            list<account> updateList = new list<account>();
            //remove error log on success
            UtilityAndFactory.ErrorLog('Successful - Netsuite Callout', 'Account Name: ' + a.Name + ' --- SFID: ' + a.Id);
            if(a.Netsuite_Id__c == Null || (a.Netsuite_Id__c != Null && a.Netsuite_Id__c != response.get('id'))) {
                a.Netsuite_Id__c = string.valueOf(response.get('id'));
                updatelist.add(a);
                if(!updateList.isEmpty()){
                    Database.SaveResult [] SRes = Database.update(updatelist, False);
                    UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
                }
            }
        } else {
            string description = 'Account Name: ' + a.Name + ' --- SFID: ' + a.Id + '\n' + response;
            string shortDesc = description.left(255);
            UtilityAndFactory.ErrorLog('Failure - Netsuite Callout', shortDesc);
        }
    }

    public static Map<String, Object> MakeNSCallout(HttpRequest req, Account a){
        map<string, object> errMap = new map<string, object>();
        Http h = new Http();
        try{
            HTTPResponse res = h.send(req);
            return (Map <String, Object> ) JSON.deserializeUntyped(res.getBody());
        } catch (exception e){
            errMap.put('error', e);
            return errMap;
        }
    }
}