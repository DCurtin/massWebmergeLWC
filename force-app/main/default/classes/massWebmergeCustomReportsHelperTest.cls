@isTest
public class massWebmergeCustomReportsHelperTest {
    @TestSetup
    static void setup()
    {
        List<string> assetType = new List<string>();
        List<string> caseSubjects = new List<string>();
        TestUtils.getPortalUser(5,1,assetType,caseSubjects);
        generateAndInsertMappings(1,'Related_Party__c');
    }

    static testmethod void getQueriesFromStaticResource_generalTestWithCorrectInputUsingOverloadedTestFunction_returnsMappingOfSoqlQueryWrappers()
    {
        StaticResource soqlQueriesStaticResource = getTestStaticResource();

        map<string, soqlQueryWrapper> soqlQueryWrapperConverted = massWebmergeCustomReportsHelper.getQueriesFromStaticResource(soqlQueriesStaticResource);
        Set<string> soqlQueryWrapperNameSet = soqlQueryWrapperConverted.keySet();
        
        System.assertNotEquals(null, soqlQueryWrapperConverted);
        System.assertEquals(true, soqlQueryWrapperNameSet.contains('Deceased'));
        System.assertEquals(true, soqlQueryWrapperNameSet.contains('All Parties'));
    }


    static testmethod void retrieveRecordsUsingWrapper_soqlWrapperWithFilterDefined_ListOfFilteredRecords()
    {
        List<Account> testAccounts = [SELECT id, Misc_Notes__c FROM Account WHERE status__c !='' LIMIT 2];
        
        system.debug(testAccounts + ' TEST6565');


        for(Account testAccount : testAccounts)
        {
            testAccount.Misc_Notes__c = 'BLAH BLAH BLAH Deceased';
        }
        update testAccounts;


        StaticResource soqlQueriesStaticResource = getTestStaticResource();
        map<string, soqlQueryWrapper> soqlQueryWrapperConverted = massWebmergeCustomReportsHelper.getQueriesFromStaticResource(soqlQueriesStaticResource);
        list<Related_Party__c> filteredParties = (list<Related_Party__c>) massWebmergeCustomReportsHelper.retrieveRecordsUsingWrapper(soqlQueryWrapperConverted.get('Deceased'));
        system.debug(filteredParties + ' TEST6565');
        System.assertEquals(2, filteredParties.size());
        
    }

    static testmethod void retrieveRecordsUsingWrapper_soqlWrapperWithoutDefinedFilter_ListOfAllRelatedPartyRecords()
    {
        StaticResource soqlQueriesStaticResource = getTestStaticResource();
        map<string, soqlQueryWrapper> soqlQueryWrapperConverted = massWebmergeCustomReportsHelper.getQueriesFromStaticResource(soqlQueriesStaticResource);
        list<Related_Party__c> filteredParties = (list<Related_Party__c>) massWebmergeCustomReportsHelper.retrieveRecordsUsingWrapper(soqlQueryWrapperConverted.get('All Parties'));
        System.assertEquals(5, filteredParties.size());
    }

    static testmethod void doWebmerge_generalCallWithGeneratedMapping_noExceptionThrownAndReturnsTrue()
    {
        webm__Webmerge_Mapping__c testMapping = [Select id, name from webm__Webmerge_Mapping__c LIMIT 1];
        Related_Party__c relatedPartyTest = [Select id from Related_Party__c LIMIT 1]; //cannot use more than 1 due to how webm's batchable is defined
        List<Id> recordIds = new List<id>();
        recordIds.add(relatedPartyTest.id);
        
    
        try
        {
            boolean runSuccessful = massWebmergeCustomReportsHelper.doWebmerge(recordIds, testMapping.name);
            System.assertEquals(True, runSuccessful);
        }catch(Exception err)
        {
            System.assert(false, 'Error message: ' + err.getMessage() + ' Exception thrown at assertion.');
        }
        //System.assertEquals(5, filteredParties.size());
    }

    static testmethod void doWebmerge_fakeMappingName_noExceptionThrownAndReturnsFalse()
    {
        string fakeMappingName = 'fakeTestMapping';
        Related_Party__c relatedPartyTest = [Select id from Related_Party__c LIMIT 1]; //cannot use more than 1 due to how webm's batchable is defined
        List<Id> recordIds = new List<id>();
        recordIds.add(relatedPartyTest.id);
        
    
        try
        {
            boolean runSuccessful = massWebmergeCustomReportsHelper.doWebmerge(recordIds, fakeMappingName);
            System.assertEquals(False, runSuccessful);
        }catch(Exception err)
        {
            System.assert(false, 'Error message: ' + err.getMessage() + ' Exception thrown at assertion.');
        }
        //System.assertEquals(5, filteredParties.size());
    }

    static testmethod void getStaticResource_existingNameInDatabase_staticresourceWithSameName()
    {
        StaticResource existingResource = [SELECT id, Name From StaticResource LIMIT 1];
        StaticResource testStaticResource = massWebmergeCustomReportsHelper.getStaticResource(existingResource.name);
        system.assertEquals(existingResource.id, testStaticResource.id);
    }
    

    //Helper

    static StaticResource getTestStaticResource()
    {
        String queryWrapperExample = '{\n'+
        '   \"Deceased\":{\n'+
        '       \"query\"         		    :\"SELECT id, name, Account__r.Id, Account__r.Misc_Notes__c FROM Related_Party__c\",\n'+
        '       \"description\"   		    :\"Returns list of accounts whom are deceased.\",\n'+
        '       \"filterFieldPath\" 		:\"Account__r.Misc_Notes__c\",\n'+
        '       \"filterValue\"     		:\"Deceased\",\n'+
        '       \"webmergeMappingName\"	    :\"test mapping combine\"\n'+
        '   },\n'+
        '   \"All Parties\":{\n'+
        '       \"query\"         		    :\"SELECT Id, Name, Account__r.Id FROM Related_Party__c\",\n'+
        '       \"description\"   		    :"Returns list of accounts which are closed.\",\n'+
        '       \"filterFieldPath\" 		:\"\",\n'+
        '       \"filterValue\"     		:\"\",\n'+
        '       \"webmergeMappingName\"	    :\"test mapping combine\"\n'+
        '   }\n'+
        '}';



        //MetadataService.MetadataPort service = createService();
        StaticResource sr = new StaticResource();
        sr.name = 'soqlQueries';
        sr.contentType = 'json';
        sr.cacheControl = 'private';
        sr.body = Blob.valueOf(queryWrapperExample);

        return sr;
    }

    public static void generateAndInsertMappings(integer mappingCount, string typeName)
    {
        List<webm__Webmerge_Mapping__c> mappingsToInsert = new List<webm__Webmerge_Mapping__c>();
        for(Integer step=0; step < mappingCount; ++step)
        {
            webm__Webmerge_Mapping__c testMapping = new webm__Webmerge_Mapping__c();
            testMapping.Name = 'testMapping'+ step;
            testMapping.webm__Salesforce_Object_Name__c = typeName;
            mappingsToInsert.add(testMapping);
        }
        insert mappingsToInsert;
    }
}


