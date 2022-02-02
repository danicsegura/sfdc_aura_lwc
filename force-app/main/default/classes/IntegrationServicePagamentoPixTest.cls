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
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new IntegrationServicePagamentoPixMock());
            PagamentoPixReturnWrapper result = IntegrationServicePagamentoPix.callServiceNewPix(cobrancaString);
        Test.stopTest();

        System.assertEquals('EX23210000000000000000000000146', result.pix.txId, 'Não retornou o txId corretamente.');       
    }
}