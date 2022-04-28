public class SalesReportingController {
    private static boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].isSandbox;
    private static date lastMonth = date.today().addMonths(-1).toStartOfMonth();
    private static date yesterday = date.today().addDays(-1);
    private static date thisMonth = date.today().toStartOfMonth();
    private static boolean firstThreeDays = (date.today().day() <= 3 && date.today().day() >= 1)? TRUE : FALSE;
    private static Id currentUserId = UserInfo.GetUserId();
    private static user currentUser = [select franchise__c from user where id =: currentUserId];
    private static string currentUserFranchise = currentUser.franchise__c;

    @AuraEnabled(cacheable=true)
    public static list<user> getCompanyWideStoreHighMonth(){
        list<user> returnList = new list<user>();
        list<User> recordBroken = new list<User>([Select LastName, Highest_Month_Amount__c,Highest_Month_Date__c 
                                                from USER where isactive = true and Highest_Month_Amount__c != Null 
                                                AND franchise__c =: currentUserFranchise
                                                ORDER BY Highest_Month_Amount__c DESC limit 1]);

        if(!test.isRunningTest() && recordBroken[0].Highest_Month_Date__c == lastMonth && (firstThreeDays || isSandbox))
            returnList.add(recordBroken[0]);

        return !returnList.isEmpty()? returnList : Null;
    }

    @AuraEnabled(cacheable=true)
    public static list<user> getCompanyWideStoreHighDay(){
        list<user> returnList = new list<user>();
        list<User> recordBroken = new list<User>([Select LastName, Highest_Day_Sale_Amount__c,Highest_Sale_Date__c 
                                                from USER where isactive = true and Highest_Day_Sale_Amount__c != Null 
                                                AND franchise__c =: currentUserFranchise
                                                ORDER BY Highest_Day_Sale_Amount__c DESC limit 1]);

        if(!test.isRunningTest() && recordBroken[0].Highest_Sale_Date__c == yesterday)
            returnList.add(recordBroken[0]);

        return !returnList.isEmpty()? returnList : Null;
    }

    @AuraEnabled(cacheable=true)
    public static list<Sales_Representative__c> getCompanyWideIndividualHighMonth(){
        
        list<Sales_Representative__c> returnList = new list<Sales_Representative__c>();
        list<Sales_Representative__c> recordBroken = new list<Sales_Representative__c>([Select FirstName__c, Name, owner.lastName,Highest_Month_Amount__c, High_Sale_Month_Formula__c,  
                                                                                        Highest_Month_Date__c,Previous_High_Sale_Month_Date_Formula__c 
                                                                                        from Sales_Representative__c where Active__c = TRUE And Highest_Month_Date__c <: thisMonth
                                                                                        AND Highest_Month_Amount__c != Null AND franchise__c =: currentUserFranchise
                                                                                        ORDER BY Highest_Month_Amount__c DESC limit 1]);
        if(!test.isRunningTest() && recordBroken[0].Highest_Month_Date__c == lastMonth && (firstThreeDays || isSandbox))
            returnList.add(recordBroken[0]);
        
        return !returnList.isEmpty()? returnList : Null;
    }

    @AuraEnabled(cacheable=true)
    public static list<Sales_Representative__c> getCompanyWideIndividualHighDay(){
        list<Sales_Representative__c> returnList = new list<Sales_Representative__c>();
        list<Sales_Representative__c> recordBroken = new list<Sales_Representative__c>([Select FirstName__c, Name, Highest_Sale_Date__c, owner.lastName, Highest_Sale_Day_Amount__c 
                                                                                        from Sales_Representative__c where Active__c = TRUE AND Highest_Sale_Day_Amount__c != Null
                                                                                        AND franchise__c =: currentUserFranchise
                                                                                        ORDER BY Highest_Sale_Day_Amount__c DESC limit 1]);
        
        if(!test.isRunningTest() && recordBroken[0].Highest_Sale_Date__c == yesterday)
            returnList.add(recordBroken[0]);
        
        return !returnList.isEmpty()? returnList : Null;
    }

    @AuraEnabled(cacheable=true)
    public static list<user> getStoreHighestReceipt(){
        list<user> returnList = new list<user>();
        list<User> recordBroken = new list<User>([Select Top_Sale_Receipt_Date__c, Top_Sale_Receipt_Amount__c,Top_Sale_Receipt_Sales_Rep__c, LastName 
                                                from USER where isactive = TRUE and Top_Sale_Receipt_Amount__c != Null 
                                                AND franchise__c =: currentUserFranchise
                                                ORDER BY Top_Sale_Receipt_Amount__c DESC limit 1]);

        if(!test.isRunningTest() && recordBroken[0].Top_Sale_Receipt_Date__c == date.Today().AddDays(-1) 
          && recordBroken[0].Top_Sale_Receipt_Amount__c > 6860)
            returnList.add(recordBroken[0]);

        return !returnList.isEmpty()? returnList : Null;
    }

    @AuraEnabled(cacheable=true)
    public static list<user> getStoreMonthRecordBreak(){
        list<user> recordBroken = new list<user>();
        
        if(firstThreeDays || isSandbox)
            recordBroken = [Select LastName, Highest_Month_Amount__c, Highest_Month_Date__c, High_Month_Date_Formula__c,
                                                 Previous_High_Month_Amount__c, Previous_High_Month_Date__c,Previous_High_Month_Date_Formula__c 
                                                from USER where isactive = TRUE AND Highest_Month_Date__c =: lastMonth AND
                                                Highest_Month_Amount__c >= 30000
                                                AND franchise__c =: currentUserFranchise
                                                ORDER BY Highest_Month_Amount__c DESC];

        return !recordBroken.isEmpty()? recordBroken : Null;
    }

    @AuraEnabled(cacheable=true)
    public static list<Sales_Representative__c> getIndividualHighMonth(){
        list<Sales_Representative__c> recordBroken = new list<Sales_Representative__c>();
        
        if(firstThreeDays || isSandbox)
             recordBroken = [Select firstname__c,Name, owner.lastName,Highest_Month_Amount__c, High_Sale_Month_Formula__c,  
                             Previous_High_Sale_Month_Amount__c,Previous_High_Sale_Month_Date_Formula__c  
                             from Sales_Representative__c where Active__c = TRUE
                             AND Highest_Month_Amount__c >= 30000 AND Highest_Month_Date__c =: lastMonth 
                             AND franchise__c =: currentUserFranchise
                             ORDER BY Highest_Month_Amount__c DESC];
        
        return !recordBroken.isEmpty()? recordBroken : Null;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getStoreHighestSaleDayBreak(){
        list<User> recordBroken = new list<User>([Select Highest_Day_Sale_Amount__c,High_Sale_Date_Formula__c, Previous_Highest_Day_Sale__c, 
                                                Previous_High_Sale_Date_Formula__c, LastName 
                                                from USER where Highest_Sale_Date__c =: Date.Today().AddDays(-1) AND
                                                Highest_Day_Sale_Amount__c >= 2000
                                                AND franchise__c =: currentUserFranchise
                                                ORDER BY Highest_Day_Sale_Amount__c DESC]);
        return !recordBroken.isEmpty()? recordBroken : Null;
    }

    @AuraEnabled(cacheable=true)
    public static list<Sales_Representative__c> getIndividualHighestSaleDayBreak(){
        list<Sales_Representative__c> recordBroken = new list<Sales_Representative__c>([Select firstname__c,Name,High_Sale_Date_Formula__c, Previous_High_Sale_Day_Amount__c,Previous_High_Sale_Date_Formula__c, Previous_High_Sale_Date__c, 
                                                                                        Highest_Sale_Day_Amount__c, Highest_Sale_Date__c, owner.lastName 
                                                                                        from Sales_Representative__c where Highest_Sale_Date__c =: Date.Today().AddDays(-1) AND Active__c = TRUE
                                                                                        AND Highest_Sale_Day_Amount__c >= 2000 AND franchise__c =: currentUserFranchise
                                                                                        ORDER BY Highest_Sale_Day_Amount__c DESC]);
        return !recordBroken.isEmpty()? recordBroken : Null;
    }

}