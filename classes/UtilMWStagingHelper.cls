/*
Developed by Minh Nguyen    11/4/2021
Jira: FRN-35 GF Midwest data processing

Description: Utility class to convert MW staging objects to accounts and purchase histories
- Calls ConvertToAccount() or ConvertToPurchaseHistory() from MWStagingProcessingBatch
*/

public class UtilMWStagingHelper {

    /*
    Description: Main function to converts MW staging object to account
    Parameter: A single MW staging record of type account.  
    Return: formats it to proper account fields, and returns new account
    */
    public static Account ConvertToAccount(Mw_Staging__c mw){
        Account a = new account();
        a.Name = NameFormat(mw.Customer_Name__c);
        a.Phone = mw.Phone__c != Null ? UtilityAndFactory.PhoneSimplify(mw.Phone__c) : randomPhoneGenerator();
        a.ContactEmail__c = mw.Email__c;
        a.address__c = mw.AddressStreet__c;
        a.Zip_code__c = mw.Zip_Code__c;
        a.AcumaticaId__c = mw.customerId__c;
        return a;
    }
    
    /*
    Description: Main function to converts MW staging object to Purchase History
    Parameter: A single MW staging record of type purchase history.  
    Return: formats it to proper account fields, and returns new account
    */
    public static purchase_history__c ConvertToPurchaseHistory(MW_Staging__c mw){
        purchase_history__c ph = new purchase_history__c();
        ph.FirstName__c = mw.Sales_Customer_Name__c != Null? UtilityAndFactory.GetFirstName(mw.Sales_Customer_Name__c) : Null;
        ph.LastName__c = mw.Sales_Customer_Name__c != Null? UtilityAndFactory.GetLastName(mw.Sales_Customer_Name__c) : Null;
        ph.Transaction_Type__c = mw.TranType__c == 'INV' ? 'Regular Sale' : 'Return';
        ph.Store__c = mw.BranchId__c != Null? mw.BranchId__c : Null;
        ph.Ticket_Number__c = mw.OrderNBR__c != Null? mw.OrderNBR__c : Null;
        ph.Ticket_Line_Number__c = mw.OrderLineNbr__c != Null? mw.OrderLineNbr__c : Null;
        ph.Price__c = mw.NetSalesAmount__c != Null? mw.NetSalesAmount__c : Null;
        ph.Quantity__c = mw.Quantity__c != Null? mw.Quantity__c : Null;
        ph.Salesperson_Number__c = mw.SalesPersonId__c != Null? mw.SalesPersonId__c : Null;
        ph.Transaction_date__c = mw.DocumentDate__c != Null? (date.parse(mw.DocumentDate__c.substring(0, mw.DocumentDate__c.length() - 4).deleteWhiteSpace())) : Null;
        ph.SKU__c = mw.InventoryId__c != Null ? mw.InventoryId__c : NULL;
        return ph;
    }
    
    /*
    Description: Formats the name.  MW Midwest captures a full name field only and has two possible formats.
    format 1: 'LAST, FIRST'
    format 2: 'FIRST LAST'
    Paramteter: A string full name
    Return: a name string in the correct format for account (first last);
    */
    public static string NameFormat(String fullName){
        string Name = fullName;
        list<string> SplitName = new list<string>();
        
        //Name is "LAST, FIRST"
        if(fullName != Null && fullName.contains(',')){
            SplitName = fullName.Split(',');
            Name = SplitName[1] + ' ' + SplitName[0].trim();
        }
        
        return Name;
    }

    public static string randomPhoneGenerator(){
        string randomPhoneNumber;
        for(integer i = 0; i < 10; i++){
            randomPhoneNumber = randomPhoneNumber == Null ? String.valueOf(Integer.valueof((Math.random() * 9))) : 
            randomPhoneNumber + String.valueOf(Integer.valueof((Math.random() * 9))); 
        }

        return randomPhoneNumber;
    }
}