public with sharing class massWebmergeCustomReportsHelper {
    @AuraEnabled
    public static list<Related_Party__c> queryValue(soqlQueryWrapper soqlQuery){
        System.debug(soqlQuery);
        List<Related_Party__c> accountQuery = database.query(soqlQuery.query);
        List<Related_Party__c> filteredList = new List<Related_Party__c>();
        
        if(String.isEmpty(soqlQuery.filterFieldPath) || String.isEmpty(soqlQuery.filterValue))
            return accountQuery;
        for(Related_Party__c accountQ : accountQuery)
        {         
            boolean addObjectToList = filterSobject(accountQ, soqlQuery.filterFieldPath, soqlQuery.filterValue);
            if(addObjectToList)
                filteredList.add((Related_Party__c) accountQ);
        }
        return filteredList;
    }

    @AuraEnabled
    public static soqlQueriesWrapper getQueriesFromStaticResource(){
        StaticResource soqlQueriesStaticResource = [select id,body from StaticResource Where name = 'soqlQueries' LIMIT 1];
        soqlQueriesWrapper soqlQueries = (soqlQueriesWrapper)JSON.deserialize(soqlQueriesStaticResource.body.toString(), soqlQueriesWrapper.class);
        return soqlQueries;    
    }

    @AuraEnabled(cacheable=false)
    public static void doWebmerge(list<Id> recordIds, string mappingName){
        System.debug(mappingName);
        System.debug(recordIds);
        webm__webmerge_mapping__c mapping = [SELECT id, webm__Salesforce_Object_Name__c from webm__webmerge_mapping__c where name=:mappingName LIMIT 1];
        
        if(mapping == null)
            return;
        System.debug(mapping.id);
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


