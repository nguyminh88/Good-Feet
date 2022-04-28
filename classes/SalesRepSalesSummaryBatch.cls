/*
Written by Minh Nguyen
Description: Batch class that runs on all sales representative records to roll up purchase history information
Batch query: All Sales_Representative__c
Batch execute: Subqueries for purchase_history__c in each Sales_Representative__c and roll up to account fields
Batch finish: Calls 'AccountReferralBatch' class.  

09/20/2021: Jira SFSLII-265: Refactor - Convert list of hard coded supports to Support_SKUS__mdt
09/29/2021 Update: Moved query to New custom metadata (Batch job breaker) for ease of accessibility
- New CMDT: Franchise Opt Out. Easy opt in and out of apex classes for records.
*/

//id bpid = Database.ExecuteBatch(new SalesRepSalesSummaryBatch(), 1);

public class SalesRepSalesSummaryBatch implements Database.Batchable<SObject>{
    private static string apexClass = 'SalesRepSalesSummaryBatch'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    
    public database.QueryLocator start(Database.BatchableContext BC){
        list<String> optouts = new list<String>();
        optOuts = UtilityAndFactory.OptOutList(OptOutList);
        return database.getQueryLocator(UtilityAndFactory.BatchQuery(apexClass));
     }
    
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        //Set all variables to 0.  This job runs every night and queries entire DB every night
        
        Sales_Representative__c sr = (Sales_Representative__c)scope[0]; 
        map<string, decimal> topReceiptStoreAmountMap = new map<string, decimal>();
        map<string, date> topReceiptStoreDateMap = new map<string, date>();
        map<string, string> topReceiptStoreTicketNumber = new map<string,string>();
        
        map<date, decimal> highSaleDayAmountMap = new map<date, decimal>();
        map<string, decimal> highSaleMonthMap = new map<string, decimal>();
        
        decimal currentTopReceiptAmount = 0;
        decimal previousTopReceiptAmount = 0;
        string currentTopReceiptString;
        string previousTopReceiptString;

        decimal tempLoopVarHighSaleAmount = 0;
        decimal tempLoopVarHighPrevAmount = 0;
        date tempLoopVarPrevHighSaleDate;
        date tempLoopVarHighSaleDate;

        decimal tempLoopVarHighMonthAmount = 0;
        string tempLoopVarHighMonthString;
        decimal tempLoopVarPrevHighMonthAmount = 0;
        string tempLoopVarPrevHighMonthDate;
        date topMonth;
        date prevMonth;

        sr.Yesterday_Sales__c = 0;
        sr.WTD__c = 0;
        sr.MTD__c = 0;
        sr.Last_Week__c = 0;
        sr.Last_Month__c = 0;
        
        //Loop through purchase history for each sales rep
        for(Purchase_History__c ph : [Select owner.lastName, Salesperson_number__c, OwnerId, Ticket_Number__c, Ticket_Line_Number__c, Store__c, price__c, transaction_date__c from purchase_history__c where sales_representative__c =: sr.Id and ticket_voided__c = FALSE order by Transaction_Date__c DESC]){
            if(ph.Transaction_Date__c == date.today().addDays(-1))
                sr.Yesterday_Sales__c = sr.Yesterday_Sales__c + ph.Price__c;
            
            if(ph.Transaction_Date__c >= date.today().toStartOfWeek())
                sr.WTD__c = sr.WTD__c + ph.Price__c;
            
            if(ph.Transaction_Date__c >= date.today().toStartOfMonth())
                sr.MTD__c = sr.MTD__c + ph.Price__c;
            
            if(ph.Transaction_Date__c >= date.today().addDays(-7).toStartOfWeek() && ph.Transaction_Date__c < date.today().toStartOfWeek())
                sr.Last_Week__c = sr.Last_Week__c + ph.Price__c;
            
            if(ph.Transaction_Date__c >= date.today().addMonths(-1).toStartOfMonth() && ph.Transaction_Date__c < date.today().toStartOfMonth())
                sr.Last_Month__c = sr.Last_Month__c + ph.Price__c;

            //Top Receipt of all time calculation
            if(!topReceiptStoreAmountMap.containsKey(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c)){
                topReceiptStoreAmountMap.put(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c, ph.price__c);
                topReceiptStoreDateMap.put(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c, ph.transaction_date__c);
                topReceiptStoreTicketNumber.put(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c, ph.Ticket_number__c);
            } else {
                decimal tempCurrentReceiptAmt = topReceiptStoreAmountMap.get(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c);
                tempCurrentReceiptAmt += ph.price__c;
                topReceiptStoreAmountMap.put(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c, tempCurrentReceiptAmt);
                topReceiptStoreDateMap.put(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c, ph.transaction_date__c);
                topReceiptStoreTicketNumber.put(ph.Ticket_number__c+ph.Salesperson_number__c+ph.Store__c+ph.transaction_date__c, ph.Ticket_number__c);
            }
            
            //high sale day
            if(!highSaleDayAmountMap.containsKey(ph.transaction_date__c))
                highSaleDayAmountMap.put(ph.transaction_date__c, ph.price__c);
            else {
                decimal tempDayAmount = highSaleDayAmountMap.get(ph.transaction_date__c);
                tempDayAmount += ph.price__c;
                highSaleDayAmountMap.put(ph.transaction_date__c, tempDayAmount);
            }

            //Create High Sale Month Map -  High Sale Month Record
            if(!highSaleMonthMap.containsKey(string.valueOf(ph.transaction_date__c.month() + '' + ph.transaction_date__c.year())))
                highSaleMonthMap.put(string.valueOf(ph.transaction_date__c.month() + '' +  ph.transaction_date__c.year()), ph.price__c);
            else {
                decimal tempMonthAmount = highSaleMonthMap.get(string.valueOf(ph.transaction_date__c.month() + '' +  ph.transaction_date__c.year()));
                tempMonthAmount += ph.price__c;
                highSaleMonthMap.put(string.valueOf(ph.transaction_date__c.month() + '' +  ph.transaction_date__c.year()), tempMonthAmount);
            }

        }
        
        //outside loop: calculate high sale day
        for(date d : highSaleDayAmountMap.keySet()){
            if(highSaleDayAmountMap.get(d) > tempLoopVarHighSaleAmount){
                tempLoopVarHighSaleAmount = highSaleDayAmountMap.get(d);
                tempLoopVarHighSaleDate = d;
            }
            if((highSaleDayAmountMap.get(d) > tempLoopVarHighPrevAmount) && 
            highSaleDayAmountMap.get(d) < tempLoopVarHighSaleAmount){
                tempLoopVarHighPrevAmount = highSaleDayAmountMap.get(d);
                tempLoopVarPrevHighSaleDate = d;
            }
        }

        //outside loop: calculate high month 
        for(string d : highSaleMonthMap.keySet()){
            if(highSaleMonthMap.get(d) > tempLoopVarHighMonthAmount){
                tempLoopVarHighMonthAmount = highSaleMonthMap.get(d);
                tempLoopVarHighMonthString = d;
            }
            if((highSaleMonthMap.get(d) > tempLoopVarPrevHighMonthAmount) && 
            highSaleMonthMap.get(d) < tempLoopVarHighMonthAmount){
                tempLoopVarPrevHighMonthAmount = highSaleMonthMap.get(d);
                tempLoopVarPrevHighMonthDate = d;
            }
        }

        if(tempLoopVarHighMonthString != Null && tempLoopVarHighMonthString.length() == 5){
            integer year = integer.valueOf(tempLoopVarHighMonthString.Right(4));
            integer month = integer.valueOf(tempLoopVarHighMonthString.Left(1));
            TopMonth = date.newInstance(year, month, 1);
        } else if(tempLoopVarHighMonthString != Null && tempLoopVarHighMonthString.length() == 6){
            integer year = integer.valueOf(tempLoopVarHighMonthString.Right(4));
            integer month = integer.valueOf(tempLoopVarHighMonthString.Left(2));
            TopMonth = date.newInstance(year, month, 1);
        }

        if(tempLoopVarPrevHighMonthDate != Null && tempLoopVarPrevHighMonthDate.length() == 5){
            integer year = integer.valueOf(tempLoopVarPrevHighMonthDate.Right(4));
            integer month = integer.valueOf(tempLoopVarPrevHighMonthDate.Left(1));
            PrevMonth = date.newInstance(year, month, 1);
        } else if(tempLoopVarPrevHighMonthDate != Null && tempLoopVarPrevHighMonthDate.length() == 6){
            integer year = integer.valueOf(tempLoopVarPrevHighMonthDate.Right(4));
            integer month = integer.valueOf(tempLoopVarPrevHighMonthDate.Left(2));
            PrevMonth = date.newInstance(year, month, 1);
        }

        //outside loop: calculate top receipt
        for(string st : topReceiptStoreAmountMap.keySet()){
            if(topReceiptStoreAmountMap.get(st) > currentTopReceiptAmount){
                currentTopReceiptAmount = topReceiptStoreAmountMap.get(st);
                currentTopReceiptString = st;
            }
        }

        sr.Highest_Month_Amount__c = highSaleMonthMap.get(tempLoopVarHighMonthString);
        sr.Highest_Month_Date__c = topMonth;
        sr.Previous_High_Sale_Month_Amount__c = tempLoopVarPrevHighMonthAmount;
        sr.Previous_High_Sale_Month_Date__c = PrevMonth;
        
        sr.Highest_Sale_Day_Amount__c = highSaleDayAmountMap.get(tempLoopVarHighSaleDate);
        sr.Highest_Sale_Date__c = tempLoopVarHighSaleDate;
        sr.Previous_High_Sale_Day_Amount__c = tempLoopVarHighPrevAmount;
        sr.Previous_High_Sale_Date__c = tempLoopVarPrevHighSaleDate;
        
        sr.Top_Receipt_With_Store__c = topReceiptStoreAmountMap.get(currentTopReceiptString);
        sr.Top_Receipt_With_Store_Date__c = topReceiptStoreDateMap.get(currentTopReceiptString);
        sr.Top_Receipt_With_Store_Ticket_Number__c = topReceiptStoreTicketNumber.get(currentTopReceiptString);

        update sr;
    }
    
    public void finish(Database.BatchableContext BC){
        if(!test.isRunningTest() && !UtilityAndFactory.isSandBox()){
            Id Sar = 'a0u3l00000fKgJRAA0';
            sales_representative__c Sarah = [select Top_Receipt_With_Store__c from Sales_Representative__c where id =: Sar];
            if(Sarah.Top_Receipt_With_Store__c <= 6860)
                Sarah.Top_Receipt_With_Store__c = 6860;
            update Sarah;
        }


        UtilityAndFactory.ErrorLog('Successful - SalesRepsSummaryBatch ' + date.today().format(), 'Starting PHAttemptPopulateAccountBatch');
        Database.ExecuteBatch(new PHAttemptPopulateAccountBatch(), 100);
    }
}