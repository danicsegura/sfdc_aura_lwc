import { LightningElement, track, wire } from 'lwc';
import getPagamento from '@salesforce/apex/IntegrationServiceUltimosPag.getPagamentosVencidos';
import getMetadata from '@salesforce/apex/getParamets.getMetadata';
import getBoleto from '@salesforce/apex/IntegrationServiceUltimosPag.getBoletos';
// metodo para envio do boleto por emailimport getEmails from '@salesforce/apex/IntegrationServiceUltimosPag.getEmails';
import { NavigationMixin } from 'lightning/navigation';
import sendCaseFormaPagamento from '@salesforce/apex/IntegrationServiceUltimosPag.sendCaseFormaPagamento';
import msgErroInesperado from '@salesforce/label/c.Msg_ErroInesperado';
import msgmSucessCaseLabel from '@salesforce/label/c.Msg_SolicitacaoAberta';
import Msg_BloqueioNovoBoleto from '@salesforce/label/c.Msg_BloqueioNovoBoleto';
import Msg_RetornoVazio from '@salesforce/label/c.Msg_RetornoVazio';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const base64ToBlobUrl = (base64Data, contentType) =>
{
    const sliceSize = 512;
    const byteCharacters = atob(base64Data);
    const byteArrays = [];
    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize)
    {
        const slice = byteCharacters.slice(offset, offset + sliceSize);

        const byteNumbers = new Array(slice.length);
        for (let i = 0; i < slice.length; i++)
        {
            byteNumbers[i] = slice.charCodeAt(i);
        }

        const byteArray = new Uint8Array(byteNumbers);
        byteArrays.push(byteArray);
    }

    const blob = new Blob(byteArrays, { type: contentType });
    const urlBlob = URL.createObjectURL(blob);

    return urlBlob;
};

var daysApart;
export default class CobrancaVencerVencidas extends NavigationMixin(LightningElement) {
    @track results;
    @track columns;
    @track guardaMeta;
    @track error;
    @track apolice;
    @track fatura;
    @track data;
    @track objUser = {};
    @track optionsBanco;
    @track resultSave;
    disabledSave = true;
    openPixModal;
    openPixErrorModal;
    currentRow;
    vencidaMaisDoisdias = true;

    constructor() {
        super();
        this.columns = [
            {
                label: 'Competência',
                fieldName: 'competencia',
                type: 'text'
            },
            {
                label: 'Apólice',
                fieldName: 'apolice',
                type: 'text',
            },
            {
                label: 'Doc. Cobrança',
                fieldName: 'fatura',
                type: 'text',
            },
            {
                label: 'Valor(R$)',
                fieldName: 'valor',
                type: 'text',
            },
            /*{
                label: 'Dias Vencidos',
                fieldName: 'diasVencido',
                type: 'text',
            },*/
            {
                label: 'Forma Pag.',
                fieldName: 'formaPagamento',
                type: 'text',
            },
            { label: 'Ações', fixedWidth: 60, type: 'action', typeAttributes: { rowActions: this.getRowActions } },
        ] 
    }
    @wire(getMetadata)
    metadataRetorno({ error, data }) {
        if (data) {
            this.guardaMeta = data;
            window.console.log('optionsValues ===> ' + JSON.stringify(data));
        }
        else if (error) {
            window.console.log('error ===> ' + JSON.stringify(error));
        }
    }
    exibirPdf(url) {
                 this[NavigationMixin.Navigate]({
                     type: 'standard__webPage',
                     attributes: {
                         url: url
                     }
                 },
                 false
             );
         }
    downloadRow(row) {
        //download do PDF
        if(row.ColetivoSn === 'N'){

            this.spinnerOpen = true;
            this.apolice = row.apolice;
            this.fatura = row.fatura;       
            getBoleto({apolice: this.apolice, fatura: this.fatura})
            .then(result =>{
                let blobPDF = result;
                if(blobPDF !==''){
                    const contentType = 'application/pdf';
                    let urlBlobPDF = base64ToBlobUrl(blobPDF, contentType);
                    this.exibirPdf(urlBlobPDF);
                } else {
                    this.messageAvisoDownload();
                }
            })
            .catch(error =>{    
                // Mensagem para Error de código, bug ou permissão
                this.messageErrorService();
            })
        } else {
            this.msgNotOpen();
        }
    }
    /*  metodo para enviar boleto por e-mail
    emailRow(row) {
        this.spinnerOpen = true;
        this.apolice = row.apolice;
        this.fatura = row.fatura;
        alert('Entrou');
        getEmails({apolice: this.apolice, fatura: this.fatura})
        .then(result => {
            if (result === true) {
                this.msgInvalidoCase();
                this.disabledSave = false;

            } else {
                this.msgInvalidoCase();
                this.disabledSave = true;
            }

        })
        .catch(error =>{    
            // Mensagem para Error de código, bug ou permissão
            this.messageErrorService();
        }) 
    }*/
    sendCase(row) {
            //enviar caso 
        if(row.ColetivoSn === 'N'){

            this.apolice = row.apolice;
            this.fatura = row.fatura;   
            console.log(this.apolice);
            sendCaseFormaPagamento({apolice: this.apolice, fatura: this.fatura, cobranca: row.fatura})
            .then(result => {
                this.resultSave = result;
                console.log(this.apolice);
                console.log(this.fatura);
                let numeroCaso = this.resultSave.numberCaseNew;
                let numeroCasoExiste = this.resultSave.numberCaseExiste;
                if(this.resultSave.numberCaseNew != '' && this.resultSave.success === true){
                    
                    this.msgSucessCase(numeroCaso);
                    this.isModalOpen = false;
                    this.isformOpen = false;
                    this.isBoletoOpen = false;

                } else if(this.resultSave.existe === true) {
                    this.msgExistCase(numeroCasoExiste); 
                } else {
                    this.msgInvalidoCase();
                }
                
            })
            .catch(error => {
                this.messageError();
            })
        } else {
            this.msgNotOpen();
        }
    }
        getRowActions(row, doneCallback) {
        const actions = [];
        if(row.formaPagamento === 'Boleto'){
            if(row.diasVencido < parseFloat('55')){
                actions.push({
                        'label': 'Download Boleto',
                        'name': 'download_boleto',
                    });
       /*     actions.push({
                'label': 'Enviar Boleto por E-mail',
                'name': 'enviar_email',
            });*/
            }else if(row.diasVencido > parseFloat('55')){
                actions.push({
                    'label': 'Solicitar um Novo Boleto',
                    'name': 'solicitar_boleto',
                });
            }
        }

        const day = row.dtVencimento.substring(0,2);
        const month = row.dtVencimento.substring(3,5);
        const year = row.dtVencimento.substring(6,11);
        const dateVencimento = new Date(year + '-' + month + '-' + day);

        const today = new Date();
        today.setUTCHours(0, 0, 0, 0);

        const timeApart = today - dateVencimento;
        daysApart = timeApart / (1000 * 60 * 60 * 24);

        if(daysApart > -1){
            actions.push({
                'label' : 'Pagamento via PIX',
                'name' : 'pagamento_pix',
            }); 
        }
        

        setTimeout(() => {
            doneCallback(actions);
        }), 200
    }

    @wire(getPagamento)
    wireApolice({ error, data }) {
        if (data) {
            console.log('dados ' + JSON.stringify(data));
            this.results = data;

            if(data === ''){
                this.messageAviso();
            }
        } else if (error) {
            console.log('error ');
            console.log(JSON.stringify(error));
            this.messageError();
        }
    }
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.currentRow = row;
        
        switch (actionName) {
            case 'download_boleto':
                this.downloadRow(row);
                break;
            case 'solicitar_boleto':
                this.sendCase(row);
                break;
            case 'pagamento_pix':
                if(daysApart > 2){
                    this.openPixModal = true;
                }else{
                    this.openPixErrorModal = true;
                }
                break; 
            /*case 'enviar_email':
                 this.emailRow(row);
                 break;*/
            default:
        }
    }
    messageError(){
        const event = new ShowToastEvent({
            "title": "Error!",
            "message": msgErroInesperado,
            "variant": "error"
        });
        this.dispatchEvent(event);
    }
    msgSucessCase(numeroCaso){
        const event = new ShowToastEvent({
            "title": "Sua solicitação foi enviada",
            "message": "Aberto Caso " + numeroCaso +" "+msgmSucessCaseLabel,
            "variant": "Success"
        });
        this.dispatchEvent(event);
    }
    msgExistCase(numeroCasoExiste){
        const event = new ShowToastEvent({
            "title": "Ops, Não foi possivel enviar sua solicitação",
            "message": "Solicitação já em andamento no caso "+ numeroCasoExiste + ", consulte no menu Ajuda -> Status de Atendimento.",
            "variant": "warning"
        });
        this.dispatchEvent(event);
    }
    messageAviso(){
        const event = new ShowToastEvent({
            "title": "Aviso",
            "message": Msg_RetornoVazio,
            "variant": "warning"
        });
        this.dispatchEvent(event);
    }
    msgNotOpen(row){
        const event = new ShowToastEvent({
            "title": "Ops",
            "message": Msg_BloqueioNovoBoleto,
            "variant": "warning"
        });
        this.dispatchEvent(event);
    }

    closeModal(){
        this.openPixModal = false;
        this.openPixErrorModal = false;
    }
}