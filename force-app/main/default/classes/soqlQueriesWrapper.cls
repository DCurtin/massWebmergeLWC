public with sharing class soqlQueriesWrapper {
    @AuraEnabled
    public Map<string,Map<string,string>> queries{get; set;}   
}
