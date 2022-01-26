/******************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ========================================================================================================================================
* Purpose: US 15477 - Realizar a inserção dos registros de AccountContactRelation, chamado pela classe RelateContactToAccountsController
* ========================================================================================================================================
* History
* -------
* VERSION   AUTHOR                  DATE        DETAIL      Description
* 1.0       Daniela Segura          24/11/2021  Created     Versão inicial
******************************************************************************************************************************************/
public class RelateContactToAccountsBatch implements Database.Batchable<sObject>{
    private List<AccountContactRelation> lstACRtoInsert = new List<AccountContactRelation>();

    public RelateContactToAccountsBatch(List<AccountContactRelation> lstACR){
        this.lstACRtoInsert = lstACR;
    }

    public List<AccountContactRelation> start(Database.BatchableContext bc){
        return this.lstACRtoInsert;
    }

    public void execute(Database.BatchableContext bc, List<AccountContactRelation> scope){
        List<LogApexException__c> lstLogApexException = new List<LogApexException__c>();

        Database.SaveResult[] srListACR = Database.insert(scope, false);

        for (Database.SaveResult srACR : srListACR) 
        {
            if (!srACR.isSuccess()) 
            {          
                for(Database.Error errorAccount : srACR.getErrors()) 
                {
                    LogApexException__c regLogApexException = new LogApexException__c();
                    regLogApexException.Class_Name__c = 'RelateContactToAccountsBatch';
                    regLogApexException.Method_Name__c = 'execute / insert scope';
                    regLogApexException.Exception_Message__c = errorAccount.getStatusCode() + ': ' + errorAccount.getMessage() + ' >>>> ' + errorAccount.getFields();
                    regLogApexException.log_de_erro__c = true;     

                    lstLogApexException.add(regLogApexException);
                }
            }
        }


        if(!lstLogApexException.isEmpty())
            Util.insereLstLogApexException(lstLogApexException);
    }

    public void finish(Database.BatchableContext bc){
        System.debug('RelateContactToAccountsBatch finalizado.');
    }
}