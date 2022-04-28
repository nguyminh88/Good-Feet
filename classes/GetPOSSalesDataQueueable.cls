/* Developed by: Minh Nguyen
 * Date: 2/2021
 * Jira: SFSLII-58  RICS-salesforce account sales data integration
 * Enqueued from GetRICSPOSTransactionSchedulable.  Given a date range, Gets all POS transaction from RICS and creates Purchase_History__c records.
 * Calls RICSBatchPOStransaction batch class for insert chunking.    
 * to run manually in dev console:
 * GetPOSSalesDataQueueable RICS = new GetPOSSalesDataQueueable();
   system.enqueueJob(RICS);
 * 
 */

public class GetPOSSalesDataQueueable implements Queueable, Database.AllowsCallouts{
    private static string apexClass = 'GetPOSSalesDataQueueable';

    public void execute(QueueableContext context) {
        date RICSUnclosedBatchDate = date.today();
        Integer Skip = 0;
        integer Total = 0;
        String errorDescription = Null;
        list<purchase_history__c> InsertList = new list<purchase_history__c>();
        list<RICS_Sales_Data__mdt> RO = new list<RICS_Sales_Data__mdt>([select override__C, batchday__c from RICS_Sales_Data__mdt where override__c = true]);
        
        //error log is used as polymorphic object to pull data from rics over a longer date period
        list<Error_log__c> el = new list<error_log__c>([select endDate__c from error_log__c where context_Record__c = 'Migration' limit 1]);
        
        //start and end day contains some override capabilities for forced pulls
        date batchStartDay = !RO.isEmpty() ? RO[0].batchday__c.addDays(-4) : (!el.isEmpty() ? el[0].EndDate__c.addDays(-4) : date.today().addDays(-4));
        date batchEndDay = !RO.isEmpty() ? RO[0].batchday__c : (!el.isEmpty() ? el[0].EndDate__c : RICSUnclosedBatchDate);
        
        /*
        Do-while loop to always try the integration once.

        Reaches into RICS, gets total, populates a list of purchase history, 
        checks if total matches list size before insert to ensure correct data amount is pulled from RICS
        SKIP/TAKE is a RICS requirement.  Pagination of 100 line items at a time, increment SKIP every iteration
        
        While condition =  skip is still below the total from the initial response.  
        */
        do{ 
            Map<integer, list<purchase_history__c>> theMap = new Map<integer, list<purchase_history__c>>();
            theMap = (Map<integer, list<purchase_history__c>>)GetPOSSalesDataQueueable.GetPOSTransaction(batchStartDay, batchEndDay, Skip, False);
            for(integer s : theMap.keySet()){
                Total = s;  //get total from response and save it in a variable.
            }
            if(theMap != Null && !theMap.isEmpty() && theMap.containsKey(total))
                insertList.addAll(theMap.get(total)); //build the list here with each iteration
            Skip += 100; //increment SKIP to get the next set of sales data from RICS
        } while (Skip < Total);
        
        //Calls batch job to process inserting the list of purchase history.
        //list must not be empty, and must equal exactly the total from the response body of the calls
        if(!insertlist.isEmpty() && (insertList.size() == Total)){
            Database.executeBatch(new RICSBatchPOSTransaction(insertList, batchEndDay), 100); //Inserts all new purchase history in batches of 100
            
            //For pulling data over a longer period (more than 4 days)
            if(!el.isEmpty()){
                el[0].EndDate__c -= 1;
                Database.SaveResult [] SRes = Database.update(el, False);
                UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
            } else {
                UtilityAndFactory.ErrorLog('Successful GetPOSSalesDataQueueable Insert ' + batchEndDay.format(), 'Size of Insert: ' + insertList.size());
            }
        }

        //did not meet requirements to insert purchase history list
        //list is empty, or data pulled failed in one of the iteration, reattempts 200 times.
        else {
            errorDescription = 'GetPOSSalesDataQueueable Insert Failure: ' + batchEndDay.format() + '\nInsert/Total size = ' + insertList.size() + '/' + Total;
            UtilityAndFactory.ErrorLog('GetPOSSalesDataQueueable Failure', errorDescription);
            list<error_log__c> errlog = new list<error_log__c>([select id from error_log__c where description__c =: errorDescription]);
            if(!test.isRunningTest() && errlog.size() < 200){
                    GetRICSPOSTransactionSchedulable abc = new GetRICSPOSTransactionSchedulable(); 
					abc.execute(null);
            }
        }
    }
    
    /*
    Description: Called in each iteration of the Do-while loop from execute function
    -Wrapper for the callout of response, create a list of purchase history, then return it to execute function to process
    
    Parameter: Start Date of batch, end date of batch, The skip integer to keep track of iteration, and migration boolean
    Return: A map: key = total records, value = list of purchase history
    */
    private static Map<integer, list<purchase_history__c>> GetPOSTransaction(Date BatchStart, Date BatchEnd,Integer Skip, boolean Migration){
        String apiEndPoint = 'POS/GetPOSTransaction';
        Map<integer, list<purchase_history__c>> returnMap = new Map<integer, list<purchase_history__c>>();       
        list<purchase_history__c> phList = new list<purchase_history__c>();
        list < object > Sales = new list < object > ();
        map<string,object> ResultStatistics = new map<string,object>();
        map < string, object > js = new map < string, object > ();
        
        //Build out the payload
        js.put('BatchStartDate',BatchStart.Month() + '/' + BatchStart.day() + '/' + BatchStart.Year());
        js.put('BatchEndDate',BatchEnd.Month() + '/' + BatchEnd.day() + '/' + BatchEnd.Year());
        js.put('Skip', Skip);
        string JSONReq = JSON.serialize(js);
        
        //Callout
        Map < String, Object > theReturn = (Map < String, Object > ) UtilityAndFactory.MakeRICSCallOut(apiEndPoint, JSONReq, Null);
        Sales = thereturn != Null ? (list<object>)theReturn.get('Sales') : Null;
        
        //Result statistics is a response from RICS that contains the total records
        ResultStatistics = thereturn != Null && theReturn.containsKey('ResultStatistics')? (map<string,object>)theReturn.get('ResultStatistics') : Null;
        
        //Call function to convert response to new purchase_history__c list
        phList = sales != null ? (list<purchase_history__c>)GetPOSSalesDataQueueable.CreatePurchaseHistory(Sales) : Null;
        
        if(ResultStatistics != Null)
            returnMap.put((integer)ResultStatistics.get('TotalRecords'),phList);
        
        //return a map as a way to return two values (total and the objects)
        return returnMap;
    }
    
    /*
    Description: Deconstructs the response from an individual POStrasaction callout from RICS, builds out the list
    of purchase history and returns it

    Parameter: List of generic response objects from callout
    Return: List of Purchase history after iteraction and mapping deserialized payload
    */
    @testVisible
    private static list<purchase_history__c> CreatePurchaseHistory(list<object> SalesObj){
        list<purchase_history__c> phInsertList = new list<purchase_history__c>();

        //outer most, contains the Sales, User and SalesHeader [] list
        for(object S : SalesObj){
            map<string,object> sales = new map<string,object>();
            map<string,object> User = new map<string,object>();
            list<object> salesHeaderObj = new list<object>();
            
            sales = (map<string,object>)S;
            salesheaderObj = sales.ContainsKey('SaleHeaders') ? (list<object>)sales.get('SaleHeaders') : Null;
            User = Sales.ContainsKey('User') ? (map<string,object>)sales.get('User') : Null;
            
            //SalesHeaderObj: contains cashier, customer and sales header information
            for(object SH : salesHeaderObj){
                list<object> salesDetailObj = new list<object>();
                map<string,object> Cashier = new map<string,object>();
                map<string,object> Customer = new map<string,object>();
                map<string,object> salesHeader = new map<string,object>();
                salesHeader = (map<string,object>)SH;   
                Customer = SalesHeader.ContainsKey('Customer') ? (map<string,object>)SalesHeader.Get('Customer') : Null;
                salesDetailObj = (list<object>)salesHeader.get('SaleDetails');
                
                //SalesDetail (line items): contains line level information (price, SKU, etc)
                for(object SD : salesDetailObj){
                    map<string,object> salesDetail = new map<string,object>();
                    map<string,object> ProductItem = new map<string,object>();
                    map<string,object> SalesPerson = new map<string,object>();
                    list<object> classes = new list<object>();
                    salesDetail = (map<string,object>)SD;
                    ProductItem = salesDetail.ContainsKey('ProductItem')? (map<string,object>)salesDetail.Get('ProductItem') : Null;
                    SalesPerson = salesDetail.ContainsKey('SalesPerson')? (map<string,object>)salesDetail.Get('SalesPerson') : Null;
                    
                    Purchase_History__c ph = new Purchase_History__c();
                    ph.Batch_Date__c = Sales != Null && Sales.ContainsKey('BatchStartDate') ? date.valueOf(Sales.Get('BatchStartDate').toString().Left(10)) : Null;
                    ph.Salesperson_Number__c = SalesPerson != Null && SalesPerson.ContainsKey('UserCashierCode') ? (String)SalesPerson.Get('UserCashierCode') : Null;
                    ph.Store__c = Sales != Null && Sales.ContainsKey('StoreCode') ? String.valueOf(Sales.Get('StoreCode')) : Null;
                    
                    ph.CustomerId__c = Customer!= Null && Customer.ContainsKey('CustomerId') ? (String)Customer.Get('CustomerId') : Null;
                    ph.FirstName__c = Customer!= Null && Customer.ContainsKey('FirstName') ? (String)Customer.Get('FirstName') : Null;
                    ph.LastName__c = Customer!= Null && Customer.ContainsKey('LastName') ? (String)Customer.Get('LastName') : Null;
                    ph.Phone__c = Customer!= Null && Customer.ContainsKey('PhoneNumber') ? (String)Customer.Get('PhoneNumber') : Null;
                    ph.Account_Number__c = Customer!= Null && Customer.ContainsKey('AccountNumber') ? (String)Customer.Get('AccountNumber') : Null;
                        
                    ph.Transaction_Date__c = SalesHeader != Null && SalesHeader.ContainsKey('SaleDateTime') ? date.valueOf(SalesHeader.Get('SaleDateTime').toString().Left(10)) : Null;
                    ph.Ticket_Number__c = SalesHeader != Null && SalesHeader.ContainsKey('TicketNumber') ? String.valueOf(SalesHeader.Get('TicketNumber')) : Null;
                    ph.Ticket_Voided__c = SalesHeader != Null && SalesHeader.ContainsKey('TicketVoided') ? (Boolean)(SalesHeader.Get('TicketVoided')) : False;
                    ph.PromoCode__c = SalesHeader != Null && SalesHeader.ContainsKey('PromotionCode') ? (String)SalesHeader.Get('PromotionCode') : Null;
                    
                    ph.Ticket_Line_Number__c = SalesDetail != Null && SalesDetail.ContainsKey('TicketLineNumber') ? (Integer)SalesDetail.Get('TicketLineNumber') : Null;
                    ph.Transaction_Type__c = SalesDetail != Null && SalesDetail.ContainsKey('TransactionSaleDescription') ? (String)SalesDetail.Get('TransactionSaleDescription') : Null;
                    ph.Quantity__c = SalesDetail != Null && SalesDetail.ContainsKey('Quantity') ? (Integer)SalesDetail.Get('Quantity') : Null;
                    ph.Price__c = SalesDetail != Null && SalesDetail.ContainsKey('AmountPaid') ? (Decimal)SalesDetail.Get('AmountPaid') : Null;
                    ph.Transaction_Type__c = SalesDetail != Null && SalesDetail.ContainsKey('TransactionSaleDescription') ? 
                            (String)SalesDetail.Get('TransactionSaleDescription') : Null;
                        
                    ph.SKU__c = ProductItem != Null && ProductItem.ContainsKey('Sku') ? (String)ProductItem.Get('Sku') : Null;
                    ph.Row__c = ProductItem != Null && ProductItem.ContainsKey('Row') ? (String)ProductItem.Get('Row') : Null;
                    ph.SKU__c = ProductItem != Null && ProductItem.ContainsKey('Sku') ? (String)ProductItem.Get('Sku') : Null;
                    ph.Supplier__c = ProductItem != Null && ProductItem.ContainsKey('Supplier') ? (String)ProductItem.Get('Supplier') : Null;
                    ph.Description__c = ProductItem != Null && ProductItem.ContainsKey('Summary') ? (String)ProductItem.Get('Summary') : Null;
                    ph.Column__c = ProductItem != Null && ProductItem.ContainsKey('Column') ? (String)ProductItem.Get('Column') : Null;
                    
                    phInsertList.add(ph);
                }
            }
        }

        //Return the list purchase history that was created for processing/inserting
        return !phInsertList.isEmpty() ? phInsertList : Null;
    }
}