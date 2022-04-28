@isTest
public class SalesReportingControllerTest {
    @isTest
    static void SalesReportingControllerCoverageTest() {
        SalesReportingController.getStoreHighestSaleDayBreak();
        SalesReportingController.getIndividualHighestSaleDayBreak();
        
        SalesReportingController.getCompanyWideStoreHighMonth();
        SalesReportingController.getCompanyWideStoreHighDay();
        SalesReportingController.getCompanyWideIndividualHighMonth();
        SalesReportingController.getCompanyWideIndividualHighDay();
        SalesReportingController.getStoreHighestReceipt();
        SalesReportingController.getStoreMonthRecordBreak();
        SalesReportingController.getIndividualHighMonth();
    }
     
}