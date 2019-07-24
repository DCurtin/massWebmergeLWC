import { LightningElement, track } from 'lwc';
import retrieveRecordsUsingWrapper from '@salesforce/apex/massWebmergeCustomReportsHelper.retrieveRecordsUsingWrapper';
import getQueriesFromStaticResource from '@salesforce/apex/massWebmergeCustomReportsHelper.getQueriesFromStaticResource';
import doWebmerge from '@salesforce/apex/massWebmergeCustomReportsHelper.doWebmerge';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class MassWebmergeCustomReports extends LightningElement 
{
    @track statusMessage;
    @track queriedRecords;
    @track soqlOptionNamesList;
    @track tableLoadingState = true;
    @track finishedMerging = false;
    @track selectedSoqlOptionName = null;

    tableColumnLabels = [
        { label: 'Name', fieldName: 'Name' }
    ];
    
    statusMessages = {
        welcomeMessage: 'Welcome, Please choose a query.',
        finish:         'Webmerge has been submit. Please wait 5 to 10 minutes to received the email. Feel free to navigate away from this page.'
    }
    availableSoqlQueries=null;//a list of possible soql queries
    
    selectedRecords = [];
    selectedMapping = null;
    selectedAction = null;

    constructor()
    {
        super();
        this.setStatusMessage(this.statusMessages.welcomeMessage);
        this.callGetQueriesFromStaticResourceApex();
    }

    
    //soql query combobox 
    callGetQueriesFromStaticResourceApex()
    {
        getQueriesFromStaticResource().then(function(result)
        {
            this.setAvailableSoqlQueries(result);
            this.setsoqlOptionNamesList(result);
        }.bind(this));
    }

    setAvailableSoqlQueries(queries)
    {
        this.availableSoqlQueries=queries;
    }
    setsoqlOptionNamesList(queries)
    {
        this.soqlOptionNamesList = this.getSoqlOptionNamesIfQueriesNotNull(queries);
    }

    getSoqlOptionNamesIfQueriesNotNull(availableQueries)
    {
        var soqlQueryNames = [];

        if(availableQueries == null || availableQueries.length === 0){
            return soqlQueryNames;
        }
        
        Object.keys(availableQueries).forEach(query => {
            soqlQueryNames.push({label: query, value: query})
        });

        return soqlQueryNames;
    }

    setSelectedSoqlOptionName(event)
    {
        this.selectedSoqlOptionName = event.detail.value;
    }

    //Run Soql Query Button
    runSoqlQuery()
    {
        this.setSelectedMapping();
        this.setSelectedAction();
        this.callRetrieveRecordsUsingWrapperApex();
    }

    setSelectedAction()
    {
        this.selectedAction = this.availableSoqlQueries[this.selectedSoqlOptionName].action;
        console.log(this.selectedAction);
    }

    setSelectedMapping()
    {
        this.selectedMapping = this.availableSoqlQueries[this.selectedSoqlOptionName].webmergeMappingName;
        console.log(this.selectedMapping);
    }

    callRetrieveRecordsUsingWrapperApex()
    {
        var selectedSoqlOptionName = this.selectedSoqlOptionName;

        this.settableLoadingState(true);
        retrieveRecordsUsingWrapper({wrappedSoqlQuery: this.availableSoqlQueries[selectedSoqlOptionName]}).then(function(result)
        {
            this.settableLoadingState(false);
            this.setQueriedRecords(result);
            if(result.length === 0){
                this.notifyUserQueryReturnedNoRecords();
            }
        }.bind(this))
    }
    settableLoadingState(state)
    {
        this.tableLoadingState=state;
    }
   
    setQueriedRecords(result)
    {
        this.queriedRecords=result;
    }

    notifyUserQueryReturnedNoRecords()
    {
        const showInfo = new ShowToastEvent({
            title: 'Selected Query Returned No Records',
            message: 'It\'s possible there are no records that meet the queries filter options or the query was written incorrectly.',
            variant: 'info',
        });
        this.dispatchEvent(showInfo);
    }

    //Merge Records Button
    executeWebmergeFinishMerging()
    {
        this.callDoWebmergeApexIfRecordsSelected();
        this.finishMerging();
    }

    callDoWebmergeApexIfRecordsSelected()
    {
        var recordIds = this.getRecordIdsFromSelectedRecords();
        if(recordIds.length === 0){
            this.notifyUserNoRecordsSelected();
            return;
        }

        doWebmerge({recordIds: recordIds, mappingName: this.selectedMapping, action: this.selectedAction})

    }

    notifyUserNoRecordsSelected()
    {
        const showWarning = new ShowToastEvent({
            title: 'No Records Selected',
            message: 'Please selected 1 or more records by clicking on the check boxes beside them.',
            variant: 'warning',
        });
        this.dispatchEvent(showWarning);
    }

    getRecordIdsFromSelectedRecords()
    {
        var recordIds = [];
        this.selectedRecords.forEach(record => {recordIds.push(record.Id)});
        return recordIds;
    }

    finishMerging()
    {
        this.setStatusMessage(this.statusMessages.finish);
        this.finishedMerging=true;
    }

     //queried records table
     setSelectedRecords(event)
     {
         this.selectedRecords = event.detail.selectedRows;
     }

    //helper
    setStatusMessage(message)
    {
        this.statusMessage = message;
    }
}