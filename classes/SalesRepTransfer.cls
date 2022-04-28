/*
Developed by Minh Nguyen
Description: Invocable class called from a button on sales representative record.  
When terminated/exiting sales rep leaves, use this functionality to transfer current customer accounts/tasks to new rep(s)
Jira: SFSLII-263 Sales Rep Transfer
*/

global class SalesRepTransfer {
    private static string apexClass = 'SalesRepTransfer'; //var to pass to query and opt out MDT
    private static list<Franchise_Opt_Out__mdt> OptOutList = new list<Franchise_Opt_Out__mdt>([Select Franchise__c, Class__c from Franchise_Opt_Out__mdt 
                                                                                              where class__c =: apexClass]);
    
    global class SalesRepTransferInputs {
        @InvocableVariable
        global boolean transferAll;
    
        @InvocableVariable
        global Id originalSalesRepId;
    
        @InvocableVariable
        global list<Id> listSalesReps;

        @InvocableVariable
        global Id ownerId;
    }

    @InvocableMethod(label='Sales Rep Account Transfer' description='Transfers accounts to team members')
    public static void transferInitiator(list<SalesRepTransferInputs> flowInputs){
        SalesRepTransferInputs inputs = flowInputs[0];
        list<Sales_Representative__c> srList = new list<sales_representative__c>();
        srList = inputs.transferAll? [Select Id from Sales_Representative__c where ownerid =: inputs.ownerId AND active__c = TRUE AND Id !=: inputs.originalSalesRepId] : [Select Id from Sales_Representative__c where id in : inputs.listSalesReps];
        if(srList.isEmpty())
            return;

        SalesRepTransferQueueable SRTQueueable = new SalesRepTransferQueueable(inputs.ownerId, inputs.originalSalesRepId, srlist);
        system.enqueueJob(SRTQueueable);
    }
    
    public static void transferExecute(Id OwnerId, Id SalesRepId, list<Sales_Representative__c> srlist){
        integer count = 0;
        integer oppCount = 0;
        integer taskCount = 0;
        integer srCount = 0;
        list<account> accountUpdateList = new list<account>();
        list<contact> contactUpdateList = new list<contact>();
        list<opportunity> opportunityUpdateList = new list<opportunity>();
        list<task> taskUpdateList1 = new list<task>();
        list<task> reviewTaskInsertList = new list<task>();
        list<task> taskUpdateList2 = new list<task>();
        list<Opportunity> queryTaskOpps = new list<Opportunity>(); 
        sales_representative__c sr = [select name from sales_representative__c where id =: salesRepId];
        map<integer, Id> srIndexMap = new map<integer, Id>();
        map<id, id> srAccIdMap = new map<id,id>();
        map<id, id> srOwnerIdMap = new map<id,id>();
        map<id, id> oppAccMap = new map<id,Id>();
        for(Sales_Representative__c sr1 : srList){
            srIndexMap.put(srCount, sr1.Id);
            srCount++;
        }
        Set<Id> TaskReviewAccIds = new Set<Id>();
        map<Id, Id> catchAllTaskAccMap = new map<Id, Id>();
        map<Id, Id> catchAllTaskOppMap = new map<Id, Id>();

        //Transfer Accounts/Contacts
        list<Account> AccountList = new list<Account>([Select ownerId, All_Previous_Sales_Reps__c, Original_Sales_Rep__c, Sales_Representative__c,
                                                        (Select Sales_Representative__c from Contacts), 
                                                        (Select accountId From Opportunities) from Account 
                                                        Where Sales_Representative__c =: SalesRepId
                                                        AND ownerId =: OwnerId limit 100]);
        
        for(account a : accountList){
            count++;
            for(opportunity o : a.Opportunities){
                oppAccMap.put(o.Id, o.AccountId);
            }
            if(count <= srList.size()){
                a.Sales_Representative__c = srIndexMap.get(count - 1);
            } else {
                a.Sales_Representative__c = srIndexMap.get(math.mod(count - 1, srList.size()));
            }
            for(contact c : a.contacts){
                c.sales_representative__c = a.sales_representative__c;
                contactUpdateList.add(c);
            }
            if(a.Original_Sales_Rep__c == Null)
                a.Original_Sales_Rep__c = SalesRepId;

            if(a.All_Previous_Sales_Reps__c == Null)
                a.All_Previous_Sales_Reps__c = sr.Name + ', ';
            else
            a.All_Previous_Sales_Reps__c = a.All_Previous_Sales_Reps__c + sr.Name + ', ';

            accountUpdateList.add(a);
            srAccIdMap.put(a.Id, a.sales_representative__c);
            srOwnerIdMap.put(a.Id, a.OwnerId);
        }

        list<task> accountOpenedTasks = new list<task>([Select whatId, OwnerId, status, description From Task where (whatid in : oppAccMap.keySet() OR whatid in : srAccIdMap.keySet())
        AND Status != 'Completed']);

        for(task t : accountOpenedTasks){
            string temp = Id.ValueOf(t.WhatId);
            if(temp.Left(3) == '006'){
                TaskReviewAccIds.add(oppAccMap.get(t.whatId));
            } else if(temp.Left(3) == '001'){
                TaskReviewAccIds.add(t.whatId);
            }
            t.status = 'Completed';
            t.description = t.description == Null? 'Closed Due to Transfer' : t.description + ' \nClosed due to transfer';
            taskUpdateList1.add(t);
        }

        for(Id i : TaskReviewAccIds){
            task t = new task();
            t.whatId = i;
            t.activityDate = date.today().addDays(21);
            t.subject = 'Review Transferred Account';
            t.sales_Representative__c = srAccIdMap.get(i);
            t.status = 'Open';
            t.OwnerId = srOwnerIdMap.get(i);
            reviewTaskInsertList.add(t);
        }

        if(!reviewTaskInsertList.isEmpty()){
            Database.SaveResult [] SRes = Database.insert(reviewTaskInsertList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
        if(!accountUPdateList.isEmpty()){
            Database.SaveResult [] SRes2 = Database.update(accountUPdateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes2);
        }
        if(!contactUpdateList.isEmpty()){
            Database.SaveResult [] SRes3 = Database.update(contactUpdateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes3);
        }
        if(!taskUpdateList1.isEmpty()){
            Database.SaveResult [] SRes4 = Database.update(taskUpdateList1, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes4);
        }

        //Close any opened opps
        list<Opportunity> Opplist = new list<Opportunity>([Select validation_override__c, Purchase_Made__c from Opportunity where Sales_Representative__c =: SalesRepId 
        AND (stageName != 'Purchase Made' AND stageName != 'No Purchase')]);
        for(Opportunity o : Opplist){
            o.validation_override__c = TRUE;
            o.stageName = o.purchase_Made__c ? 'Purchase Made' : 'No Purchase';
            opportunityUpdateList.add(o);
        }
        
        if(!opportunityUpdateList.isEmpty()){
            Database.SaveResult [] SRes5 = Database.update(opportunityUpdateList, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes5);
        }

        //Transfer Tasks
        list<Task> taskList = new list<Task>([Select Sales_Representative__c, whatId from Task Where Sales_Representative__c =: SalesRepId AND status != 'Completed' AND Id NOT in : accountOpenedTasks]);
        //list<task> tasklist = new list<task>();
        for(task t : taskList){
            string temp = t.whatid != Null? Id.ValueOf(t.WhatId) : Null;
            if(temp != Null && temp.Left(3) == '006'){
                catchAllTaskOppMap.put(t.Id, t.whatId);
            } else if(temp != Null && temp.Left(3) == '001'){
                catchAllTaskAccMap.put(t.Id, t.whatId);
            }
        }
        
        map<id, opportunity> srOppMap = new map<id, opportunity>([select sales_representative__c from opportunity where id in : catchAllTaskOppMap.values()]);
        map<id, account> srAccMap = new map<id, account>([select sales_representative__c from account where id in : catchAllTaskAccMap.values()]);
        
        for(task t : taskList){
            string temp = t.whatId != Null? Id.ValueOf(t.WhatId) : Null;
            if(temp != Null && temp.Left(3) == '006'){
                t.sales_representative__c = srOppMap.get(catchAllTaskOppMap.get(t.Id)).sales_representative__c;
            } else if(temp != Null && temp.Left(3) == '001'){
                t.sales_representative__c = srAccMap.get(catchAllTaskAccMap.get(t.Id)).sales_representative__c;
            }
            taskUpdateList2.add(t);
        }

        if(!taskUpdateList2.isEmpty()){
            Database.SaveResult [] SRes6 = Database.update(taskUpdateList2, False);
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes6);
        }
    }
}