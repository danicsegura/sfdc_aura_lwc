/********************************************************************************************************************************
* 2021 - Previsul 
* ===============================================================================================================================
* Purpose: Classe que realiza a integração para geração de PIX
* ===============================================================================================================================
* History
* -------
* VERSION   AUTHOR              DATE            DETAIL      Description
* 1.0       Daniela Segura      22/12/2021      Created     Versão inicial
*********************************************************************************************************************************/
public without sharing class IntegrationServicePagamentoPix {
    private static IntegrationServiceUltimosPag.returnPagamentoVencidos cobranca = new IntegrationServiceUltimosPag.returnPagamentoVencidos();
    private static String tokenError;

    /*************************************************************************************************************************************
    *	Purpose: Chamar serviço para geração de novo PIX
    *	Parameters: String cobrancaString
    *	Returns: PagamentoPixReturnWrapper
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      22/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    @AuraEnabled
    public static PagamentoPixReturnWrapper callServiceNewPix(String cobrancaString) {
        PagamentoPixReturnWrapper result = new PagamentoPixReturnWrapper();
        String accessToken = getToken();
        Boolean integrationSuccessful = false;
        cobranca = (IntegrationServiceUltimosPag.returnPagamentoVencidos)JSON.deserialize(cobrancaString, IntegrationServiceUltimosPag.returnPagamentoVencidos.class); 

        if(accessToken != ''){
            String body = generateBody('newPix');
            if(body == null){
                return result;
            }

            Servicos__mdt servico = [SELECT Id, Metodo__c, Timeout__c, Endpoint__c, Service_Name__c, Body__c  FROM Servicos__mdt WHERE MasterLabel = 'PIXGeracaoHM'];
            Autenticao_Previsul__mdt autenticacao = [SELECT client_id__c, client_secret__c FROM Autenticao_Previsul__mdt WHERE MasterLabel = 'PIXGeracaoAuthHM'];
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setMethod(servico.Metodo__c);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader(autenticacao.client_id__c, autenticacao.client_secret__c);
            request.setBody(body);
            request.setTimeout(Integer.valueOf(servico.Timeout__c));
            request.setEndpoint(servico.Endpoint__c);

             try{
                HttpResponse response = http.send(request);
                if(response.getStatusCode() == 200 && !String.isBlank(response.getBody())){
                    result = PagamentoPixReturnWrapper.parse(response.getBody());
                    integrationSuccessful = true;
                }else if(response.getStatusCode() == 400 && !String.isBlank(response.getBody())){
                    result = PagamentoPixReturnWrapper.parse(response.getBody());
                    integrationSuccessful = false;
                }else if(response.getStatusCode() == 401){
                    result.message = 'Não autorizado. Credenciais inválidas.';
                    integrationSuccessful = false;
                }else if(response.getStatusCode() == 500){
                    result.message = 'CNPJ não configurado no para realizar esta operação.';
                    integrationSuccessful = false;
                }else{
                    integrationSuccessful = false;

                    if(!String.isBlank(response.getBody())){
                        try{
                            result = PagamentoPixReturnWrapper.parse(response.getBody());
                        }catch(Exception e){
                            result.message = 'Status do erro: ' + String.valueOf(response.getStatusCode());
                        }

                    }
                }
            }catch(CalloutException e){
               result.message = 'Erro ao tentar gerar o PIX: ' + e.getMessage();
            }
        }else{
            result.message = tokenError != null ? tokenError : 'Erro na geração do Token.';
        }

        return result;
    }

    /*************************************************************************************************************************************
    *	Purpose: Chamar serviço para impressão de Pix anteriormente gerado
    *	Parameters: String cobrancaString
    *	Returns: PagamentoPixReturnWrapper
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      05/01/2022		Created 	Versão inicial
    **************************************************************************************************************************************/
    @AuraEnabled
    public static PagamentoPixReturnWrapper callServiceReimpressao(String cobrancaString){
        PagamentoPixReturnWrapper result = new PagamentoPixReturnWrapper();
        String accessToken = getToken();
        Boolean integrationSuccessful = false;
        cobranca = (IntegrationServiceUltimosPag.returnPagamentoVencidos)JSON.deserialize(cobrancaString, IntegrationServiceUltimosPag.returnPagamentoVencidos.class); 

        if(accessToken != ''){
            String body = generateBody('reimpressao');
            if(body == null){
                return result;
            }
            
            Servicos__mdt servico = [SELECT Id, Metodo__c, Timeout__c, Endpoint__c, Service_Name__c, Body__c  FROM Servicos__mdt WHERE MasterLabel = 'PIXImpressaoHM'];
            Autenticao_Previsul__mdt autenticacao = [SELECT client_id__c, client_secret__c FROM Autenticao_Previsul__mdt WHERE MasterLabel = 'PIXGeracaoAuthHM'];
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setMethod(servico.Metodo__c);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader(autenticacao.client_id__c, autenticacao.client_secret__c);
            request.setBody(body);
            request.setTimeout(Integer.valueOf(servico.Timeout__c));
            request.setEndpoint(servico.Endpoint__c);

            try{
                HttpResponse response = http.send(request);
                if(response.getStatusCode() == 200 && !String.isBlank(response.getBody())){
                    result = PagamentoPixReturnWrapper.parse(response.getBody());
                    integrationSuccessful = true;
                }else{
                    integrationSuccessful = false;
                    try{
                        result = PagamentoPixReturnWrapper.parse(response.getBody());
                        if(String.IsBlank(result.message)){
                            result.message = result.moreInformation;
                        }
                    }catch(Exception e){
                        result.message = 'Status do erro: ' + String.valueOf(response.getStatusCode());
                    }                  
                }
            }catch(CalloutException e){
               result.message = 'Erro ao tentar reimprimir o PIX: ' + e.getMessage();
            }
        }else{
            result.message = tokenError != null ? tokenError : 'Erro na geração do Token.';
        }

        return result;
    }

    /*************************************************************************************************************************************
    *	Purpose: Chamar serviço para geração do access token
    *	Parameters: 
    *	Returns: String
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      22/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    public static String getToken(){
        String accessToken;
        Servicos__mdt servico = [SELECT Id, Metodo__c, Timeout__c, Endpoint__c, Service_Name__c, Body__c  FROM Servicos__mdt WHERE MasterLabel = 'PIXAccessTokenHM'];
        Autenticao_Previsul__mdt autenticacao = [SELECT client_id__c, client_secret__c  FROM Autenticao_Previsul__mdt WHERE MasterLabel = 'PIXAccessTokenAuthHM'];
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        Blob headerValue = Blob.valueOf(autenticacao.client_id__c + ':' + autenticacao.client_secret__c);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
        request.setMethod(servico.Metodo__c);
        request.setBody(servico.Body__c);
        request.setEndpoint(servico.Endpoint__c);

        try{
            HttpResponse response = http.send( request );
            if(response.getStatusCode() == 200 && !String.isBlank(response.getBody())){
                IntegrationConnectUltimosPag.JsonResponse jresp = (IntegrationConnectUltimosPag.JsonResponse)JSON.deserialize(response.getBody(), IntegrationConnectUltimosPag.JsonResponse.class);
                accessToken = jresp.access_token;

            }else {
                accessToken = '';
                tokenError = 'Erro na geração do token. Status:  ' + response.getStatusCode();
            }
        }catch(CalloutException e){
            accessToken = '';
            tokenError = 'Erro na geração do token: ' + e.getMessage();
        }

        return accessToken;
    }

    /*************************************************************************************************************************************
    *	Purpose: Gerar o corpo da requisição para geração de PIX
    *	Parameters: 
    *	Returns: String
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      22/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    private static String generateBody(String serviceName){
        String txId = '';
        String body, userCpf;
        List<User> lstUser = [SELECT CPF__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(!lstUser.isEmpty() && String.isNotBlank(lstUser.get(0).CPF__c)){
            userCpf = lstUser.get(0).CPF__c;
        }

        JSONGenerator json = JSON.createGenerator(true);

        if(serviceName == 'newPix'){
            Informacoes_Empresa_Previsul__mdt infoEmpresa = [SELECT CNPJ__c, Nome__c  FROM Informacoes_Empresa_Previsul__mdt WHERE MasterLabel = 'Previsul'];
            txId = generateTxId();
            Double valor = Double.valueOf(cobranca.valor);
            String dataCobranca = System.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            String userName = UserInfo.getName();

            json.writeStartObject();
            json.writeFieldName('identificacao');
            json.writeStartObject();
            json.writeStringField('codigoNegocio', '0');
            json.writeEndObject();
            
            json.writeFieldName('produto');
            json.writeStartObject();
            json.writeStringField('codigoProdutoNegocio', infoEmpresa.Nome__c);
            json.writeStringField('cnpjEmpresa', infoEmpresa.CNPJ__c);
            json.writeEndObject();
            
            json.writeNumberField('valor', valor);
            
            json.writeFieldName('pix');
            json.writeStartObject();
            json.writeStringField('txId', txId);
            json.writeEndObject();
            
            json.writeStringField('dataCobranca', dataCobranca);
            
            json.writeFieldName('pagador');
            json.writeStartObject();
            json.writeStringField('nome', userName);
            json.writeStringField('cpfCnpj', userCpf);
            json.writeEndObject();
            json.writeEndObject();

            body = json.getAsString();
    
        }else if(serviceName == 'reimpressao'){
            List<LogIntegracao__c> lstLogIntegracao = [SELECT TxId__c 
                                                        FROM LogIntegracao__c 
                                                        WHERE NumeroContrato__c =: cobranca.fatura 
                                                        AND Status__c = 'Ativo' 
                                                        ORDER BY CreatedDate DESC 
                                                        LIMIT 1];
            
            if(lstLogIntegracao.isEmpty()){
                return body;
            }

            txId = lstLogIntegracao.get(0).TxId__c;

            json.writeStartObject();
            json.writeFieldName('pix');
            json.writeStartObject();
            json.writeStringField('txId', txId);
            json.writeEndObject();
            json.writeFieldName('pagador');
            json.writeStartObject();
            json.writeStringField('cpfCnpj', userCpf);
            json.writeEndObject();
            json.writeEndObject();

            body = json.getAsString();
        }

        System.debug('$$$ json: ' + body);

        return body;
    }

    /*************************************************************************************************************************************
    *	Purpose: Gerar o código txId utilizado no corpo da requisição
    *	Parameters: 
    *	Returns: String
	*
    * History
    * --------
    * VERSION   AUTHOR 			    DATE 			DETAIL 		Description
    * 1.0 	    Daniela Segura      22/12/2021 		Created 	Versão inicial
    **************************************************************************************************************************************/
    private static String generateTxId(){
        String txId;
        Decimal identificadorSequencial = 1;

        List<LogIntegracao__c> lstLogIntegracao = [SELECT Identificador_sequencial__c FROM LogIntegracao__c ORDER BY Identificador_sequencial__c DESC];

        if(!lstLogIntegracao.isEmpty() && lstLogIntegracao.get(0).Identificador_sequencial__c != null){
            identificadorSequencial = lstLogIntegracao.get(0).Identificador_sequencial__c + 1;
        }

        if(cobranca.fatura != null){
            txId = 'C001' + cobranca.fatura + String.valueOf(System.now()).replaceAll('\\D+', '') + String.valueOf(identificadorSequencial);

            if(txId.length() < 31){
                Integer currentLength = txId.length();
                Integer diff = 31 - currentLength;
                String txIdTemp = txId.removeEnd(String.valueOf(identificadorSequencial));

                for(Integer i = 0; i < diff; i++){
                    txIdTemp = txIdTemp + '0';
                }

                txIdTemp = txIdTemp + String.valueOf(identificadorSequencial);
                txId = txIdTemp;
            }
        }

        return txId;
    }
}