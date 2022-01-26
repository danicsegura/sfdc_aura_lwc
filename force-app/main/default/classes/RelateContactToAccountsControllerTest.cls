/******************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ========================================================================================================================================
* Purpose: US 15477 - Classe de teste para a classe RelateContactToAccountsController
* ========================================================================================================================================
* History
* -------
* VERSION   AUTHOR                  DATE        DETAIL      Description
* 1.0       Daniela Segura          24/11/2021  Created     Versão inicial
******************************************************************************************************************************************/
@isTest
public class RelateContactToAccountsControllerTest {
    @testSetup
    static void testSetup(){
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('ACRTriggerHandler');
        
        Grupo_Plano_Contas__c grupoPlanoContas = new Grupo_Plano_Contas__c();
        grupoPlanoContas.Name = 'Grupo de Contas';
        grupoPlanoContas.Codigo__c = 'A050';
        insert grupoPlanoContas;
        
        Account account = TestSetup.getAccount('Test Account', true);
        Account account2 = TestSetup.getAccount('New Account', false);
        account2.Grupo_Plano_Contas__c = grupoPlanoContas.Id;
        insert account2;
        
        Contact contact = TestSetup.getContact(account.Id, 'Test', 'User', true);
        
        TriggerHandler.clearAllBypasses();
    }
    
    @isTest
    static void getRecordsAccountTest(){
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Account account2 = [SELECT Name, Numero_Do_Documento__c FROM Account WHERE Name = 'New Account' LIMIT 1];
        
        Test.startTest();
        List<RelateContactToAccountsController.ResultWrapper> lstResultWrapper = RelateContactToAccountsController.getRecords(contact.Id, 'New Account', 'account', 1);
        Test.stopTest();
        
        System.assertEquals(account2.Name, lstResultWrapper.get(0).name);
        System.assertEquals(account2.Numero_Do_Documento__c, lstResultWrapper.get(0).numeroDocumento);
    }
    
    @isTest
    static void getRecordsGrupoPCTest(){
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Grupo_Plano_Contas__c gpc = [SELECT Name, Codigo__c FROM Grupo_Plano_Contas__c LIMIT 1];
        
        Test.startTest();
        List<RelateContactToAccountsController.ResultWrapper> lstResultWrapper = RelateContactToAccountsController.getRecords(contact.Id, 'Grupo de Contas', 'grupoPlanoContas', 1);
        Test.stopTest();
        
        System.assertEquals(gpc.Name, lstResultWrapper.get(0).nomeGrupo);
        System.assertEquals(gpc.Codigo__c, lstResultWrapper.get(0).codigoGrupo);
    }
    
    @isTest
    static void getRecordsCnpjBasicoTest(){
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Account account2 = [SELECT Name, Numero_Do_Documento__c FROM Account WHERE Name = 'New Account' LIMIT 1];
        
        Test.startTest();
        List<RelateContactToAccountsController.ResultWrapper> lstResultWrapper = RelateContactToAccountsController.getRecords(contact.Id, account2.Numero_Do_Documento__c.left(8), 'cnpjBasico', 1);
        Test.stopTest();
        
        System.assertEquals(account2.Name, lstResultWrapper.get(0).name);
        System.assertEquals(account2.Numero_Do_Documento__c, lstResultWrapper.get(0).numeroDocumento);
    }
    
    @isTest
    static void insertACRAccountTest(){
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Account account2 = [SELECT Id, Name, Numero_Do_Documento__c, Codigo_SAP__c, Grupo_Plano_Contas__r.Name FROM Account WHERE Name = 'New Account' LIMIT 1];
        
        List<RelateContactToAccountsController.ResultWrapper> lstResultWrapper = new List<RelateContactToAccountsController.ResultWrapper>();
        
        RelateContactToAccountsController.ResultWrapper resultWrapper = 
            new RelateContactToAccountsController.ResultWrapper(account2.Id, 'New Account', account2.Numero_Do_Documento__c, account2.Codigo_SAP__c, account2.Grupo_Plano_Contas__r.Name);
        lstResultWrapper.add(resultWrapper);
        
        String selectedRecordsStr = JSON.serialize(lstResultWrapper);

        AccountContactRelation acr = new AccountContactRelation();
        acr.Boleto_Por_Email__c = true;
        acr.Funcoes_Contato__c = 'Z0';

        String acrString = JSON.serialize(acr);
        
        Test.startTest();
        RelateContactToAccountsController.insertAccountContactRelations(contact.Id, selectedRecordsStr, 'account', acrString);
        Test.stopTest();
        
        List<AccountContactRelation> lstAcr = [SELECT Id FROM AccountContactRelation WHERE ContactId =: contact.Id AND AccountId =: account2.Id];
        System.assertEquals(1, lstAcr.size());
        
    }
    
    @isTest
    static void insertACRGrupoTest(){
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Account account2 = [SELECT Name, Numero_Do_Documento__c FROM Account WHERE Name = 'New Account' LIMIT 1];
        Grupo_Plano_Contas__c gpc = [SELECT Id, Name, Codigo__c FROM Grupo_Plano_Contas__c LIMIT 1];
        
        List<RelateContactToAccountsController.ResultWrapper> lstResultWrapper = new List<RelateContactToAccountsController.ResultWrapper>();

		RelateContactToAccountsController.ResultWrapper resultWrapper = 
    		new RelateContactToAccountsController.ResultWrapper(gpc.Id, gpc.Name, gpc.Codigo__c);
        lstResultWrapper.add(resultWrapper);
        
        String selectedRecordsStr = JSON.serialize(lstResultWrapper);

        AccountContactRelation acr = new AccountContactRelation();
        acr.Boleto_Por_Email__c = true;
        acr.Funcoes_Contato__c = 'Z0';

        String acrString = JSON.serialize(acr);
        
        Test.startTest();
        RelateContactToAccountsController.insertAccountContactRelations(contact.Id, selectedRecordsStr, 'grupoPlanoContas', acrString);
        Test.stopTest();
        
        List<AccountContactRelation> lstAcr = [SELECT Id FROM AccountContactRelation WHERE ContactId =: contact.Id AND AccountId =: account2.Id];
        System.assertEquals(1, lstAcr.size());
    }

    @isTest
    static void getPicklistsTests() {

        Test.startTest();
            Map<String, String> mapFuncoesContato = RelateContactToAccountsController.getPicklistFuncoesDoContato();
            Map<String, String> mapRoles = RelateContactToAccountsController.getPicklistRoles();
            Map<String, String> mapRelationshipStrength = RelateContactToAccountsController.getPicklistRelationshipStrength();
        Test.stopTest();
        
        String errorMsg = 'Os valores de picklist não foram retornados corretamente.';

        System.assert(mapFuncoesContato != null, errorMsg);
        System.assert(mapRoles != null, errorMsg);
        System.assert(mapRelationshipStrength != null, errorMsg);
    }
}