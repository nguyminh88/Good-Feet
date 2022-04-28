@isTest
public with sharing class TaskOverdueBatchTest {
    @isTest
    static void taskOverdueMainTest(){
        task t  = new task();
        t.subject = 'tester';
        t.status = 'Open';
        t.activityDate = date.today().addDays(-1);
        insert t;

        test.startTest();
        Database.executeBatch(new TaskOverdueBatch(), 2000);
        test.stopTest();
    }
}