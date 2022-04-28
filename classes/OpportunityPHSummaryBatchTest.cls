@isTest
public class OpportunityPHSummaryBatchTest {
    static list<Auto_Generated_Tasks__mdt> autoGenTasks = [Select Franchise__c, Use_in_OPPPHSummaryBatch__c,PurchasedSupports__c, Purchase_Made__c, is_return_customer__c, Task_Subject__c from Auto_Generated_Tasks__mdt];

    @isTest static void TaskExistsDontMakeNewTaskTest(){
        account a = new account();
        a.name = 'Test name';
        insert a;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'test Opp');
        insert o;
        task t = new task();
        t.WhatId = o.Id;
        t.Subject = 'Break-in Followup';
        t.ActivityDate = date.today();
        t.Status = 'Open';
        insert t;
        
        list<purchase_history__c> insertlist = new list<purchase_history__c>();
        
        purchase_history__c p = new purchase_history__c();
        p.Price__c = 5.00;
        p.Transaction_Type__c = 'Regular Sale';
        p.SKU__c = 'mid flex';
        p.Quantity__c = 1;
        p.opportunity__c = o.id;
        
        purchase_history__c p1 = new purchase_history__c();
        p1.Price__c = 5.00;
        p1.Transaction_Type__c = 'Regular Sale';
        p1.SKU__c = 'mid flex';
        p1.Quantity__c = 1;
        p1.opportunity__c = o.id;
        
        purchase_history__c p2 = new purchase_history__c();
        p2.Price__c = -5.00;
        p2.Transaction_Type__c = 'Return';
        p2.SKU__c = 'mid flex';
        p2.Quantity__c = -1;
        p2.opportunity__c = o.id;
        
        insertList.add(p);
        insertList.add(p1);
        insertList.add(p2);
        insert insertList;
        
        test.startTest();
            Database.executeBatch(new OpportunityPHSummaryBatch(), 200);
        test.stopTest();
        
        opportunity o2 = [select purchase_made__c, purchase_total__c, number_of_steps__c from opportunity limit 1];
        system.assertEquals(TRUE, o2.Purchase_Made__c);
        system.assertEquals(5.00, o2.Purchase_Total__c);
        system.assertEquals(1, o2.Number_of_Steps__c);
        
        list<task> tasks = new list<task>([select subject, activityDate, whatid from task]);
        system.assertEquals(1,tasks.size());
    }
    
    @isTest static void NewClientNoTasksSupportPurchasedTest(){
        integer taskCount = 0;
        date tod = date.today();
        boolean purchasedSupports;
        account a = new account();
        a.name = 'LAST, FIRST';
        insert a;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'test Opp');
        insert o;
        list<purchase_history__c> insertlist = new list<purchase_history__c>();
        
        purchase_history__c p = new purchase_history__c();
        p.Price__c = 5.00;
        p.Transaction_Type__c = 'Regular Sale';
        p.SKU__c = 'mid flex';
        p.Quantity__c = 1;
        p.transaction_date__c = tod;
        p.opportunity__c = o.id;
        
        purchase_history__c p1 = new purchase_history__c();
        p1.Price__c = 5.00;
        p1.Transaction_Type__c = 'Regular Sale';
        p1.SKU__c = 'mid flex';
        p1.Quantity__c = 1;
        p1.transaction_date__c = tod;
        p1.opportunity__c = o.id;
        
        purchase_history__c p2 = new purchase_history__c();
        p2.Price__c = -5.00;
        p2.Transaction_Type__c = 'Return';
        p2.SKU__c = 'mid flex';
        p2.Quantity__c = -1;
        p2.transaction_date__c = tod;
        p2.opportunity__c = o.id;
        
        insertList.add(p);
        insertList.add(p1);
        insertList.add(p2);
        insert insertList;
        
        test.startTest();
            Database.executeBatch(new OpportunityPHSummaryBatch(), 200);
        test.stopTest();
        
        opportunity o2 = [select franchise__c, is_return_customer__c, purchase_made__c, purchase_total__c, number_of_steps__c from opportunity limit 1];
        purchasedSupports = o2.Number_of_Steps__c > 0 ? TRUE : FALSE;
        system.assertEquals(TRUE, o2.Purchase_Made__c);
        system.assertEquals(5.00, o2.Purchase_Total__c);
        system.assertEquals(1, o2.Number_of_Steps__c);
        
        for(Auto_Generated_Tasks__mdt ag : autoGenTasks){
            if(ag.PurchasedSupports__c == PurchasedSupports &&
               ag.Purchase_Made__c == o2.Purchase_Made__c &&
               ag.is_Return_Customer__c == o2.Is_Return_Customer__c &&
               (ag.Franchise__c != Null && ag.Franchise__c.split(',').Contains(o2.Franchise__c)) &&
               ag.Use_in_OPPPHSummaryBatch__c){
                   taskCount++;
               }
        }
        
        list<task> tasks = new list<task>([select subject from task]);
        system.assertEquals(taskCount,tasks.size());
    }
    
    @isTest static void ReturnPurchasedTest(){
        integer taskCount = 0;
        boolean purchasedSupports;
        account a = new account();
        a.name = 'Test name';
        insert a;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'test Opp');
        o.Is_Return_Customer__c = TRUE;
        insert o;
        list<purchase_history__c> insertlist = new list<purchase_history__c>();
        
        purchase_history__c p = new purchase_history__c();
        p.Price__c = 5.00;
        p.Transaction_Type__c = 'Regular Sale';
        p.SKU__c = 'mid flex';
        p.Quantity__c = 1;
        p.opportunity__c = o.id;
        
        purchase_history__c p1 = new purchase_history__c();
        p1.Price__c = 5.00;
        p1.Transaction_Type__c = 'Regular Sale';
        p1.SKU__c = 'mid flex';
        p1.Quantity__c = 1;
        p1.opportunity__c = o.id;
        
        purchase_history__c p2 = new purchase_history__c();
        p2.Price__c = -5.00;
        p2.Transaction_Type__c = 'Return';
        p2.SKU__c = 'mid flex';
        p2.Quantity__c = -1;
        p2.opportunity__c = o.id;
        
        insertList.add(p);
        insertList.add(p1);
        insertList.add(p2);
        insert insertList;
        
        test.startTest();
            Database.executeBatch(new OpportunityPHSummaryBatch(), 200);
        test.stopTest();
        
        opportunity o2 = [select Franchise__c, is_return_customer__c, purchase_made__c, purchase_total__c, number_of_steps__c from opportunity limit 1];
        purchasedSupports = o2.Number_of_Steps__c > 0 ? TRUE : FALSE;
        
        system.assertEquals(TRUE, o2.Purchase_Made__c);
        system.assertEquals(5.00, o2.Purchase_Total__c);
        system.assertEquals(1, o2.Number_of_Steps__c);
        
        for(Auto_Generated_Tasks__mdt ag : autoGenTasks){
            if(ag.PurchasedSupports__c == PurchasedSupports &&
               ag.Purchase_Made__c == o2.Purchase_Made__c &&
               ag.is_Return_Customer__c == o2.Is_Return_Customer__c &&
               (ag.Franchise__c != Null && ag.Franchise__c.split(',').Contains(o2.Franchise__c)) &&
               ag.Use_in_OPPPHSummaryBatch__c){
                   taskCount++;
               }
        }
        
        list<task> tasks = new list<task>([select subject, activityDate from task]);
        system.assertEquals(taskCount,tasks.size());
    }
    
    @isTest static void NonSupportPurchasedTest(){
        integer taskCount = 0;
        boolean purchasedSupports;
        account a = new account();
        a.name = 'Test name';
        insert a;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'test Opp');
        insert o;
        list<purchase_history__c> insertlist = new list<purchase_history__c>();
        
        purchase_history__c p = new purchase_history__c();
        p.Price__c = 5.00;
        p.Transaction_Type__c = 'Regular Sale';
        p.SKU__c = '';
        p.Quantity__c = 1;
        p.opportunity__c = o.id;
        
        purchase_history__c p1 = new purchase_history__c();
        p1.Price__c = 5.00;
        p1.Transaction_Type__c = 'Regular Sale';
        p1.SKU__c = '';
        p1.Quantity__c = 1;
        p1.opportunity__c = o.id;
        
        purchase_history__c p2 = new purchase_history__c();
        p2.Price__c = -5.00;
        p2.Transaction_Type__c = 'Return';
        p2.SKU__c = '';
        p2.Quantity__c = -1;
        p2.opportunity__c = o.id;
        
        insertList.add(p);
        insertList.add(p1);
        insertList.add(p2);
        insert insertList;
        
        test.startTest();
            Database.executeBatch(new OpportunityPHSummaryBatch(), 200);
        test.stopTest();
        
        opportunity o2 = [select Franchise__c, is_return_customer__c, purchase_made__c, purchase_total__c, number_of_steps__c from opportunity limit 1];
        purchasedSupports = o2.Number_of_Steps__c > 0 ? TRUE : FALSE;
        
        system.assertEquals(TRUE, o2.Purchase_Made__c);
        system.assertEquals(5.00, o2.Purchase_Total__c);
        system.assertEquals(0, o2.Number_of_Steps__c);
        
        for(Auto_Generated_Tasks__mdt ag : autoGenTasks){
            if(ag.PurchasedSupports__c == PurchasedSupports &&
               ag.Purchase_Made__c == o2.Purchase_Made__c &&
               ag.is_Return_Customer__c == o2.Is_Return_Customer__c &&
               (ag.Franchise__c != Null && ag.Franchise__c.split(',').Contains(o2.Franchise__c)) &&
               ag.Use_in_OPPPHSummaryBatch__c){
                   taskCount++;
               }
        }
        
        list<task> tasks = new list<task>([select subject, activityDate from task]);
        system.assertEquals(taskCount,tasks.size());
    }
    
    @isTest static void NewNonPurchasedTest(){
        integer taskCount = 0;
        boolean purchasedSupports;
        account a = new account();
        a.name = 'Test name';
        insert a;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'test Opp');
        insert o;
        
        test.startTest();
            Database.executeBatch(new OpportunityPHSummaryBatch(), 200);
        test.stopTest();
        
        opportunity o2 = [select Franchise__c, is_return_customer__c, purchase_made__c, purchase_total__c, number_of_steps__c from opportunity limit 1];
        purchasedSupports = o2.Number_of_Steps__c > 0 ? TRUE : FALSE;
        
        system.assertEquals(FALSE, o2.Purchase_Made__c);
        system.assertEquals(0, o2.Purchase_Total__c);
        system.assertEquals(0, o2.Number_of_Steps__c);
        
        for(Auto_Generated_Tasks__mdt ag : autoGenTasks){
            if(ag.PurchasedSupports__c == PurchasedSupports &&
               ag.Purchase_Made__c == o2.Purchase_Made__c &&
               ag.is_Return_Customer__c == o2.Is_Return_Customer__c &&
               (ag.Franchise__c != Null && ag.Franchise__c.split(',').Contains(o2.Franchise__c)) &&
               ag.Use_in_OPPPHSummaryBatch__c){
                   taskCount++;
               }
        }
        
        list<task> tasks = new list<task>([select subject, activityDate from task]);
        system.assertEquals(taskCount,tasks.size());
    }
}