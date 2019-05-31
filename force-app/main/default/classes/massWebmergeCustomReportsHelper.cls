public with sharing class massWebmergeCustomReportsHelper {
    private static final string SQUERYSTATICRESOURCENAME = 'soqlQueries';
    
    @AuraEnabled
    public static list<sobject> retrieveRecordsUsingWrapper(soqlQueryWrapper wrappedSoqlQuery){
        
        if(isFilteringRequired(wrappedSoqlQuery))
        {
            return getFilteredObjects(wrappedSoqlQuery);
        }
        else 
        {
            return getRecordsFromSoqlQuery(wrappedSoqlQuery);
        }
            
    }

    public static map<string,soqlQueryWrapper> getQueriesFromStaticResource(StaticResource soqlQueriesStaticResource){
        map<string,soqlQueryWrapper> wrappedSoqlQueries = convertStaticResourceToMapOfsoqlQueryWrappers(soqlQueriesStaticResource);
        return wrappedSoqlQueries;    
    }

    @AuraEnabled
    public static map<string,soqlQueryWrapper> getQueriesFromStaticResource(){
         StaticResource soqlQueriesStaticResource = getStaticResource(SQUERYSTATICRESOURCENAME);
        map<string,soqlQueryWrapper> wrappedSoqlQueries = convertStaticResourceToMapOfsoqlQueryWrappers(soqlQueriesStaticResource);
        return wrappedSoqlQueries;    
    }  

    @AuraEnabled(cacheable=false)
    public static Boolean doWebmerge(list<Id> recordIds, string mappingName){
        webm__webmerge_mapping__c mapping = getMappingFromName(mappingName);

        if(mapping == null)
        {
            return false;
        }

        boolean run = webm.WebmergeGenerator.generateDocumentBatchCombined(
            mapping.id, 
            recordIds, 
            mapping.webm__Salesforce_Object_Name__c
            );
        return run;
    }

  
    //HELPERS
    public static StaticResource getStaticResource(string resourceName)
    {
            return[select id,body from StaticResource Where name =: SQUERYSTATICRESOURCENAME LIMIT 1];
    }
    
    private static map<string,soqlQueryWrapper> convertStaticResourceToMapOfsoqlQueryWrappers(StaticResource soqlQueriesStaticResource)
    {
        return (map<string,soqlQueryWrapper>)JSON.deserialize(soqlQueriesStaticResource.body.toString(), map<string,soqlQueryWrapper>.class);
    }

    private static webm__webmerge_mapping__c getMappingFromName(string mappingName)
    {
        List<webm__webmerge_mapping__c> listOfMappings = [SELECT id, webm__Salesforce_Object_Name__c from webm__webmerge_mapping__c where name=:mappingName];
        if(listOfMappings.size() == 0)
        {
            return null;
        }
        return listOfMappings[0];
    }

    private static boolean isFilteringRequired(soqlQueryWrapper wrappedSoqlQuery)
    {
        if(String.isEmpty(wrappedSoqlQuery.filterFieldPath) || String.isEmpty(wrappedSoqlQuery.filterValue))
        {
            return false;
        }
        return true;
    }

    private static List<sobject> getFilteredObjects(soqlQueryWrapper wrappedSoqlQuery)
    {
        List<sobject> accountQuery = getRecordsFromSoqlQuery(wrappedSoqlQuery);
        List<sobject> filteredList = new List<sobject>();

        for(sobject accountQ : accountQuery)
        {         
            boolean addObjectToList = filterSobject(accountQ, wrappedSoqlQuery.filterFieldPath, wrappedSoqlQuery.filterValue);
            if(addObjectToList)
            {
                filteredList.add((sobject) accountQ);
            }
        }
        
        return filteredList;
    }

    private static List<sobject> getRecordsFromSoqlQuery(soqlQueryWrapper wrappedSoqlQuery)
    {
        return database.query(wrappedSoqlQuery.query);
    }

    /*
        root is the sobject you are trying to filter.
        filterFieldPath is a dot-notated string of the child of root toward the field that you are checking.
        filterValue is the value that must be contained in the field.
        e.g. root_transaction->account->long_text_field filtering 'Deceased'
        root=root_transaction
        filterFieldPath='account__r.long_text_field__c'
        filterValue='Deceased'
    */
    private static boolean filterSobject(sobject root, string filterFieldPath, string filterValue)
    {
        List<string> orderedListOfDescendents = filterFieldPath.split('\\.');
        String fieldAtBaseOFDescendentObjects = orderedListOfDescendents.get(orderedListOfDescendents.size() - 1);

        sobject baseSobject = retriveBaseObject(root, orderedListOfDescendents, fieldAtBaseOFDescendentObjects);

        return objectContainsValueInField(baseSobject, fieldAtBaseOFDescendentObjects, filterValue);
    }

    private static sobject retriveBaseObject(Sobject root, list<string> orderedListOfDescendents, string fieldAtBaseOFDescendentObjects)
    {
        sobject currentOjbect = root;

        for(string currentChild : orderedListOfDescendents )
        {

            if(currentChild == fieldAtBaseOFDescendentObjects)
            {
                break;
            }
            currentOjbect = stepDownToChild(currentChild, currentOjbect);
        }

        return currentOjbect;
    }

    private static sobject stepDownToChild(string childName, sobject parent)
    {
        return parent.getSobject(childName);
    }

    private static boolean objectContainsValueInField(sobject baseObject, string field, string testValue)
    {
        string fieldValue = (string) baseObject.get(field);
        if(fieldValue != null)
        {
            return fieldValue.containsIgnoreCase(testValue);
        }
        else 
        {
            return false;
        }
    }
}


