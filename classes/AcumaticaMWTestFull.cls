@isTest
public class AcumaticaMWTestFull {
    @testSetup static void settingUp(){
        list<mw_staging__c> stagingInsertList = new list<mw_staging__c>();
        list<user> mwStore1 = new list<user>([select Franchise__c, RICS_Store_Number__c from user where RICS_Store_Number__c != Null limit 1]);
        mwStore1[0].Franchise__c = 'Midwest';
        update mwStore1;
        list<user> mwStore = new list<user>([select RICS_Store_Number__c from user where Franchise__c = 'Midwest' limit 1]);
        account a = new account();
        a.name = 'Test MinhAcc';
        a.phone = '5033800999';
        a.contactEmail__c = 'Tester@gmail.com';
        if(!mwStore.isEmpty())
            a.ownerId = mwStore[0].Id;
        sales_representative__c sr = new sales_representative__c();
        sr = utilityAndFactory.singleSalesRepresentative('Test Rep', '1337');
        
        insert sr;
        insert a;
        
        for(integer i = 0; i < 1; i++){
            mw_staging__c mw = new mw_staging__c();
            mw.customerId__c = string.valueOf(i);
            mw.customer_name__c = 'MINH TEST' + i;
            mw.Phone__c = MWStagingProcessingBatch.randomPhoneGenerator();
            mw.Email__c = 'test' + i + '@gmail.com';
            mw.AddressStreet__c = '123' + i + ' fake st';
            mw.Zip_Code__c = '97220';
            stagingInsertList.add(mw);
        }
        
        for(integer i = 0; i < 10; i++){
            mw_staging__c mw = new mw_staging__c();
            mw.TranType__c = 'INV';
            mw.InventoryId__c = 'Test';
            mw.DocumentDate__c = '10/7/2021 0:00';
            mw.PostingClass__c = 'SUPPORTS';
            mw.Sales_Customer_Name__c = 'MINH TEST0';
            mw.Sales_CustomerId__c = '0';
            mw.Quantity__c = 1;
 			mw.NetSalesAmount__c = 400;
            mw.ReferenceNbr__c = '1';
            mw.OrderLineNbr__c = i;
            mw.OrderNbr__c = '1';
            mw.SalesPersonId__c = [select pin__c from sales_representative__c where pin__c = '1337' limit 1].pin__c;
            mw.BranchId__c = mwStore[0].RICS_Store_Number__c;
            stagingInsertList.add(mw);
        }
        
        insert stagingInsertList;
        
    }

    @isTest static void AcumaticaQueueableCoverage(){
        system.debug('do nothing');//delete this and uncomment everythig to reactivate test class
        /*
        list<account> acclist = [select sales_representative__c from account limit 1];
        list<sales_representative__c> srRep = new list<sales_representative__c>([select id from sales_representative__c limit 1]);
        
        if(!srRep.isEmpty()){
            system.debug('true');
            accList[0].sales_representative__c = srRep[0].Id;
            test.startTest();
            	update accList[0];
            test.stopTest();
        } 
    }
    
    @isTest static void AcumaticaLogOutCoverage(){
        Acumatica__mdt acumaticaAPI = [select Cache_Control__c, Content_Type__c, Cookie__c, Endpoint__c, Name__c, Password__c  from
            Acumatica__mdt where masterlabel = 'Midwest'];
        
        string cookies = 'cookies';
        test.startTest();
        	UtilityAndFactory.AcumaticaLogout(acumaticaAPI, cookies);
        test.stopTest();
    }
    
    @isTest static void MWStagingConvertToAccountAndPurchaseHistory(){
        list<purchase_history__c> ExpectedPHSizeNone = new list<purchase_history__c>([select id from purchase_history__c]);
        list<account> ExpectedAccSizeOne = new list<account>([select id from account]);
        system.assertEquals(1,ExpectedAccSizeOne.size());
        system.assertEquals(0,ExpectedPHSizeNone.size());
        
        test.startTest();
        	Database.executeBatch(new MWStagingProcessingBatch(), 1);
        test.stopTest();
        
        list<account> ExpectedAccSizeTwo = [select id from account];
        list<purchase_history__c> ExpectedPHSizeTen = new list<purchase_history__c>([select id from purchase_history__c]);
        system.assertEquals(2,ExpectedAccSizeTwo.size());
        system.assertEquals(10,ExpectedPHSizeTen.size());
        */
    }
}