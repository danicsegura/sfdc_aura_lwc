/******************************************************************************************************************************************
 * Copyright © 2021 BR Distribuidores
 * ========================================================================================================================================
 * Purpose: Classe de teste para a classe batch AccountUpdateCentroDeLucroBatch
 * ========================================================================================================================================
 * History
 * -------
 * VERSION      AUTHOR              DATE           DETAIL      Description
 * 1.0          Daniela Segura      16/11/2021     Created     Versão Inicial
 ******************************************************************************************************************************************/
@isTest
private class AccountUpdateCentroDeLucroBatchTest {
	@testSetup
    static void testSetup(){
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('AreaDeVendasTriggerHandler');
        TriggerHandler.bypass('CentroDeLucroTriggerHandler');

        Account account = TestSetup.getAccount('Test Account', true);

        List<User> lstUsers = TestSetup.getUsers(2, true);

        Equipe_De_Vendas__c equipeVendas = TestSetup.getEquipeDeVendas('COD', true);
        
        Centro_De_Lucro__c centroLucro1 = TestSetup.getCentroDeLucro('CL001', 'COD001', lstUsers.get(0).Id, equipeVendas.Id, true);
        Centro_De_Lucro__c centroLucro2 = TestSetup.getCentroDeLucro('CL002', 'COD002', lstUsers.get(1).Id, equipeVendas.Id, true);

        Area_De_Vendas__c areaVendasAviacao = TestSetup.getAreaDeVendas(account.Id, centroLucro2.Id, '2001', '10', '03', true);
        Area_De_Vendas__c areaVendasExtra = TestSetup.getAreaDeVendas(account.Id, centroLucro1.Id, '2001', '10', '09', true);
        Area_De_Vendas__c areaVendasPrincipal = TestSetup.getAreaDeVendas(account.Id, centroLucro1.Id, '2001', '10', '02', true);

        TriggerHandler.clearAllBypasses();
    }
    
    @isTest
    static void testBatch(){
        Set<Id> setAccountId = new Map<Id, Account>([SELECT Id FROM Account]).keySet();

        Test.startTest();
            AccountUpdateCentroDeLucroBatch batch = new AccountUpdateCentroDeLucroBatch(setAccountId);
            Database.executeBatch(batch);
        Test.stopTest();

        List<Centro_De_Lucro__c> lstCentroLucro = [SELECT Id FROM Centro_De_Lucro__c ORDER BY Name];
        Account updatedAccount = [SELECT Centro_de_Lucro_Principal__c, Centro_de_Lucro_Avia_o__c FROM Account LIMIT 1];

        System.assertEquals(lstCentroLucro.get(0).Id, updatedAccount.Centro_de_Lucro_Principal__c);
        System.assertEquals(lstCentroLucro.get(1).Id, updatedAccount.Centro_de_Lucro_Avia_o__c);
    }
}