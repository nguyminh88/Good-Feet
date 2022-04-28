@isTest 
public class NetsuiteCustomerIntegrationTest {
    @TestSetup
    static void makeData(){
        sales_representative__c sr = UtilityAndFactory.SingleSalesRepresentative('nameer', '1234');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Tester', sr);
        a.RICSId__c = '12343434';
        a.Phone = '5033800755';
        insert a;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'Name');
        insert o;
    }

    @isTest
    static void NetsuiteOppCreatedTest(){
        account a = [select id from account limit 1];
        opportunity o1 = UtilityAndFactory.SingleOpportunity(a, 'Name1');
        
        test.startTest();
            insert o1;
        test.stopTest();
    }

    @isTest
    static void AccountUpdatedTest(){
        account a = [select Netsuite_Id__c, phone from account limit 1];
        a.netsuite_id__c = '12345';
        update a;

        account a1 = [select Netsuite_Id__c, phone from account limit 1];
        a1.phone = '5039876543';
        test.startTest();
            update a1;
        test.stopTest();
    }

    @isTest
    static void RetryScheduleAndBatch(){
        account a = [select RICSId__c, Netsuite_Id__c, phone from account limit 1];
        a.RICSId__c = '12345';
        update a;
        test.startTest();
        System.schedule('testNSRetry 00',  '0 00 * * * ?', new NetsuiteRetrySchedulable());
        test.stopTest();
    }
}