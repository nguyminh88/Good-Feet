@isTest
public class AccountReferralBatchTest {
	@TestSetup
    static void makeData(){
        sales_representative__c sr = UtilityAndFactory.SingleSalesRepresentative('John Smith', '1394');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Tester Acc', sr);
        insert a;
    }
    
    @isTest
    static void AccountReferralBatchTest(){
        list<account> insertlist = new list<account>();
        sales_representative__c sr = [select id from sales_representative__c limit 1];
        account a = [select Id from account limit 1];
        for(integer i = 0; i < 4; i++){
            account b = UtilityAndFactory.SingleCustomerAccount('Test acc ' + i, sr);
            b.Referred_By__c = a.Id;
            b.Net_Purchase_total__c = 100 + i;
            b.Purchase_Total_MTD__c = 50 + i;
            insertList.add(b);
        }
        insert insertList;
        
        test.startTest();
        	Database.executeBatch(new AccountReferralBatch(), 2000);
        test.stopTest();
        
        account afterTest = [select referral_MTD__c, referral_Purchase_Total__c from account where id =: a.Id];
        system.assertEquals(206,afterTest.Referral_MTD__c);
        system.assertEquals(406,afterTest.referral_Purchase_Total__c);
    }
}