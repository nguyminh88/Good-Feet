/*
Developed by Minh Nguyen
Description: A schedulable class to refresh dashboards automatically.  
-Makes a callout to own org and refreshes dashboards queried in CMDT


String cron = '0 0 0 ? * * *';
  RefreshDashboardSchedulable GR = new RefreshDashboardSchedulable();
  System.Schedule('Refresh Dashboards', cron, GR);

System.schedule('RefreshDashboardSchedulable 00',  '0 00 * * * ?', new RefreshDashboardSchedulable());

System.schedule('RefreshDashboardSchedulable 10',  '0 10 * * * ?', new RefreshDashboardSchedulable());

System.schedule('RefreshDashboardSchedulable 20',  '0 20 * * * ?', new RefreshDashboardSchedulable());

System.schedule('RefreshDashboardSchedulable 30',  '0 30 * * * ?', new RefreshDashboardSchedulable());

System.schedule('RefreshDashboardSchedulable 40',  '0 40 * * * ?', new RefreshDashboardSchedulable());

System.schedule('RefreshDashboardSchedulable 50',  '0 50 * * * ?', new RefreshDashboardSchedulable());

RefreshDashboardSchedulable abc = new RefreshDashboardSchedulable(); 
abc.execute(null);
*/

global class RefreshDashboardSchedulable implements Schedulable{
	global void execute(SchedulableContext SC) {
        list<Dashboard__mdt> Dashboards = new list<Dashboard__mdt>([select DashboardId__c from Dashboard__mdt]);
        
        for(Dashboard__mdt db : Dashboards){
            refreshDashboard(db.DashboardId__c);
        }
    }

    /*
    Description: Calls salesforce analytics endpoint and refreshes the dashboard
    Parameter: Dashboard id (queried from execute class)
    Void action: Callout to analytics object, refreshes dashboard in parameter
    */
    @future(callout=true)
    public static void refreshDashboard(Id dashboardId){
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setMethod('PUT');
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v51.0/analytics/dashboards/' + dashboardId);
		Http http = new Http();
        if(!test.isRunningTest()){
            try {
                HttpResponse res = http.send(req);
            } catch (exception e){
                UtilityAndFactory.ErrorLog('Failure - refreshDashboard', 'Exception : ' + e);
            }
        }
        	
    }
}