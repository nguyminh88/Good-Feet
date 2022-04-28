trigger TempMWStaging on MW_Staging__c (before insert) {
    /*
    list<string> customerIdList = new list<string>();
    MW_Staging__c [] phlist = [select Sales_CustomerId__c from MW_Staging__c where type__c = 'Purchase History'];
    for(MW_Staging__c m : phlist){
        customerIdList.add(m.Sales_CustomerId__c);
    }
    
    if(trigger.isBefore && trigger.isInsert){
        for(MW_Staging__c mw : trigger.New){
            if(mw.type__c == 'Account' && mw.CustomerId__c != Null && !customerIdList.contains(mw.CustomerId__c)){
                mw.addError('No sales history found');
            }
        }
    }*/
}