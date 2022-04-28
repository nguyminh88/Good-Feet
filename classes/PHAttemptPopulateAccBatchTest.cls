@isTest
public class PHAttemptPopulateAccBatchTest {
    @testSetup static void settingUp(){
        list<purchase_history__c> insertList = new list<purchase_history__c>();
        //Yesterday
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-1);
            ph.firstname__c = 'Test';
            ph.lastname__c = 'acc';
            ph.Phone__c = '1234567777';
            insertList.add(ph);
        }
        
        //Yesterday
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-1);
            ph.firstname__c = 'Test';
            ph.lastname__c = 'acc';
            ph.Phone__c = '1234567777';
            ph.CustomerId__c = '123';
            insertList.add(ph);
        }
        
        insert insertList;
    }
    
    @istest static void PHAttempBatchTest(){
        sales_Representative__c sr = UtilityAndFactory.SingleSalesRepresentative('john wayne', '1234');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Test Acc', sr);
        a.phone = '1234567777';
        insert a;
        test.starttest();
        	Database.ExecuteBatch(new PHAttemptPopulateAccountBatch(), 100);
        test.stopTest();
        
        list<purchase_history__c> phList = new list<purchase_history__c>([select id from purchase_history__c where account__c != Null]);
        list<opportunity> opplist = new list<opportunity>([select id from opportunity]);
        system.assertEquals(10, phList.size());
        system.assertEquals(1, opplist.size());
    }
    
    @istest static void PHAttempBatchTestWithRICSId(){
        sales_Representative__c sr = UtilityAndFactory.SingleSalesRepresentative('john wayne', '1234');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Test Acc', sr);
        a.phone = '1234567777';
        a.RICSid__c = '123';
        insert a;
        
       	insert UtilityAndFactory.SingleContact(a, 'Test', 'Acc', '1234567777', 'Email@g.com');
        test.starttest();
        	Database.ExecuteBatch(new PHAttemptPopulateAccountBatch(), 100);
        test.stopTest();
        
        list<purchase_history__c> phList = new list<purchase_history__c>([select id from purchase_history__c where account__c != Null]);
        list<opportunity> opplist = new list<opportunity>([select id from opportunity]);
        system.assertEquals(10, phList.size());
        system.assertEquals(1, opplist.size());
    }
}