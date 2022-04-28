@isTest
public class AccountFunctionsTest{
    @TestSetup
    static void makeData(){
        sales_representative__c sr = UtilityAndFactory.SingleSalesRepresentative('John Smith', '1394');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Tester Acc', sr);
        a.phone = '5033800755';
        insert a;
    }

    @isTest
    static void PhoneDupeCheck(){
        sales_representative__c sr = [select id from sales_representative__c limit 1];
        account a = UtilityAndFactory.SingleCustomerAccount('Tester Acc', sr);
        a.phone = '5033800755';
        test.startTest();
            try{
                insert a;
            } catch (exception e){
                
            }
        test.stopTest();

        list<account> acclist = [select id from account limit 10000];
        system.assertEquals(1, acclist.size());
    }

    @isTest 
    static void BeforeUpdateDoNotContactTest(){
        account a = [select Do_Not_Contact__c from account limit 1];
        list<task> existingTasks = new list<task>();
        task t1 = new task();
        t1.subject = 'test1';
        t1.whatid = a.Id;
        t1.status = 'Open';
        t1.activityDate = date.today();
        task t2 = new task();
        t2.subject = 'test1';
        t2.whatid = a.Id;
        t2.Status = 'Open';
        t2.activityDate = date.today();
        existingTasks.add(t1);
        existingTasks.add(t2);
        insert existingTasks;
        
        a.Do_Not_Contact__c = TRUE;
        test.startTest();
            update a;
        test.stopTest();

        list<task> checkList = new list<task>([select id from task where status = 'Completed']);
        system.assertEquals(2, checkList.size());
    }

}