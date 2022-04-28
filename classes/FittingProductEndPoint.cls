/*
Developed by: Minh Nguyen      4/2021
Description: Rest endpoint (POST) for GF-app to create fitting product
*/


@RestResource(urlMapping='/FittingProduct/*')
global class FittingProductEndPoint {
    private static string apexClass = 'FittingProductEndPoint'; //var to pass to query and opt out MDT

	@HttpPost
    global static void CreateFittingProducts(){
        RestResponse resp = RestContext.response;
        String requestBody = RestContext.request.requestBody.toString(); //Stringify the json payload
		list<Fitting_Product__c> insertList = new list<Fitting_Product__c>();
        map<string,object> response = new map<string,object>();
        map<string,object> Payload = (map<string,object>)json.deserializeUntyped(requestBody); //deserialize payload to object
        String OppId = (String)Payload.get('Opportunity__c');
        list<fitting_product__c> deleteList = new list<fitting_product__c>([select id from fitting_product__c where opportunity__c =: OppId]);
        if(!deleteList.isEmpty())
            delete deleteList; //Delete and rebuild so theres no duplicates if GF-APP goes back/previous
        
        list<object> FittingProducts = new list<object>();
        FittingProducts = (list<object>)Payload.get('FittingProducts');
        
        //Loop through deserialized object list and create fitting product, add to insert list
        for(object fp : FittingProducts){
            map<string,object> Products = new map<string,object>();
            Products = (map<string,object>)fp;
            
            fitting_product__c newFP = new fitting_product__c();
            newFP.Product__c = (String)Products.get('Product');
            newFP.Style__c = (String)Products.get('Style');
            newFP.Size__c = (String)Products.get('Size');
            newFP.Opportunity__c = OppId;
            insertList.add(newFP);
        }
        
        if(!insertList.isEmpty()){
            Database.SaveResult [] SRes = Database.insert(insertlist, False);
            response.put('InsertSize',insertList.size());
                if(!test.isRunningTest())
                    resp.responseBody = Blob.valueOf(json.serialize(response));
            UtilityAndFactory.SaveResultErrorLog(apexClass, SRes);
        }
    }
}