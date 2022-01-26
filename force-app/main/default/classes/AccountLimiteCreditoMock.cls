/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15366 - Classe teste de mock utilizada pela classe de teste AccountLimiteCreditoServiceTest
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		26/10/2021		Created		Classe responsável por criar o mock utilizado na classe de teste
*																AccountLimiteCreditoServiceTest.
**************************************************************************************************************************************************/
@isTest
public class AccountLimiteCreditoMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"RetornoConsultaCreditoClienteCRM":{"AdministracoesCredito":{"ContaCliente":"0000015366","CNPJ":"12345678912345","LimiteCredito":892200150.33,"GrauEsgotamento":100.02,"DataHorizonte":"2021-10-27","TotalDividas":772081596.07,"CompromissoEspecial":0.00,"TotalValores":909276.63,"TotalCompromisso":772990872.70,"AdministracaoCredito":"Z06","GrupoCredito":"Z02S","VerificacaoSeguinte":"2020-10-30"}},"StatusExecucao":{"ExecutadaCorretamente":true}}');
        response.setStatusCode(200);
        return response; 
    }
}