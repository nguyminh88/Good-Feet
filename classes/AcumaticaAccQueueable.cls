/*Developed by Minh Nguyen
 * Called from RICSEnqueuer.  This class should only be temporary until GF Midwest migrates to RICS. 
 * 
 * AcumaticaAccQueueable Acu = new AcumaticaAccQueueable(acclist);
 * system.enqueueJob(Acu);
*/

public with sharing class AcumaticaAccQueueable implements Queueable, Database.AllowsCallouts{
    private list < account > accList;
    private static string apexClass = 'AcumaticaAccQueueable'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    
    //Constructor, called from RICSEnqeuer class
    public AcumaticaAccQueueable(list <account> accounts) {
        this.accList = accounts;
    }

    //Execute
    public void execute(QueueableContext context) {/*
        list<account> updatelist = new list<account>();
        list < account > accounts = new list<account>([select City__c, State__c, Country__c, Name, Phone, ContactEmail__c, AcumaticaId__c, Address__c, Zip_Code__c 
                                     from account where id in: acclist]);
        
		updateList = (list < account > ) MainProcessor(accounts);
    	if(!updateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }    
    }
    
    //Main processor loops through account and calls CreateOrGetAcumaticaId() for each account
    //returns list account for Execute()'s updatelist
    public static list<account> MainProcessor(list<account> accounts){
        list<account> updateList = new list<account>();
        
        for (account a: accounts) {
            try{
                a.AcumaticaId__c = AcumaticaCall(a);
        	    updatelist.add(a);
            } catch (exception e){
                
            }
        }
        
        return updateList;
        
        
    }
    
    //Build JSON payload, call the utility function to handle the callout, receive response containing acumatica Id, save to account
    public static string AcumaticaCall(account a){
     

        string customerId;
        string JSONString;
        map<string,object> theReturn = new map<string,object>();
       	map<string,object> mainPayload = new map<string,object>();
        map<string,object> mainContact = new map<string,object>();
        map<string,object> name = new map<string,object>();
        map<string,object> email = new map<string,object>();
        map<string,object> address = new map<string,object>();
        map<string,object> street = new map<string,object>();
        map<string,object> postalCode = new map<string,object>();
        map<string,object> city = new map<string,object>();
        map<string,object> state = new map<string,object>();
        map<string,object> country = new map<string,object>();
        map<string,object> phone = new map<string,object>();
        map<string,object> AcumaticaId = new map<string,object>();
        map<string,object> customerIdMap = new map<string,object>();

        if(a.AcumaticaId__c != Null)
            AcumaticaId.put('value', a.AcumaticaId__c);
        if(a.Address__c != Null){
            street.put('value', a.Address__c);
            address.put('AddressLine1', street);
        }
        if(a.Zip_Code__c != Null) {   
            postalCode.put('value', a.Zip_Code__c);
            address.put('PostalCode', postalCode);
        }
        if(a.City__c != Null) {
            city.put('value', a.City__c);
            address.put('City', city);
        }
        if(a.State__c != Null) {
            state.put('value', a.State__c);
            address.put('State', state);
        }
        if(a.Country__c != Null) {
            country.put('value', a.Country__c);
            address.put('Country', country);
        }
        if(!address.isEmpty())
            mainContact.put('Address', address);
        
        name.put('value',a.Name);
        email.put('value', a.ContactEmail__c);
        phone.put('value', a.Phone);
        mainContact.put('Email', email);
        mainContact.put('Phone1', phone);
        mainpayload.put('MainContact', mainContact);
        mainPayload.put('CustomerName', Name);

        if(a.AcumaticaId__c != Null)
            mainPayload.put('CustomerID', AcumaticaId);

        JSONString = JSON.serialize(mainPayLoad);
        
        theReturn = (Map < String, Object > ) UtilityAndFactory.AcumaticaMainCall(JSONString);
        customerIdMap = (map<string,object>) theReturn.get('CustomerID');
        
        //get acumatica id and save it to account
        customerId = CustomerIdMap != Null? (string) CustomerIdMap.get('value') : a.AcumaticaId__c;
        return customerId;
        
        */
	}
}