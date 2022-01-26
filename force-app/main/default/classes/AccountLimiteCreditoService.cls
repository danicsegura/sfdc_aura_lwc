/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15366 - Service class para consultar o limite de crédito da Conta
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		26/10/2021		Created		Classe responsável por conter os métodos de consulta ao limite de crédito da Conta.
**************************************************************************************************************************************************/
public class AccountLimiteCreditoService {
    
    @AuraEnabled
    public static AccountLimiteCreditoWrapper callService(String cnpj){ 
        String endpoint, key, value;
        
        Organization org = [SELECT IsSandbox FROM Organization];

        if(org.IsSandbox == true){
            Integration_Information__mdt integrationInfoSandbox = [SELECT Endpoint__c, Authentication__c 
                                                                   FROM Integration_Information__mdt 
                                                                   WHERE MasterLabel = 'AzureConsultaCreditoHOM' LIMIT 1];
            
            Authentication__mdt authInfo = [SELECT Username__c, Password__c 
                                            FROM Authentication__mdt 
                                            WHERE Id =:integrationInfoSandbox.Authentication__c LIMIT 1];
            
            endpoint 	= integrationInfoSandbox.Endpoint__c;
            key 		= authInfo.Username__c;
            value 		= authInfo.Password__c;
        }else{
            Integration_Information__mdt integrationInfoProd = [SELECT Endpoint__c, Authentication__c 
                                                                FROM Integration_Information__mdt 
                                                                WHERE MasterLabel = 'AzureConsultaCreditoPROD' LIMIT 1];
            
            Authentication__mdt authInfo = [SELECT Username__c, Password__c 
                                            FROM Authentication__mdt 
                                            WHERE Id =:integrationInfoProd.Authentication__c LIMIT 1];
            
            endpoint 	= integrationInfoProd.Endpoint__c;
            key 		= authInfo.Username__c;
            value 		= authInfo.Password__c;
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader(key, value);
        req.setBody('{ "CNPJ": "' + cnpj + '"}');
        req.setMethod('POST');

        Http http = new Http();
        HttpResponse response = http.send(req);
        
        AccountLimiteCreditoWrapper wrapperClass = AccountLimiteCreditoWrapper.parse(response.getBody());
        
        //remover zeros a esquerda
        if(wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.ContaCliente != null)
            wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.ContaCliente = String.valueOf(Integer.valueOf(wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.ContaCliente));
        
        //formatar data da Verificação Seguinte
        if(wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.VerificacaoSeguinte != null){
            String dia = wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.VerificacaoSeguinte.substringAfterLast('-');
            String mes = wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.VerificacaoSeguinte.substringAfter('-').substringBefore('-');
            String ano = wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.VerificacaoSeguinte.substringBefore('-');
			wrapperClass.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.VerificacaoSeguinte = dia + '/' + mes + '/' + ano;
        }
        
        return wrapperClass;
    }
}