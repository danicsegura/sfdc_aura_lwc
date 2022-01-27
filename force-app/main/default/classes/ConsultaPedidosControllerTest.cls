/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15365 - Classe de teste para a classe ConsultaPedidosController
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		16/12/2021		Created		Versão inicial
**************************************************************************************************************************************************/
@isTest
public class ConsultaPedidosControllerTest {
    
    @TestSetup
    static void testSetup(){
        TriggerHandler.bypass('AccountTriggerHandler');  

        Account testAccount = TestSetup.getAccount('Test Account', false);
        testAccount.Rua__c = 'Avenida Paulista';
        testAccount.CEP__c = '05464333';
        insert testAccount;

        TriggerHandler.clearAllBypasses();
    }

    @isTest
    static void getCodigoSapTest(){
        Account testAccount = [SELECT Codigo_SAP__c FROM Account LIMIT 1];

        Test.startTest();
            String returnedCodigoSap = ConsultaPedidosController.getCodigoSap(String.valueOf(testAccount.Id));
        Test.stopTest();

        System.assertEquals(testAccount.Codigo_SAP__c, returnedCodigoSap);
    }

    @isTest
    static void getEnderecoTest(){
        Account testAccount = [SELECT Rua__c, CEP__c, Codigo_SAP__c FROM Account LIMIT 1];

        Test.startTest();
            String returnedEndereco = ConsultaPedidosController.getEndereco(testAccount.Codigo_SAP__c);
        Test.stopTest();

        System.assert(returnedEndereco.contains(testAccount.Rua__c) && returnedEndereco.contains(testAccount.CEP__C));
        
    }

    @isTest
    static void getCodeToLabelReferencesTest(){
        List<ConsultaPedidosWrapper.DetalhesOrdemVenda> lstDetalhes = new List<ConsultaPedidosWrapper.DetalhesOrdemVenda>();
        
        ConsultaPedidosWrapper.DetalhesOrdemVenda detalhe = new ConsultaPedidosWrapper.DetalhesOrdemVenda();
        detalhe.CondicaoPagamento = 'BW00';
        lstDetalhes.add(detalhe);

        String detalhesString = JSON.serialize(lstDetalhes);

        Test.startTest();
        List<ConsultaPedidosWrapper.DetalhesOrdemVenda> returnedLstDetalhes = ConsultaPedidosController.getCodeToLabelReferences(detalhesString);
        Test.stopTest();

        String returnedCondicaoPagamento;
        for(ConsultaPedidosWrapper.DetalhesOrdemVenda varDetalhe : returnedLstDetalhes){
            returnedCondicaoPagamento = varDetalhe.CondicaoPagamento;
        }

        System.assertEquals('BW00 - À Vista, Títulos Migrados', returnedCondicaoPagamento);
    }
}