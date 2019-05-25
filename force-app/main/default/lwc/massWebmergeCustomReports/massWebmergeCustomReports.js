import { LightningElement, track } from 'lwc';
import queryValue from '@salesforce/apex/massWebmergeCustomReportsHelper.queryValue';
import getQueriesFromStaticResource from '@salesforce/apex/massWebmergeCustomReportsHelper.getQueriesFromStaticResource';
import doWebmerge from '@salesforce/apex/massWebmergeCustomReportsHelper.doWebmerge';


export default class MassWebmergeCustomReports extends LightningElement 
{
    @track statusMessage;
    @track relatedParties;
    @track soqlOptionNamesList;
    @track tableLoadingState = true;

    availableSoqlQueries=null;//a list of possible soql queries

    @track tableColumnLabels = [
        { label: 'Name', fieldName: 'name' },
        { label: 'account', fieldName: 'Account__r.Id' }
    ];

    selectedSoqlOptionName = null;
    selectedRows = [];
    
    /*
        provide available 
    */
    get soqlOptionNames(){
        return this.soqlOptionNamesList;
    }
    constructor()
    {
        super();
        this.statusMessage = "Welcome, please choose a query.";
        this.getSoqlQueryOptions();
    }

    getSelectedRecords(event)
    {
        this.selectedRows = event.detail.selectedRows;
    }

    queryGenericCall()
    {
        if(this.selectedSoqlOptionName == null)
            {
                this.failWhale();
                return;
            }
        this.queryValueCall(this.selectedSoqlOptionName);
    }

    mergeRecords()
    {
        var recordIds = [];
        console.log(this.availableSoqlQueries[this.selectedSoqlOptionName].webmergeMappingName);
        this.selectedRows.forEach(record => {recordIds.push(record.Id)});
        console.log(recordIds);
        doWebmerge({recordIds: recordIds, mappingName: this.availableSoqlQueries[this.selectedSoqlOptionName].webmergeMappingName})
    }

    queryValueCall(selectedSoqlOptionName)
    {
        console.log(this.availableSoqlQueries[selectedSoqlOptionName]);
        queryValue({soqlQuery: this.availableSoqlQueries[selectedSoqlOptionName]}).then(function(result)
        {
            console.log(result[0].Account__r.Id);
            this.relatedParties=result;
            this.tableLoadingState=false;
        }.bind(this))
    }

    getSoqlQueryOptions()
    {
        getQueriesFromStaticResource().then(function(result)
        {
            this.availableSoqlQueries=result.queries;
            this.soqlOptionNamesList = this.getSoqlOptionNames(result.queries);
        }.bind(this));
    }

    getTableColumnLabels(selectedSoqlOptionName)
    {
        var queryParts = this.breakDownQueryStringRemoveSelect(selectedSoqlOptionName)
        var columnNames = this.parseOutColumnNames(queryParts);
        return this.generateFormattedColumnNames(columnNames);
    }

    generateFormattedColumnNames(columnNames)
    {
        var columnNamesFormatted = [];

        columnNames.forEach(name=>
            {
                columnNamesFormatted.push({ label: name, fieldName: name })
            })
            console.log(columnNamesFormatted);
            return columnNamesFormatted;
    }

    breakDownQueryStringRemoveSelect(selectedSoqlOptionName)
    {
        var queryString =  this.availableSoqlQueries[selectedSoqlOptionName].query;
        var queryParts = queryString.split(' ');
        return queryParts.slice(1); //return array with 'select' removed
    }

    parseOutColumnNames(queryParts)
    {
        var columns = [];
        var partsCount = queryParts.length;
        var index;
        var valueAtIndex;
        var valueAtIndexCleaned;

        for(index=0; index < partsCount; ++index)
        {
            valueAtIndex = queryParts[index];
            valueAtIndexCleaned = valueAtIndex.replace(',', '');


            if(valueAtIndexCleaned.toLowerCase() === 'from')
                break;

            columns.push(valueAtIndexCleaned);
        }
        return columns;
    }

    getSoqlOptionNames(availableQueries)
    {
        console.log("getting options");
        var soqlQueryNames = [];

        if(availableQueries == null)
        {
            return soqlQueryNames;
        }
        
        Object.keys(availableQueries).forEach(query => {
            soqlQueryNames.push({label: query, value: query})
        });
        console.log(soqlQueryNames);
        return soqlQueryNames;
    }

    setselectedSoqlOptionName(event)
    {
        this.selectedSoqlOptionName = event.detail.value;
        //this.tableColumnLabels = this.getTableColumnLabels(this.selectedSoqlOptionName);
    }

    failWhale()
    {
        var failWhaleString = ` 
            FAIL WHALE!

        W     W      W        
        W        W  W     W    
                      '.  W      
          .-""-._     \\ \\.--|  
         /       "-..__) .-'   
        |     _         /      
        '-.__,   .__.,'       
         \`'----'._--'      
        VVVVVVVVVVVVVVVVVVVVV`;
        console.log(failWhaleString);
    }
}