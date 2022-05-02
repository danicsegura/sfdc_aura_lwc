import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import TIPO_DOCUMENTO from '@salesforce/schema/Account.Tipo_De_Documento__c';
import NUM_DOCUMENTO from '@salesforce/schema/Account.Numero_Do_Documento__c';
import getTitulosFinanceiros from '@salesforce/apex/ConsultaTitulosFinanceirosService.callService';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';
import MSG_MISSING_DOCUMENT from '@salesforce/label/c.ERROR_MISSING_DOCUMENT';
import MSG_TITULOS_NOT_FOUND from '@salesforce/label/c.ERROR_TITULOS_NOT_FOUND';
import MSG_ERRO_INTEGRACAO from '@salesforce/label/c.ERROR_INTEGRACAO_TITULOS';

export default class ConsultaTitulosFinanceiros extends LightningElement {
    @api recordId;
    @track result = [];
    showSpinner = true;
    documentNumber;
    documentType;
    filterBy = 'DataVencimento';
    searchPeriodValue = 'ultProx7dias';
    searchPeriodLabel = (this.isMobile) ? 'Últ. 7 dias + Próx. 7 dias' : 'Últimos 7 dias + Próximos 7 dias';
    quantidVencidos = 0;
    quantNoPrazo = 0;
    montanteVencidos = 0;
    montanteNoPrazo = 0;
    showMessage = false;
    showTable = false;
    showFilters = true;
    errorCode;
    sortIcon = 'utility:arrowdown';
    sortedBy = '';
    sortedDirection = 'asc';

    @wire(getRecord, { recordId: '$recordId', fields: [TIPO_DOCUMENTO, NUM_DOCUMENTO]})
    account({   error, data }){
        if(data){
            this.documentType = data.fields.Tipo_De_Documento__c.value;
            this.documentNumber = data.fields.Numero_Do_Documento__c.value;
        }
        if(error){
            console.log('Erro no lwc consultaTitulosFinanceiros: ');
            console.log(error);
        }
    }

    @wire(getTitulosFinanceiros, {  documentType: '$documentType',
                                    document: '$documentNumber',
                                    startDate: '$startDate',
                                    endDate: '$endDate',
                                    dateFilter: '$filterBy' })
    wiredTitulos({  error, data }){
        if(data){
            this.resetVariables();

            if(Object.keys(data).length != 0 && data.constructor === Object && data.StatusExecucao.ExecutadaCorretamente){
                this.result = JSON.parse(JSON.stringify(data.RetornoConsultaDebitosCentroLucro.Debitos));
                this.formatData();
                this.calculateAggregateFields();
                this.showSpinner = false;
                this.showMessage = false;
                this.showTable = true; 
                this.showFilters = true;
            }else{
                if(data.StatusExecucao != null && data.StatusExecucao.Mensagens != null){
                    this.errorCode = data.StatusExecucao.Mensagens[0].Codigo;
                }

                this.showErrorMessage(this.errorMessage);
            }
        }
        if(error){
            this.showErrorMessage(error);
        }
    }

    resetVariables(){
        this.quantidVencidos = 0;
        this.quantNoPrazo = 0;
        this.montanteVencidos = 0;
        this.montanteNoPrazo = 0;
    }

    showErrorMessage(error){
        if(this.errorMessage == MSG_TITULOS_NOT_FOUND){
            this.showSpinner = false;
            this.showMessage = true;
            this.showTable = false;
            this.showFilters = true;
        }else{
            this.showSpinner = false;
            this.showMessage = true;
            this.showTable = false;
            this.showFilters = false;
            console.log(error);
        }
    }

    formatData(){
        for(let titulo of this.result){
            titulo['ValorTotalHelpText'] = 'Juros: R$' + titulo.Juros + ' | ' + 'Multa: R$' + titulo.Multa + ' | ' + 'Deduções: R$' + titulo.OutrasDeducoes;

            titulo['CodigoCliente'] = titulo.CodigoCliente.replace(/^0+/, '');
        }
    }

    calculateAggregateFields(){
        let today = new Date();
        today.setUTCHours(0, 0, 0, 0);

        for(let titulo of this.result){
            let dataVencimento = new Date(titulo.DataVencimento);
            
            if(dataVencimento < today){
                this.quantidVencidos++;
                this.montanteVencidos += titulo.ValorTotal;
                titulo['ColorStatus'] = 'status-vencido';
            }else{
                this.quantNoPrazo++;
                this.montanteNoPrazo += titulo.ValorTotal;
                titulo['ColorStatus'] = 'status-no-prazo';
            }
        }
    }

    handleFilterBy(event){
        if(event.detail.value != this.filterBy){
            this.showSpinner = true;
            this.filterBy = event.detail.value;

            if(event.detail.value == 'DataVencimento'){
                this.searchPeriodValue = 'ultProx7dias';
                this.searchPeriodLabel = (this.isMobile) ? 'Últ. 7 dias + Próx. 7 dias' : 'Últimos 7 dias + Próximos 7 dias';
            }else{
                this.searchPeriodValue = 'ultimos7dias';
                this.searchPeriodLabel = 'Últimos 7 dias';
            } 
        }
    }

    handleSearchPeriod(event){
        if(event.target.value != this.searchPeriodValue){
            this.showSpinner = true;
            this.searchPeriodValue = event.target.value;
            this.searchPeriodLabel = event.target.label;

            refreshApex(this.wiredTitulos);
        }
    }

    sort(event){
        if(this.sortedBy == '' || event.currentTarget.dataset.id != this.sortedBy){
            this.sortIcon = 'utility:arrowup';
            this.sortedDirection = 'asc';
        }else{
            this.sortIcon = (this.sortIcon == 'utility:arrowdown') ? 'utility:arrowup' : 'utility:arrowdown';
            this.sortedDirection = (this.sortedDirection == 'asc') ? 'desc' : 'asc';
        }

        this.sortedBy = event.currentTarget.dataset.id;

        var reverse = this.sortedDirection == 'asc' ? 1 : -1;

        this.result.sort((a, b) => {
            a[event.currentTarget.dataset.id] = (a[event.currentTarget.dataset.id] == undefined) ? '' : a[event.currentTarget.dataset.id];
            b[event.currentTarget.dataset.id] = (b[event.currentTarget.dataset.id] == undefined) ? '' : b[event.currentTarget.dataset.id];
            return a[event.currentTarget.dataset.id] > b[event.currentTarget.dataset.id] ? 1 * reverse : -1 * reverse;
        });

        for(let icon of this.template.querySelectorAll('lightning-icon')){
            if(icon.dataset.id.includes(event.currentTarget.dataset.id, 0)){
                icon.className = 'icon-show';
            }else{
                icon.className = 'icon-hide';
            }
        }
    }

    get startDate(){
        let startDate = new Date();
        startDate.setUTCHours(0, 0, 0, 0);

        switch(this.searchPeriodValue){
            case 'ultimos7dias':
                startDate.setDate(startDate.getDate() - 7);
                break;
            case 'ultProx7dias':
                startDate.setDate(startDate.getDate() - 7);
                break;
            case 'ultimos15dias':
                startDate.setDate(startDate.getDate() - 15);
                break;
            case 'ultimos30dias':
                startDate.setDate(startDate.getDate() - 30);
                break;
            case 'ultimos90dias':
                startDate.setDate(startDate.getDate() - 90);
                break;
            case 'ultimos120dias':
                startDate.setDate(startDate.getDate() - 120);
                break;
        }

        return startDate.toISOString().substring(0, 10);
    }

    get endDate(){
        let endDate = new Date();
        endDate.setUTCHours(0, 0, 0, 0);

        switch(this.searchPeriodValue){
            case 'ultProx7dias':
                endDate.setDate(endDate.getDate() + 7);
                break;
            case 'proximos30dias':
                endDate.setDate(endDate.getDate() + 30);
                break;
        }

        return endDate.toISOString().substring(0, 10);
    }

    get filterOptions(){
        return [
            {   label: 'Data de Vencimento',    value: 'DataVencimento'     },
            {   label: 'Data de Emissão',       value: 'DataEmissao'        },
        ];
    }

    get searchPeriodItems(){
        if(this.filterBy == 'DataVencimento'){
            return [
                {
                    value: 'ultProx7dias',
                    label: (this.isMobile) ? 'Últ. 7 dias + Próx. 7 dias' : 'Últimos 7 dias + Próximos 7 dias'
                },
                {
                    value: 'ultimos15dias',
                    label: 'Últimos 15 dias'
                },
                {
                    value: 'ultimos30dias',
                    label: 'Últimos 30 dias'
                },
                {
                    value: 'ultimos90dias',
                    label: 'Últimos 90 dias'
                },
                {
                    value: 'ultimos120dias',
                    label: 'Últimos 120 dias'
                },
                {
                    value: 'proximos30dias',
                    label: 'Próximos 30 dias'
                },
            ];
        }else{
            return [
                {
                    value: 'ultimos7dias',
                    label: 'Últimos 7 dias'
                },
                {
                    value: 'ultimos15dias',
                    label: 'Últimos 15 dias'
                },
                {
                    value: 'ultimos30dias',
                    label: 'Últimos 30 dias'
                },
                {
                    value: 'ultimos90dias',
                    label: 'Últimos 90 dias'
                },
                {
                    value: 'ultimos120dias',
                    label: 'Últimos 120 dias'
                },
            ];
        }
    }

    get errorMessage(){
        const codigosTitulosNaoEncontrados = ['005', '027', '008'];

        if(this.documentNumber == null){
            return MSG_MISSING_DOCUMENT;
        }else if(this.documentType == 'Estrangeiro' || (this.errorCode && codigosTitulosNaoEncontrados.includes(this.errorCode))){
            return MSG_TITULOS_NOT_FOUND;
        }else{
            return MSG_ERRO_INTEGRACAO;
        }
    }

    get isMobile(){
        return FORM_FACTOR === 'Small'
    }
}