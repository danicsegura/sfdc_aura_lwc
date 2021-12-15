/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15366 - Classe de teste para a classe AccountLimiteCreditoService
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		26/10/2021		Created		Classe de teste para a classe AccountLimiteCreditoService
**************************************************************************************************************************************************/
@isTest
public class AccountLimiteCreditoServiceTest {
	@isTest
    static void calloutTest(){
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new AccountLimiteCreditoMock());
            AccountLimiteCreditoWrapper response = AccountLimiteCreditoService.callService('12345678912345');
        Test.stopTest();
        
		System.assertEquals('15366', response.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.ContaCliente);
        System.assertEquals('12345678912345', response.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.CNPJ);
        System.assertEquals('30/10/2020', response.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.VerificacaoSeguinte);
    }
}