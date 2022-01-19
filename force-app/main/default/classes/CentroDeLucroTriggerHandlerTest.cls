@isTest
private class CentroDeLucroTriggerHandlerTest {

    @testSetup
    static void testSetup() {

        TestSetup.getTerritory('T00', true);

    }

    static void doInit()
    {
		TriggerHandler.bypass('EquipeDeVendasTriggerHandler');
        TriggerHandler.bypass('CentroDeLucroTriggerHandler');
        TriggerHandler.bypass('AreaDeVendasTriggerHandler');
        TriggerHandler.bypass('ParceiroTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        
        User user1 = TestSetup.getUser(false);
        user1.LastName = 'User CL 1';
        user1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Apoio a Vendas' LIMIT 1].Id;
        insert user1;
        
        User user2 = TestSetup.getUser(false);
        user2.LastName = 'User CL 2';
        user2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Gerente' LIMIT 1].Id;
		insert user2;

        Equipe_De_Vendas__c equipeDeVendasTest = TestSetup.getEquipeDeVendas('T00', true);
        Equipe_De_Vendas__c equipeDeVendasTest2 = TestSetup.getEquipeDeVendas('Test Equipe', '	774', 'OPER', true);
        
        Centro_De_Lucro__c centroDeLucroTest = TestSetup.getCentroDeLucroWithVendedor(equipeDeVendasTest.Id, true);
        
        List<Centro_De_Lucro__c> lstCentroLucro = new List<Centro_De_Lucro__c>();
        Centro_De_Lucro__c testCentroLucro1  = TestSetup.getCentroDeLucroWithVendedorAndEquipe(false);
        testCentroLucro1.Name = 'Centro de Lucro Principal';
        testCentroLucro1.Vendedor__c = user1.Id;
        lstCentroLucro.add(testCentroLucro1);       
        
        Centro_De_Lucro__c testCentroLucro2  = TestSetup.getCentroDeLucro(user2.Id, equipeDeVendasTest2.Id, false);
        testCentroLucro2.Name = 'Centro de Lucro Aviação';
        lstCentroLucro.add(testCentroLucro2);
        insert lstCentroLucro;
        
        Account testAccount = TestSetup.getAccount('Test Account Centro Lucro', true);
        
        Area_De_Vendas__c areaDeVendasTest = TestSetup.getAreaDeVendas(centroDeLucroTest.Id, '2001', '10', '02', true);
        Area_De_Vendas__c areaDeVendasTest2 = TestSetup.getAreaDeVendas(testAccount.Id, testCentroLucro1.Id, '2002', '10', '02', true);
        Area_De_Vendas__c areaDeVendasTest3 = TestSetup.getAreaDeVendas(testAccount.Id, testCentroLucro2.Id, '2002', '10', '03', true);
    }

    @isTest
    static void afterInsertTest() {

        doInit();
        TriggerHandler.clearBypass('CentroDeLucroTriggerHandler');

        Equipe_De_Vendas__c equipeDeVendasTest = [SELECT Id FROM Equipe_De_Vendas__c WHERE Codigo_Equipe_De_Venda__c = 'T00'];
        User vendedorTest = TestSetup.getUser(true);

        Test.startTest();
        Test.setMock(WebServiceMock.class, new MultiRequestMock());
        Centro_De_Lucro__c centroDeLucroTest = TestSetup.getCentroDeLucro(vendedorTest.Id, equipeDeVendasTest.Id, false);
        centroDeLucroTest.Name = 'centro_de_lucro_test2';
        insert centroDeLucroTest;
        Test.stopTest();

        Territory2 territoryTest = [SELECT Id FROM Territory2 WHERE Name = 'T00' LIMIT 1];
        List<UserTerritory2Association> associationsTest = [SELECT Id FROM UserTerritory2Association WHERE Territory2Id = :territoryTest.Id AND UserId = :vendedorTest.Id];

        System.assert(associationsTest.size() > 0, 'ERRO');
        
        TriggerHandler.clearAllBypasses();

    }

    @isTest
    static void updateTest() {

        doInit();
        TriggerHandler.clearBypass('CentroDeLucroTriggerHandler');

        Centro_De_Lucro__c centroDeLucroTest = [SELECT Id, Vendedor__c FROM Centro_De_Lucro__c LIMIT 1];
        User newVendedor = TestSetup.getUser(false);
        newVendedor.ProfileId = UserInfo.getProfileId();
        newVendedor.ManagerId = UserInfo.getUserId();
        insert newVendedor;

        Id oldVendedor = centroDeLucroTest.Vendedor__c;

        Test.startTest();
        Test.setMock(WebServiceMock.class, new MultiRequestMock());

        centroDeLucroTest.Vendedor__c = newVendedor.Id;
        update centroDeLucroTest;
        Test.stopTest();

        Territory2 territoryTest = [SELECT Id FROM Territory2 WHERE Name = 'T00' LIMIT 1];
        List<UserTerritory2Association> associationsTest = [SELECT Id FROM UserTerritory2Association WHERE Territory2Id = :territoryTest.Id AND UserId = :oldVendedor];
        centroDeLucroTest = [SELECT Id, Vendedor__c, OwnerId FROM Centro_De_Lucro__c WHERE Id = :centroDeLucroTest.Id];

        System.assert(associationsTest.size() == 0, 'ERRO');
        //System.assertEquals(centroDeLucroTest.Vendedor__c, centroDeLucroTest.OwnerId, 'ERRO');
        
        TriggerHandler.clearAllBypasses();

    }

    @isTest
    static void afterDeleteTest() {

        doInit();
        TriggerHandler.clearBypass('CentroDeLucroTriggerHandler');
        TriggerHandler.bypass('EquipeDeVendasTriggerHandler');
        TriggerHandler.bypass('AreaDeVendasTriggerHandler');
        TriggerHandler.bypass('ParceiroTriggerHandler');

        Equipe_De_Vendas__c equipeDeVendasTest = [SELECT Id FROM Equipe_De_Vendas__c WHERE Codigo_Equipe_De_Venda__c = 'T00' LIMIT 1];
        Centro_De_Lucro__c centroDeLucroTest = [SELECT Id FROM Centro_De_Lucro__c WHERE Equipe_De_Vendas__c =: equipeDeVendasTest.Id];
        Area_De_Vendas__c areaDeVendasTest = [SELECT Id FROM Area_De_Vendas__c WHERE Centro_De_Lucro__c =: centroDeLucroTest.Id];

        User vendedorTest = TestSetup.getUser(true);

        Test.startTest();
        Test.setMock(WebServiceMock.class, new MultiRequestMock());
        delete [SELECT Id FROM Parceiro__c];
        delete areaDeVendasTest;
        delete centroDeLucroTest;
        Test.stopTest();

        Territory2 territoryTest = [SELECT Id FROM Territory2 WHERE Name = 'T00' LIMIT 1];
        List<UserTerritory2Association> associationsTest = [SELECT Id FROM UserTerritory2Association WHERE Territory2Id = :territoryTest.Id AND UserId = :vendedorTest.Id];

        System.assert(associationsTest.size() == 0, 'ERRO');
        
        TriggerHandler.clearAllBypasses();

    }
    
    @isTest
    static void updateAccountCentroDeLucroTest(){
        doInit();
        User testUser1 = [SELECT Id FROM User WHERE LastName = 'User CL 1' LIMIT 1];
        User testUser2 = [SELECT Id FROM User WHERE LastName = 'User CL 1' LIMIT 1];

		List<Centro_De_Lucro__c> lstCentroLucro = new List<Centro_De_Lucro__c>();
        Centro_De_Lucro__c centroLucro1 = [SELECT Id, Vendedor__c FROM Centro_De_Lucro__c WHERE Name = 'Centro de Lucro Principal' LIMIT 1];
        centroLucro1.Vendedor__c = testUser1.Id;
        lstCentroLucro.add(centroLucro1);
        
        Centro_De_Lucro__c centroLucro2 = [SELECT Id, Vendedor__c FROM Centro_De_Lucro__c WHERE Name = 'Centro de Lucro Aviação' LIMIT 1];
        centroLucro2.Vendedor__c = testUser2.Id;
        lstCentroLucro.add(centroLucro2);
        
        TriggerHandler.clearBypass('CentroDeLucroTriggerHandler');
        
        Test.startTest();
        	update lstCentroLucro;
        Test.stopTest();
        
        Account account = [SELECT Id, Centro_de_Lucro_Principal__c, Centro_de_Lucro_Avia_o__c FROM Account WHERE Name = 'Test Account Centro Lucro' LIMIT 1];
        
        System.assertEquals(centroLucro1.Id, account.Centro_de_Lucro_Principal__c);
        System.assertEquals(centroLucro2.Id, account.Centro_de_Lucro_Avia_o__c);

        TriggerHandler.clearAllBypasses();
        
    }
}