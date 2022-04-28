/*Developer: Minh Nguyen
 *Date: 02/2021
 *On update of account/contact, or insert of opportunity:
 *Populates RICSId__c on Account by making POST method to RICS endpoint to link SF with RICS customer
 *Additionally updates RICS customer info when customer info is updated in SF

  Update: 11/4/2021 - Added Opt out code for new franchise opt out (midwest)
 */
public class RICSQueueableClass implements Queueable, Database.AllowsCallouts {
    private list < account > accList;
    private static string apexClass = 'RICSQueueableClass'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);

    //Constructor, called from RICSEnqeuer class
    public RICSQueueableClass(list < account > accounts) {
        this.accList = accounts;
    }
    
    //overloaded constructor, used by update calls to allow previous call to finish.  Prevents duplicate RICS Account    
    public RICSQueueableClass(list < account > accounts, boolean isUpdate) {
        if(isUPdate == true)
            UtilityAndFactory.Wait(5000);
        this.accList = accounts;
    }
    
    //Execute implementation.  Attempts to populate an account updatelist by calling MainProcessor()
    //try catches an update to account updateList
    public void execute(QueueableContext context) {
        
        //update: 11/4/2021 optout lines to allow franchise to opt out
    list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        list<account> updatelist = new list<account>();
        
        list < account > accounts = new list<account>([select Possible_RICS_Duplicate__c,RICS_Account_Number__c, Name, Phone, ContactEmail__c, RICSid__c 
                                     from account where id in: acclist AND owner.Franchise__c NOT IN : optOuts]);
        
        if(!accounts.isEmpty())
           updateList = (list < account > ) RICSQueueableClass.MainProcessor(accounts);
        if(!updateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(updateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
    }
    
    //Main processor loops through account and calls CreateOrGetRICSId() for each account
    //returns list account for Execute()'s updatelist
    public static list < account > MainProcessor(list < account > accounts) {
        list < account > updateList = new list < account > ();
        map < id, contact > contactMap = new map < id, contact > ([select firstname, lastname, email, accountid,
            birthdate, MailingStreet, MailingCity, MailingState,
            MailingPostalCode from contact
            where accountid in: accounts
        ]);
        map < string, contact > accContactMap = new map < string, contact > ();
        for (contact c: contactMap.values()) {
            accContactMap.put(c.accountid, c);
        }
        if (!accContactMap.isEmpty()) {
            for (account a: accounts) {
                updatelist.add(CreateOrGetRICSId(a, accContactMap.get(a.id)));
            }
        }
        return updateList;
    }

    //Called by MainProcessor() within a loop, each account has 2 main pathways depending on RICSID__C field
    //returns account to MainProcessor()
    private static account CreateOrGetRICSId(account a, contact c) {
        if (a.RICSid__c == NULL) { //Not synced, attempt find match, either create or update RICS 
            list < object > FromGetCustomerAll = new list < object > ();
            FromGetCustomerAll = (list < object > )(GetJSONRequest(a, c));
            return MatchAndSave(a, c, FromGetCustomerAll);
        
        } else { //Synced, just update RICS data with SF data
            list < object > FromGetCustomerSpecific = new list < object > ();
            FromGetCustomerSpecific = (list < object > )(GetCustomerSpecificJSONRequest(a));
            return FromGetCustomerSpecific != Null && !FromGetCustomerSpecific.isEmpty() ? UpdateSaveRICSCustomer(a, c, FromGetCustomerSpecific,FALSE) :
                    MatchAndSave(a, c, FromGetCustomerSpecific); //Attempts match and save if RICS customer is deleted in RICS
         }
    }
    
    /*Null RICS pathway from CreateOrGetRICSId(), Loops through list of possible matches from Response GetJSONREquest() and calls DoMatching()
      If Match found, link RICS Id / Account number, and update the customer with current SF data.
      If no match, call NewSaveRICSCustomer() to create new RICS customer
      returns Account to CreateOrGetRICSId()
    */
    @testVisible
    private static account MatchAndSave(account a, contact c, list < object > FromGetCustomer2) {
        map<string,object> RICSToLink = new map<string,object>();
        list < object > FromGetCustomer = new list < object > ();
        FromGetCustomer = (list < object > ) FromGetCustomer2;
        map < string, object > Matched = new map < string, object > ();
        Integer MoreThanOne = 0;
        String RICId;
        String AccountNumber;
        date mostRecent = date.newInstance(1999, 1, 1);
        list < map < string, object >> outerlist = new list < map < string, object >> ();
        if (FromGetCustomer != Null) {
            for (object cust: FromGetCustomer) {
                outerlist.add((map < string, object > ) cust);
            }
            //Loop through response, call do matching and check for last modified match
            for (map < string, object > r: outerList) {
                Matched = RICSQueueableClass.DoMatching(a, c, r);
                if(Matched != Null)
                    MoreThanOne++; //If more than one match, set Possible Duplicate checkbox to true for manual reconciliation
                If(Matched != Null && mostRecent < date.valueOf(r.Get('ModifiedOn').toString().Left(10))) {
                    mostRecent = date.valueOf(r.Get('ModifiedOn').toString().Left(10));
                    RICid = Matched.get('CustomerId').toString();
                    AccountNumber = Matched.get('AccountNumber').toString();
                }
            }
        }
        if (RICid == Null) {//No Match found, create a new customer in RICS
            return RICSQueueableClass.NewSaveRICSCustomer(a, c);
        } else {//Match Found, Update RICS with current SF info, save RICS id/Acc number on SF account
            a.RICSid__c = RICid;
            a.RICS_Account_Number__c = AccountNumber;
            a.Possible_RICS_Duplicate__c = MoreThanOne > 1? True : False;
            return RICSQueueableClass.UpdateSaveRICSCustomer(a, c, RICSQueueableClass.GetCustomerSpecificJSONRequest(a), TRUE);
        }
    }
    
    //Checks Phone or Email if phone is null for match between account and a single RICS customer JSON response.  
    //Returns the JSON object in map form to MatchAndSave() for further processing
    @testVisible
    private static Map < string, object > DoMatching(account a, contact c, map < string, object > CustomerMap) {
        Map < string, object > retMap = new map < string, object > ();
        String Aphone = UtilityAndFactory.phoneSimplify(a.Phone);
        String Rphone = CustomerMap.containsKey('PhoneNumber') ? 
            UtilityAndFactory.PhoneSimplify(CustomerMap.get('PhoneNumber').toString()) 
            : NULL;
        String Remail = CustomerMap.containsKey('Email') ? CustomerMap.get('Email').toString() : NULL;
        if ((RPhone != NULL && Aphone == RPhone) || (RPhone == NULL && REmail != NULL && Remail == c.Email)) {
            if (CustomerMap.ContainsKey('CustomerId'))
                retMap.put('CustomerId', CustomerMap.get('CustomerId').toString());
            if (CustomerMap.ContainsKey('AccountNumber'))
                retMap.put('AccountNumber', CustomerMap.get('AccountNumber').toString());
            Return retMap;
        }
        Return Null;
    }
    
    //Wrapper class that calls NewSaveJSONRequest() to handle response. Creates new RICS Customer
    //returns account
    private static account NewSaveRICSCustomer(account a, contact c) {
        map < string, object > theReturn = new map < string, object > ();
        theReturn = (map < string, object > )(RICSQueueableClass.NewSaveJSONRequest(a, c));
        map < string, object > custMap = new map < string, object > ();
        custmap = (map < string, object > ) theReturn.get('Customer');
        a.RICSid__c = custMap != Null && custMap.containsKey('CustomerId') ? (custMap.get('CustomerId')).toString() : a.RICSid__c;
        a.RICS_Account_Number__c = custMap != Null && custMap.containsKey('AccountNumber') ? (custMap.get('AccountNumber')).toString() : a.RICS_Account_Number__c;
        
        return a;
    }
    
    //Wrapper class that calls UpdateSaveJSONRequest() to handle response.  Updates RICS customer
    //returns account
    @testVisible
    private static account UpdateSaveRICSCustomer(account a, contact c, list < object > FromGetCustomer,boolean firstAttempt) {
        map < string, object > theReturn = new map < string, object > ();
        theReturn = (map < string, object > )(RICSQueueableClass.UpdateSaveJSONRequest(a, c, FromGetCustomer, firstAttempt));
        map < string, object > custMap = new map < string, object > ();
        custmap = (map < string, object > ) theReturn.get('Customer');
        a.RICSid__c = custMap != Null && custMap.containsKey('CustomerId') ? (custMap.get('CustomerId')).toString() : a.RICSid__c;
        a.RICS_Account_Number__c = custMap != Null &&  custMap.containsKey('AccountNumber') ? (custMap.get('AccountNumber')).toString() : a.RICS_Account_Number__c;
        
        return a;
    }

    //New RICS customer Insert.  JSON building function that calls MakeCallOut()
    //returns deserialized unmapped list<object> response.   
    private static Map < string, object > NewSaveJSONRequest(account a, contact c) {
        String apiEndPoint = 'Customer/SaveCustomer';
        map < string, object > cust = new map < string, object > ();
        map < string, object > MailingAddress = new map < string, object > ();
        MailingAddress.put('Address', c.MailingStreet);
        MailingAddress.put('City', c.MailingCity);
        MailingAddress.put('State', c.MailingState);
        MailingAddress.put('PostalCode', c.MailingPostalCode);

        map < string, object > js = new map < string, object > ();
        js.put('AccountNumber', 'SF' + a.Id);
        js.put('firstname', c.firstName);
        js.put('lastname', c.lastName);
        js.put('PhoneNumber', a.Phone);
        js.put('Email', a.ContactEmail__c);
        js.put('Comments','Salesforce Synced');
        if (c.BirthDate != Null)
            js.put('DateOfBirth', c.BirthDate.month() + '/' + c.Birthdate.Day() + '/' + c.BirthDate.year());
        js.put('MailingAddress', MailingAddress);
        cust.put('customer', js);
        string JSONReq = JSON.serialize(cust);

        return UtilityAndFactory.MakeRICSCallOut(apiEndPoint, JSONReq, a);
    }

    //Update RICS customer JSON build.  Ensures only non-null SF Data overwrites RICS customer
    //returns a single response from the SaveCustomer endpoint of RICS API. 
    @testVisible
    private static Map < string, object > UpdateSaveJSONRequest(account a, contact c, list < object > FromGetCustomer2,boolean firstAttempt) {
        String apiEndPoint = 'Customer/SaveCustomer';
        list < object > FromGetCustomer = new list < object > ();
        FromGetCustomer = (list < object > ) FromGetCustomer2;
        map < string, object > FromMailingAddress = new map < string, object > ();
        map < string, object > cust = new map < string, object > ();
        map < string, object > MailingAddress = new map < string, object > ();
        list < map < string, object >> outerlist = new list < map < string, object >> ();
        map < string, object > js = new map < string, object > ();
        if (FromGetCustomer != Null) {
            for (object FC: FromGetCustomer) {
                outerlist.add((map < string, object > ) FC);
            }
        }
        
        if (outerlist.size() > 0) {
            //Default populate mailing data with RICS data if available
            if (outerlist[0].containsKey('MailingAddress')) {
                FromMailingAddress = (map < string, object > ) outerlist[0].get('MailingAddress');
                if (FromMailingAddress.containsKey('Address'))
                    MailingAddress.put('Address', FromMailingAddress.get('Address'));
                if (FromMailingAddress.containsKey('City'))
                    MailingAddress.put('City', FromMailingAddress.get('City'));
                if (FromMailingAddress.containsKey('State'))
                    MailingAddress.put('State', FromMailingAddress.get('State'));
                if (FromMailingAddress.containsKey('PostalCode'))
                    MailingAddress.put('PostalCode', FromMailingAddress.get('PostalCode'));
            }
            
            //Overwrite Mailing data if SF Mailing exists
            if (c.MailingStreet != Null)
                MailingAddress.put('Address', c.MailingStreet);
            if (c.MailingCity != Null)
                MailingAddress.put('City', c.MailingCity);
            if (c.MailingState != Null)
                MailingAddress.put('State', c.MailingState);
            if (c.MailingPostalCode != Null)
                MailingAddress.put('PostalCode', c.MailingPostalCode);

            //Populate Customer Data with RICS data
            js.put('CustomerId', a.RICSid__c);
            js.put('AccountNumber', outerlist[0].get('AccountNumber'));
            if (outerlist[0].containsKey('FirstName'))
                js.put('firstname', outerlist[0].get('FirstName'));
            if (outerlist[0].containsKey('LastName'))
                js.put('lastname', outerlist[0].get('LastName'));
            if (outerlist[0].containsKey('PhoneNumber'))
                js.put('PhoneNumber', outerlist[0].get('PhoneNumber'));
            if (outerlist[0].containsKey('DateOfBirth'))
                js.put('DateOfBirth', outerlist[0].get('DateOfBirth'));
            if (outerlist[0].containsKey('Email'))
                js.put('Email', outerlist[0].get('Email'));
            
            //Overwrite Customer Data with SF data if it exists
            if (('SF' + a.Id) == outerlist[0].get('AccountNumber'))
                js.put('AccountNumber', 'SF' + a.Id);
            if (c.firstName != Null)
                js.put('firstname', c.firstName);
            if (c.lastName != Null)
                js.put('lastname', c.lastName);
            if (a.Phone != Null)
                js.put('PhoneNumber', a.Phone);
            if (a.ContactEmail__c != Null)
                js.put('Email', a.ContactEmail__c);
            if (c.Birthdate != Null)
                js.put('DateOfBirth', c.BirthDate.month() + '/' + c.Birthdate.Day() + '/' + c.BirthDate.year());
            
            //If first time linking, add Salesforce Sync to Comments. 
            if(firstAttempt == True){
                if(outerlist[0].containsKey('Comments'))
                    js.put('Comments','Salesforce Synced\n' + outerlist[0].get('Comments'));
                else 
                    js.put('Comments','Salesforce Synced');
            } else {
                if(outerlist[0].containsKey('Comments'))
                    js.put('Comments',outerlist[0].get('Comments'));
            }

            js.put('MailingAddress', MailingAddress);
            cust.put('Customer', js);
        }
        string JSONReq = JSON.serialize(cust);

        return UtilityAndFactory.MakeRICSCallOut(apiEndPoint, JSONReq, a);
    }

    //GET a customer List from RICS DB by first/last name 
    //returns the deserialized unmapped list object response 
    private static list < object > GetJSONRequest(account a, contact c) {
        String apiEndPoint = 'Customer/GetCustomerDetails';
        map < string, object > js = new map < string, object > ();
        js.put('firstname', c.firstName);
        js.put('lastname', c.lastName);
        string JSONReq = JSON.serialize(js);

        //Callout
        //UtilityAndFactory.Wait(2000);
        Map < String, Object > theReturn = (Map < String, Object > ) UtilityAndFactory.MakeRICSCallOut(apiEndPoint, JSONReq, a);
        list < object > customers = new list < object > ();
        customers = (list < object > ) theReturn.get('CustomerDetails');
        
        return customers;
    }
    
    //Get a specific customer by CustomerId in RICS DB
    //returns the deserialized unmapped list object response
    private static list < object > GetCustomerSpecificJSONRequest(account a) {
        String apiEndPoint = 'Customer/GetCustomerDetails';
        map < string, object > js = new map < string, object > ();
        js.put('CustomerId', a.RICSid__c);
        string JSONReq = JSON.serialize(js);
        
        //Callout
        UtilityAndFactory.Wait(1500);
        Map < String, Object > theReturn = (Map < String, Object > ) UtilityAndFactory.MakeRICSCallOut(apiEndPoint, JSONReq, a);
        list < object > customers = new list < object > ();
        customers = (list < object > ) theReturn.get('CustomerDetails');
        return customers;
    }
}