@isTest
public with sharing class AccountPurchaseMCTest {
    @TestSetup
    static void makeData(){
        list<account> insertList = new list<account>();
        sales_representative__c sr = UtilityAndFactory.SingleSalesRepresentative('name me','1234');
        insert sr;


        account a = UtilityAndFactory.SingleCustomerAccount('First Support', sr);
        a.Marketing_Status__c = 'New';
        a.steps_purchased__c = 1;
        a.contactEmail__c  = 'minh@test.com';
        insertList.add(a);

        account a2 = UtilityAndFactory.SingleCustomerAccount('First Accessories', sr);
        a2.Marketing_Status__c = 'New';
        a2.Accessories__c = 1;
        a2.contactEmail__c  = 'minh@test.com';
        insertList.add(a2);

        account a3 = UtilityAndFactory.SingleCustomerAccount('First DNB', sr);
        a3.Marketing_Status__c = 'New';
        a3.contactEmail__c  = 'minh@test.com';
        insertList.add(a3);

        insert insertList;
    }

    @isTest
    static void FullCoverage(){
        list<account> accountSizeNone = [select id from account where 
        marketing_status__c = 'Supports First Send' OR 
        marketing_status__c = 'Accessories First Send' OR 
        marketing_status__c = 'Did Not Buy First Send'];
        system.AssertEquals(0, accountSizeNone.size());

        test.startTest();
        Database.executeBatch(new AccountPurchaseMCJourneyBatch(), 2000);
        test.stopTest();

        list<account> accountSize3 = [select id from account where 
        marketing_status__c = 'Supports First Send' OR 
        marketing_status__c = 'Accessories First Send' OR 
        marketing_status__c = 'Did Not Buy First Send'];

        system.AssertEquals(3, accountSize3.size());

    }
    
}