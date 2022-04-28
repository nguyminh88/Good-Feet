@isTest
public class RICSSalesDataIntegrationTest {
    @testSetup static void SettingUp(){
        Sales_Representative__c sr = UtilityAndFactory.SingleSalesRepresentative('John Wayne', '1234');
        insert sr;
        Account a = UtilityAndFactory.SingleCustomerAccount('Name Last', sr);
        a.Phone = '123';
        insert a;
        Insert UtilityAndFactory.SingleOpportunity(a,  'test opp');
    }
    
    @isTest static void CreateOrphanPHBatchNoOpp(){
        Sales_Representative__c sr = [select id from Sales_Representative__c limit 1];
        Account a = UtilityAndFactory.SingleCustomerAccount('first new', sr);
        insert a;
        purchase_history__c ph = new purchase_history__c();
        ph.firstname__c = 'test';
        ph.Account__c = a.Id;
        ph.customerId__c = '123';
        ph.price__c = 5.00;
        ph.Transaction_type__c = 'Regular Sale';
        ph.Quantity__c = 1;
        ph.Transaction_Date__c = date.today();
        insert ph;
        
        test.startTest();
            id bpId = Database.executeBatch(new CreateOpportunityOrphanPHBatch(), 10);
        test.stopTest();
    }
    
    @isTest static void CreateOrphanPHBatchWithOpp(){
        Sales_Representative__c sr = [select id from Sales_Representative__c limit 1];
        Account a = UtilityAndFactory.SingleCustomerAccount('first new', sr);
        insert a;
        purchase_history__c ph = new purchase_history__c();
        ph.firstname__c = 'test';
        ph.Account__c = a.Id;
        ph.customerId__c = '123';
        ph.Transaction_Date__c = date.today();
        ph.price__c = 5.00;
        ph.Transaction_type__c = 'Regular Sale';
        ph.Quantity__c = 1;
        insert ph;
        Insert UtilityAndFactory.SingleOpportunity(a,  'test opp');
        test.startTest();
            id bpId = Database.executeBatch(new CreateOpportunityOrphanPHBatch(), 10);
        test.stopTest();
    }
    
    @isTest static void PurchHistoryCreatedDateBatchTest1(){
        account a = [select id from account limit 1];
        list<purchase_history__c> theList = new list<purchase_history__c>();
        purchase_history__c ph = new purchase_history__c();
        ph.firstname__c = 'test';
        ph.Account__c = a.Id;
        ph.customerId__c = '123';
        ph.transaction_date__c = date.today();
        theList.add(ph);
        insert thelist;
        
        test.startTest();
            id bpId = Database.executeBatch(new PurchHistoryRICSCustCreatedDateBatch(), 1);
        test.stopTest();
    }
    
    @isTest static void ScheduleWithMigration(){
        error_log__c el = new error_log__c(context_record__c = 'Migration', endDate__c = date.today());
            insert el;
        GetRICSPOSTransactionSchedulable GetPOS = new GetRICSPOSTransactionSchedulable(); 
        test.starttest();
        GetPOS.execute(null);
        test.stoptest();
    }
    
    @isTest static void ScheduleWithoutMigration(){
        GetRICSPOSTransactionSchedulable GetPOS = new GetRICSPOSTransactionSchedulable();
        test.starttest();
        GetPOS.execute(null);
        test.stoptest();
    }
    
    @isTest static void RICSBatchPOSCoverage(){
        error_log__c el = new error_log__c(context_record__c = 'Migration', endDate__c = date.today());
            insert el;
        list<purchase_history__c> theList = new list<purchase_history__c>();
        purchase_history__c ph = new purchase_history__c();
        ph.firstname__c = 'test';
        theList.add(ph);
        
        id bpId = Database.executeBatch(new RICSBatchPOSTransaction(theList, date.today()), 1);
    }
    
    @isTest static void RICSBatchPOSCoverageNoMigrate(){
        list<purchase_history__c> theList = new list<purchase_history__c>();
        purchase_history__c ph = new purchase_history__c();
        ph.firstname__c = 'test';
        theList.add(ph);
        
        id bpId = Database.executeBatch(new RICSBatchPOSTransaction(theList, date.today()), 1);
    }
    
    @isTest static void RICSBatchPOSUpdateCoverage(){
        list<purchase_history__c> theList = new list<purchase_history__c>();
        purchase_history__c ph = new purchase_history__c();
        ph.Transaction_Date__c = date.today();
        ph.Ticket_Line_Number__c = 1;
        ph.Ticket_Number__c = '1';
        ph.Salesperson_Number__c = '1';
        ph.Store__c = '123';
        insert ph;
        
        purchase_history__c ph2 = new purchase_history__c();
        ph2.Transaction_Date__c = date.today();
        ph2.Ticket_Line_Number__c = 1;
        ph2.Ticket_Number__c = '1';
        ph2.Salesperson_Number__c = '2';
        ph2.Store__c = '123';
        theList.add(ph2);
        
        id bpId = Database.executeBatch(new RICSBatchPOSTransaction(theList, date.today()), 1);
    }

    @isTest static void PurchaseHistoryCoverage(){
        list<object> salesObj = new list<object>();
        list<object> saleHeaderObj = new list<object>();
        list<object> saleDetailObj = new list<object>();
        Map<string,object> salesMapObj = new map<string,object>();
        map<string,object> saleHeaderMap = new map<string,object>();
        map<string,object> saleDetailMap = new map<string,object>();
        
        
        map<string,object> productItem = new map<string,object>();    
        map<string,object> usermap = new map<string,object>();
        map<string,object> customer = new map<string,object>();
        productItem.put('Sku','1235');
        productItem.put('Column','1235');
        productItem.put('Row','1235');
        productItem.put('Supplier','wat');
        productItem.put('Summary','ever');
        customer.put('CustomerId','whatever');
        usermap.put('UserCashierCode','test');
        
        saleDetailMap.put('TicketLineNumber',3);
        saleDetailMap.put('Quantity',3);
        saleDetailMap.put('AmountPaid', 33.50);
        saleDetailMap.put('TransactionSaleDescription','wat');
        saleDetailMap.put('ProductItem', productItem);
        
        saleHeaderMap.put('Customer', customer);
        saleHeaderMap.put('SaleDetails',saleDetailObj);
        
        saleDetailObj.add(saleDetailMap);
        saleHeaderObj.add(saleHeaderMap);
        
        salesMapObj.put('SaleHeaders', saleHeaderObj);
        salesMapObj.put('User', userMap);
        salesObj.add(salesMapObj);
        
        GetPOSSalesDataQueueable.CreatePurchaseHistory(SalesObj);
    }
    
    @isTest() static void PurchaseHistoryPopulateAccountWithtRICSId(){
        account a = [select RICSid__c from account limit 1];
        a.RICSid__c = '12';
        update a;
        list<purchase_history__c> phlist = new list<purchase_history__c>();
        purchase_history__c ph = new purchase_history__c();
        ph.Account__c = a.Id;
        ph.CustomerId__c = '12';
        ph.transaction_date__c = date.today();
        phlist.add(ph);
        
        test.startTest();
        insert phlist;
        test.stopTest();
    }
    
    @isTest() static void PurchaseHistoryPopulateAccountWithOutRICSId(){
        account a = [select id from account limit 1];
        list<purchase_history__c> phlist = new list<purchase_history__c>();
        purchase_history__c ph = new purchase_history__c();
        ph.FirstName__c = 'Name';
        ph.LastName__c = 'Last';
        ph.Phone__c = '123';
        ph.Account__c = a.Id;
        ph.transaction_date__c = date.today();
        phlist.add(ph);
        
        test.startTest();
        insert phlist;
        test.stopTest();
    }
}