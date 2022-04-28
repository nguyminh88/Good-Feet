trigger MonthlyMinimumsPlannerTrigger on Monthly_Minimums_Planner__c (before insert)  {
    system.debug('Do nothing useful');
}