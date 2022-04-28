@isTest
public class StoreSummarySalesBatchTest {
    @testSetup static void settingUp(){
        list<purchase_history__c> insertList = new list<purchase_history__c>();
        //Today
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today();
            insertList.add(ph);
        }
        
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 2.50;
            ph.Transaction_Date__c = date.today().addYears(-1);
            insertList.add(ph);
        }
        
        //Yesterday
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-1);
            insertList.add(ph);
        }
        //Yesterday LY
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 2.50;
            ph.Transaction_Date__c = date.today().addDays(-1).addYears(-1);
            insertList.add(ph);
        }
        //last week
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-7);
            insertList.add(ph);
        }
        //last week LY
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-7).addYears(-1);
            insertList.add(ph);
        }
        //last Month
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-35);
            insertList.add(ph);
        }
        //last Month LY
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-35).addYears(-1);
            insertList.add(ph);
        }
        //Last Quarter
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-95);
            insertList.add(ph);
        }
        //Last Quarter
        for(integer i = 0; i < 5; i++){
            purchase_history__c ph = new purchase_history__c();
            ph.Store__c = '471';
            ph.Price__c = 5;
            ph.Transaction_Date__c = date.today().addDays(-95).addYears(-1);
            insertList.add(ph);
        }
        
        insert insertList;
    }
    
    @isTest static void StoreSalesBatchCoverageTest(){
        user u = [select Highest_Day_Sale_Amount__c from user where RICS_Store_Number__c = '471' limit 1];
        u.Highest_Day_Sale_Amount__c = 1.00;
        update u;
        test.startTest();
        Database.ExecuteBatch(new StoreSalesSummaryBatch(date.today().addYears(-1), date.today()), 1);
        test.stopTest();
    }

}