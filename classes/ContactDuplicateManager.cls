/* Created by Mario 2018-05-08 */

@RestResource(urlMapping='/ContactDupeCheck/*')
global with sharing class ContactDuplicateManager {

	@HttpGet
	global static String checkContactDuplicate() {
		RestRequest req = RestContext.request;
		String firstname = req.params.get('firstname');
		String lastname = req.params.get('lastname');
		String phone = req.params.get('phone');
		String email = req.params.get('email');
		String result = null;
		
		Contact c = new Contact(FirstName=firstname, LastName = lastname, Phone=phone, Email=email);
		List<Contact> cList = new List<Contact>();
		cList.add(c);

		ResponseWrapper respWrapper = new ResponseWrapper();

		List<Datacloud.FindDuplicatesResult> findDupResults = Datacloud.FindDuplicates.findDuplicates(cList);
		System.debug('*****findDupResults:' + findDupResults);
		for (Datacloud.FindDuplicatesResult findDupResult : findDupResults) {
			System.debug('*****findDupResult:' + findDupResult);
			for(Datacloud.DuplicateResult dupResult : findDupResult.getDuplicateResults()) {
				System.debug('*****dupResult:' + dupResult);
				for(Datacloud.MatchResult matchResult : dupResult.getMatchResults()) {
					if (matchResult.getEntityType()=='Lead') {
						System.debug('*****entityTypeLead');
						// if found Lead, we're converting lead to contact.
						for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
							Sobject sobj = matchRecord.getRecord();
							Lead lead = (Lead) sobj;
							Database.LeadConvert lc = new Database.LeadConvert();
							lc.setLeadId(lead.Id);
							LeadStatus convertStatus = 
								[SELECT Id, MasterLabel 
								FROM LeadStatus
								WHERE IsConverted=true
								LIMIT 1];
							lc.setConvertedStatus(convertStatus.MasterLabel);
							lc.setDoNotCreateOpportunity(true);
							Database.LeadConvertResult lcr = Database.convertLead(lc);
							if (respWrapper.exactMatch==null) respWrapper.exactMatch = new Map<String,String>();
							Lead leadInDb = [SELECT ConvertedContactId FROM Lead WHERE Id = :lead.Id];
							respWrapper.exactMatch.put('id', leadInDb.ConvertedContactId);
						}
					}
					else if (matchResult.getEntityType()=='Contact') {
						System.debug('*****entityTypeContact');
						System.debug('*****matchResult:' + matchResult);
						for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
							System.debug('*****supposedToBeMatchRecord:' + matchRecord);
							sObject sobj = matchRecord.getRecord();
							String sobjId = (String)sobj.get('id');
							if (isExactMatch(matchRecord)) {
								if (respWrapper.exactMatch==null) respWrapper.exactMatch = new Map<String, String>(); 
								respWrapper.exactMatch.put('id', sobjId);
							}
							else {
								Map<String, String> partialMatchItems = new Map<String, String>();
								respWrapper.partialMatches.add(partialMatchItems);
								List<String> fieldsToGet = new List<String>();
								for (Datacloud.FieldDiff fd : matchRecord.getFieldDiffs()) {
									if (fd.getDifference() == 'SAME') {
										fieldsToGet.add(fd.getName());
									}
								}
								String queryString = 'SELECT ';
								for (Integer i=0; i<fieldsToGet.size(); i++) {
									if ((i+1)<fieldsToGet.size()) {
										queryString += (fieldsToGet.get(i) + ', ');
									}
									else {
										queryString += fieldsToGet.get(i);
									}
								}
								queryString += ' FROM Contact WHERE Id = \'' + sobjId + '\'';
								Contact cInDb = Database.query(queryString);
								partialMatchItems.put('id', cInDb.Id);
								for (String fieldName : fieldsToGet) {
									partialMatchItems.put(fieldName.toLowerCase(), (String)cInDb.get(fieldName));
								}
							}
						}
					}
				}
			}
		}

		result = JSON.serialize(respWrapper);
		System.debug('*****respWrapper serialize result:' + result);
		return result;
	}

	// Returns true if all FieldDiffs are the Same, otherwise returns false 
	private static Boolean isExactMatch (Datacloud.MatchRecord mRec) {
		Integer countFoundSame = 0;
		for (Datacloud.FieldDiff fd : mRec.getFieldDiffs()) {
			if (fd.getDifference() == 'SAME') {
				countFoundSame++;
			}
		}
		return (mRec.getFieldDiffs().size() == countFoundSame);
	}

	@TestVisible
	private without sharing class ResponseWrapper {
		// Only map with String keys are supported in Apex
		public Map<String, String> exactMatch; 
		public List<Map<String,String>> partialMatches;

		public ResponseWrapper() {
			partialMatches = new List<Map<String,String>>();
		}

	}
}