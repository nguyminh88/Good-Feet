public class UtilityAndFactory {
    public static string StoreRTId = '0121N000001fsXV';
    public static string CustomerRTId = '0121N000001fsXU';
    public static string OppSaleRTId = '0121N000001fsks';
    private static Id SalesAssociateProfileId = [Select Id from Profile where Name = 'Sales Associate'].Id;

    public static boolean isSandbox(){
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

    public static void Wait(integer seconds){
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        
        if(!test.isRunningTest()){
            while ((finishTime - startTime) < seconds) {
            finishTime = DateTime.now().getTime();
            }
        }
    }
    
    public static String BatchQuery(String ApexClass){
        list<Batch_Job_Breaker__mdt> BJB = new list<Batch_Job_Breaker__mdt>([Select Query2__c from Batch_Job_Breaker__mdt where masterLabel =: apexClass limit 1]);
        String Query = BJB.size() > 0 ? BJB[0].Query2__c : Null;
        return Query;
    }

    public static user RunAsSalesRep(){
        return [select id from user where profileId =: SalesAssociateProfileId and isActive = TRUE limit 1];
    }
  
    public static String GetFirstName(String Full){
        string fullName = Full;
        string tempName;
        string lastName;
        string firstName;
        string commaFirstname;
        tempName = fullName.contains('MR.') ? fullName.remove('MR.') : tempName;
        tempName = fullName.contains('Mr.') ? fullName.remove('Mr.') : tempName;
        tempName = fullName.contains('MRS.') ? fullName.remove('MRS.') : tempName;
        tempName = fullName.contains('Mrs.') ? fullName.remove('Mrs.') : tempName;
        fullName = tempName != Null && tempName.contains(',') ? tempName.remove(',').trim() : fullName;
        
        if(fullName.contains(',')){
            firstName = fullName.substring(fullName.lastIndexOf(' ') +1);
            lastName = fullName.remove(firstName).trim();
            commaFirstname = firstName.remove(',');
            return commaFirstname;
        } else {
            lastName = fullName.substring(fullName.lastIndexOf(' ') +1);
            firstName = fullName.remove(lastName).trim();
            return firstName;
        }
    }
    
    public static String GetLastName(String Full){
        string fullName = Full;
        string firstName;
        string lastName;
        string tempName;
        tempName = fullName.contains('MR.') ? fullName.remove('MR.') : tempName;
        tempName = fullName.contains('Mr.') ? fullName.remove('Mr.') : tempName;
        tempName = fullName.contains('MRS.') ? fullName.remove('MRS.') : tempName;
        tempName = fullName.contains('Mrs.') ? fullName.remove('Mrs.') : tempName;
        fullName = tempName != Null && tempName.contains(',') ? tempName.remove(',').trim() : fullName;

        if(fullName.contains(',')){
            firstName = fullName.substring(fullName.lastIndexOf(' ') +1);
            tempName = fullName.remove(firstName).trim();
            lastName = tempName.remove(',');
        } else {
            lastName = fullName.substring(fullName.lastIndexOf(' ') +1);
        }

        return lastName;
    }
    
    public static void LastBatchMigrationCheck(){
        string stopMigration = 'stopMigration ' + date.today();
        list<error_log__c> el = new list<error_log__c>([select id from error_log__c where context_record__c =: stopMigration]);
        if ((el.isEmpty() && ![SELECT IsSandbox FROM Organization LIMIT 1].isSandbox && date.today().day() == 15) || test.isRunningTest()){
            UtilityAndFactory.startRICSMigration(date.today(), date.today().addMonths(-1).toStartOfMonth());   
        }
        else if((date.today() == date.today().toStartOfWeek() && ![SELECT IsSandbox FROM Organization LIMIT 1].isSandbox && el.isEmpty()) 
           || test.isRunningTest()){
            UtilityAndFactory.startRICSMigration(date.today(), date.today().addDays(-7));
        }
    }
    
    
    public static void startRICSMigration(date Upper, Date Lower){
            list<error_log__c> errlist = new list<error_log__c>();
            error_log__c el = new error_log__c();
            el.context_record__c = 'Migration';
            el.endDate__c = Upper;
            error_log__c stop = new error_log__c();
            stop.context_record__c = 'stop';
            stop.endDate__c = Lower;
            errlist.add(el);
            errlist.add(stop);
            insert errlist;
            GetRICSPOSTransactionSchedulable abc = new GetRICSPOSTransactionSchedulable(); 
            if(!test.isRunningTest())
                abc.execute(null);
    }
    
    public static void stopRICSMigration(){
        error_log__c stopmigration = new error_log__c();
        stopmigration.context_record__c = 'stopMigration ' + date.today();
        insert stopmigration;
        list<error_log__c> errlist = new list<error_log__c>([select endDate__c from error_log__c where context_record__c = 'Migration' OR context_record__c = 'stop' order by context_record__c asc]);
        if(!errlist.isEmpty()){
            UtilityAndFactory.ErrorLog('Successful Migration ' + date.today().format(), null);
            delete errlist;
        }
    }
    
    public static map<string,object> AcumaticaMainCall(string RequestBody){
        map<string, object> nullMap = new map<string,object>();
        map<string, object> responseObj = new map<string,object>();
        Acumatica__mdt acumaticaAPI = [select Cache_Control__c, Content_Type__c, Cookie__c, Endpoint__c, Name__c, Password__c  from
            Acumatica__mdt where masterlabel = 'Midwest'];
        
        string cookies = AcumaticaLogin(acumaticaAPI);
        try{
          responseObj = (map<string,object>) AcumaticaCustomerCallout(acumaticaAPI, cookies, RequestBody);
          AcumaticaLogout(acumaticaAPI, cookies);
          //return responseObj;
        } catch (Exception e){
            
        }
        return responseObj;
    }
    
    public static string AcumaticaLogin(Acumatica__mdt api){
        string nullString;
        HttpRequest req = new HttpRequest();
    req.setEndpoint(api.Endpoint__c + 'auth/login');
    req.setMethod('POST');
    req.setHeader('cache-control', api.Cache_Control__c);
    req.setHeader('Content-Type', api.Content_Type__c);
    map<string,object> thejson = new map<string,object>();
    thejson.put('Name', api.Name__c);
    thejson.put('Password', api.Password__c);
    string bod = json.serialize(thejson);
    req.setBody(bod);
    
        try{
          HttpResponse res = new Http().send(req);
            if(res.getStatusCode() == 204){
        string cookies = res.getHeader('Set-Cookie');
              return cookies;
            } else {
                return nullString;
            }
        } catch (Exception e){
            return nullString;
        }
    }
    
    public static map<string,object> AcumaticaCustomerCallout(Acumatica__mdt api, string cookies, string RequestBody){
        map < string, object > ReturnObj = new map < string, object > ();
        map<string,object> thejson = new map<string,object>();
        HttpRequest req = new HttpRequest();
    req.setEndpoint(api.Endpoint__c + 'Default/18.200.001/Customer');
    req.setMethod('PUT');
    req.setHeader('cache-control', api.Cache_Control__c);
    req.setHeader('Content-Type', api.Content_Type__c);
        req.setHeader('Cookie', cookies);
        thejson.put('Name', api.Name__c);
    thejson.put('Password', api.Password__c);
        req.setBody(RequestBody);
        
        try{
          HttpResponse res = new Http().send(req);
            ReturnObj = (map<string,object>) JSON.deserializeUntyped(res.getBody());
         } catch (Exception e){
        
         }
        
        return ReturnObj;
    }
    
    public static void AcumaticaLogout(Acumatica__mdt api, string cookies){
        map<string,object> thejson = new map<string,object>();
        string nullString;
        HttpRequest req = new HttpRequest();
    req.setEndpoint(api.Endpoint__c + 'auth/logout');
    req.setMethod('POST');
    req.setHeader('cache-control', api.Cache_Control__c);
    req.setHeader('Content-Type', api.Content_Type__c);
        req.setHeader('Cookie', cookies);
    thejson.put('Name', api.Name__c);
    thejson.put('Password', api.Password__c);
    string bod = json.serialize(thejson);
    req.setBody(bod);
    
        try{
          HttpResponse res = new Http().send(req);
         } catch (Exception e){
        
         }
    }
    
    public static Map < String, Object > MakeRICSCallout(String apiEndPoint, String RequestBody, object o) {
        map < string, object > nullMap = new map < string, object > ();
        RICS_Token__mdt tokenMDT = [select production_token__c, sandbox_token__c, use_production__c, Production_Endpoint__c, Sandbox_Endpoint__c from
            RICS_Token__mdt where masterlabel = 'Token'
        ];
        String Token = tokenMDT.use_production__c ? tokenMDT.production_token__c : tokenMDT.sandbox_token__c;
        String prefix = tokenMDT.use_production__c ? tokenMDT.Production_Endpoint__c : tokenMDT.Sandbox_Endpoint__c;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(prefix + apiEndPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Token', Token);
        req.setBody(RequestBody);

        try {
            HttpResponse res = new Http().send(req);
            if(res.getStatusCode() == 429 || test.isRunningTest()){
                try{
                    Wait(3000);
                    HttpResponse res2 = new Http().send(req);
                    return res2.getStatusCode() == 200 ? (Map < String, Object > ) JSON.deserializeUntyped(res2.getBody()) : nullMap;
                } catch (exception e){
                    return nullMap;
                }
            }
            return res.getStatusCode() == 200 ? (Map < String, Object > ) JSON.deserializeUntyped(res.getBody()) : nullMap;
        } catch (exception e) {
            return nullMap;
        }
    }
    
    public static void ErrorLog(String Context, String Description){
        error_log__c er = new error_log__c();
        er.Context_Record__c = Context;
        er.Long_Description__c = Description;
        insert er;
    }

    public static List<String> OptOutList(list<Franchise_Opt_Out__mdt> OptOutList){
        list<String> optouts = new list<String>();
        for(Franchise_Opt_Out__mdt o : OptOutList){
            optouts.add(o.Franchise__c); //Create string list of all franchise to exclude in queryLocator
        }
        return optOuts; 
    }

    public static void SaveResultErrorLog(String location, list<Database.SaveResult> saveResults){
        list<Error_Log__c> insertList = new list<Error_Log__c>();
        for(Database.SaveResult sr : saveResults){
            if(!sr.isSuccess()){
                for(Database.Error err : sr.getErrors()){
                    error_log__c erlog = new error_log__c();
                    erlog.Context_Record__c = 'Error Location: ' + location;
                    erlog.Error_Status_Code__c = 'Code: ' + err.getStatusCode();
                    erlog.Error_Message__c = err.getMessage();
                    erlog.Error_Fields__c = 'Fields: ' + err.getFields();
                    insertList.add(erlog);
                }
            }
        }
        if(!insertList.isEmpty()){
            Database.SaveResult [] SRes = Database.insert(insertList, False);
        }
    }
    
    public static account SingleStoreAccount(string Name, String StoreNumber){
        account a = new account();
        a.RecordTypeId = StoreRTId;
        a.name = name;
        a.Clienteling_Id__c = StoreNumber;
        
        return a;
    }
    
    public static account SingleCustomerAccount(string Name, sales_representative__c sr){
        account a = new account();
        a.RecordTypeId = CustomerRTId;
        a.Name = Name;
        a.region__c = 'SE';
        a.Clienteling_Id__c = 'someId';
        a.sales_representative__c = sr.Id;        
        return a;
    }
    
    public static sales_representative__c SingleSalesRepresentative(String Name, String Pin){
        sales_representative__c sr = new sales_representative__c();
        sr.name = 'Test Rep';
        sr.PIN__c = Pin;
        sr.Active__c = true;
        
        return sr;
    }
    
    public static contact SingleContact(account a, string firstName, string lastName, string Phone, string Email){
        contact c = new contact();
        c.accountId = a.Id;
        c.FirstName = firstName;
        c.LastName = lastName;
        c.Phone = Phone;
        c.Email = Email;
        c.BirthDate = date.today();
        
        return c;
    }
    
    public static opportunity SingleOpportunity(account a, string Name){
        Opportunity o = new Opportunity();
        o.recordTypeId = OppSaleRTId;
        o.accountId = a.Id;
        o.Name = Name;
        o.StageName = 'New';
        o.CloseDate = date.today();
        
        return o;
    }
    
    public static string PhoneSimplify(String p) {
        string a;
        if (P != Null) {
            a = p.deleteWhitespace();
            a = a.remove('`');
            a = a.remove('(');
            a = a.remove(')');
            a = a.remove('-');
            a = a.remove('.');
        }
        return a;
    }
}