public with sharing class massWebmergeCustomReportsHelper {
    @AuraEnabled
    public static list<sobject> retrieveRecordsUsingWrapper(soqlQueryWrapper wrappedSoqlQuery){
        
        if(isFilteringRequired(wrappedSoqlQuery))
        {
            return getFilteredObjects(wrappedSoqlQuery);
        }else 
        {
            return getRecordsFromSoqlQuery(wrappedSoqlQuery);
        }
            
    }

    @AuraEnabled
    public static map<string,soqlQueryWrapper> getQueriesFromStaticResource(){
        StaticResource soqlQueriesStaticResource = [select id,body from StaticResource Where name = 'soqlQueries' LIMIT 1];
        map<string,soqlQueryWrapper> wrappedSoqlQueries = (map<string,soqlQueryWrapper>)JSON.deserialize(soqlQueriesStaticResource.body.toString(), map<string,soqlQueryWrapper>.class);
        return wrappedSoqlQueries;    
    }

    @AuraEnabled(cacheable=false)
    public static void doWebmerge(list<Id> recordIds, string mappingName){
        webm__webmerge_mapping__c mapping = [SELECT id, webm__Salesforce_Object_Name__c from webm__webmerge_mapping__c where name=:mappingName LIMIT 1];
        
        if(mapping == null)
            return;

        boolean run = webm.WebmergeGenerator.generateDocumentBatchCombined(
            mapping.id, 
            recordIds, 
            mapping.webm__Salesforce_Object_Name__c
            );

        System.debug(run);
    }

    //HELPERS
    private static boolean isFilteringRequired(soqlQueryWrapper wrappedSoqlQuery)
    {
        if(String.isEmpty(wrappedSoqlQuery.filterFieldPath) || String.isEmpty(wrappedSoqlQuery.filterValue))
            return false;
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
                filteredList.add((sobject) accountQ);
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

        return objectContainsFieldValue(baseSobject, fieldAtBaseOFDescendentObjects, filterValue);
    }

    private static sobject retriveBaseObject(Sobject root, list<string> orderedListOfDescendents, string fieldAtBaseOFDescendentObjects)
    {
        sobject currentOjbect = root;

        for(string currentPosition : orderedListOfDescendents )
        {
            if(currentPosition == fieldAtBaseOFDescendentObjects)
            {
                break;
            }
            currentOjbect = stepDownToChild(currentPosition, currentOjbect);
        }

        return currentOjbect;
    }

    private static sobject stepDownToChild(string childFieldName, sobject parent)
    {
        return parent.getSobject(childFieldName);
    }

    private static boolean objectContainsFieldValue(sobject baseObject, string field, string value)
    {
        return ((string) baseObject.get(field)).contains(value);
    }
}


