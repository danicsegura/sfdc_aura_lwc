import { LightningElement, api, track } from 'lwc';
import callService from '@salesforce/apex/ConsultaPedidosService.callService';
import getCodigoSap from '@salesforce/apex/ConsultaPedidosController.getCodigoSap';

export default class ConsultaPedidos extends LightningElement {
    @api recordId;
    codigoSap;
    searchPeriod = 15;

    ordensVenda = [];
    ordensVendaCombustiveis = [];
    ordensVendaLubrificantes = [];
    @track ordensVendaCombustiveisView = [];
    @track ordensVendaLubrificantesView = [];
    detalhesOrdemVenda = [];
    remessas = [];
    currentPedido = [];
    currentDetalhesOrdemVenda = [];
    currentRemessa = [];

    msgNenhumPedido = false;
    msgSemCodigoSap;
    nenhumPedidoCombustivel;
    nenhumPedidoLubrificante;

    showDetails = false;
    showSpinner = true;
    showLessCombustiveis;
    showLessLubrificantes;
    showTable;

    get periodoBusca(){
        return "Últimos " + this.searchPeriod + " dias";
    }

     connectedCallback(){
        getCodigoSap({  recordId: this.recordId })
        .then(result =>{
            if(result){
                this.codigoSap = result;
                this.callApexService();
            }
            else{
                this.showSpinner = false;
                this.msgSemCodigoSap = true;
                this.showTable = false;
            }
        }).catch(error =>{
            console.log('Erro no método getCodigoSap: ');
            console.log(JSON.stringify(error));
        })
    }

    callApexService(){
        this.msgNenhumPedido = false;
        this.showSpinner = true;
        this.cleanArrays();

        callService({   codigoSap       :   this.codigoSap,
                        searchPeriod    :   this.searchPeriod  })
        .then(result =>{
            this.error = undefined;

            if(result.StatusExecucao.ExecutadaCorretamente){
                this.ordensVenda = result.RetornoConsultaOrdemVendaDetalhada.OrdensVenda;
                this.detalhesOrdemVenda = result.RetornoConsultaOrdemVendaDetalhada.DetalhesOrdemVenda;
                this.remessas = result.RetornoConsultaOrdemVendaDetalhada.Remessa;
    
                this.splitArraysCombustivelLubrificante();

                this.msgNenhumPedido = false;
                this.showTable = true;
            }else{
                this.msgNenhumPedido = true;
                this.showTable = false;
            }

            this.showSpinner = false;
        })
        .catch(error =>{
            console.log('Erro no método callService: ');
            console.log(JSON.stringify(error));
        })
    }

    cleanArrays(){
        this.ordensVendaCombustiveis.length = 0;
        this.ordensVendaLubrificantes.length = 0;
        this.ordensVendaCombustiveisView.length = 0;
        this.ordensVendaLubrificantesView.length = 0;
    }

    splitArraysCombustivelLubrificante(){
        for(let ordemVenda of this.ordensVenda){
            (ordemVenda.SetorAtividade == '02') ? this.ordensVendaCombustiveis.push(ordemVenda) : this.ordensVendaLubrificantes.push(ordemVenda);
        }

        this.ordensVendaCombustiveis = this.sortArrayByDateDesc(this.ordensVendaCombustiveis);
        this.ordensVendaLubrificantes = this.sortArrayByDateDesc(this.ordensVendaLubrificantes);

        if(this.ordensVendaCombustiveis.length < 1){
            this.nenhumPedidoCombustivel = true;
        }else{
            if(this.ordensVendaCombustiveis.length > 6){
                this.ordensVendaCombustiveisView = this.ordensVendaCombustiveis.slice(0, 6);
                this.showLessCombustiveis = true;
            }else{
                this.ordensVendaCombustiveisView = this.ordensVendaCombustiveis;
            }

            this.nenhumPedidoLubrificante = false;
        }

        if(this.ordensVendaLubrificantes.length < 1){
            this.nenhumPedidoLubrificante = true;
        }else{
            if(this.ordensVendaLubrificantes.length > 6){
                this.ordensVendaLubrificantesView = this.ordensVendaLubrificantes.slice(0, 6);
                this.showLessLubrificantes = true;
            }else{
                this.ordensVendaLubrificantesView = this.ordensVendaLubrificantes;
            }

            this.nenhumPedidoLubrificante = false;
        }
        
    }

    sortArrayByDateDesc(array){
        array.sort(function(a, b){
            return new Date(b.DataEntrega) - new Date(a.DataEntrega);
        });

        return array;
    }

    openDetails(event){
        for(let ordemVenda of this.ordensVenda){
            if(ordemVenda.Numero == event.target.label){
                this.currentPedido = ordemVenda;
            }
        }

        for(let detalhe of this.detalhesOrdemVenda){
            if(detalhe.OrdemVenda == event.target.label){
                this.currentDetalhesOrdemVenda.push(detalhe);
            }
        }

        if(this.remessas){
            for(let remessa of this.remessas){
                if(remessa.DocumentoVenda == event.target.label){
                    this.currentRemessa.push(remessa);
                }
            }
        }
        
        this.showDetails = true;
    }

    showAll(event){
        if(event.target.name == 'showAllCombustiveis'){
            this.ordensVendaCombustiveisView = this.ordensVendaCombustiveis;
            this.showLessCombustiveis = false;
        }else if(event.target.name == 'showAllLubrificantes'){
            this.ordensVendaLubrificantesView = this.ordensVendaLubrificantes;
            this.showLessLubrificantes = false;
        }

    }

    changeDate(event){
        this.searchPeriod = event.target.value;
        this.callApexService();
    }

    closeDetail(){
        this.showDetails = false;

        //empty current order arrays
        this.currentDetalhesOrdemVenda.length = 0;
        this.currentRemessa.length = 0;
    }
}