/*******************************************************************************************************************************
 * Copyright © 2019 BR Distribuidores
 * =============================================================================================================================
 * Purpose: Testa os métodos da classe AreaDeVendasTriggerHandler
 * =============================================================================================================================
 * History
 * -------
 * VERSION      AUTHOR          DATE            DETAIL      Description
 * 1.0          Daniel Fehnle   25/06/2019      Created     Testa os métodos da classe AreaDeVendasTriggerHandler
 * 1.1          Daniel Fehnle   15/07/2019      Updated     ByPass na trigger de Equipe de Vendas
 *******************************************************************************************************************************/

@isTest
private class AreaDeVendasTriggerHandlerTest
{

    /******************************************************************************************************************************************
     * Purpose: Criar os dados de teste
     * Parameters: 
     * Returns: 
     * Throws -
     * 
     * History
     * --------
     * VERSION      AUTHOR          DATE            DETAIL      Description
     * 1.0          ???             ???             Created     Cria os dados de teste
     ******************************************************************************************************************************************/
    @testSetup
    static void testSetup()
    {
        System.debug('########## START AreaDeVendasTriggerHandlerTest.testSetup');

        CS_TriggerHandler__c csTriggerHandler = CS_TriggerHandler__c.getOrgDefaults();
        csTriggerHandler.BypassTriggerExecution__c = true;
        csTriggerHandler.SetupOwnerId = UserInfo.getUserId();
        upsert csTriggerHandler;

        Equipe_De_Vendas__c equipeVendas  = TestSetup.getEquipeDeVendas('GRPMG3', '642', '2021', true);
        Equipe_De_Vendas__c equipeVendas2 = TestSetup.getEquipeDeVendas('GRPDF', '646', '2022', true);
        Equipe_De_Vendas__c equipeVendas3 = TestSetup.getEquipeDeVendas('GRPDF2', '643', '2022', true);

        Centro_De_Lucro__c centroLucro  = TestSetup.getCentroDeLucro('CENTRO1', 'DAC0OCB000', UserInfo.getUserId(), equipeVendas.Id, true);
        Centro_De_Lucro__c centroLucro2 = TestSetup.getCentroDeLucro('CENTRO2', 'DAC0OCB001', UserInfo.getUserId(), equipeVendas2.Id, true);
        Centro_De_Lucro__c centroLucro3 = TestSetup.getCentroDeLucro('CENTRO3', 'DAC0OCB002', UserInfo.getUserId(), equipeVendas3.Id, true);
        
        Account varAccount = TestSetup.getAccount('Emissor01', false);
        varAccount.Codigo_SAP__c = 'TSTDTT';
        insert varAccount;

        Area_De_Vendas__c newAreaVendas = TestSetup.getAreaDeVendas(varAccount.Id, centroLucro.Id, '2002', '10', '03', true);

        Contract varContract = new Contract();
        varContract.AccountId = varAccount.Id;
        varContract.Data_De_Inicio_De_Aquisicao__c = Date.today().addMonths(1);
        varContract.StartDate = Date.today();
        varContract.EndDate = Date.today().addYears(1);
        varContract.RecordTypeId = Util.getRecordTypeIdbyName('Contract', 'DCVIM_CPCVM');        
        varContract.Centro_De_Lucro_Do_Contrato__c = centroLucro.Id;
        insert varContract; 

        Contract varContractB2B = new Contract();
        varContractB2B.AccountId = varAccount.Id;
        varContractB2B.Data_De_Inicio_De_Aquisicao__c = Date.today().addMonths(1);
        varContractB2B.StartDate = Date.today();
        varContractB2B.EndDate = Date.today().addYears(1);
        varContractB2B.RecordTypeId = Util.getRecordTypeIdbyName('Contract', 'DCB2B_CPCVM');        
        varContractB2B.Centro_De_Lucro_Do_Contrato__c = centroLucro.Id;
        insert varContractB2B;          
        
        Contract varSublocacao = varContract.clone(false,false,false,false);
        varSublocacao.Numero_Do_Contrato_Vinculado__c = varContract.Id;
        varSublocacao.Data_Efetiva_Da_Assinatura_Do_Contrato__c = null;
        varSublocacao.RecordTypeId = Util.getRecordTypeIdbyName('Contract', 'DCVIM_Sublocacao'); 
        insert varSublocacao;
        
        varContract.Status = 'Ativo';
        varSublocacao.Status = 'Ativo';
        varContractB2B.Status = 'Ativo';
        update new List<Contract>{varContract, varSublocacao, varContractB2B};
        
        csTriggerHandler.BypassTriggerExecution__c = false;
        upsert csTriggerHandler;        

        System.debug('########## END AreaDeVendasTriggerHandlerTest.testSetup');
    }

    @isTest
    static void upsertNewAreaDeVendas()
    {
        System.debug('########## START AreaDeVendasTriggerHandlerTest.upsertNewAreaDeVendas');

        List<Centro_De_Lucro__c> lstCentroDeLucro = [SELECT Id FROM Centro_De_Lucro__c LIMIT 2];
        //Test.setMock(WebServiceMock.class, new BRAtualizaAreaDeVendasSFMock(Label.INTEGRATION_SYNC_AREA_DE_VENDAS_EDIT, Label.INTEGRATION_SYNC_AREA_DE_VENDAS_SUCCESS));
        Test.setMock(WebServiceMock.class, new MultiRequestMock());

        Area_De_Vendas__c newAreaVendas = TestSetup.getAreaDeVendas(lstCentroDeLucro[0].Id, '2002', '10', '03', false);
        //Area_De_Vendas__c newAreaVendas2 = TestSetup.getAreaDeVendas(lstCentroDeLucro[1].Id, '2001', '10', '03', false);

        Test.startTest();

        TriggerHandler.clearBypass('AreaDeVendasTriggerHandler');
        TriggerHandler.bypass('ParceiroTriggerHandler');
        System.debug('INSERT newAreaVendas: '+newAreaVendas+
                     '\nRESULT: '+Database.insert(newAreaVendas));
        /*System.debug('INSERT newAreaVendas2: '+newAreaVendas2+
                     '\nRESULT: '+Database.insert(newAreaVendas2));*/

        System.assertNotEquals(newAreaVendas.Id, null, 'Área de Vendas não foi criada');
        /*System.assertNotEquals(newAreaVendas2.Id, null, 'Área de Vendas 2 não foi criada');*/

        //newAreaVendas.Incoterms__c = 'Z02';
        // System.debug('UPDATE newAreaVendas: '+newAreaVendas+
        //              '\nRESULT: '+Database.update(newAreaVendas));

        Test.stopTest();

        System.debug('########## END AreaDeVendasTriggerHandlerTest.upsertNewAreaDeVendas');
    }

    @isTest
    static void deleteNewAreaDeVendas()
    {
        System.debug('########## START AreaDeVendasTriggerHandlerTest.deleteNewAreaDeVendas');

        List<Centro_De_Lucro__c> lstCentroDeLucro = [SELECT Id FROM Centro_De_Lucro__c];
        TriggerHandler.bypass('ParceiroTriggerHandler');
        TriggerHandler.clearBypass('AreaDeVendasTriggerHandler');

        //Test.setMock(WebServiceMock.class, new BRAtualizaAreaDeVendasSFMock(Label.INTEGRATION_SYNC_AREA_DE_VENDAS_EDIT, Label.INTEGRATION_SYNC_AREA_DE_VENDAS_SUCCESS));
        Test.setMock(WebServiceMock.class, new MultiRequestMock());

        Test.startTest();

        Area_De_Vendas__c newAreaVendas = TestSetup.getAreaDeVendas(lstCentroDeLucro[0].Id, '2002', '10', '03', false);
        newAreaVendas.Sync_SAP__c = true;
        //Area_De_Vendas__c newAreaVendas2 = TestSetup.getAreaDeVendas(lstCentroDeLucro[1].Id, '2001', '10', '03', true);
        //Area_De_Vendas__c newAreaVendas3 = TestSetup.getAreaDeVendas(lstCentroDeLucro[2].Id, '2001', '11', '03', true);

        System.debug('INSERT newAreaVendas: '+newAreaVendas+
                     '\nRESULT: '+Database.insert(newAreaVendas));

        System.assertNotEquals(newAreaVendas.Id, null, 'Área de Vendas não foi criada');
        //System.assertNotEquals(newAreaVendas2.Id, null, 'Área de Vendas 2 não foi criada');

        TriggerHandler.clearBypass('AreaDeVendasTriggerHandler');

        System.debug('DELETE parceiro: '+Database.delete([SELECT Id FROM Parceiro__c WHERE Area_De_Vendas_Do_Emissor__c = :newAreaVendas.Id OR Area_De_Vendas_Do_Recebedor__c = :newAreaVendas.Id]));

        System.debug('DELETE newAreaVendas: '+newAreaVendas+
                     '\nRESULT: '+Database.delete(newAreaVendas));

        /*System.debug('DELETE newAreaVendas: '+newAreaVendas2+
                     '\nRESULT: '+Database.delete(newAreaVendas2));
        System.debug('DELETE newAreaVendas: '+newAreaVendas3+
                     '\nRESULT: '+Database.delete(newAreaVendas3));*/

        Test.stopTest();

        System.debug('########## END AreaDeVendasTriggerHandlerTest.deleteNewAreaDeVendas');
    }

    //@isTest
    static void scheduleBatchTest()
    {
        System.debug('########## START AreaDeVendasTriggerHandlerTest.scheduleBatchTest');

        TriggerHandler.bypass('AreaDeVendasTriggerHandler');
        TriggerHandler.bypass('EquipeDeVendasTriggerHandler');
        TriggerHandler.bypass('CentroDeLucroTriggerHandler');
        TriggerHandler.bypass('ParceiroTriggerHandler');

        Centro_De_Lucro__c centroDeLucroTest = TestSetup.getCentroDeLucroWithVendedorAndEquipe(true);
        Area_De_Vendas__c areaDeVendasTest = TestSetup.getAreaDeVendas(centroDeLucroTest.Id, '2001', '10', '03', true);
        Test.setMock(WebServiceMock.class, new BRAtualizaAreaDeVendasSFMock(Label.INTEGRATION_SYNC_AREA_DE_VENDAS_EDIT, Label.INTEGRATION_SYNC_AREA_DE_VENDAS_SUCCESS));
        //Test.setMock(WebServiceMock.class, new MultiRequestMock());

        // TriggerHandler.clearBypass('ParceiroTriggerHandler');
        // TriggerHandler.clearBypass('EquipeDeVendasTriggerHandler');
        // TriggerHandler.clearBypass('CentroDeLucroTriggerHandler');
        TriggerHandler.clearBypass('AreaDeVendasTriggerHandler');

        Test.startTest();
        areaDeVendasTest.Centro_De_Lucro__c = centroDeLucroTest.Id;
        System.debug('UPDATE areaDeVendasTest:'+areaDeVendasTest+
                     '\nRESULT: '+Database.update(areaDeVendasTest));
        Test.stopTest();

        List<CronJobDetail> cronJobs = [SELECT Id FROM CronJobDetail WHERE Name = 'job integracao sap area de vendas'];
        List<CronTrigger> cronTriggers = [SELECT Id, NextFireTime FROM CronTrigger WHERE CronJobDetailId IN :cronJobs];

        System.assertNotEquals(areaDeVendasTest.Id, null, 'Área de Vendas não foi criada');

        System.debug('########## END AreaDeVendasTriggerHandlerTest.scheduleBatchTest');
    }

    @isTest
    static void updateTerritoriesTest()
    {
        System.debug('########## START AreaDeVendasTriggerHandlerTest.updateTerritoriesTest');

        TriggerHandler.bypass('AreaDeVendasTriggerHandler');
        TriggerHandler.bypass('ParceiroTriggerHandler');

        List<Centro_De_Lucro__c> lstCentroDeLucro = [SELECT Id, Equipe_De_Vendas__r.Codigo_Equipe_De_Venda__c FROM Centro_De_Lucro__c LIMIT 2];

        Area_De_Vendas__c areaDeVendasTest = TestSetup.getAreaDeVendas(lstCentroDeLucro[0].Id,'2001', '10', '14', true);
        //Area_De_Vendas__c areaDeVendasTest2 = TestSetup.getAreaDeVendas(lstCentroDeLucro[1].Id,'2002', '10', '14', true);

        String newTerritory = lstCentroDeLucro[0].Equipe_De_Vendas__r.Codigo_Equipe_De_Venda__c;
        String oldTerritory = lstCentroDeLucro[1].Equipe_De_Vendas__r.Codigo_Equipe_De_Venda__c;

        TriggerHandler.clearBypass('AreaDeVendasTriggerHandler');

        //Test.setMock(WebServiceMock.class, new BRAtualizaAreaDeVendasSFMock(Label.INTEGRATION_SYNC_AREA_DE_VENDAS_EDIT, Label.INTEGRATION_SYNC_AREA_DE_VENDAS_SUCCESS));
        Test.setMock(WebServiceMock.class, new MultiRequestMock());

        Test.startTest();
        areaDeVendasTest.Centro_De_Lucro__c = lstCentroDeLucro[1].Id;
        //areaDeVendasTest2.Centro_De_Lucro__c = lstCentroDeLucro[0].Id;
        //areaDeVendasTest2.Eliminacao__c = true;
        //areaDeVendasTest2.Chamada_SAP__c = 'TESTE';
        areaDeVendasTest.Sync_SAP__c = true;
        areaDeVendasTest.Chamada_SAP__c = 'TESTE';
        areaDeVendasTest.Integracao_Em_Processamento__c = false;
        System.debug('UPDATE lstAreaDeVendas: '+Database.update(new List<Area_De_Vendas__c> {areaDeVendasTest/*, areaDeVendasTest2*/}));
        Test.stopTest();

        //System.assertNotEquals(areaDeVendasTest2.Id, null, 'Área de Vendas não foi criada');
        System.assertNotEquals(areaDeVendasTest.Id, null, 'Área de Vendas não foi criada');

        System.debug('########## END AreaDeVendasTriggerHandlerTest.updateTerritoriesTest');
    }
    /******************************************************************************************************************************************
     * Purpose: Chamar integração de avaliação de orçamento para a Nota PM
     * Parameters: 
     * Returns: 
     * Throws -
     * 
     * History
     * --------
     * VERSION      AUTHOR          DATE            DETAIL      Description
     * 1.0          Daniel Fehnle   04/03/2021      Created     Testar o rezoneamento dos contratos DCVIM e DCB2B (US 12282)
     ******************************************************************************************************************************************/
    @isTest
    static void unitTestRezoneamento()
    {
        System.debug('########## START AreaDeVendasTriggerHandlerTest.unitTestWithContract');

        Area_De_Vendas__c areaDeVendas = [SELECT Id, Centro_De_Lucro__c FROM Area_De_Vendas__c WHERE Centro_De_Lucro__c != null LIMIT 1];
        Centro_De_Lucro__c centroLucro = [SELECT Id FROM Centro_De_Lucro__c WHERE Id != :areaDeVendas.Centro_De_Lucro__c LIMIT 1];

        Test.startTest();
            areaDeVendas.Centro_De_Lucro__c = centroLucro.Id;
            update areaDeVendas;
        Test.stopTest();
        
        // Assertions
        Contract varContract = [SELECT Id, Centro_De_Lucro_Do_Contrato__c FROM Contract WHERE RecordType.DeveloperName like 'DCVIM%' LIMIT 1];
        System.assertEquals(varContract.Centro_De_Lucro_Do_Contrato__c, centroLucro.Id, 'Centro de lucro não foi alterado');
        
        System.debug('########## END AreaDeVendasTriggerHandlerTest.unitTestWithContract');
    }
}