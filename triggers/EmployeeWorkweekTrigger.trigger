trigger EmployeeWorkweekTrigger on Employee_Workweek__c (before insert) {
    system.debug('Do nothing useful');
}