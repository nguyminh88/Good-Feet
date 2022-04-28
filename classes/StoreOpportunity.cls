/*

Put request expects JSON similar to this:

{
    "storeName" : "storeName",
    "firstName" : "firstName",
    "lastName" : "lastName",
    "emailAddress" : "emailAddress"
}
*/

/**
 * @author Connor Zint
 * @date 3/23/2018
 * @description Custom rest endpoint to create opportunities and necessary associative data
 * @history
 *   03-30-2018 - Bradley Wong - refactored Opportunity to use Store__c
 *   10-10-2018 - Bradley Wong - refactored Store assignment to use Clienteling_Id__c (assigned via OpportunityTriggerHandler)
 */

global with sharing class StoreOpportunity  {

   
}