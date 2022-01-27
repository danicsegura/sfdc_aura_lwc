/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15365 - Classe de teste para a classe ConsultaPedidosService
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		26/11/2021		Created		Versão inicial
**************************************************************************************************************************************************/
@isTest
public class ConsultaPedidosServiceTest {
	@isTest
    static void calloutTest(){
        
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ConsultaPedidosMock());
            ConsultaPedidosWrapper response = ConsultaPedidosService.callService('19105', 15);
        Test.stopTest();
        
		System.assertEquals('19105', response.RetornoConsultaOrdemVendaDetalhada.OrdensVenda.get(0).Emissor);
        System.assertEquals('2019-11-25', response.RetornoConsultaOrdemVendaDetalhada.OrdensVenda.get(0).DataEntrega);
    }
}