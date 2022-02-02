/********************************************************************************************************************************
* 2021 - Previsul 
* ===============================================================================================================================
* Purpose: Classe agendada que realiza o expurgo de Logs de Integração que foram criados a mais de 12 meses
* ===============================================================================================================================
* History
* -------
* VERSION   AUTHOR              DATE            DETAIL      Description
* 1.0       Daniela Segura      22/12/2021      Created     Versão inicial
*********************************************************************************************************************************/
public class ExpurgoLogDeIntegracoesBatch implements Database.Batchable<sObject>, Schedulable{

    public Database.QueryLocator start(Database.BatchableContext bc){
        Date dateLimit = Date.today().addMonths(-12);

        return Database.getQueryLocator([SELECT Id, CreatedDate 
                                        FROM LogIntegracao__c 
                                        WHERE CreatedDate <: dateLimit]);
    }

    public void execute(Database.BatchableContext bc, List<LogIntegracao__c> scope){
        if(!scope.isEmpty()){
            Database.DeleteResult[] results = Database.delete(scope, false);
            for(Database.DeleteResult varResult : results){
                if(!varResult.isSuccess()){
                    System.debug('### ExpurgoLogDeIntegracoesSchedulable ###');
                    System.debug('### Erro na deleção do registro de Id: ' + varResult.getId());
                    for(Database.Error error : varResult.getErrors()){
                        System.debug('### Mensagem de erro: ' + error.getMessage());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc){
        System.debug('ExpurgoLogDeIntegracoesBatch finalizado.');
    }

    public void execute(SchedulableContext sc){
        ExpurgoLogDeIntegracoesBatch batch = new ExpurgoLogDeIntegracoesBatch();
        Database.executeBatch(batch);
    }
}