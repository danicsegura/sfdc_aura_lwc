/********************************************************************************************************************************
* 2021 - Previsul 
* ===============================================================================================================================
* Purpose: Classe controller para o LWC pagamentoPix
* ===============================================================================================================================
* History
* -------
* VERSION   AUTHOR              DATE            DETAIL      Description
* 1.0       Daniela Segura      22/12/2021      Created     Versão inicial
*********************************************************************************************************************************/
public without sharing class PagamentoPixLwcController {

    /*************************************************************************************************************************************
    *	Purpose: Validar a solicitação de geração de novo PIX (verifica de deve gerar novo PIX ou imprimir um PIX ainda válido)
    *	Parameters: String cobrancaString
    *	Returns: Boolean
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      22/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    @AuraEnabled
    public static Boolean validateNewPixRequest(String cobrancaString){
        Boolean validNewRequest = true;
        PagamentoPixReturnWrapper resultWrapper = new PagamentoPixReturnWrapper();
        IntegrationServiceUltimosPag.returnPagamentoVencidos cobranca = (IntegrationServiceUltimosPag.returnPagamentoVencidos)JSON.deserialize(cobrancaString, IntegrationServiceUltimosPag.returnPagamentoVencidos.class); 

        String docCobranca = cobranca.fatura;
        Datetime currentDateTime = Datetime.now();

        List<LogIntegracao__c> lstLogIntegracao = [SELECT Id, Status__c, DataExpiracaoQRCode__c, NumeroContrato__c FROM LogIntegracao__c WHERE NumeroContrato__c =: docCobranca];
        
        for(LogIntegracao__c varLogIntegracao : lstLogIntegracao){
            if(varLogIntegracao.DataExpiracaoQRCode__c >= currentDateTime && varLogIntegracao.Status__c == 'Ativo'){
                validNewRequest = false;
            }
        }

        return validNewRequest;
    }

    /*************************************************************************************************************************************
    *	Purpose: Gerar string utilizada para cálculo do CRC16-CCIT
    *	Parameters: String payloadLocation, String transactionAmount
    *	Returns: String
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      27/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    @AuraEnabled
    public static String getFieldsValuesString(String payloadLocation, String transactionAmount){
        String fieldsValuesString = '';
        List<QrCodeElement> lstQrCodeElements = new List<QrCodeElement>();

        QrCodeElement gui = new QrCodeElement('GUI', '00', '14', 'br.gov.bcb.pix');
        QrCodeElement payloadLocationField = new QrCodeElement('Payload Location', '25', String.valueOf(payloadLocation.length()), payloadLocation);

        QrCodeElement merchantAccountInformation = new QrCodeElement();
        Integer merchantAccInfoSize = Integer.valueOf(gui.tamanho) + 4 + Integer.valueOf(payloadLocationField.tamanho) + 4;

        merchantAccountInformation.nome = 'Merchant Account Information';
        merchantAccountInformation.id = '26';
        merchantAccountInformation.tamanho = String.valueOf(merchantAccInfoSize);
        merchantAccountInformation.valor = '';

        QrCodeElement transactionAmountField = new QrCodeElement();
        String transactionAmountLength = String.valueOf(transactionAmount.length());
        if(transactionAmountLength.length() < 2){
            transactionAmountLength = '0' + transactionAmountLength;
        }

        transactionAmountField.nome = 'Transaction Amount';
        transactionAmountField.id = '54';
        transactionAmountField.tamanho = transactionAmountLength;
        transactionAmountField.valor = transactionAmount;

        lstQrCodeElements.add(new QrCodeElement('Payload Format Indicator', '00', '02', '01'));
        lstQrCodeElements.add(new QrCodeElement('Point of Initiation Method', '01', '02', '12'));
        lstQrCodeElements.add(merchantAccountInformation);
        lstQrCodeElements.add(gui);
        lstQrCodeElements.add(payloadLocationField);
        lstQrCodeElements.add(new QrCodeElement('Merchant Category Code', '52', '04', '0000'));
        lstQrCodeElements.add(new QrCodeElement('Transaction Currency', '53', '03', '986'));
        lstQrCodeElements.add(transactionAmountField);
        lstQrCodeElements.add(new QrCodeElement('Country Code', '58', '02', 'BR'));
        lstQrCodeElements.add(new QrCodeElement('Merchant Name', '59', '08', 'PREVISUL'));
        lstQrCodeElements.add(new QrCodeElement('Merchant City', '60', '09', 'SAO PAULO'));
        lstQrCodeElements.add(new QrCodeElement('Additional Data Field Template', '62', '07', ''));
        lstQrCodeElements.add(new QrCodeElement('Reference Label', '05', '03', '***'));
        lstQrCodeElements.add(new QrCodeElement('CRC16-CCIT', '63', '04', ''));
            
        for(QrCodeElement varCrcField : lstQrCodeElements){
            fieldsValuesString += varCrcField.id + varCrcField.tamanho + varCrcField.valor;
        }

        return fieldsValuesString;
    }
    
    public class QrCodeElement{
        String id;
        String tamanho;
        String nome;
        String valor; 

        public QrCodeElement(){
        }

        public QrCodeElement(String nome, String id, String tamanho, String valor){
            this.id = id;
            this.tamanho = tamanho;
            this.nome = nome;
            this.valor = valor;
        }
    }

    /*************************************************************************************************************************************
    *	Purpose: Criar registro no objeto LogIntegracao__c com o resultado da integração de geração de PIX
    *	Parameters: String cobrancaString, String resultWrapperString, String qrCode, String txId, Boolean integrationSuccessful
    *	Returns: String
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      22/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    @AuraEnabled
    public static String createLogIntegracao(String cobrancaString, String resultWrapperString, String qrCode, String txId, Boolean integrationSuccessful){
        String logIntegracaoId;
        String cpfSegurado;
        Decimal identificadorSequencial = 1;
        IntegrationServiceUltimosPag.returnPagamentoVencidos cobranca = (IntegrationServiceUltimosPag.returnPagamentoVencidos)JSON.deserialize(cobrancaString, IntegrationServiceUltimosPag.returnPagamentoVencidos.class);      

        List<User> lstUser = [SELECT CPF__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(!lstUser.isEmpty() && String.isNotBlank(lstUser.get(0).CPF__c)){
            cpfSegurado = lstUser.get(0).CPF__c;
        }

        List<LogIntegracao__c> lstLogIntegracao = [SELECT Identificador_sequencial__c FROM LogIntegracao__c ORDER BY Identificador_sequencial__c DESC];

        if(!lstLogIntegracao.isEmpty() && lstLogIntegracao.get(0).Identificador_sequencial__c != null){
            identificadorSequencial = lstLogIntegracao.get(0).Identificador_sequencial__c + 1;
        }

        LogIntegracao__c logIntegracao = new LogIntegracao__c();
        logIntegracao.Apolice__c = cobranca.apolice;
        logIntegracao.NumeroContrato__c = cobranca.fatura;
        logIntegracao.DataVencOriginal__c = Date.parse(cobranca.dtVencimento);
        logIntegracao.DvRequisicaoSucesso__c = integrationSuccessful;
        logIntegracao.RecordTypeId = Schema.SObjectType.LogIntegracao__c.getRecordTypeInfosByDeveloperName().get('PIX').getRecordTypeId();
        logIntegracao.CPFSegurado__c = (String.isNotBlank(cpfSegurado)) ? cpfSegurado : '';
        logIntegracao.Identificador_sequencial__c = identificadorSequencial;
        logIntegracao.Valor__c = Double.valueOf(cobranca.valor);

        PagamentoPixReturnWrapper resultWrapper = PagamentoPixReturnWrapper.parse(resultWrapperString);
        String dataCriacao;

        dataCriacao = resultWrapper?.dataCriacao?.replace('T', ' ').replace('Z', '');

        if(integrationSuccessful){
            logIntegracao.Status__c = 'Ativo';
            logIntegracao.TxId__c = txId;
            logIntegracao.QRCodePIX__c = qrCode;

            if(dataCriacao != null){
                logIntegracao.DataVencNova__c = Datetime.valueOf(dataCriacao).addDays(2);
                logIntegracao.DataExpiracaoQRCode__c = Datetime.valueOf(dataCriacao).addDays(2);
            }
            
            if(resultWrapper?.parcela?.numeroParcela != null){
                logIntegracao.Parcela__c = resultWrapper.parcela.numeroParcela;
            }
        }else{
            logIntegracao.ErroRequisicao__c = resultWrapper.message != null ? resultWrapper.message : 'Mensagem de erro não encontrada.';
            logIntegracao.Status__c = 'Erro na geração do PIX';
        }

        try{
            insert logIntegracao;
            logIntegracaoId = logIntegracao.Id;
        }catch(DmlException ex){
            System.debug('Classe: PagamentoPixLwcController. Erro ao tentar inserir Log de Integração: ' + ex);
        }

        return logIntegracaoId;
    }

    /*************************************************************************************************************************************
    *	Purpose: Enviar email com dados do PIX
    *	Parameters: String emailAddress, String logIntegracaoId, Boolean isNewPixRequest, String numeroContrato
    *	Returns: Boolean
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      22/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    @AuraEnabled
    public static String sendEmail(String emailAddress, String logIntegracaoId, Boolean isNewPixRequest, String numeroContrato){
        String errorMessage = '';

        if(emailAddress == null || (isNewPixRequest && logIntegracaoId == null)){
            errorMessage = 'Parâmetros inválidos';
            return errorMessage;
        }

        EmailTemplate emailTemplate = [SELECT Id
                                        FROM EmailTemplate 
                                        WHERE DeveloperName = 'EnvioPIXViaEMail'];

        List<Contact> lstContact = new List<Contact>();
        List<User> lstUser = [SELECT CPF__c FROM User WHERE Id =: UserInfo.getUserId()];
        if(!lstUser.isEmpty()){
            lstContact = [SELECT Id FROM Contact WHERE CPF__c =: lstUser.get(0).CPF__c LIMIT 1];
        }

        if(lstContact.isEmpty() || lstContact == null){
            errorMessage = 'Usuário não encontrado';
            return errorMessage;
        }

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        List<LogIntegracao__c> lstLogIntegracao = new List<LogIntegracao__c>();
        if(!isNewPixRequest){
            lstLogIntegracao = [SELECT Id FROM LogIntegracao__c WHERE NumeroContrato__c =: numeroContrato AND Status__c = 'Ativo' LIMIT 1];
            
            if(lstLogIntegracao.isEmpty()){
                errorMessage = 'Pix não encontrado para reimpressão.';
                return errorMessage;
            }

            message.setWhatId(lstLogIntegracao.get(0).Id);
        }else if(String.isNotBlank(logIntegracaoId)){
            message.setWhatId(logIntegracaoId);
        }
        
        message.setTemplateId(emailTemplate.Id);
        message.setTargetObjectId(lstContact.get(0).Id);
        message.setToAddresses(new String[] {emailAddress});
        message.setReplyTo('naoresponda@previsul.com.br');
        message.setSenderDisplayName('Previsul Seguradora');
        message.setSaveAsActivity(false);

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};

        try{
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

            if(!results[0].isSuccess()){
                errorMessage = results[0].errors[0].message;
                System.debug('Erro no envio do email: ' + errorMessage);
            }
        }catch(EmailException ex){
            errorMessage = ex.getMessage();
            System.debug('Erro no envio do email: ' + ex);
        }

        return errorMessage;

    }
}