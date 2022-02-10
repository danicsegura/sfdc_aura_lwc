import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import validateNewPixRequest from '@salesforce/apex/PagamentoPixLwcController.validateNewPixRequest';
import sendEmail from '@salesforce/apex/PagamentoPixLwcController.sendEmail';
import createLogIntegracao from '@salesforce/apex/PagamentoPixLwcController.createLogIntegracao';
import getFieldsValuesString from '@salesforce/apex/PagamentoPixLwcController.getFieldsValuesString';
import callServiceNewPix from '@salesforce/apex/IntegrationServicePagamentoPix.callServiceNewPix';
import callServiceReimpressao from '@salesforce/apex/IntegrationServicePagamentoPix.callServiceReimpressao';

export default class PagamentoPix extends LightningElement {
    @api row;
    rowString;
    logIntegracaoId;
    email;
    error;
    integrationPixResult;
    integrationSuccess;
    isNewPixRequest;
    txId = '';
    numeroContrato;
    qrCode = '';
    qrCodeSource;
    crc16;
    emvString;
    changeVisibility = false;
    qrCodeVisibility;
    spinnerVisibility;
    disableSendEmail = true;
    disableSendBtn = true;
    errorPrevisulMsg = 'Favor entrar em contato com a equipe de suporte da Previsul.';
    
    get emailFieldsVisibility(){
        return this.changeVisibility ? 'emailFieldsVisible' : 'emailFieldsNotVisible';
    }

    connectedCallback(){
        this.spinnerVisibility = 'show';
        this.qrCodeVisibility = 'hide';
        this.rowString = JSON.stringify(this.row);
        this.numeroContrato = this.row.fatura;

        validateNewPixRequest({  cobrancaString : this.rowString    })
            .then(result =>{
                 if(result){
                    this.isNewPixRequest = true;
                    this.callServiceNewPix();
                 }else{
                    this.isNewPixRequest = false;
                    this.callServiceReimpressao();
                }
            })
            .catch(error =>{
                console.log('Erro na chamada do método validateNewPixRequest: ');
                console.log(error);
            })
    }

    callServiceNewPix(){
        callServiceNewPix({ cobrancaString : this.rowString })
            .then(result =>{
                if(result){
                    this.integrationPixResult = result;
                    if(result.message){
                        this.showToast('Ocorreu o seguinte erro na geração do QRCode:', result.message, 'error', 'sticky');
                        this.integrationSuccess = false;
                        this.createLogIntegracao();
                    }else{
                        this.showToast('Foi gerado o QRCode para pagamento no valor de R$ ' + result.valor, '', 'success', 'dismissible');
                        this.integrationSuccess = true;
                        this.txId = this.integrationPixResult.pix.txId;
                        this.getFieldsValuesString(this.integrationPixResult.pix.location, this.integrationPixResult.valor.toString());

                    }
                }else{
                    this.showToast('Ocorreu um erro no envio do QRCode.', this.errorPrevisulMsg, 'error', 'sticky');
                }
            })
            .then(result =>{
                this.disableSendEmail = false;
            })
            .catch(error => {
                console.log('Erro na chamada do método callServiceNewPix: ')
                console.log(error);
            })
    }

    callServiceReimpressao(){
        callServiceReimpressao({ cobrancaString : this.rowString })
        .then(result =>{
            if(result){
                this.integrationPixResult = result;
                if(result.message){
                    this.showToast('Ocorreu o seguinte erro na impressão do QRCode:', result.message, 'error', 'sticky');
                    this.integrationSuccess = false;
                }else{
                    this.showToast('Exibição do QRCode para pagamento no valor de R$ ' + result.valor, '', 'success', 'dismissible');
                    this.integrationSuccess = true;
                    this.qrCode = this.integrationPixResult.pix.qrCode;
                    this.printQrCode();
                }
            }else{
                this.showToast('Ocorreu um erro no envio do QRCode.', this.errorPrevisulMsg, 'error', 'sticky');
            }
        })
        .then(result =>{
            this.disableSendEmail = false;
        })
        .catch(error => {
            console.log('Erro na chamada do método callServiceReimpressao: ')
            console.log(error);
        })
    }

    getFieldsValuesString(location, value){
        getFieldsValuesString({ payloadLocation     : location,
                                transactionAmount   : value   })
            .then(result =>{
                if(result){
                    this.emvString = result;
                }
            })
            .then(result => {
                this.calculateCrc16();
                this.printQrCode();

                if(this.isNewPixRequest){
                    this.createLogIntegracao();
                }
            })
            .catch(error =>{
                console.log('Erro na chamada apex getFieldsValuesString:');
                console.log(error);
            })
    }

    calculateCrc16(){
        var crcTable = [0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5,
            0x60c6, 0x70e7, 0x8108, 0x9129, 0xa14a, 0xb16b,
            0xc18c, 0xd1ad, 0xe1ce, 0xf1ef, 0x1231, 0x0210,
            0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
            0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c,
            0xf3ff, 0xe3de, 0x2462, 0x3443, 0x0420, 0x1401,
            0x64e6, 0x74c7, 0x44a4, 0x5485, 0xa56a, 0xb54b,
            0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
            0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6,
            0x5695, 0x46b4, 0xb75b, 0xa77a, 0x9719, 0x8738,
            0xf7df, 0xe7fe, 0xd79d, 0xc7bc, 0x48c4, 0x58e5,
            0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
            0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969,
            0xa90a, 0xb92b, 0x5af5, 0x4ad4, 0x7ab7, 0x6a96,
            0x1a71, 0x0a50, 0x3a33, 0x2a12, 0xdbfd, 0xcbdc,
            0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
            0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03,
            0x0c60, 0x1c41, 0xedae, 0xfd8f, 0xcdec, 0xddcd,
            0xad2a, 0xbd0b, 0x8d68, 0x9d49, 0x7e97, 0x6eb6,
            0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
            0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a,
            0x9f59, 0x8f78, 0x9188, 0x81a9, 0xb1ca, 0xa1eb,
            0xd10c, 0xc12d, 0xf14e, 0xe16f, 0x1080, 0x00a1,
            0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
            0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c,
            0xe37f, 0xf35e, 0x02b1, 0x1290, 0x22f3, 0x32d2,
            0x4235, 0x5214, 0x6277, 0x7256, 0xb5ea, 0xa5cb,
            0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
            0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447,
            0x5424, 0x4405, 0xa7db, 0xb7fa, 0x8799, 0x97b8,
            0xe75f, 0xf77e, 0xc71d, 0xd73c, 0x26d3, 0x36f2,
            0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
            0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9,
            0xb98a, 0xa9ab, 0x5844, 0x4865, 0x7806, 0x6827,
            0x18c0, 0x08e1, 0x3882, 0x28a3, 0xcb7d, 0xdb5c,
            0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
            0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0,
            0x2ab3, 0x3a92, 0xfd2e, 0xed0f, 0xdd6c, 0xcd4d,
            0xbdaa, 0xad8b, 0x9de8, 0x8dc9, 0x7c26, 0x6c07,
            0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
            0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba,
            0x8fd9, 0x9ff8, 0x6e17, 0x7e36, 0x4e55, 0x5e74,
            0x2e93, 0x3eb2, 0x0ed1, 0x1ef0];
            
        var crc = 0xFFFF;
        var j, i;
    
    
        for (i = 0; i < this.emvString.length; i++) {
            var c = this.emvString.charCodeAt(i);
            if (c > 255) {
                throw new RangeError();
            }
            j = (c ^ (crc >> 8)) & 0xFF;
            crc = crcTable[j] ^ (crc << 8);
        }

        this.crc16 = ((crc ^ 0) & 0xFFFF);

        var crc16string = Number(this.crc16).toString(16).toUpperCase();

        while(crc16string.length < 4){
            let zero = '0';
            crc16string = zero.concat(crc16string);
        }

        this.qrCode = this.emvString + crc16string;
    }

    printQrCode(){
        this.qrCodeSource = 'https://chart.googleapis.com/chart?cht=qr&chs=200x200&chl=' + this.qrCode;

        this.qrCodeVisibility = 'show';
        this.spinnerVisibility = 'hide';
    }

    createLogIntegracao(){
        let errorTitle = 'Ocorreu um erro na criação do Log de Integração.';
        let rowString = JSON.stringify(this.row);
        let resultString = JSON.stringify(this.integrationPixResult);

        createLogIntegracao({   cobrancaString          : rowString, 
                                resultWrapperString     : resultString,
                                qrCode                  : this.qrCode,
                                txId                    : this.txId,
                                integrationSuccessful   : this.integrationSuccess})
        .then(result =>{
            if(result){
                this.logIntegracaoId = result;
            }else{
                this.showToast(errorTitle, this.errorPrevisulMsg, 'error', 'sticky');
            }
        })
        .catch(error =>{
            this.showToast(errorTitle, this.errorPrevisulMsg, 'error', 'sticky');
            console.log('Erro na chamada do método createLogIntegracao: ');
            console.log(error);
        })
    }

    copyToClipboard(){
        let pixNumber = this.template.querySelector('.copyPix');
        pixNumber.select();
        pixNumber.setSelectionRange(0, 9999999);

        document.execCommand('copy');
        this.showToast('O código foi copiado para a área de transferência.', '', 'info', 'pester');
    }

    handleCheckboxEmail(event){
        this.changeVisibility = event.target.checked;
    }

    handleEmailChange(event){
        this.email = event.target.value;
        this.validateEmail(this.email);
    }

    validateEmail(email){
        var regex = /\S+@\S+\.\S+/;
        if(email.match(regex)){
            this.disableSendBtn = false;
        }else{
            this.disableSendBtn = true;
        }
    }

    sendEmail(){
        sendEmail({ emailAddress    :   this.email,
                    logIntegracaoId :   this.logIntegracaoId,
                    isNewPixRequest :   this.isNewPixRequest,
                    numeroContrato  :   this.numeroContrato    })
            .then(result =>{
                if(result == ''){
                    this.showToast('O QRCode foi enviado para seu e-mail com sucesso.', '', 'success', 'pester');
                }else{
                    this.showToast('Ocorreu o seguinte erro no envio do QRCode:', result, 'error', 'sticky');
                }
            })
            .catch(error =>{
                this.showToast('Ocorreu um erro no envio do QRCode.', this.errorPrevisulMsg, 'error', 'sticky');
                console.log('Erro na chamada do método sendEmail: ');
                console.log(error);
            })
    }

    showToast(title, message, variant, mode){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    close(){
        this.dispatchEvent(new CustomEvent('close'));
    }
}