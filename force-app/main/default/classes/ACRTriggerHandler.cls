/*********************************************************************************************************************************
* Copyright � 2019 BR Distribuidores
* ================================================================================================================================
* Purpose: US 8525 - [Melhoria] - Inativa��o de Contato
* ================================================================================================================================
* History
* -------
* VERSION   AUTHOR         					DATE         	DETAIL      	Description
* 1.0       Daniel Lopes                    06/08/2020      Created         Cria��o de classe para gerenciar relacionamentos de contatos
* 1.1       Daniela Segura                  24/01/2022      Edited          Edição no método setStartDate
**********************************************************************************************************************************/
public without sharing class ACRTriggerHandler extends TriggerHandler {
    private Map<Id,AccountContactRelation> mapOldACR;
    private Map<Id,AccountContactRelation> mapNewACR;
    private List<AccountContactRelation> 	lstNewACR;
    private List<AccountContactRelation> 	lstOldACR;

    private final Id RECORDTYPE_CONTATO_SAC;
    
    public ACRTriggerHandler() 
    {
        this.mapNewACR = (Map<Id, AccountContactRelation>) Trigger.newMap;
        this.mapOldACR = (Map<Id, AccountContactRelation>) Trigger.oldMap;
        this.lstNewACR = (List<AccountContactRelation>) Trigger.new;
        this.lstOldACR = (List<AccountContactRelation>) Trigger.old;

        this.RECORDTYPE_CONTATO_SAC = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contato SAC').getRecordTypeId();
    }

    public override void beforeInsert()
    {
        setStartDate();
    }

    public override void afterUpdate()
    {
        sendContactSap();
    }

    /*********************************************************************************************************************
     * Purpose: US 8525 - [Melhoria] - Inativa��o de Contato
     * Parameters: void
     * Returns: void
     * Throws -
     *
     * History
     * --------
     * VERSION      AUTHOR                          DATE            DETAIL      Description
     * 1.0          Daniel Lopes                    13/08/2020      Created     Preencher campo StartDate nos relacionamentos de Contato.
    **********************************************************************************************************************/
    private void setStartDate()
    {
        if(!System.isFuture() && !System.isBatch()){
            for(AccountContactRelation varACR : this.lstNewACR)
            {
                varACR.StartDate = System.today();
            }
        }
    }

    /*********************************************************************************************************************
     * Purpose: US 8525 - [Melhoria] - Inativa��o de Contato
     * Parameters: void
     * Returns: void
     * Throws -
     *
     * History
     * --------
     * VERSION      AUTHOR                          DATE            DETAIL      Description
     * 1.0          Daniel Lopes                    13/08/2020      Created     Sincronização de contatos relacionados com
     *                                                                          o SAP.
     * 1.1          Daniel Lopes                    16/12/2020      Edited      Alteração para rodar integração para todas as funções
    **********************************************************************************************************************/
    private void sendContactSAP()
    {
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        Map<Id, Contact> mapContact = new Map<Id, Contact>();
        List<AccountContactRelation> lstACRToProcess = new List<AccountContactRelation>();
        Map<String, Funcao_Contato__c> mapFuncaoContato = new Map<String, Funcao_Contato__c>();
        List<Funcao_Contato__c> lstFuncoesDoContato = new List<Funcao_Contato__c>();
        List<FuncaoWrapper> lstFuncoesToSync = new List<FuncaoWrapper>();
        Map<Id, String> mapContactToOperacao = new Map<Id, String>();
        for(AccountContactRelation varACR : lstNewACR)
        {
            AccountContactRelation varOldACR = mapOldACR.get(varACR.Id);
           
            if((varACR.Funcoes_Contato__c != varOldACR.Funcoes_Contato__c) || (varOldACR.IsActive && !varACR.IsActive) || (!varOldACR.IsActive && varACR.IsActive)){
                mapAccount.put(varACR.AccountId, null);
                mapContact.put(varACR.ContactId, null);
                lstACRToProcess.add(varACR);
            }
        }
        mapAccount = new Map<Id, Account>(AccountUtil.getAccountsWithAllFields(mapAccount.keySet()));
        mapContact = new Map<Id, Contact>(ContactUtil.getContactstWithAllFields(mapContact.keySet()));
        
       
        lstFuncoesDoContato = [SELECT Funcao_Contato__c, Account__c, Contact__c, ID_Contato_SAP__c FROM Funcao_Contato__c WHERE Account__c IN :mapAccount.keySet() AND Contact__c IN :mapContact.keySet()];
        
        
        for(Funcao_Contato__c funcao : lstFuncoesDoContato)
        {
            String chave = funcao.Account__c + '_' + funcao.Contact__c + '_' + funcao.Funcao_Contato__c;
            
            mapFuncaoContato.put(chave, funcao);
        }
        List<Funcao_Contato__c> lstFuncoesToInsert = new List<Funcao_Contato__c>();
        List<Funcao_Contato__c> lstFuncoesToDelete = new List<Funcao_Contato__c>();
        for(AccountContactRelation varACR : lstACRToProcess)
        {
            AccountContactRelation varOldACR = mapOldACR.get(varACR.Id);
            String chaveAcr = varACR.AccountId + '_' + varACR.ContactId;
            if(!String.isBlank(mapAccount.get(varACR.AccountId).Codigo_SAP__c) && mapContact.get(varACR.ContactId).RecordTypeId != RECORDTYPE_CONTATO_SAC)
            {
                Boolean varACRInativada = varOldACR.IsActive && !varACR.IsActive;
                Boolean varACRInativadaPorRemocao = String.isEmpty(varACR.Funcoes_Contato__c) && String.isNotEmpty(varOldACR.Funcoes_Contato__c);
                if(varACRInativada || varACRInativadaPorRemocao)
                {
                    List<String> lstFuncoesToProcess = new List<String>();
                    if(varACRInativada && String.isNotEmpty(varACR.Funcoes_Contato__c))
                    {
                        lstFuncoesToProcess = varACR.Funcoes_Contato__c.split(';');
                    }
                    else if (varACRInativadaPorRemocao)
                    {
                        lstFuncoesToProcess = varOldACR.Funcoes_Contato__c.split(';');
                    }
            
                    for(String funcao : lstFuncoesToProcess)
                    {
                        if(mapFuncaoContato.containsKey(chaveAcr + '_' + funcao) && mapFuncaoContato.get(chaveAcr + '_' + funcao).ID_Contato_SAP__c != null)
                        {
                            lstFuncoesToSync.add(new FuncaoWrapper(mapFuncaoContato.get(chaveAcr + '_' + funcao), Label.INTEGRATION_SYNC_CONTACT_DELETE));
                        }
                        else if(mapFuncaoContato.containsKey(chaveAcr + '_' + funcao) && mapFuncaoContato.get(chaveAcr + '_' + funcao).ID_Contato_SAP__c == null)
                        {
                            lstFuncoesToDelete.add(mapFuncaoContato.get(chaveAcr + '_' + funcao));
                        }
                    }
                }
                else if(!varOldACR.IsActive && varACR.IsActive && String.isNotEmpty(varACR.Funcoes_Contato__c))
                {
                    for(String funcao : varACR.Funcoes_Contato__c.split(';'))
                    {
                        Funcao_Contato__c funcaoToInsert = new Funcao_Contato__c(
                            Account__c = varACR.AccountId, 
                            Contact__c = varACR.ContactId, 
                            Funcao_Contato__c = funcao
                        );
                        lstFuncoesToInsert.add(funcaoToInsert);
                        lstFuncoesToSync.add(new FuncaoWrapper(funcaoToInsert, Label.INTEGRATION_SYNC_CONTACT_INSERT));
                        if(!mapFuncaoContato.isEmpty() && mapFuncaoContato.containsKey(chaveAcr + '_' + funcao) && String.isEmpty(mapFuncaoContato.get(chaveAcr + '_' + funcao).ID_Contato_SAP__c)){
                            lstFuncoesToDelete.add(mapFuncaoContato.get(chaveAcr + '_' + funcao));
                        }
                        else if(!mapFuncaoContato.isEmpty() && mapFuncaoContato.containsKey(chaveAcr + '_' + funcao) && String.isNotEmpty(mapFuncaoContato.get(chaveAcr + '_' + funcao).ID_Contato_SAP__c))
                        {
                            lstFuncoesToSync.add(new FuncaoWrapper(mapFuncaoContato.get(chaveAcr + '_' + funcao), Label.INTEGRATION_SYNC_CONTACT_DELETE));
                        }
                    }
                }
                else if(varACR.IsActive && String.isNotEmpty(varACR.Funcoes_Contato__c))
                {
                    if(!varACR.Funcoes_Contato__c.equals(varOldACR.Funcoes_Contato__c)){
                        for(String funcao : varACR.Funcoes_Contato__c.split(';'))
                        {
                            if((String.isEmpty(varOldACR.Funcoes_Contato__c) || !varOldACR.Funcoes_Contato__c.contains(funcao)) && !mapFuncaoContato.containsKey(chaveAcr + '_' + funcao))
                            {
                                Funcao_Contato__c funcaoToInsert = new Funcao_Contato__c(
                                    Account__c = varACR.AccountId, 
                                    Contact__c = varACR.ContactId, 
                                    Funcao_Contato__c = funcao
                                );
                                lstFuncoesToInsert.add(funcaoToInsert);
                                lstFuncoesToSync.add(
                                    new FuncaoWrapper(
                                        funcaoToInsert,
                                        Label.INTEGRATION_SYNC_CONTACT_INSERT
                                    ));
                            }
                        }
                        if(!String.isEmpty(varOldACR.Funcoes_Contato__c))
                        {
                            for(String funcao : varOldACR.Funcoes_Contato__c.split(';'))
                            {
                                if(!varACR.Funcoes_Contato__c.contains(funcao) && mapFuncaoContato.containsKey(chaveAcr + '_' + funcao))
                                {
                                    lstFuncoesToSync.add(
                                        new FuncaoWrapper(
                                            mapFuncaoContato.get(chaveAcr + '_' + funcao), 
                                            Label.INTEGRATION_SYNC_CONTACT_DELETE
                                        )
                                    );
                                }
                            }
                        }
                    }
                }   
            }
        }
        if(lstFuncoesToInsert.size() > 0)
            {
            Database.insert(lstFuncoesToInsert);
            }
        if(lstFuncoesToDelete.size() > 0)
        {
            Database.delete(lstFuncoesToDelete);
        }
        Map<Id, String> mapFuncaoToOperacao = new Map<Id, String>();
        for(FuncaoWrapper wrapper : lstFuncoesToSync)
                {
            if(String.isNotEmpty(wrapper.funcao.Id) && String.isNotEmpty(wrapper.operacao))
            {
                mapFuncaoToOperacao.put(wrapper.funcao.Id, wrapper.operacao);
                }
            }
        if(!mapFuncaoToOperacao.isEmpty())
        {
            IntegrationSyncContact.sendFuture(mapFuncaoToOperacao);
        }
}


    private class FuncaoWrapper {
        Funcao_Contato__c funcao;
        String operacao;
        public FuncaoWrapper(Funcao_Contato__c tempFuncao, String tempOperacao)
        {
            this.funcao = tempFuncao;
            this.operacao = tempOperacao;
        }


    }
}