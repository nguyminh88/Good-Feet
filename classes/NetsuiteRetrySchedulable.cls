/*
Developed by Minh Nguyen
JIRA: SFSLII-255 Hourly retry job to catch any failed netsuite callouts
Description: Schedulable for NetsuiteRetryFailedAccountsBatch class
-Run hourly.  Check listview on account (Netsuite failure) to see current failures.  

System.schedule('NetsuiteRetrySchedulable 00',  '0 00 * * * ?', new NetsuiteRetrySchedulable());
*/


public  class NetsuiteRetrySchedulable Implements Schedulable{
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new NetsuiteRetryFailedAccountsBatch(), 1);
    }
}