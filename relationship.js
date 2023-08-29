import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import apex method
import getRecords from '@salesforce/apex/CNT_RelationshipPage.getRecords';
import getAccountInfo from '@salesforce/apex/CNT_RelationshipPage.getAccountInfo';
import getPickListValues from '@salesforce/apex/CNT_RelationshipPage.getPickListValues';
import getAccounts from '@salesforce/apex/CNT_RelationshipPage.getAccounts'
import createRelation from '@salesforce/apex/CNT_RelationshipPage.createRelation';
import deleteRelation from '@salesforce/apex/CNT_RelationshipPage.deleteRelation';
import editRelation from '@salesforce/apex/CNT_RelationshipPage.editRelation';

import labelFamily from '@salesforce/label/c.REL_RelatedRelatives';
import labelBusinesses from '@salesforce/label/c.REL_RelatedBusinesses';
import labelFriends from '@salesforce/label/c.REL_RelatedFriends';
import labelEdit from '@salesforce/label/c.REL_Edit';
import labelNew from '@salesforce/label/c.REL_New';
import labelDelete from '@salesforce/label/c.GEN_Delete';
import labelSelect from '@salesforce/label/c.GEN_SelectOption';
import labelType from '@salesforce/label/c.Rel_Type';
import labelSave from '@salesforce/label/c.GEN_save';
import labelCancel from '@salesforce/label/c.GEN_CancelButton';
import labelEtiqueta from '@salesforce/label/c.GEN_Etiqueta';
import labelDeletedRecord from '@salesforce/label/c.GEN_DeletedRecord';

// label to create
import GEN_SelectAccountType from '@salesforce/label/c.GEN_SelectAccountType';
import CAS_Client from '@salesforce/label/c.CAS_Client';
import Gen_PotentialClient from '@salesforce/label/c.Gen_PotentialClient';
import GEN_InsuredPolicyholder from '@salesforce/label/c.GEN_InsuredPolicyholder';



export default class Lwc_RelationshipPage extends NavigationMixin(LightningElement) {
    
    // Variables
    // To organize the type of the relation for show them
    recordsFamily1;
    Family1visible;
    recordsFamily2;
    Family2visible;
    recordsBusiness1;
    Business1visible;
    recordsBusiness2;
    Business2visible;
    recordsFriends1;
    Friends1visible;
    recordsFriends2;
    Friends2visible;
    Friendsvisible;
    
    record;// Account that where ara showing the relationship
    businessRecordType; // true if RT is business false in other case
    @api recordId; // Id Account the we show relationship
    relation = []; // Relationship selected
    optionEtiqueta; // Values of REL_PCK_RelationType__c picklist
    optionTypes; // Values of REL_PCK_Type__c picklist
    isCreateRelationship =false; // To show the page to create new relationship 
    @api selectedAccount; // Account selected in the lookup
    etiqueta; //value selected of REL_PCK_RelationType__c picklist
    type; //value selected of REL_PCK_Type__c picklist

    isEditRelationship =false;

    // Labels
    label = {
        labelFamily,
        labelBusinesses,
        labelFriends,
        labelEdit,
        labelNew,
        labelDelete,
        GEN_SelectAccountType,
        CAS_Client,
        Gen_PotentialClient,
        GEN_InsuredPolicyholder,
        labelSelect,
        labelType,
        labelSave,
        labelCancel,
        labelEtiqueta,
        labelDeletedRecord
    }

    
    // SHOW RELATIONSHIP PAGE
    connectedCallback() {
        // Action that we need to start show relationship
        console.log('recordId ' + this.recordId);
        getAccountInfo({
            recordId: this.recordId
        }).then(result =>{
            this.record = result;
            var recordType = result[0].RecordType.Name;
            this.businessRecordType = recordType.includes('Business');
        });    

        this.getRelations();
    }
    getRelations(){
        // Query relationship that account record have  
        getRecords({
            recordId: this.recordId
        }).then(result =>{
            
            this.recordsFamily1 = result.FAM1;
            this.Family1visible = this.recordsFamily1.length !=0;
    
            this.recordsFamily2 = result.FAM2;
            this.Family2visible = this.recordsFamily2.length !=0;
            
            
            this.recordsBusiness1 = result.BUS1;
            this.Business1visible = this.recordsBusiness1.length !=0;
    
            this.recordsBusiness2 = result.BUS2;
            this.Business2visible = this.recordsBusiness2.length !=0;
           
            
            this.recordsFriends1 = result.FRI1;
            this.Friends1visible = this.recordsFriends1.length !=0;
    
            this.recordsFriends2 = result.FRI2;
            this.Friends2visible = this.recordsFriends2.length !=0;
    
            this.Friendsvisible = this.Friends1visible || this.Friends2visible;
            console.log(this.Friendsvisible);
        }); 
    }
    navigateToViewAccountPage(event) {
       // Navigate to account that we have clicked
        var accId = event.target.label;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accId,
                objectApiName: 'Account',
                actionName: 'view'
            },
        });
    }
    handleChange(e){
        // Add of remove selected or unselected relationship to "relation" list
        if(this.relation.includes(e.target.value)){
            const index = this.relation.indexOf(e.target.value);
            this.relation.splice(index,1);
        }else{
            this.relation.push(e.target.value);
        }
        
        console.log('relation' + this.relation);
    }

    // ACTION OF BUTTON
    handleNew(){
        // Action that have new button

        // Take the values of the picklist that we are show
        getPickListValues({
            objApiName: 'Relationship__c',
            fieldName: 'REL_PCK_RelationType__c'
        })
        .then(data => {
            this.optionEtiqueta = data;
        })
        .catch(error => {
            this.displayError(error);
        });
        
        getPickListValues({
            objApiName: 'Relationship__c',
            fieldName: 'REL_PCK_Type__c'
        })
        .then(data => {
            this.optionTypes = data;
        })
        .catch(error => {
            this.displayError(error);
        });
        this.isCreateRelationship =true;
    }
    handleEdit(){
        // Action that have edit button
        // Take the values of the picklist that we are show
        getPickListValues({
            objApiName: 'Relationship__c',
            fieldName: 'REL_PCK_RelationType__c'
        })
        .then(data => {
            this.optionEtiqueta = data;
        })
        .catch(error => {
            this.displayError(error);
        });

        this.isEditRelationship =true;

    }
    handleDelete(){
        // Action that have delete button
        console.log('relation' + this.relation);
        deleteRelation({recordId: this.relation})
        .then(() =>{
            const toastEvent = new ShowToastEvent({message:this.label.labelDeletedRecord, variant:"Success"});
            this.dispatchEvent(toastEvent);
            this.getRelations();
            this.relation = [];
        }).catch(error =>{
            console.log('Unable to delete record due to ' + error.body.message);
        });
    }

    // PAGE NEW
    handleEtiqueta(event){
        // Save value of etiqueta from form
        this.etiqueta = event.target.value;
    }
    
    handleType(event){
        // Save value of type from form
        this.type= event.target.value;
    }

    initClient(event){
        //Function of lookup
        this.selectedAccountObject = localStorage.getItem("accountObject");
        var accountObject = localStorage.getItem("accountObject");
        if(this.selectedAccountObject != null && this.selectedAccountObject != '' && this.selectedAccount != null && this.selectedAccount != undefined){  
            const lookupElement = event.target;
            lookupElement.setSelection(this.selectedAccountObject);  
        }
    }
    handleSelectionChange(event){
        //Function of lookup
        var accountObject = '';
        if(event.target.getSelection().length!=0){
            this.selectedAccountObject = JSON.stringify(event.target.getSelection()[0]);
            this.selectedAccount = event.target.getSelection()[0].id;
            accountObject = this.selectedAccountObject;
        }else{
            this.selectedAccountObject = '';
            this.selectedAccount = '';
            accountObject = '';
        } 

        const selectedEvent = new CustomEvent("selectedaccount", {
            detail: this.selectedAccount
        });
        this.dispatchEvent(selectedEvent);

        localStorage.setItem("accountObject", accountObject);
        
    }
    handleSearch(event){
        //Function of lookup
        const customlookup = event.target;
        let typedValue = customlookup.getSearchTerm();
        
        getAccounts({
            typedName: typedValue
        }).then(results =>{

            let clientesDevueltos = [];

            (JSON.parse(results)).forEach(element => {
                clientesDevueltos.push({'title':element.Name,'subtitle':element.ACC_TXT_NIFNIECIF__c,'id':element.Id, 'icon':'standard:people'});
            });

            customlookup.setSearchResults(clientesDevueltos);
        }) 
    }
    handleCancel(){
        // To cancel or close page NEW RELATIONSHIP
        this.isCreateRelationship =false;

         // To cancel or close page EDIT RELATIONSHIP
         this.isEditRelationship =false;
    }
    handleSave(){
        // To save the new relationship
        createRelation({
            recordId: this.recordId,
            accountId: this.selectedAccount,
            type: this.type,
            etiqueta: this.etiqueta
        }).then(() =>{
            
                this.isCreateRelationship =false;
                this.getRelations();
            
        }).catch(error =>{
            console.log('Unable to delete record due to ' + error.body.message);
        });
    }
    handleSaveEdit(){
        console.log('recordID ' +  this.relation);
        console.log('etiqueta ' + this.etiqueta);
        editRelation({
            recordId: this.relation,
            etiqueta: this.etiqueta
        }).then(() =>{
            console.log('edit');
            this.getRelations();
            // Unchecked relations
            this.uncheckRelation();
            this.isEditRelationship =false;
            this.relation = [];
        }).catch(error =>{
            console.log('Unable to delete record due to ' + error.body.message);
        });
    }
    uncheckRelation(){
        const boxes = this.template.querySelectorAll('lightning-input');
        boxes.forEach(box =>
            box.checked = false
        );
    }
}
