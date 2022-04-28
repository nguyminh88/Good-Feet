@isTest
public class OpportunityFunctionsTest {
    @TestSetup
    static void makeData(){
        sales_representative__c sr = UtilityAndFactory.SingleSalesRepresentative('nameer', '1234');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Tester', sr);
        insert a;
        insert UtilityAndFactory.SingleOpportunity(a, 'OppTest');
    }

    @isTest
    static void isReturnCheckboxTest(){
        opportunity o1 = [select is_return_customer__c from opportunity limit 1];
        account a = [select id from account limit 1];
        system.assertEquals(FALSE, o1.is_return_customer__c);

        test.startTest();
        insert UtilityAndFactory.SingleOpportunity(a, 'OppTest');
        test.stopTest();

        opportunity o2 = [select is_return_customer__c from opportunity where id !=: o1.Id limit 1];
        system.assertEquals(TRUE, o2.is_return_customer__c);
    }

    @isTest
    static void OppToAccLifeStyleFieldUpdates(){
        Opportunity o = [select Primary_Work_Environment__c,
        Secondary_Work_Environment__c, Work_activities_performed__c,
        Work_activity_comment__c,Socks__c,
        Shoes__c, Wears_house_shoes_around_home__c,
        Feet_hurts_more_in_morning_evenings__c, Hard_surfaces_around_home__c,
        Outdoors__c, Sports__c, Exercise__c, For_Fun__c,Play_activity_comment__c,
        Most_Excited_About_Activity__c, Other_Most_Excited_About__c  from Opportunity limit 1];

        o.Primary_Work_Environment__c = 'Test';
        o.Secondary_Work_Environment__c = 'Test';
        o.Work_activities_performed__c = 'Test';
        o.Work_activity_comment__c = 'Test';
        o.Socks__c = 'Test';
        o.Shoes__c = 'Test';
        o.Wears_house_shoes_around_home__c = TRUE;
        o.Feet_hurts_more_in_morning_evenings__c = TRUE;
        o.Hard_surfaces_around_home__c = TRUE;
        o.Outdoors__c = 'Test';
        o.Sports__c = 'Test';
        o.Exercise__c = 'Test';
        o.For_Fun__c = 'Test';
        o.Play_activity_comment__c = 'Test';
        o.Most_Excited_About_Activity__c = 'Test';
        o.Other_Most_Excited_About__c = 'Test';

        Account b = [select Primary_Work_Environment__c,
        Secondary_Work_Environment__c, Work_activities_performed__c,
        Work_activity_comment__c,Socks__c,
        Shoes__c, Wears_house_shoes_around_home__c,
        Feet_hurts_more_in_morning_evenings__c, Hard_surfaces_around_home__c,
        Outdoors__c, Sports__c, Exercise__c, For_Fun__c,Play_activity_comment__c,
        Most_Excited_About_Activity__c, Other_Most_Excited_About__c  from Account limit 1];

        system.assertEquals(b.Wears_house_shoes_around_home__c, FALSE);

        test.StartTest();
        update o;
        test.StopTest();

        Account a = [select Primary_Work_Environment__c,
        Secondary_Work_Environment__c, Work_activities_performed__c,
        Work_activity_comment__c,Socks__c,
        Shoes__c, Wears_house_shoes_around_home__c,
        Feet_hurts_more_in_morning_evenings__c, Hard_surfaces_around_home__c,
        Outdoors__c, Sports__c, Exercise__c, For_Fun__c,Play_activity_comment__c,
        Most_Excited_About_Activity__c, Other_Most_Excited_About__c  from Account limit 1];

        system.assertEquals(a.Primary_Work_Environment__c, 'Test');
        system.assertEquals(a.Wears_house_shoes_around_home__c, TRUE);
    }
}