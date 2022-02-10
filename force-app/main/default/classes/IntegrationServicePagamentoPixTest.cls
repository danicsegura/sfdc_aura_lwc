/********************************************************************************************************************************
* 2021 - Previsul 
* ===============================================================================================================================
* Purpose: Classe de teste para a classe IntegrationServicePagamentoPix
* ===============================================================================================================================
* History
* -------
* VERSION   AUTHOR              DATE            DETAIL      Description
* 1.0       Daniela Segura      22/12/2021      Created     Versão inicial
*********************************************************************************************************************************/
@isTest
public class IntegrationServicePagamentoPixTest {
    @testSetup
    static void testSetup(){
        Profile profile = [Select Id from Profile where name in ('System Administrator', 'Administrador do Sistema') LIMIT 1];

        User userTest = new User();
        userTest.LastName = 'Test';
        userTest.Alias = 'Test';
        userTest.Email = 'usertest@previsul.com';
        userTest.Username = 'usertest@previsul.com';
        userTest.CPF__c = '12345678910';
        userTest.ProfileId = profile.Id;
        userTest.LocaleSidKey = 'pt_BR';
        userTest.LanguageLocaleKey = 'pt_BR';
        userTest.EmailEncodingKey = 'UTF-8';
        userTest.TimeZoneSidKey = 'America/Sao_Paulo';
        userTest.IsActive = true;
        insert userTest;

        LogIntegracao__c logIntegracao = new LogIntegracao__c();
        logIntegracao.NumeroContrato__c = '71476390';
        logIntegracao.Status__c = 'Ativo';
        logIntegracao.Identificador_sequencial__c = 1;
        logIntegracao.TxId__c = 'C001testtxIdtst';
        insert logIntegracao;
    }

    @isTest
    static void getTokenTest(){
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new IntegrationServicePagamentoPixMock());
            String accessToken = IntegrationServicePagamentoPix.getToken();
        Test.stopTest();

        System.assertEquals('eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI3TFdPRDU1NFhhbThGUFMwbXprSmRtaGRqeDJORzNaYm14blBENTgtSHdvIn0.eyJqdGkiOiIxNzM3YjYzNC0zZDU2LTQ4ZjAtOTg0Ny1lM2E2MzlmNWU5YWIiLCJleHAiOjE2NDAxODY2NjksIm5iZiI6MCwiaWF0IjoxNjQwMTg2MDY5LCJpc3MiOiJodHRwczovL3Nzby1kLXNlZ3VyYW5jYS1kLmRldi5vY3AuY2FpeGFzZWd1cmFkb3JhLmludHJhbmV0L2F1dGgvcmVhbG1zL2ludGVybm8iLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiNTY5ZGYxOTUtNTI2MC00ZDc2LTgxMjQtMGRhZDU5ZmFjNTY2IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiMmZlMmVmNzEyNzhiZGI3NmNmZTM4MTA2YjdjMzkxYWEiLCJhdXRoX3RpbWUiOjAsInNlc3Npb25fc3RhdGUiOiJjM2JiN2ZmNS0yYmRkLTQ0NzQtYjVhNy03NjdlMWE5MTdmY2IiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6ImRlZmF1bHQtc2NvcGUiLCJjbGllbnRIb3N0IjoiMTAuMTE4LjAuMjAxIiwiY2xpZW50SWQiOiIyZmUyZWY3MTI3OGJkYjc2Y2ZlMzgxMDZiN2MzOTFhYSIsImNsaWVudEFkZHJlc3MiOiIxMC4xMTguMC4yMDEifQ.bC3fM9kDniLmXXfxkJMIDGoTi_adMnzhuFxUFd7Hftmyzzlog5-K0wadx2WBlZAAxXMAel3v46qfD-6lqWIkeuRZIce-57ZqHzqKH2eVu8Yzly8-z08QSBzqGaCet1VmIZjhR0TCxNtzAOyyHKU3Rhhy3qaYPZp3nsjU1kjLRKbuNgtjQXmsXGcCbJmb10fbbZ7oxWU-wi0c8afp8ME7GMlSS1A8fJrGsDT1E5a3AspyFFf9z46AfWxwhJRpIib_i-nrF6i2tpe9CmIXGRHZ0KmCrMXpLs1XwzgxrCt3gtjjwOCSy0xgj-TQhM-0bKuruddNtwPTb92l-y_K-bkfbg', accessToken, 'Não foi retornado o token esperado.');
    }

     @isTest
    static void callServiceNewPixTest(){
        String cobrancaString = '{"apolice":"10101140000124","apoliceDisplay":"10101140000124","chaveParcelaLegado":"12294329","ColetivoSn":"N","competencia":"202007","diasVencido":"0","dtVencimento":"31/12/2021","fatura":"71476390","formaPagamento":"Débito em Conta","sistema":"I4PRO","valor":"0.01"}';
        User user = [SELECT Id FROM User WHERE UserName = 'usertest@previsul.com' LIMIT 1];
        PagamentoPixReturnWrapper result = new PagamentoPixReturnWrapper();
        
        Test.startTest();
            System.runAs(user){
                Test.setMock(HttpCalloutMock.class, new IntegrationServicePagamentoPixMock());
                result = IntegrationServicePagamentoPix.callServiceNewPix(cobrancaString);
            }
        Test.stopTest();

        System.assertEquals('EX23210000000000000000000000146', result.pix.txId, 'Não retornou o txId corretamente.');       
    }

    @isTest
    static void callServiceReimpressaoTest(){
        String cobrancaString = '{"apolice":"10101140000124","apoliceDisplay":"10101140000124","chaveParcelaLegado":"12294329","ColetivoSn":"N","competencia":"202007","diasVencido":"0","dtVencimento":"31/12/2021","fatura":"71476390","formaPagamento":"Débito em Conta","sistema":"I4PRO","valor":"0.01"}';
        User user = [SELECT Id FROM User WHERE UserName = 'usertest@previsul.com' LIMIT 1];
        PagamentoPixReturnWrapper result = new PagamentoPixReturnWrapper();
        
        Test.startTest();
            System.runAs(user){
                Test.setMock(HttpCalloutMock.class, new IntegrationServicePagamentoPixMock());
                result = IntegrationServicePagamentoPix.callServiceReimpressao(cobrancaString);
            }
        Test.stopTest();

        System.assertEquals('EX23210000000000000000000000146', result.pix.txId, 'Não retornou o txId corretamente.');       
    }
}