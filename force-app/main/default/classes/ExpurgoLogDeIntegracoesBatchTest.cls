/********************************************************************************************************************************
* 2021 - Previsul 
* ===============================================================================================================================
* Purpose: Classe de teste para a classe ExpurgoLogDeIntegracoesBatch
* ===============================================================================================================================
* History
* -------
* VERSION   AUTHOR              DATE            DETAIL      Description
* 1.0       Daniela Segura      28/12/2021      Created     Versão inicial
*********************************************************************************************************************************/
@isTest
public class ExpurgoLogDeIntegracoesBatchTest {

    @testSetup
    static void testSetup(){
        List<LogIntegracao__c> lstLogs = new List<LogIntegracao__c>();

        for(Integer i = 0; i < 2; i++){
            LogIntegracao__c testLog = new LogIntegracao__c();
            testLog.Status__c = 'Vencido';
            testLog.DvRequisicaoSucesso__c = true;
            testLog.RecordTypeId = Schema.SObjectType.LogIntegracao__c.getRecordTypeInfosByDeveloperName().get('PIX').getRecordTypeId();
            if(i == 0){
                testLog.Name = 'Criado a mais de 12 meses';
                testLog.NumeroContrato__c = '1234567';
                testLog.Identificador_sequencial__c = 1;
            }else{
                testLog.Name = 'Criado hoje';
                testLog.NumeroContrato__c = '7654321';
                testLog.Identificador_sequencial__c = 2;
            }
            lstLogs.add(testLog);
        }

        insert lstLogs;

        Test.setCreatedDate(lstLogs.get(0).Id, Datetime.now().addMonths(-13));
    }

    @isTest
    static void testBatch(){        
        ExpurgoLogDeIntegracoesBatch batch = new ExpurgoLogDeIntegracoesBatch();

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        List<LogIntegracao__c> lstLogs = [SELECT Id, CreatedDate FROM LogIntegracao__c];

        System.assertEquals(1, lstLogs.size(), 'Logs não foram excluídos.');
    }

    @isTest
    static void testSchedulable(){
        Test.startTest();
        ExpurgoLogDeIntegracoesBatch schedulable = new ExpurgoLogDeIntegracoesBatch ();   
        String chron = '0 0 23 * * ?';        
        System.schedule('Test Schedulable', chron, schedulable);
        Test.stopTest();
    }
}