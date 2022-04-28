/*
Developed by Minh Nguyen
Description: This class has been repurposed to serve as the opportunity functions class
-Performs trigger functions based from OpportunityTriggerHandler class
*/

public class OpportunityFactory {
    private static string apexClass = 'OpportunityFactory';
    
    /*
    Description: Lifestyle fields exist on both account and opportunities.  Overwrite the account fields with the latest opportunity's values.
    Parameter: list of updated/inserted opportunity
    Void action: Populates account fields with the opp's values, only if it's the latest opp. 
    */
    public static void OppToAccountLifestyleInformation(list<Opportunity> newList){
        list<Account> accUpdateList = new list<Account>();
        list<Id> accId = new list<Id>();
        boolean toUpdate;

        for(Opportunity o : newList){
            accId.add(o.accountId);
        }

        list<opportunity> latestOpp = new list<opportunity>([select Id from Opportunity where auto_generated__c = FALSE AND 
        accountid in : accid order by createddate desc limit 1]);
        Map<id, Account> accountMap = new Map<id, Account>([select Primary_Work_Environment__c,
        Secondary_Work_Environment__c, Work_activities_performed__c,
        Work_activity_comment__c,Socks__c,
        Shoes__c, Wears_house_shoes_around_home__c,
        Feet_hurts_more_in_morning_evenings__c, Hard_surfaces_around_home__c,
        Outdoors__c, Sports__c, Exercise__c, For_Fun__c,Play_activity_comment__c,
        Most_Excited_About_Activity__c, Other_Most_Excited_About__c from Account where id in : accId]);
        
        //For each opportunity, check if values are different between opp and acc, if so, update
        for(Opportunity o : newList){
            toUpdate = FALSE;
            account a = accountMap.get(o.AccountId);
            //Make sure it is the latest opp that's updating it
            if(o.Auto_Generated__C == FALSE && latestOpp != Null && latestOpp[0].Id == o.Id){
                if(stringCompare(o.Primary_Work_Environment__c, a.Primary_Work_Environment__c)){
                    a.Primary_Work_Environment__c = o.Primary_Work_Environment__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Secondary_Work_Environment__c, a.Secondary_Work_Environment__c)){
                    a.Secondary_Work_Environment__c = o.Secondary_Work_Environment__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Work_activity_comment__c, a.Work_activity_comment__c)){
                    a.Work_activity_comment__c = o.Work_activity_comment__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Work_activities_performed__c, a.Work_activities_performed__c)){
                    a.Work_activities_performed__c = o.Work_activities_performed__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Socks__c, a.Socks__c)){
                    a.Socks__c = o.Socks__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Shoes__c, a.Shoes__c)){
                    a.Shoes__c = o.Shoes__c;
                    toUpdate = TRUE;
                }

                if(boolCompare(o.Wears_house_shoes_around_home__c, a.Wears_house_shoes_around_home__c)){
                    a.Wears_house_shoes_around_home__c = o.Wears_house_shoes_around_home__c;
                    toUpdate = TRUE;
                }

                if(boolCompare(o.Feet_hurts_more_in_morning_evenings__c, a.Feet_hurts_more_in_morning_evenings__c)){
                    a.Feet_hurts_more_in_morning_evenings__c = o.Feet_hurts_more_in_morning_evenings__c;
                    toUpdate = TRUE;
                }

                if(boolCompare(o.Hard_surfaces_around_home__c, a.Hard_surfaces_around_home__c)){
                    a.Hard_surfaces_around_home__c = o.Hard_surfaces_around_home__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Outdoors__c, a.Outdoors__c)){
                    a.Outdoors__c = o.Outdoors__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Sports__c, a.Sports__c)){
                    a.Sports__c = o.Sports__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Exercise__c, a.Exercise__c)){
                    a.Exercise__c = o.Exercise__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.For_Fun__c, a.For_Fun__c)){
                    a.For_Fun__c = o.For_Fun__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Play_activity_comment__c, a.Play_activity_comment__c)){
                    a.Play_activity_comment__c = o.Play_activity_comment__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Most_Excited_About_Activity__c, a.Most_Excited_About_Activity__c)){
                    a.Most_Excited_About_Activity__c = o.Most_Excited_About_Activity__c;
                    toUpdate = TRUE;
                }

                if(stringCompare(o.Other_Most_Excited_About__c, a.Other_Most_Excited_About__c)){
                    a.Other_Most_Excited_About__c = o.Other_Most_Excited_About__c;
                    toUpdate = TRUE;
                }

                if(toUpdate)
                    accUpdateList.add(a);
            }
        }

        if(!accUpdateList.isEmpty()){
            Database.SaveResult [] SRes = Database.update(accUpdateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
    }

    /*
    Description: Helper function for OppToAccountLifestyleInformation.  takes an opp / account string value, compares them and returns true or false
    */
    public static boolean stringCompare(string OppFieldValue, string AccFieldValue){
        return ((OppFieldValue != NULL && AccFieldValue == Null) || 
        OppFieldValue != NULL && AccFieldValue != Null &&
        OppFieldValue != AccFieldValue)? TRUE : FALSE;
    }

    /*
    Description: Helper function for OppToAccountLifestyleInformation.  takes an opp / account boolean value, compares them and returns true or false
    */
    public static boolean boolCompare(boolean OppFieldValue, boolean AccFieldValue){
        return (OppFieldValue == TRUE && AccFieldValue == FALSE)? TRUE : FALSE;
    }

    /*
    Description: Automatically set is Return Customer on opportunity if more than one exists on account, or if there are purchase histories with more than one transaction date
    */
    public static void isReturnCustomerCheck(list<Opportunity> OppList){
        list<Id> accId = new list<Id>();
        map<id, boolean> accountMultOppMap = new map<id, boolean>();
        map<string,list<date>> accountTransactionDate = new map<string,list<date>>();
        
        for(Opportunity o : OppList){   
            accId.add(o.AccountId); //create an account Id list
        }

        //Get accounts and get purchase histories
        list<Account> accList = new list<Account>([Select (Select id from Opportunities), (select account__c, transaction_date__c from purchase_histories__r ) 
                                                   from Account where id in : accId]);
        
        //loop through and check if opportunity list is empty or not, and save to a map
        for(Account a : accList){
            set<date> tempDateSet = new set<date>();
            if(a.Opportunities.size() > 0){
                accountMultOppMap.put(a.Id, TRUE);
            } else {
                accountMultOppMap.put(a.Id, FALSE);
            }
            for(purchase_history__c p : a.purchase_histories__r){
                tempDateSet.add(p.transaction_date__c);
            }
            if(tempDateSet != Null){ 
                list<date> tempDateList = new list<date>(tempDateSet);
                accountTransactionDate.put(a.Id, tempDateList);
            }
        }
        /*
        Set return customer to false by Default
        3 combination of conditions to check to set customer as return:
        a) Account has an existing opp prior to the current opp being created
        b) Account has a single purchase history ticket where the transaction date is not the same as the opportunity's close date 
           **Case: Migrated accounts with purchase history from franchises will not have an opportunity created during migration, so must check if this new opportunity is different date
                   to verify that this is a real return customer
           **Condition must exist because of CreateOrphanOpportunity
        
        c) Account has more than 1 ticket that have different transaction dates.  
            **Case: Customer has visited many times before on different dates.  
        */
        for(Opportunity o : OppList){
            o.Is_Return_Customer__c = FALSE;

            if(
            //a    
            (accountMultOppMap != Null 
            && accountMultOppMap.containsKey(o.AccountId) 
            && accountMultOppMap.get(o.AccountId)) 
            
            ||
            //b
            (accountMultOppMap == Null 
            && accountTransactionDate != Null 
            && accountTransactionDate.containsKey(o.AccountId) 
            && accountTransactionDate.get(o.AccountId).size() == 1 
            && accountTransactionDate.get(o.AccountId)[0] != o.closeDate) 
            
            ||
            //c
            (accountMultOppMap == Null 
            && accountTransactionDate != Null 
            && accountTransactionDate.containsKey(o.AccountId) 
            && accountTransactionDate.get(o.AccountId).size() > 1))
            {
                o.Is_Return_Customer__c = TRUE;
            }
        }
    }
}