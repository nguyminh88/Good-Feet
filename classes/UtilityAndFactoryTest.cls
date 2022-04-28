@isTest
public class UtilityAndFactoryTest {
	@istest static void UtilityStopRICSMigration(){
        list<error_log__c> errs = new list<error_log__c>();
        error_log__c e1 = new error_log__c();
        e1.context_record__c = 'migration';
        error_log__c e2 = new error_log__c();
        e2.context_record__c = 'stop';
        errs.add(e1);
        errs.add(e2);
        insert errs;
        
        test.startTest();
        	UtilityAndFactory.stopRICSMigration();
        test.stopTest();
        
        list<error_log__c> errz = new list<error_log__c>([select id from error_log__c where context_record__c = 'migration' OR context_record__c = 'stop']);
        string stopMig = 'stopMigration ' + date.today();
        list<error_log__c> stopz = new list<error_log__c>([select id from error_log__c where context_record__c =: stopMig]);
        system.assertEquals(0, errz.size());
        system.assertEquals(1, stopz.size());
    }
    
    @isTest() static void UtilityErrorLogTest(){
        UtilityAndFactory.ErrorLog('Context', 'Description');
    }
}