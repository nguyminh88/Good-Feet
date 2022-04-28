@isTest
public class RefreshDashboardTest {
    @isTest static void RefreshDashboardCoverage(){
        RefreshDashboardSchedulable abc = new RefreshDashboardSchedulable(); 
		abc.execute(null);
    }
}