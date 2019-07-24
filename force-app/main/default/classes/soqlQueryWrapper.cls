public with sharing class soqlQueryWrapper {
    @AuraEnabled
    public string query {get; set;}

    @AuraEnabled
    public string description {get; set;}

    @AuraEnabled
    public string filterFieldPath {get; set;}

    @AuraEnabled
    public string filterValue {get; set;}

    @AuraEnabled
    public string webmergeMappingName {get; set;}

    @AuraEnabled
    public string action {get; set;}
}