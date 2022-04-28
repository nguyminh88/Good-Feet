/*
 * 
  String cron = '0 0 1 ? * * *';
  GetRICSPOSTransactionSchedulable GR = new GetRICSPOSTransactionSchedulable();
  System.Schedule('RICS Sales Data', cron, GR);

GetRICSPOSTransactionSchedulable abc = new GetRICSPOSTransactionSchedulable(); 
abc.execute(null);
*/
public class GetRICSPOSTransactionSchedulable implements Schedulable, Database.AllowsCallouts{
    public void execute(SchedulableContext ctx){
        list<RICS_Sales_Data__mdt> RO = new list<RICS_Sales_Data__mdt>([select override__C, batchday__c from RICS_Sales_Data__mdt where HALT__C = true]);
        if(RO.isEmpty()){
            GetPOSSalesDataQueueable RICS = new GetPOSSalesDataQueueable();
            system.enqueueJob(RICS);
        }
    }
}