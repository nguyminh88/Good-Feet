//id bpid = Database.ExecuteBatch(new StoreSalesSummaryBatch(), 1);
/*
Developed by Minh Nguyen
Description: Batch class to roll up sales purchase history onto user license

Jira: SFSLII-166 / 167
*/


public class StoreSalesSummaryBatch implements Database.Batchable<sObject>{
    private date lower;
    private date upper;

    public StoreSalesSummaryBatch(date lowerBound, date upperBound){
        this.lower = lowerBound;
        this.upper = upperBound;
    } 
    
    public database.QueryLocator start(Database.BatchableContext BC){
        return test.isRunningTest() ? database.getQueryLocator('Select Previous_High_Month_Amount__c, Previous_High_Month_Date__c, Top_Sale_Receipt_Sales_Rep__c, Top_Sale_Receipt_Amount__c, Top_Sale_Receipt_Date__c, Highest_Month_Amount__c,  Highest_Month_Date__c, Previous_Highest_Day_Sale__c, Previous_High_Sale_Date__c, Highest_Sale_Date__c, Highest_Day_Sale_Amount__c, RICS_Store_Number__c, Yesterday_Sales__c, WTD__c, MTD__c, Last_Week__c, Last_Month__c From User where isActive = TRUE AND RICS_Store_Number__c = \'471\' limit 1') : database.getQueryLocator('Select Previous_High_Month_Amount__c, Previous_High_Month_Date__c,Top_Sale_Receipt_Sales_Rep__c, Top_Sale_Receipt_Amount__c, Top_Sale_Receipt_Date__c, Highest_Month_Amount__c,  Highest_Month_Date__c, Previous_Highest_Day_Sale__c, Previous_High_Sale_Date__c,Highest_Sale_Date__c, Highest_Day_Sale_Amount__c, RICS_Store_Number__c, Yesterday_Sales__c, WTD__c, MTD__c, Last_Week__c, Last_Month__c From User where isActive = TRUE AND StoreId__c != Null'); 
     }
    
    public void execute(Database.BatchableContext BC, list<sObject> scope){
        date lowerBound = this.lower;
        date upperBound = this.upper;
        map<string, decimal> topReceiptAmountMap = new map<string, decimal>();
        map<string, date> topReceiptDateMap = new map<string, date>();
        map<string, string> topReceiptSRMap = new map<string, string>();
        map<date, decimal> highSaleDayAmountMap = new map<date, decimal>();
        map<string, decimal> highSaleMonthMap = new map<string, decimal>();
        list<sales_reporting__c> InsertReporting = new list<sales_reporting__c>();
        User StoreUser = (User)scope[0];
        string storeId;
        decimal dayTotalAmount = 0;
        decimal currentTopReceiptAmount = 0;
        string currentTopReceiptString;
        decimal monthTotalAmount = 0;
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

        StoreId = test.isRunningTest() ? [select id from user where RICS_Store_Number__c = '471' limit 1][0].Id : StoreUser.Id;
        
        if(upperbound.year() == date.today().year()){
            StoreUser.Yesterday_Sales__c = 0;
            StoreUser.WTD__c = 0;
            StoreUser.MTD__c = 0;
            StoreUser.Last_Week__c = 0;
            StoreUser.Last_Month__c = 0;    
        }

        for(Purchase_History__c ph : [Select Store__c, Salesperson_Number__c, Sales_Representative__r.Name, Ticket_Number__c, Price__c, transaction_date__c 
                                       from Purchase_History__c where 
                                       OwnerId =: storeId AND Ticket_Voided__c = False 
                                       AND transaction_date__c <=: upperBound AND transaction_date__c >: lowerBound
                                       order by Transaction_Date__c DESC]){
            
            //store current reportings
            if(ph.Transaction_Date__c == date.today().addDays(-1))
                StoreUser.Yesterday_Sales__c = StoreUser.Yesterday_Sales__c + ph.Price__c;
            if(ph.Transaction_Date__c >= date.today().toStartOfWeek())
                StoreUser.WTD__c = StoreUser.WTD__c + ph.Price__c;
            if(ph.Transaction_Date__c >= date.today().toStartOfMonth())
                StoreUser.MTD__c = StoreUser.MTD__c + ph.Price__c;
            if(ph.Transaction_Date__c >= date.today().addDays(-7).toStartOfWeek() 
            && ph.Transaction_Date__c < date.today().toStartOfWeek())
                StoreUser.Last_Week__c = StoreUser.Last_Week__c + ph.Price__c;
            if(ph.Transaction_Date__c >= date.today().addMonths(-1).toStartOfMonth() 
            && ph.Transaction_Date__c < date.today().toStartOfMonth())
                StoreUser.Last_Month__c = StoreUser.Last_Month__c + ph.Price__c;
            
            //create High Sale Day amount Map - Store High Sale Date Record
            if(!highSaleDayAmountMap.containsKey(ph.transaction_date__c))
                highSaleDayAmountMap.put(ph.transaction_date__c, ph.price__c);
            else {
                decimal tempDayAmount = highSaleDayAmountMap.get(ph.transaction_date__c);
                tempDayAmount += ph.price__c;
                highSaleDayAmountMap.put(ph.transaction_date__c, tempDayAmount);
            }                           

            //Create High Sale Month Map - Store High Sale Month Record
            if(!highSaleMonthMap.containsKey(string.valueOf(ph.transaction_date__c.month() + '' + ph.transaction_date__c.year())))
                highSaleMonthMap.put(string.valueOf(ph.transaction_date__c.month() + '' +  ph.transaction_date__c.year()), ph.price__c);
            else {
                decimal tempMonthAmount = highSaleMonthMap.get(string.valueOf(ph.transaction_date__c.month() + '' +  ph.transaction_date__c.year()));
                tempMonthAmount += ph.price__c;
                highSaleMonthMap.put(string.valueOf(ph.transaction_date__c.month() + '' +  ph.transaction_date__c.year()), tempMonthAmount);
            }

            //Create Top Receipt Map - Store Highest Receipt
            if(!topReceiptAmountMap.containsKey(ph.Ticket_number__c + ph.Salesperson_Number__c + ph.Store__c + ph.transaction_date__c)){
                topReceiptAmountMap.put(ph.Ticket_number__c + ph.Salesperson_Number__c + ph.Store__c+ ph.transaction_date__c, ph.price__c);
                topReceiptDateMap.put(ph.Ticket_number__c + ph.Salesperson_Number__c + ph.Store__c+ ph.transaction_date__c, ph.transaction_date__c);
                topReceiptSRMap.put(ph.Ticket_number__c + ph.Salesperson_Number__c + ph.Store__c+ ph.transaction_date__c, ph.Sales_Representative__r.Name);
            } else {
                decimal tempCurrentReceiptAmt = topReceiptAmountMap.get(ph.Ticket_number__c+ph.Salesperson_Number__c+ ph.Store__c+ph.transaction_date__c);
                tempCurrentReceiptAmt += ph.price__c;
                topReceiptAmountMap.put(ph.Ticket_number__c + ph.Salesperson_Number__c + ph.Store__c+ ph.transaction_date__c, tempCurrentReceiptAmt);
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
        //Store High Sale Day and previous High Sale Day
        if(highSaleDayAmountMap.get(tempLoopVarHighSaleDate) > StoreUser.Highest_Day_Sale_Amount__c || 
         StoreUser.Highest_Day_Sale_Amount__c == Null || StoreUser.Highest_Day_Sale_Amount__c == 0){
            StoreUser.Highest_Day_Sale_Amount__c = highSaleDayAmountMap.get(tempLoopVarHighSaleDate);
            StoreUser.Highest_Sale_Date__c = tempLoopVarHighSaleDate;
            
         }
        if(highSaleDayAmountMap.get(tempLoopVarPrevHighSaleDate) > StoreUser.Previous_Highest_Day_Sale__c || 
         StoreUser.Previous_Highest_Day_Sale__c == Null || StoreUser.Previous_Highest_Day_Sale__c == 0){
            StoreUser.Previous_Highest_Day_Sale__c = tempLoopVarHighPrevAmount;
            StoreUser.Previous_High_Sale_Date__c = tempLoopVarPrevHighSaleDate;
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
        //Store High Month Field Assignment
        if(highSaleMonthMap.get(tempLoopVarHighMonthString) > StoreUser.Highest_Month_Amount__c || 
         StoreUser.Highest_Month_Amount__c == Null || StoreUser.Highest_Month_Amount__c == 0){
            if(tempLoopVarHighMonthString != Null && tempLoopVarHighMonthString.length() == 5){
                integer year = integer.valueOf(tempLoopVarHighMonthString.Right(4));
                integer month = integer.valueOf(tempLoopVarHighMonthString.Left(1));
                topMonth = date.newInstance(year, month, 1);
            } else if(tempLoopVarHighMonthString != Null && tempLoopVarHighMonthString.length() == 6){
                integer year = integer.valueOf(tempLoopVarHighMonthString.Right(4));
                integer month = integer.valueOf(tempLoopVarHighMonthString.Left(2));
                topMonth = date.newInstance(year, month, 1);
            }
            StoreUser.Highest_Month_Amount__c = highSaleMonthMap.get(tempLoopVarHighMonthString);
            StoreUser.Highest_Month_Date__c = topMonth;
         }

         if(highSaleMonthMap.get(tempLoopVarPrevHighMonthDate) > StoreUser.Previous_High_Month_Amount__c || 
         StoreUser.Previous_High_Month_Amount__c == Null || StoreUser.Previous_High_Month_Amount__c == 0){
            if(tempLoopVarPrevHighMonthDate != Null && tempLoopVarPrevHighMonthDate.length() == 5){
                integer year = integer.valueOf(tempLoopVarPrevHighMonthDate.Right(4));
                integer month = integer.valueOf(tempLoopVarPrevHighMonthDate.Left(1));
                PrevMonth = date.newInstance(year, month, 1);
            } else if(tempLoopVarPrevHighMonthDate != Null && tempLoopVarPrevHighMonthDate.length() == 6){
                integer year = integer.valueOf(tempLoopVarPrevHighMonthDate.Right(4));
                integer month = integer.valueOf(tempLoopVarPrevHighMonthDate.Left(2));
                PrevMonth = date.newInstance(year, month, 1);
            }
            StoreUser.Previous_High_Month_Amount__c = highSaleMonthMap.get(tempLoopVarPrevHighMonthDate);
            StoreUser.Previous_High_Month_Date__c = PrevMonth;
         }


        //top receipt outside of loop
        for(string st : topReceiptAmountMap.keySet()){
            if(topReceiptAmountMap.get(st) > currentTopReceiptAmount){
                currentTopReceiptAmount = topReceiptAmountMap.get(st);
                currentTopReceiptString = st;
            }
        }
        //Store top receipt
        if(topReceiptAmountMap.get(currentTopReceiptString) > StoreUser.Top_Sale_Receipt_Amount__c || StoreUser.Top_Sale_Receipt_Amount__c == NULL || StoreUser.Top_Sale_Receipt_Amount__c == 0){
            StoreUser.Top_Sale_Receipt_Amount__c = topReceiptAmountMap.get(currentTopReceiptString);
            StoreUser.Top_Sale_Receipt_Date__c = topReceiptDateMap.get(currentTopReceiptString);
            StoreUser.Top_Sale_Receipt_Sales_Rep__c = topReceiptSRMap.get(currentTopReceiptString);
        }

        update StoreUser;
    }
    
    public void finish(Database.BatchableContext BC){
        if(this.upper.year() > 2015) //recursive batch call to loop through entire purchase history
            Database.ExecuteBatch(new StoreSalesSummaryBatch(this.lower.addYears(-1), this.upper.addYears(-1).addDays(-1)), 1);
        else{
            UtilityAndFactory.ErrorLog('Successful - StoreSalesSummaryBatch ' + date.today().format(), 'Starting SalesRepSalesSummaryBatch');
            Database.ExecuteBatch(new SalesRepSalesSummaryBatch(), 1);
        }
    }
}