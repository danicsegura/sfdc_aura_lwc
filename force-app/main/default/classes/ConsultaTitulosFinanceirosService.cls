/*************************************************************************************************************************************************
* Copyright © 2022 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 17299 - Classe que realiza a integração de consulta do títulos financeiros da Conta
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		11/04/2022		Created		Versão inicial
**************************************************************************************************************************************************/
public with sharing class ConsultaTitulosFinanceirosService {

    private static String ENDPOINT;
    private static String AUTH_KEY;
    private static String AUTH_VALUE;
    
    /***************************************************************************************************************************************************
    * 		Purpose: US 17299 - Realiza a chamada da integração dos títulos financeiros
    * 		Parameters: String documentType, String document, String startDate, String endDate, String dateFilter
    * 		Returns: void
    * 		Throws -
    * History
    * --------
    * VERSION 		AUTHOR 				DATE 		DETAIL 		Description
    * 1.0 			Daniela Segura     	11/04/2022 	Created 	Versão inicial
    ***************************************************************************************************************************************************/

    @AuraEnabled(cacheable=true)
    public static TitulosFinanceirosWrapper callService(String documentType, String document, String startDate, String endDate, String dateFilter){
        TitulosFinanceirosWrapper titulos = new TitulosFinanceirosWrapper();

        if(String.isBlank(document) || documentType == 'Estrangeiro'){
            return titulos;
        }

        String body = getBody(documentType, document, startDate, endDate, dateFilter);
        getIntegrationInfo();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setHeader(AUTH_KEY, AUTH_VALUE);
        req.setBody(body);
        req.setMethod('POST');

        Http http = new Http();
        HttpResponse response = http.send(req);
        System.debug('ConsultaTitulosFinanceirosService - response: ' + response.getBody());

        try{
            titulos = TitulosFinanceirosWrapper.parse(response.getBody());
        }catch(Exception ex){
            System.debug('Erro no parse response: ' + ex.getMessage());
        }
        
        if(response.getStatusCode() != 200){
            System.debug('Erro na integração dos Títulos Financeiros.');
            System.debug('Class: ConsultaTitulosFinanceirosService. Status: ' + response.getStatusCode() + ' ' + response.getStatus());
        }
        
        return titulos;
    }

    /***************************************************************************************************************************************************
    * 		Purpose: US 17299 - Constrói o JSON para a solicitação da integração
    * 		Parameters: String documentType, String document, String startDate, String endDate, String dateFilter
    * 		Returns: void
    * 		Throws -
    * History
    * --------
    * VERSION 		AUTHOR 				DATE 		DETAIL 		Description
    * 1.0 			Daniela Segura     	11/04/2022 	Created 	Versão inicial
    ***************************************************************************************************************************************************/

    public static String getBody(String documentType, String document, String startDate, String endDate, String dateFilter){
        JSONGenerator json = JSON.createGenerator(true);
        json.writeStartObject();

        if(documentType == 'CNPJ'){
            json.writeStringField('Cnpj', document.left(8));
        }else if(documentType == 'CPF'){
            json.writeStringField('Cpf', document);
        }else{
            return '';
        }

        json.writeStringField(dateFilter + 'Inicio', startDate);
        json.writeStringField(dateFilter + 'Fim', endDate);
        json.writeEndObject();

        return json.getAsString();
    }

    /***************************************************************************************************************************************************
    * 		Purpose: US 17299 - Obtém as informações necessárias para a integração
    * 		Parameters: -
    * 		Returns: void
    * 		Throws -
    * History
    * --------
    * VERSION 		AUTHOR 				DATE 		DETAIL 		Description
    * 1.0 			Daniela Segura     	11/04/2022 	Created 	Versão inicial
    ***************************************************************************************************************************************************/

    public static void getIntegrationInfo(){
        String masterLabel = 'ConsultaTitulosFinanceirosPROD';
        Organization org = [SELECT IsSandbox FROM Organization];

        if(org.IsSandbox){
            masterLabel = 'ConsultaTitulosFinanceirosHOM';
        }

        Integration_Information__mdt integrationInfo = [SELECT Endpoint__c, Authentication__r.Username__c, Authentication__r.Password__c 
                                                                FROM Integration_Information__mdt 
                                                                WHERE MasterLabel = :masterLabel LIMIT 1];

        ENDPOINT 	= integrationInfo.Endpoint__c;
        AUTH_KEY 	= integrationInfo.Authentication__r.Username__c;
        AUTH_VALUE  = integrationInfo.Authentication__r.Password__c;

    }
}