/*
SalesRepTransferQueueable SRTQueueable = new SalesRepTransferQueueable(inputs.ownerId, inputs.originalSalesRepId, srlist);
system.enqueueJob(SRTQueueable);

*/

public class SalesRepTransferQueueable implements Queueable{
    private Id OwnerId;
    private Id originalSR;
    private List<Sales_Representative__c> srList; 
    
    public SalesRepTransferQueueable(Id OwnerId, Id OriginalSR, List<Sales_Representative__c> srList){
        this.OwnerId = OwnerId;
        this.originalSR = OriginalSR;
        this.srList = srList;
    }
    
    public void execute(QueueableContext context) {
        try{
            SalesRepTransfer.transferExecute(OwnerId, OriginalSR, srList);
            string ogRepName = [select name from sales_representative__c where id =: OriginalSR].name;
            utilityAndFactory.ErrorLog('Successful Rep Transfer', 'Original Rep name: ' + ogRepName);
        } catch (exception e){
            utilityAndFactory.ErrorLog('Failure Rep Transfer', 'Original Rep id: ' + originalSR);
        }
    }
}