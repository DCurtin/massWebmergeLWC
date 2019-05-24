import { LightningElement, track } from 'lwc';
import queryValue from '@salesforce/apex/massWebmergeCustomReportsHelper.queryValue';
import getQueries from '@salesforce/apex/massWebmergeCustomReportsHelper.getQueries';
import doWebmerge from '@salesforce/apex/massWebmergeCustomReportsHelper.doWebmerge';

export default class MassWebmergeCustomReports extends LightningElement 
{
    @track soqls=null;//a list of possible soql queries
    @track statusMessage;
    @track relatedParties;
    @track soqlOptionsList;
    soqlOption = null;

    get soqlOptions(){
        return this.soqlOptionsList;
    }
    constructor()
    {
        super();
        this.statusMessage = "Welcome, please choose a query.";
        this.getSoqlQueries();
    }

    toggleCheckBoxes(event)
    {
        //console.log(event.target.checked);
        if(event.target.checked)
        {
            this.checkAll();
        }else
        {
            this.uncheckAll();
        }
    }

    uncheckAll()
    {
        //uncheck all boxex
        console.log('uncheck all');
    }
    checkAll()
    {
        //check all boxex
        console.log('check all');
    }

    queryGenericCall()
    {
        if(this.soqlOption == null)
            {
                this.failWhale();
                return;
            }
        this.queryValueCall(this.soqlOption);
    }

    mergeRecords()
    {
        var recordIds = [];
        console.log(this.soqls[this.soqlOption].webmergeMappingName);
        this.relatedParties.forEach(record => {recordIds.push(record.Id)});
        console.log(recordIds);
        doWebmerge({recordIds: recordIds, mappingName: this.soqls[this.soqlOption].webmergeMappingName})
    }

    queryValueCall(soqlName)
    {
        console.log(this.soqls[soqlName]);
        queryValue({soqlQuery: this.soqls[soqlName]}).then(function(result)
        {
            console.log(result);
            this.relatedParties=result;
        }.bind(this))
    }

    getSoqlQueries()
    {
        getQueries().then(function(result)
        {
            this.soqls=result.queries;
            this.getSoqlOptions(result.queries);
        }.bind(this));
    }

    getSoqlOptions(availableQueries)
    {
        var values = [];
        Object.keys(availableQueries).forEach(query => {
            values.push({label: query, value: query})
        });
        this.soqlOptionsList = values;
    }

    setSoqlOption(event)
    {
        this.soqlOption = event.detail.value;
    }

    failWhale()
    {
        var failWhaleString = ` FAIL WHALE!

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