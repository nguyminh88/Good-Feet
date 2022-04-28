import { LightningElement, wire} from 'lwc';
import getStoreHighDayBrokenRecord from '@salesforce/apex/SalesReportingController.getStoreHighestSaleDayBreak';
import getIndividualHighDayBrokenRecord from '@salesforce/apex/SalesReportingController.getIndividualHighestSaleDayBreak';
import getStoreHighestReceipt from '@salesforce/apex/SalesReportingController.getStoreHighestReceipt';
import getStoreHighMonth from '@salesforce/apex/SalesReportingController.getStoreMonthRecordBreak';
import getIndividualHighMonth from '@salesforce/apex/SalesReportingController.getIndividualHighMonth';
import getCompanyIndividualHighMonth from '@salesforce/apex/SalesReportingController.getCompanyWideIndividualHighMonth';
import getCompanyIndividualHighDay from '@salesforce/apex/SalesReportingController.getCompanyWideIndividualHighDay';
import getCompanyStoreHighMonth from '@salesforce/apex/SalesReportingController.getCompanyWideStoreHighMonth';
import getCompanyStoreHighDay from '@salesforce/apex/SalesReportingController.getCompanyWideStoreHighDay';


export default class HighestDayRecordBreak extends LightningElement {
    @wire(getStoreHighDayBrokenRecord) BrokenRecord;
    @wire(getIndividualHighDayBrokenRecord) IndividualHighDayRecord;
    @wire(getIndividualHighMonth) IndividualHighMonth;
    @wire(getStoreHighestReceipt) StoreHighestReceipt;
    @wire(getStoreHighMonth) StoreHighMonth;
    @wire(getCompanyIndividualHighMonth) CompanyIndividualHighMonth;
    @wire(getCompanyIndividualHighDay) CompanyIndividualHighDay;
    @wire(getCompanyStoreHighMonth) CompanyStoreHighMonth;
    @wire(getCompanyStoreHighDay) CompanyStoreHighDay;

}


