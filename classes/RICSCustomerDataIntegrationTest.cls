@isTest
public class RICSCustomerDataIntegrationTest {
	
    @testsetup static void settingUp(){
        sales_representative__c sr = UtilityAndFactory.SingleSalesRepresentative('Test Rep', '1234');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Test Feet', sr);
        a.phone = '5033800715';
        insert a;
        insert UtilityAndFactory.SingleStoreAccount('Tualatin', '147');
        insert UtilityAndFactory.SingleContact(a, 'Test', 'Feet', '5031234567', 'test@email.com');
    }
    
    @isTest static void AccountQueueableMainCoverageNullRICS(){
        account a = [select id from account limit 1];
        list<account> acclist = new list<account>();
        acclist.add(a);
        test.startTest();
        	RICSQueueableClass RICS = new RICSQueueableClass(acclist);
    		system.enqueueJob(RICS);
        test.stopTest();
    }
    
    @isTest static void AccountQueueableMainCoveragePopulatedRICS(){
        account a = [select RICSId__c from account limit 1];
        a.RICSId__c = '123';
        update a;
        list<account> acclist = new list<account>();
        acclist.add(a);
        test.startTest();
        	RICSQueueableClass RICS = new RICSQueueableClass(acclist);
    		system.enqueueJob(RICS);
        test.stopTest();
    }
    
    @isTest static void AccountSyncUpdateNameSplit(){
        account a = [select name from account limit 1];
        a.name = 'John Bill';
        test.startTest();
        	update a;
        test.stopTest();
        contact c = [select firstname, lastname from contact limit 1];
        system.assertEquals('John', c.firstName);
        system.assertEquals('Bill', c.lastName);
    }
    
    @isTest static void AccountSyncUpdateNameNonSplit(){
        account a = [select name from account limit 1];
        a.name = 'JohnBill';
        test.startTest();
        	update a;
        test.stopTest();
        contact c = [select firstname, lastname from contact limit 1];
        system.assertEquals('JohnBill', c.lastName);
    }
    
    @isTest static void AccountSRPopulate(){
        account a = [select sales_representative__c from account limit 1];
        sales_representative__c sr = [select id from sales_representative__c limit 1];
        a.sales_representative__c = null;
        update a;
        
        account b = [select sales_representative__c from account limit 1];
        b.sales_representative__c = sr.Id;
        
        test.startTest();
        	update b;
        test.stopTest();
    }
    
    @istest static void AccountSyncDuplicateCheck(){
        list<account> insertlist = new list<account>();
        account a = new account();
        a.name = 'Test Feet';
        a.phone = '5033800715';
        test.startTest();
        	 database.insert(a,false);
        test.stopTest();
        
        list<account> OnlyTwo = new list<account>([select name from account]);
        system.assertEquals(2, OnlyTwo.size());
    }
    

    
    @isTest static void OppTriggerAndHandler(){
		account a = [select createdDate from account where createdDate != Null limit 1];
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'Test Opp');
       	o.Is_Return_Customer__c = TRUE;
        test.startTest();
        	insert o;
        test.stopTest();
    }
    
    @isTest static void ContTriggerAndHandler(){
        account a = [select RICSid__c from account limit 1];
        contact c = [select sales_representative__c,firstname,lastname, phone, email, birthdate, MailingStreet,MailingCity,MailingState,MailingPostalCode from contact limit 1];
		sales_representative__c sr = [select id from sales_representative__c limit 1];        
        test.startTest();
        	c.sales_representative__c = sr.Id;
        	c.FirstName = 'ChangeName';
        	update c;
        	c.lastName = 'updateName';
        	update c;
        	c.Phone = '1234567890';
        	update c;
        	c.Email = 'test@somthingelse.com';
        	update c;
        	c.Birthdate = date.today();
        	update c;
        	c.MailingStreet = '1';
        	update c;
        	c.MailingCity = 'Portland';
        	update c;
        	c.MailingState = 'OR';
        	update c;
        	c.MailingPostalCode = '97220';
        	update c;
        test.stopTest();
    }
    
    @isTest static void contactInsertCoverage(){
        sales_representative__c sr = [select id from sales_representative__c limit 1];
        account a = UtilityAndFactory.SingleCustomerAccount('Name Test', sr);
        insert a;
        contact c = new contact();
        c.firstname = 'test';
        c.lastname = 'acc';
        c.Phone = '1234567890';
        c.AccountId = a.id;
        c.Sales_Representative__c = a.Sales_Representative__c;
        test.startTest();
        	insert c;
        test.stopTest();
    }
    
    @isTest static void contactInsertCoverageNoSalesRep(){
        account a = [select Sales_Representative__c,ContactEmail__c,phone from account limit 1];
        a.phone = null;
        a.ContactEmail__c = null;
        a.Sales_Representative__c = Null;
        update a;
        contact c = new contact();
        c.firstname = 'test';
        c.lastname = 'acc';
        c.AccountId = a.id;
        test.startTest();
        	insert c;
        test.stopTest();
    }
    
    @isTest static void contactUpdateCoverage(){
        contact c = [select phone from contact limit 1];
        Sales_Representative__c sr = [select id from sales_representative__c limit 1];
        c.phone = '1234563759';
        c.Sales_Representative__c = sr.Id;
        test.startTest();
        	update c;
        test.stopTest();
    }
    
    @isTest static void PhoneSimplifyCoverage(){
        String p = '(503) 251-8562';
        test.startTest();
        	String a = UtilityAndFactory.PhoneSimplify(p);
        	String beans = UtilityAndFactory.PhoneSimplify(Null);
        test.stopTest();
        system.assertEquals('5032518562', a);
        system.assertEquals(Null,beans);
    }
    
    @isTest static void doMatchingCoverage(){
        account a = [select Phone from account limit 1];
        contact c = [select Email from contact limit 1];
        a.Phone = '5031234567';
        update a;
        c.email = 'testing@gmail.com';
        update c;
        
        map<string,object> CustomerMap = new map<string,object>();
        CustomerMap.put('CustomerId','123');
        CustomerMap.put('AccounNumber','156');
        CustomerMap.put('PhoneNumber','5031234567');
        CustomerMap.put('Email', 'testing@gmail.com');
        test.startTest();
        	RICSQueueableclass.DoMatching(a, c, CustomerMap);
        test.stopTest();
    }
    
    @isTest static void doMatchingCoverage2(){
        account a = [select Phone from account limit 1];
        contact c = [select Email from contact limit 1];
        a.Phone = '5031234567';
        update a;
        c.email = 'testing@gmail.com';
        update c;
        
        map<string,object> CustomerMap2 = new map<string,object>();
        test.startTest();
        	RICSQueueableclass.DoMatching(a, c, CustomerMap2);
        test.stopTest();
    }
    
    @isTest static void UpdateSaveJSONRequestCoverage(){
        account a = [select firstName,lastName,Phone,ContactEmail__c,RICSid__c from account limit 1];
        contact c = [select firstname, lastname, email, accountid,
                                                          birthdate, MailingStreet, MailingCity,MailingState,
                                                          MailingPostalCode from contact limit 1];
        c.mailingstreet = 'something';
        c.mailingcity = 'portland';
        c.mailingstate = 'OR';
        c.mailingPostalCode = '97220';
        a.phone = '1234567890';
        c.phone = '1234567890';
        c.Birthdate = date.today();
        a.ContactEmail__c = 'test@gmail.com';
        update a;
        update c;
        
        list<object> NoComment = new list<object>();
        list<object> FromGetCustomer2 = new list<object>();
        map<String,object> inside = new map<String,object>();
        map<string,object> MailingAddress = new map<string,object>();
        MailingAddress.put('Address', '123 fake street');
        MailingAddress.put('City', 'Portland');
        MailingAddress.put('State', 'OR');
        MailingAddress.put('PostalCode', '97220');
        inside.put('MailingAddress',MailingAddress);
        inside.put('AccountNumber', 'SF' + a.id);
        inside.put('FirstName', 'first');
        inside.put('LastName', 'last');
        inside.put('PhoneNumber', '5031234567');
        inside.put('DateOfBirth','08/11/1988');
        inside.put('Email','test@gmail.com');
        NoComment.add(inside);
        
        test.startTest();
        	RICSQueueableClass.UpdateSaveJSONRequest(a, c, NoComment,FALSE);
        	RICSQueueableClass.UpdateSaveJSONRequest(a, c, NoComment,TRUE);
        	inside.put('Comments','Whatever Man');
        	FromGetCustomer2.add(inside);
        	RICSQueueableClass.UpdateSaveJSONRequest(a, c, FromGetCustomer2,FALSE);
        	RICSQueueableClass.UpdateSaveJSONRequest(a, c, FromGetCustomer2,TRUE);
        test.stopTest();
    }
    
    @isTest static void MatchAndSaveCoverage(){
        date tod = date.newInstance(2021, 4, 3);
        list<object> FromgetCustomer2 = new list<object>();
        list<map<string,object>> thelist = new list<map<string,object>>();
        map<string, object> inside = new map<string,object>();
        inside.put('CustomerId','SomeId');
        inside.put('AccountNumber','SomeOther');
        inside.put('CreatedOn','2021-01-01');
        inside.put('ModifiedOn','2021-01-01');
        inside.put('PhoneNumber', '5033800755');
        inside.put('Email','test@gmail.com');
        
        theList.add(inside);
        FromGetCustomer2.add(inside);
        
        account a = [select firstName,lastName,Phone,ContactEmail__c,RICSid__c from account limit 1];
        contact c = [select firstname, lastname, email, accountid,
                                                          birthdate, MailingStreet, MailingCity,MailingState,
                                                          MailingPostalCode from contact limit 1];
        c.mailingstreet = 'something';
        c.mailingcity = 'portland';
        c.mailingstate = 'OR';
        c.mailingPostalCode = '97220';
        a.phone = '5033800755';
        c.phone = '1234567890';
        c.Birthdate = date.today();
        a.ContactEmail__c = 'test@gmail.com';
        update a;
        update c;
        
        RICSQueueableClass.MatchAndSave(a, c, FromGetCustomer2);
    }
    
    @isTest static void AccountSyncCreateContactTest(){
        list<account> insertList = new list<account>();
        account a = new account();
        a.name = 'Joe Schmoe';
        a.Phone = '5031230987';
        a.contactEmail__c = 'tester@gf.com';
        account b = new account();
        b.name = 'ooLongTea';
        b.Phone = '5031230981';
        b.contactEmail__c = 'tester@gfa.com';
        insertList.add(a);
        insertList.add(b);
        test.startTest();
        	insert insertList;
        test.stopTest();
        
        list<contact> c = [select id from contact where accountid =: a.Id OR accountId =: b.Id];
        system.assertEquals(2, c.size());
    }
    
    @isTest static void updateSaveCustomerCoverage(){
        list<object> FromgetCustomer2 = new list<object>();
        list<map<string,object>> thelist = new list<map<string,object>>();
        map<string, object> inside = new map<string,object>();
        inside.put('CustomerId','SomeId');
        inside.put('AccountNumber','SomeOther');
        inside.put('CreatedOn','2021-01-01');
        inside.put('PhoneNumber', '5033800755');
        inside.put('Email','test@gmail.com');
        theList.add(inside);
        FromGetCustomer2.add(inside);
        account a = [select RICS_Account_Number__c, firstName, lastName, Phone, ContactEmail__c, RICSid__c from account limit 1];
        contact c = [select firstname, lastname, email, accountid,
            birthdate, MailingStreet, MailingCity, MailingState,
            MailingPostalCode from contact limit 1];
        
        test.startTest();
        	RICSQueueableClass.UpdateSaveRICSCustomer(a, c, FromGetCustomer2,False);
        test.stopTest();
    }
    
    @istest static void BatchRICSTest(){
        RICSAccountSyncBatch r = new RICSAccountSyncBatch();
        test.startTest();
        	database.executeBatch(r);
        test.stopTest();
    }
}