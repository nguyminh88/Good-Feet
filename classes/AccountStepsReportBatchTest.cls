@istest
public class AccountStepsReportBatchTest {
    @testsetup static void settingUP(){
        account a = new account();
        a.name = 'Test name';
        insert a;
        list<purchase_history__c> insertlist = new list<purchase_history__c>();
        
        purchase_history__c p1 = new purchase_history__c();
        p1.Price__c = 5.00;
        p1.Transaction_Type__c = 'Regular Sale';
        p1.SKU__c = 'mid flex';
        p1.account__c = a.id;
        p1.Quantity__c = 1;
        p1.Transaction_Date__c = date.today();
        
        purchase_history__c p12 = new purchase_history__c();
        p12.Price__c = 5.00;
        p12.Transaction_Type__c = 'Regular Sale';
        p12.SKU__c = 'RELAXER';
        p12.account__c = a.id;
        p12.Quantity__c = 1;
        p12.Transaction_Date__c = date.today();
        
        purchase_history__c p2 = new purchase_history__c();
        p2.Price__c = -2.00;
        p2.Transaction_Type__c = 'Return';
        p2.SKU__c = 'mid flex';
        p2.account__c = a.id;
        p2.Quantity__c = -1;
        p2.Transaction_Date__c = date.today();
        
        purchase_history__c p3 = new purchase_history__c();
        p3.Price__c = 5.00;
        p3.Transaction_Type__c = 'Regular Sale';
        p3.SKU__c = 'ALZNNER';
        p3.account__c = a.id;
        p3.Quantity__c = 1;
        p3.Transaction_Date__c = date.today();
        
        purchase_history__c p4 = new purchase_history__c();
        p4.Price__c = -2.00;
        p4.Transaction_Type__c = 'Return';
        p4.SKU__c = 'ALZNNER';
        p4.Quantity__c = -1;
        p4.Transaction_Date__c = date.today();
        p4.account__c = a.id;
        
        //90 - 180 days
        purchase_history__c p11 = new purchase_history__c();
        p11.Price__c = 5.00;
        p11.Transaction_Type__c = 'Regular Sale';
        p11.SKU__c = 'mid flex';
        p11.account__c = a.id;
        p11.Quantity__c = 1;
        p11.Transaction_Date__c = date.today().addDays(-91);
        
        purchase_history__c p121 = new purchase_history__c();
        p121.Price__c = 5.00;
        p121.Transaction_Type__c = 'Regular Sale';
        p121.SKU__c = 'RELAXER';
        p121.account__c = a.id;
        p121.Quantity__c = 1;
        p121.Transaction_Date__c = date.today().addDays(-91);
        
        purchase_history__c p21 = new purchase_history__c();
        p21.Price__c = -2.00;
        p21.Transaction_Type__c = 'Return';
        p21.SKU__c = 'mid flex';
        p21.account__c = a.id;
        p21.Quantity__c = -1;
        p21.Transaction_Date__c = date.today().addDays(-91);
        
        purchase_history__c p31 = new purchase_history__c();
        p31.Price__c = 5.00;
        p31.Transaction_Type__c = 'Regular Sale';
        p31.SKU__c = 'ALZNNER';
        p31.account__c = a.id;
        p31.Quantity__c = 1;
        p31.Transaction_Date__c = date.today().addDays(-91);
        
        purchase_history__c p41 = new purchase_history__c();
        p41.Price__c = -2.00;
        p41.Transaction_Type__c = 'Return';
        p41.SKU__c = 'ALZNNER';
        p41.Quantity__c = -1;
        p41.Transaction_Date__c = date.today().addDays(-91);
        p41.account__c = a.id;
        
        
        //180+ days
        purchase_history__c p111 = new purchase_history__c();
        p111.Price__c = 5.00;
        p111.Transaction_Type__c = 'Regular Sale';
        p111.SKU__c = 'mid flex';
        p111.account__c = a.id;
        p111.Quantity__c = 1;
        p111.Transaction_Date__c = date.today().addDays(-181);
        
        purchase_history__c p1211 = new purchase_history__c();
        p1211.Price__c = 5.00;
        p1211.Transaction_Type__c = 'Regular Sale';
        p1211.SKU__c = 'RELAXER';
        p1211.account__c = a.id;
        p1211.Quantity__c = 1;
        p1211.Transaction_Date__c = date.today().addDays(-181);
        
        purchase_history__c p211 = new purchase_history__c();
        p211.Price__c = -2.00;
        p211.Transaction_Type__c = 'Return';
        p211.SKU__c = 'mid flex';
        p211.account__c = a.id;
        p211.Quantity__c = -1;
        p211.Transaction_Date__c = date.today().addDays(-181);
        
        purchase_history__c p311 = new purchase_history__c();
        p311.Price__c = 5.00;
        p311.Transaction_Type__c = 'Regular Sale';
        p311.SKU__c = 'ALZNNER';
        p311.account__c = a.id;
        p311.Quantity__c = 1;
        p311.Transaction_Date__c = date.today().addDays(-181);
        
        purchase_history__c p411 = new purchase_history__c();
        p411.Price__c = -2.00;
        p411.Transaction_Type__c = 'Return';
        p411.SKU__c = 'ALZNNER';
        p411.Quantity__c = -1;
        p411.Transaction_Date__c = date.today().addDays(-181);
        p411.account__c = a.id;
        
        
        insertlist.add(p1);
        insertlist.add(p12);
        insertlist.add(p2);
        insertlist.add(p3);
        insertlist.add(p4);
        
        insertlist.add(p11);
        insertlist.add(p121);
        insertlist.add(p21);
        insertlist.add(p31);
        insertlist.add(p41);
        
        insertlist.add(p111);
        insertlist.add(p1211);
        insertlist.add(p211);
        insertlist.add(p311);
        insertlist.add(p411);
                
        insert insertlist;
    }
    
    @istest static void accountPurchaseStepsReportingBatchTest(){
        test.startTest();
            Database.executeBatch(new AccountPurchasedStepsReportingBatch(), 200);
        test.stopTest();
        
        account a = [select Net_Purchase_Total__c, NonLifetime_Purchase__c, Steps_Purchased__c, NonLifetime_Purchase_91_180__c, NonLifetime_Purchase_181__c,  
                            Steps_Purchased_181__c, Steps_Purchased_91_180__c from account limit 1];
        system.assertEquals(33,a.Net_Purchase_Total__c);
        system.assertEquals(0,a.NonLifetime_Purchase__c);
        system.assertEquals(1,a.Steps_Purchased__c);
        
        system.assertEquals(1,a.Steps_Purchased_181__c);
        system.assertEquals(1,a.Steps_Purchased_91_180__c);
        
        system.assertEquals(0,a.NonLifetime_Purchase_91_180__c);
        system.assertEquals(0,a.NonLifetime_Purchase_181__c);
    }
}