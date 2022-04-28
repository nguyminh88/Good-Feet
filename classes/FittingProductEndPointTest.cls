@isTest
public class FittingProductEndPointTest {
    @istest static void CreateFittingProductsTest(){
        sales_Representative__c sr = UtilityAndFactory.SingleSalesRepresentative('john wayne', '1234');
        insert sr;
        account a = UtilityAndFactory.SingleCustomerAccount('Test', sr);
        insert a;
        opportunity o = UtilityAndFactory.SingleOpportunity(a, 'testopp');
        insert o;
     	fitting_product__c fp= new fitting_product__c();
        fp.opportunity__c = o.id;
        insert fp;
        
        RestRequest req = new RestRequest();
    	RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
    	req.requestURI = '/services/apexrest/FittingProduct/';
    	
		
        map<string,object> products = new map<string,object>();
        products.put('Product', 'someProd');
        products.put('Style', 'SomeStyle');
        products.put('Size', 'SomeSize');
        list<object> prods = new list<object>();
        prods.add(products);
        
        map<string,object> payload = new map<string,object>();
        payload.put('Opportunity__c',o.Id);
        payload.put('FittingProducts',prods);
        string jsonbody = json.serialize(payload);
        req.requestbody = blob.valueof(jsonbody);
        RestContext.request = req;
        
        test.startTest();
        	FittingProductEndPoint.CreateFittingProducts();
        test.stopTest();
        
        system.assertEquals(1,[select id from fitting_product__c].size());
    }
}