@isTest
public  class ChatterFunctionsTest {
    private static user u = UtilityAndFactory.RunAsSalesRep();

    @TestSetup
    static void makeData(){
        sales_Representative__c sr = UtilityAndFactory.SingleSalesRepresentative('Tester', '1234');
        insert sr;
        insert UtilityAndFactory.SingleCustomerAccount('test name', sr);
    }
    
    @isTest
    static void FeedItemPositivePinTest(){
        system.runAs(u){
            account a =[select id from account limit 1];
            FeedItem fi = new FeedItem();
            fi.parentId = a.Id;
            fi.Body = '*1234 test';
            test.startTest();
            try{
                insert fi;
            } catch (exception e){
                  
            }
            test.stopTest();
            
            list<feedItem> flist = [select id from feeditem where id =: fi.Id];
            system.assertEquals(1, flist.size());
        }
    }

    @isTest
    static void FeedItemMissingPinTest(){
        system.runAs(u){
            account a =[select id from account limit 1];
            FeedItem fi = new FeedItem();
            fi.parentId = a.Id;
            fi.Body = 'test';
            test.startTest();
            	try{
                	insert fi;
            	} catch (exception e){
                  
            	}
            test.stopTest();
            
            list<feedItem> flist = [select id from feeditem where id =: fi.Id];
            system.assertEquals(0, flist.size());
        }
    }
    
	@isTest
    static void FeedItemNegativePinTest(){
        system.runAs(u){
            account a =[select id from account limit 1];
            FeedItem fi = new FeedItem();
            fi.parentId = a.Id;
            fi.Body = '*1111 test';
            test.startTest();
            	try{
                	insert fi;
            	} catch (exception e){
                  
            	}
            test.stopTest();
            
            list<feedItem> flist = [select id from feeditem where id =: fi.Id];
            system.assertEquals(0, flist.size());
        }
    }
    
    @isTest
    static void FeedCommentPositivePinTest(){
        system.runAs(u){
            	account a =[select id from account limit 1];
            	FeedItem fi = new FeedItem();
            	fi.parentId = a.Id;
            	fi.Body = '*1234 test';
            	insert fi;
            	FeedComment fi1 = new FeedComment();
            	fi1.feedItemId = fi.Id;
            	fi1.CommentBody = '*1234 test';
            	test.startTest();
                	try{
                		insert fi1;
            		} catch (exception e){
                  
            		}
            	test.stopTest();
        	}
    }

    @isTest
    static void FeedCommentMissingPinTest(){
        system.runAs(u){
            	account a =[select id from account limit 1];
            	FeedItem fi = new FeedItem();
            	fi.parentId = a.Id;
            	fi.Body = '*1234 test';
            	insert fi;
            	FeedComment fi1 = new FeedComment();
            	fi1.feedItemId = fi.Id;
            	fi1.CommentBody = 'test';
            	test.startTest();
                	try{
                		insert fi1;
            		} catch (exception e){
                  
            		}
            	test.stopTest();
        	}
    }
    
    @isTest
    static void FeedCommentNegativePinTest(){
        system.runAs(u){
            	account a =[select id from account limit 1];
            	FeedItem fi = new FeedItem();
            	fi.parentId = a.Id;
            	fi.Body = '*1234 test';
            	insert fi;
            	FeedComment fi1 = new FeedComment();
            	fi1.feedItemId = fi.Id;
            	fi1.CommentBody = '*1111 test';
            	test.startTest();
                	try{
                		insert fi1;
            		} catch (exception e){
                  
            		}
            	test.stopTest();
        	}
    }
}