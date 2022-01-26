/******************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ========================================================================================================================================
* Purpose: US 15477 - Componente para adicionar um contato à multiplas Contas
* ========================================================================================================================================
* History
* -------
* VERSION   AUTHOR                  DATE        DETAIL      Description
* 1.0       Daniela Segura          24/11/2021  Created     Versão inicial
******************************************************************************************************************************************/
import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getRecords from '@salesforce/apex/RelateContactToAccountsController.getRecords';
import returnSelectedIds from '@salesforce/apex/RelateContactToAccountsController.returnSelectedIds';
import insertAccountContactRelations from '@salesforce/apex/RelateContactToAccountsController.insertAccountContactRelations';
import getFuncoesDoContato from '@salesforce/apex/RelateContactToAccountsController.getPicklistFuncoesDoContato';
import getRoles from '@salesforce/apex/RelateContactToAccountsController.getPicklistRoles';
import getRelationshipStrength from '@salesforce/apex/RelateContactToAccountsController.getPicklistRelationshipStrength';

export default class RelateContactToAccounts extends LightningElement {
@api recordId;

data = [];
recordsIds = [];
currentSelection = [];
allSelectedRecords = [];
@track mapFuncoesContato = [];
@track mapRoles = []
@track mapRelationshipStrength = []
selectedFuncoesContato = [];
selectedFuncoesContatoLabels = [];
selectedRoles = [];
selectedRolesLabels = [];
options = [];

searchKey = '';
searchBy;
selectedRecordsCount = 0;
boletoPorEmail = false;
active = false;
relationshipStrength;
startDate;
endDate;
firstPageSelection = true;
secondPageFields = false;
thirdPageConfirmation = false;
pageNumber = 1;
isLastPage = true;
isFirstPage = true;

showSpinner = false;
showTable = false;
showAccountsTable = false;
showGruposPlanoContasTable = false;
validateInputCnpjBasico = false;

disableRadioButtons = false;
disableNextButton = true;
disableDeleteButton = false;

msgNoSearchReference = false;
msgNoSearchKey = false;
msgNoSelection = false;
msgNoRecordsFound = false;

    columnsAccount = [
        { label: 'Nome da Conta', fieldName: 'name', type: 'text', initialWidth: 285},
        { label: 'Código SAP', fieldName: 'codigoSAP', type: 'text', initialWidth: 120},
        { label: 'Número do Documento', fieldName: 'numeroDocumento', type: 'text', initialWidth: 200},
        { label: 'Grupo Plano de Contas', fieldName: 'nomeGrupo', type: 'text', initialWidth: 190}
    ]

    columnsGrupoPlanoContas = [
        { label: 'Grupo Plano de Contas', fieldName: 'nomeGrupo', type: 'text'},
        { label: 'Código', fieldName: 'codigoGrupo', type: 'text', initialWidth: 180}
    ]

    get colAccountsWithDeleteBtn(){
        return [
            { label: 'Nome da Conta', fieldName: 'name', type: 'text', initialWidth: 270},
            { label: 'Código SAP', fieldName: 'codigoSAP', type: 'text', initialWidth: 115},
            { label: 'Número do Documento', fieldName: 'numeroDocumento', type: 'text', initialWidth: 185},
            { label: 'Grupo Plano de Contas', fieldName: 'nomeGrupo', type: 'text', initialWidth: 180},
            {   type: 'button-icon',
                typeAttributes: {   iconName: 'utility:delete',
                                    name: 'delete',
                                    iconClass: 'slds-icon-text-error',
                                    disabled: this.disableDeleteButton   },
                initialWidth: 70
            }
        ];
    }

    get colGruposWithDeleteBtn(){
        return [
            { label: 'Grupo Plano de Contas', fieldName: 'nomeGrupo', type: 'text'},
            { label: 'Código', fieldName: 'codigoGrupo', type: 'text', initialWidth: 120},
            {   type: 'button-icon',
                typeAttributes: {   iconName: 'utility:delete',
                                    name: 'delete',
                                    iconClass: 'slds-icon-text-error',
                                    disabled: this.disableDeleteButton   },
                initialWidth: 70
            }
        ];
    }

    get radioBtnOptions(){
        return [
            {   label: 'Contas', value: 'account'   },
            {   label: 'Grupos Plano de Contas', value: 'grupoPlanoContas'   },
            {   label: 'CNPJ básico', value: 'cnpjBasico'   },
        ];
    }

    connectedCallback(){
        getFuncoesDoContato({})
        .then(result => {
            for (let key in result) {
                this.mapFuncoesContato.push({label:result[key], value:key});
            }
        })
        .catch(error => {
            console.log('Erro no método getFuncoesDoContato.');
            console.log(error);
        })

        getRoles({})
        .then(result => {
            for (let key in result) {
                this.mapRoles.push({label:result[key], value:key});
            }
        })
        .catch(error => {
            console.log('Erro no método getRoles.');
            console.log(error);
        })

        getRelationshipStrength({})
        .then(result => {
            for (let key in result) {
                this.mapRelationshipStrength.push({label:result[key], value:key});
            }
        })
        .catch(error => {
            console.log('Erro no método getRoles.');
            console.log(error);
        })
    }

    handleRadioBtnChoice(event){
        this.searchBy = event.detail.value;
        this.msgNoSearchReference = false;
        if(this.searchBy == 'cnpjBasico') this.validateInputCnpjBasico = true;
        this.disableRadioButtons = true;
    }

    updateKey(event){
        this.searchKey = event.target.value;
        if(this.searchKey != '') this.msgNoSearchKey = false;
    }

    handleSearch(){
        this.pageNumber = 1;
        this.disableNextButton = false;
        this.getRecords();
    }

    getRecords(){
        this.updateAllSelectedRecords();

        let allSelectedRecordsString = JSON.stringify(this.allSelectedRecords);
        this.getIds({    selectedRecordsString : allSelectedRecordsString    });    

        if(this.searchBy == null){
            this.msgNoSearchReference = true
            return;
        }

        if(this.searchKey === ''){
            this.msgNoSearchKey = true;
            return;
        }

        this.showSpinner = true;

        getRecords({    recordId    :   this.recordId,
                        searchKey   :   this.searchKey,
                        searchBy    :   this.searchBy,
                        pageNumber  :   this.pageNumber })
        .then(result=>{
            (result.length < 10) ? this.isLastPage = true : this.isLastPage = false;
            (this.pageNumber == 1) ? this.isFirstPage = true : this.isFirstPage = false;

            this.data = result;

            if(this.searchBy == 'grupoPlanoContas')
                this.showGruposPlanoContasTable = true;
            else if(this.searchBy == 'account' || this.searchBy == 'cnpjBasico')
                this.showAccountsTable = true;

            if(result.length == 0){
                this.msgNoRecordsFound = true;
                this.showSpinner = false;
                this.showTable = false;
                return;
            }
            
            this.msgNoRecordsFound = false;
            this.showTable = true;
            this.showSpinner = false;
            
            this.getIds({    selectedRecordsString : allSelectedRecordsString    });  

            for(let row of this.data){
                if(this.allSelectedRecords.includes(row) && !this.currentSelection.includes(row)){
                    this.currentSelection.push(row);
                }
            }
        })
        .catch(error=>{
            this.data = null;
            this.showSpinner = false;
            console.log('Erro no componente relateContactToAccounts. Detalhes: ' + JSON.stringify(error));
            this.showToast('Erro', 'Ocorreu um erro no componente relateContactToAccounts. Entre em contato com o Administrador do Sistema.', 'error');
        })
    }

    getIds(value){
        returnSelectedIds(value)
        .then(result => {
            if(result)  this.recordsIds = result;
        })
        .catch(error =>{
            console.log('Erro no método getIds: ');
            console.log(JSON.stringify(error));
        })
    }

    onRowSelection(){
        this.msgNoSelection = false;
    }

    onPreviousPage(){
        this.pageNumber--;
        this.pageChange();
    }

    onNextPage(){
        this.pageNumber++;
        this.pageChange();
    }

    pageChange(){
        this.updateAllSelectedRecords();

        let allSelectedRecordsString = JSON.stringify(this.allSelectedRecords);
        this.getIds({    selectedRecordsString : allSelectedRecordsString    });

        this.getRecords();
    }

    toACRfieldsPage(){
        this.updateAllSelectedRecords();
        
        if(this.allSelectedRecords.length > 0){
            this.firstPageSelection = false;
            this.secondPageFields = true;
            this.selectedRecordsCount = this.allSelectedRecords.length;
            (this.allSelectedRecords.length <= 1) ? this.disableDeleteButton = true : this.disableDeleteButton = false;
        }else{
            this.msgNoSelection = true;
        }
    }

    handleDualListBox(event){
        if(event.target.name == 'funcoesContato'){
            this.selectedFuncoesContato = event.detail.value;
        }else{
            this.selectedRoles = event.detail.value;
        }
    }

    handleCheckbox(event){
        if(event.target.name == 'boletoPorEmail'){
            this.boletoPorEmail = !this.boletoPorEmail;
        }else{
            this.active = !this.active;
        }
    }

    handleCombobox(event){
        this.relationshipStrength = event.detail.value;
    }

    handleDateInput(event){
        if(event.target.name == 'startDate'){
            this.startDate = event.detail.value;
        }else{
            this.endDate = event.detail.value;
        }
    }

    toConfirmationPage(){
        for(let funcaoContato of this.mapFuncoesContato){
            if(this.selectedFuncoesContato.includes(funcaoContato.value) && !this.selectedFuncoesContatoLabels.includes(funcaoContato.label)){
                this.selectedFuncoesContatoLabels.push(funcaoContato.label);
            }
        }

        for(let role of this.mapRoles){
            if(this.selectedRoles.includes(role.value)  && !this.selectedRolesLabels.includes(role.label)){
                this.selectedRolesLabels.push(role.label);
            }
        }

        this.secondPageFields = false;
        this.thirdPageConfirmation = true;
    }

    handleDelete(event){
        if(this.allSelectedRecords.length <= 1){
            return;
        }

        let notDeletedRecords = this.allSelectedRecords.filter(isNotDeleted);
        this.allSelectedRecords = notDeletedRecords;

        this.selectedRecordsCount--;

        if(this.allSelectedRecords.length <= 1){
            this.disableDeleteButton = true;
        }

        function isNotDeleted(value){
            return value.Id != event.detail.row.Id;
        }
    }

    handleReturn(){
        let allSelectedRecordsString = JSON.stringify(this.allSelectedRecords);
        this.getIds({    selectedRecordsString : allSelectedRecordsString    });    
        
        if(this.secondPageFields){
            this.secondPageFields = false;
            this.firstPageSelection = true;
        }else if(this.thirdPageConfirmation){
            this.thirdPageConfirmation = false;
            this.secondPageFields = true;
        }
    }

    handleConfirm(){
        this.closeQuickAction();
        
        let allSelectedRecordsString = JSON.stringify(this.allSelectedRecords);

        let acrFields = JSON.stringify({    'Funcoes_Contato__c'        :   this.selectedFuncoesContato.join(';'), 
                                            'Roles'                     :   this.selectedRoles.join(';'),
                                            'Boleto_Por_Email__c'       :   this.boletoPorEmail,
                                            'Relationship_Strength__c'  :   this.relationshipStrength,
                                            'StartDate'                 :   this.startDate,
                                            'EndDate'                   :   this.endDate,
                                            'IsActive'                  :   this.active});

        insertAccountContactRelations({ contactId           :   this.recordId,
                                        selectedRecordsStr  :   allSelectedRecordsString,
                                        objectType          :   this.searchBy,
                                        acrString           :   acrFields })
            .then(result=>{
                console.log('Chamou insertAccountContactRelations com sucesso.');
            })
            .catch(error=>{
                console.log('Erro no componente relateContactToAccounts. Detalhes: ' + JSON.stringify(error));
                this.showToast('Erro', 'Ocorreu um erro no componente relateContactToAccounts. Entre em contato com o Administrador do Sistema.', 'error');
        })
    }

    updateAllSelectedRecords(){
        var table = [];

        if(this.searchBy == 'grupoPlanoContas'){
            table = this.template.querySelector('[data-id="gruposTable"]');
        }else if(this.searchBy == 'account' || this.searchBy == 'cnpjBasico'){
            table = this.template.querySelector('[data-id="accountsTable"]');
        }
        
        if(table){
            this.currentSelection = table.getSelectedRows();
            
            if(this.currentSelection){
                for(let row of this.data){
                    if(!this.allSelectedRecords.includes(row) && this.currentSelection.includes(row)){
                        this.allSelectedRecords.push(row);
                    }
                    
                    if(this.allSelectedRecords.includes(row) && !this.currentSelection.includes(row)){
                        let index = this.allSelectedRecords.indexOf(row);
                        this.allSelectedRecords.splice(index, 1);
                    }
                }
            }
        }
    }

    showToast(varTitle, varMessage, varVariant) {
        const event = new ShowToastEvent({ 
            title: varTitle, 
            message: varMessage, 
            variant: varVariant,
            mode: "sticky"
        })
        
        this.dispatchEvent(event)
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}