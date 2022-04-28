/* Created by Mario 2018-05-08 */

@isTest
public with sharing class ContactDuplicateManagerTest {
	public ContactDuplicateManagerTest() {
		
	}

	@isTest
	static void sendContactWithNoDuplicate_getAJSONResponseWithEmptyField() {
		Contact c = createNewContact();
		RestRequest request = createNewContactRequest(c);
		RestContext.request = request;
		Test.startTest();
		String dupStringResponse = ContactDuplicateManager.checkContactDuplicate();
		System.debug('*****dupStringResponse:' + dupStringResponse);
		Test.stopTest();
		ContactDuplicateManager.ResponseWrapper expectedResult = new ContactDuplicateManager.ResponseWrapper();
		System.assertEquals(JSON.serialize(expectedResult), dupStringResponse);
		System.debug('*****expectedResult:' + expectedResult);
	}


	@isTest
	static void sendADuplicateContact_getAnExistingContactWithId() {
		Contact c = createNewContact();
		RestRequest request = createNewContactRequest(c);
		RestContext.request = request;
		Test.startTest();
		insert c;
		String dupStringResponse = ContactDuplicateManager.checkContactDuplicate();
		Test.stopTest();
		ContactDuplicateManager.ResponseWrapper expectedResult = new ContactDuplicateManager.ResponseWrapper();
		expectedResult.exactMatch = new Map<String,String>();
		expectedResult.exactMatch.put('id', c.Id);
		System.assertEquals(JSON.serialize(expectedResult), dupStringResponse);
		System.debug('*****expectedResult:' + expectedResult);
	}

	@isTest
	static void sendADuplicateLead_getNewContactCreatedId() {
		Lead l = createNewLead();
		insert l;
		Contact c = createNewContact();
		RestRequest request = createNewContactRequest(c);
		RestContext.request = request;
		Test.startTest();
		String dupStringResponse = ContactDuplicateManager.checkContactDuplicate();
		Test.stopTest();
		ContactDuplicateManager.ResponseWrapper expectedResult = new ContactDuplicateManager.ResponseWrapper();
		expectedResult.exactMatch = new Map<String, String>();
		Contact cInDb = [SELECT Id FROM Contact where FirstName = 'Jack' LIMIT 1];
		expectedResult.exactMatch.put('id', cInDb.Id);
		System.assertEquals(JSON.serialize(expectedResult), dupStringResponse);
		System.debug('*****expectedResult:' + expectedResult);
	}
	
	@isTest
	static void sendAPartialMatchContact_getPartialMatchesList() {
		Contact c = createNewContact();
		insert c;
		Contact c2 = createNewContact();
		c2.FirstName = 'NotJack';
		RestRequest request = createNewContactRequest(c2);
		RestContext.request = request;
		Test.startTest();
		String dupStringResponse = ContactDuplicateManager.checkContactDuplicate();
		Test.stopTest();
		ContactDuplicateManager.ResponseWrapper expectedResult = new ContactDuplicateManager.ResponseWrapper();
		Map<String,String> partialMatchItem = new Map<String, String>();
		partialMatchItem.put('id', c.Id);
		partialMatchItem.put('lastname', c.lastName);
		partialMatchItem.put('email', c.Email);
		partialMatchItem.put('phone', c.Phone);
		expectedResult.partialMatches.add(partialMatchItem);
		System.assertEquals(JSON.serialize(expectedResult), dupStringResponse);
		System.debug('*****expectedResult' + expectedResult);
	}


	static void init() {

	}

	private static RestRequest createNewContactRequest(Contact c) {
		RestRequest request = new RestRequest();
		request.requestUri = '/services/apexrest/ContactDupeCheck';
		request.httpMethod = 'GET';
		request.addParameter('firstname', c.FirstName);
		request.addParameter('lastname', c.LastName);
		request.addParameter('email', c.Email);
		request.addParameter('phone', c.Phone);
		return request;
	}

	private static Contact createNewContact() {
		Contact c = new Contact();
		setFieldToKnownValues(c);
		return c;
	}

	private static Lead createNewLead() {
		Lead l = new Lead();
		setFieldToKnownValues(l);
		l.Company = 'RadialSpark';
		return l;
	}

	private static void setFieldToKnownValues(sObject s) {
		s.put('FirstName', 'Jack');
		s.put('LastName', 'Quick');
		s.put('Email', 'jackquick@radialspark.com');
		s.put('Phone', '602-555-1234');
	}
}