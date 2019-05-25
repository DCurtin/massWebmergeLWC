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


    @AuraEnabled
    public static map<string,soqlQueryWrapper> getQueriesFromStaticResource(){
        StaticResource soqlQueriesStaticResource = [select id,body from StaticResource Where name = 'soqlQueries' LIMIT 1];
        map<string,soqlQueryWrapper> soqlQueries = (map<string,soqlQueryWrapper>)JSON.deserialize(soqlQueriesStaticResource.body.toString(), map<string,soqlQueryWrapper>.class);
        return soqlQueries;    
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

    /*
        root is the sobject you are trying to filter.
        filterFieldPath is a dot-notated string of the child of root toward the field that you are checking.
        filterValue is the value that must be contained in the field.
        e.g. root_transaction->account->long_text_field filtering 'Deceased'
        root=root_transaction
        filterFieldPath= 'account__r.long_text_field__c'
        filterValue= 'Deceased'
    */
    private static boolean filterSobject(sobject root, string filterFieldPath, string filterValue)
    {

        List<string> filterFieldSplit = filterFieldPath.split('\\.');
        String filterField = filterFieldSplit.get(filterFieldSplit.size() - 1);

        sobject parent = root;

        for(string filterFieldParent : filterFieldSplit )
        {
            if(filterFieldParent == filterField)
            {
                break;
            }
            parent = parent.getSobject(filterFieldParent);
        }

        return ((string) parent.get(filterField)).contains(filterValue);
    }
}


