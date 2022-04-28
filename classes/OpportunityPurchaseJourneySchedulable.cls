public with sharing class OpportunityPurchaseJourneySchedulable implements Schedulable{
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new OpportunityPurchaseJourneyBatch(), 2000);
    }
}
