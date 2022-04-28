/**
 * @author Connor Zint
 * @date 3/23/2018
 * @description test methods for custom rest endpoint (StoreOpportunity)
 * @changelog
 *   05-13-2018 - Bradley Wong - added initEwws() to account for new before insert Opp trigger, added System.runAs() in tests
 *   10-10-2018 - Bradley Wong - refactored Store assignment to use Clienteling_Id__c (assigned via OpportunityTriggerHandler)
 */
@isTest
private class StoreOpportunityTest {
    @istest private static void doNothing() {
        system.debug('do Nothing');   
    }
}