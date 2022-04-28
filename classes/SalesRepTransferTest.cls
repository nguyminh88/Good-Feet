@isTest
public class SalesRepTransferTest {
    @TestSetup
    static void makeData(){
        sales_representative__c sr = utilityAndFactory.SingleSalesRepresentative('test1 rep', '1234');
        sales_representative__c sr2 =  utilityAndFactory.SingleSalesRepresentative('test2 rep', '4321');
        insert sr;
        insert sr2;
        account a = utilityAndFactory.SingleCustomerAccount('test name', sr);
        insert a;
        account a1 = utilityAndFactory.SingleCustomerAccount('test name2 ', sr2);
        insert a1;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'opp name');
        o.sales_representative__c = sr.id;
        insert o;
        opportunity o2 = UtilityAndFactory.SingleOpportunity(a1, 'opp name');
        o2.sales_representative__c = sr2.id;
        insert o2;
        task t = new task();
        t.status = 'Open';
        t.whatid = o.id;
        t.subject = 'Test';
        t.activitydate = date.today();
        t.sales_representative__c = sr.id;
        insert t;
        task t2 = new task();
        t2.status = 'Open';
        t2.whatid = o2.id;
        t2.subject = 'Test';
        t2.activitydate = date.today();
        t.sales_representative__c = sr.id;
        insert t2;
    }

    @isTest
    static void transferAll(){
        sales_representative__c ogRep = [select id,ownerId from Sales_Representative__c where pin__c = '1234' limit 1];
        sales_representative__c newRep = [select id,ownerId from Sales_Representative__c where pin__c = '4321' limit 1];
        list<SalesRepTransfer.SalesRepTransferInputs> theList = new list<SalesRepTransfer.SalesRepTransferInputs>();
        SalesRepTransfer.SalesRepTransferInputs inputs = new SalesRepTransfer.SalesRepTransferInputs();
        inputs.transferAll = TRUE;
        inputs.originalSalesRepId = ogRep.Id;
        inputs.ownerId = ogRep.ownerId;
        theList.add(inputs);
        test.startTest();
            SalesRepTransfer.transferInitiator(theList);
        test.stopTest();
    }

    @isTest
    static void QueueableTest(){
        sales_representative__c ogRep = [select id,ownerId from Sales_Representative__c where pin__c = '1234' limit 1];
        list<sales_representative__c> srList = [select id,ownerId from Sales_Representative__c where pin__c = '4321' limit 1];
        test.startTest();
            SalesRepTransferQueueable SRTQueueable = new SalesRepTransferQueueable(ogRep.ownerId, ogRep.Id, srlist);
            system.enqueueJob(SRTQueueable);
        test.stopTest();
    }
}