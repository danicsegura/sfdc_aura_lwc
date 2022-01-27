import { LightningElement, api, track } from 'lwc';
import getEndereco from '@salesforce/apex/ConsultaPedidosController.getEndereco';
import getCodeToLabelReferences from '@salesforce/apex/ConsultaPedidosController.getCodeToLabelReferences';

export default class DetalhesPedido extends LightningElement {
    @api pedido;
    @api detalhes;
    @api remessas;
    endereco;
    valorTotal = 0;
    @track detalhesComValor = [];
    @track remessasCarregamento = [];
    @track remessasProgramadas = [];
    @track nenhumaRemessaProgramada;
    @track nenhumaRemessaCarregada;

     get statusTextColor(){
        switch(this.pedido.StatusOrdem){
            case 'Totalmente Cancelado':
                return 'status_totalmente_cancelado';
            case 'Totalmente Faturado':
                return 'status_totalmente_faturado';
            case 'Parcialmente Faturado':
                return 'status_parcialmente_faturado';
            case 'Não Programado':
                return 'status_nao_programado';
            case 'Totalmente Programado':
                return 'status_totalmente_programado';
            case 'Parcialmente Programado':
                return 'status_pacialmente_programado';
            case 'Bloqueio Financeiro':
                return 'status_bloqueio_financeiro';
            case 'Parcialmente Bloqueado':
                return 'status_parcialmente_bloqueado';
            default:
                return 'status_default';       
        }
      }

    connectedCallback(){
        this.getEndereco();
        this.getValorTotal();
        this.loadProdutos();
        this.loadRemessas();
    }

    getEndereco(){
        getEndereco({    codigoSapRecebedor : this.pedido.Recebedor  })
        .then(result => {
            this.endereco = result;
        })
        .catch(error => {
            console.log('Erro no método getEndereco: ');
            console.log(error);
        })
    }

    getValorTotal(){
        for(let detalhe of this.detalhes){
            this.valorTotal += detalhe.Valor;
        }
    }

    loadProdutos(){
        let detalhesString = JSON.stringify(this.detalhes);
        let detalhesAux = [];

        getCodeToLabelReferences({   detalhesString : detalhesString     })
        .then(result => {
            if(result){
                detalhesAux = result;

                for(let detalhe of detalhesAux){
                    if(detalhe.Valor > 0 && !this.detalhesComValor.includes(detalhe)){
                        this.detalhesComValor.push(detalhe);
                    }
                }
            }
        })
        .catch(error =>{
            console.log('Erro no método getCodeToLabelReferences: ');
            console.log(error);
        })
    }

    loadRemessas(){
        for(let remessa of this.remessas){
            if(remessa.QuantidadeTransporte > 0 && !this.remessasProgramadas.includes(remessa)){
                this.remessasProgramadas.push(remessa);
            }

            if(remessa.ValorFaturado > 0 && remessa.DataEfetivaCarregamento && !this.remessasCarregamento.includes(remessa)){
                this.remessasCarregamento.push(remessa);
            }
        }

        this.remessasProgramadas.sort(compare);
        this.remessasCarregamento.sort(compare);

        function compare(a, b){
            const numProgramacao1 = a.NumeroProgramacao;
            const numProgramacao2 = b.NumeroProgramacao;

            let comparison = 0;
            if(numProgramacao1 > numProgramacao2){
                comparison = 1;
            }else if(numProgramacao1 < numProgramacao2){
                comparison = -1;
            }
            return comparison;
        }

        if(this.remessasProgramadas.length < 1) this.nenhumaRemessaProgramada = true;
        if(this.remessasCarregamento.length < 1) this.nenhumaRemessaCarregada = true;
    }

    close(){
        this.valorTotal = 0;
        this.dispatchEvent(new CustomEvent('close'));
    }
}