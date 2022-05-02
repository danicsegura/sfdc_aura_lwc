/*************************************************************************************************************************************************
* Copyright © 2022 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 17299 - Testar a execução dos métodos da classe ConsultaTitulosFinanceirosService
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		11/04/2022		Created		Versão inicial
**************************************************************************************************************************************************/
@isTest
public class ConsultaTitulosFinanceirosServiceTest {

    /***************************************************************************************************************************************************
    * 		Purpose: US 17299 - Testar a execução do método callService
    * 		Parameters: -
    * 		Returns: void
    * 		Throws -
    * History
    * --------
    * VERSION 		AUTHOR 				DATE 		DETAIL 		Description
    * 1.0 			Daniela Segura     	11/04/2022 	Created 	Versão inicial
    ***************************************************************************************************************************************************/

    @isTest
    static void callServiceTest(){

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ConsultaTitulosFinanceirosMock());
            TitulosFinanceirosWrapper response = ConsultaTitulosFinanceirosService.callService('CNPJ', '03447202111111', '2022-03-20', '2022-04-20', 'DataVencimento');
        Test.stopTest();
        
        System.assertEquals('0000005617', response.RetornoConsultaDebitosCentroLucro.Debitos.get(0).CodigoCliente);
        System.assertEquals(true, response.StatusExecucao.ExecutadaCorretamente);

    }
}