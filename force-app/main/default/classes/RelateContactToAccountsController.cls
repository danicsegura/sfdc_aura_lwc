/******************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ========================================================================================================================================
* Purpose: US 15477 - Controller para o componente lwc relateContactToAccounts
* ========================================================================================================================================
* History
* -------
* VERSION   AUTHOR                  DATE        DETAIL      Description
* 1.0       Daniela Segura          24/11/2021  Created     Versão inicial
******************************************************************************************************************************************/
public with sharing class RelateContactToAccountsController {

    /**********************************************************************************************************************************
    * ================================================================================================================================
    * Purpose: US 15477 - Obter os registros selecionados pelo componente
    * ================================================================================================================================
    * History
    * -------
    * VERSION     AUTHOR                  DATE            DETAIL      Description
    * 1.0         Daniela Segura          24/11/2021      Created     Versão Inicial
    **********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> getRecords(String recordId, String searchKey, String searchBy, Integer pageNumber){
        Integer pageSize = 10;
        Integer offSet = (pageNumber - 1) * pageSize;
        List<ResultWrapper> lstResultWrapper = new List<ResultWrapper>();

        switch on searchBy{
            when 'account'{
                List<Account> lstAccount = [SELECT Id, Name, Numero_Do_Documento__c, Codigo_SAP__c, Grupo_Plano_Contas__r.Name
                                            FROM Account 
                                            WHERE Name LIKE :'%' + searchKey + '%'
                                            AND Id NOT IN (SELECT AccountId 
                                                            FROM AccountContactRelation 
                                                            WHERE ContactId =: recordId)
                                            ORDER BY Name
                                            LIMIT 10
                                            OFFSET :offSet];

                for(Account varAccount : lstAccount){
                    lstResultWrapper.add(new ResultWrapper( varAccount.Id,
                                                    varAccount.Name, 
                                                    varAccount.Numero_Do_Documento__c, 
                                                    varAccount.Codigo_SAP__c,
                                                    varAccount.Grupo_Plano_Contas__r.Name
                                                    )
                    );
                }
            }
            when 'grupoPlanoContas'{
                List<Account> lstAccountsFromGroup = [SELECT Id, Grupo_Plano_Contas__c FROM Account WHERE Grupo_Plano_Contas__c != null];
                List<Id> lstAccountFromGroupIds = new List<Id>();
    
                for(Account varAccount : lstAccountsFromGroup){
                    lstAccountFromGroupIds.add(varAccount.Grupo_Plano_Contas__c);
                }
    
                List<Grupo_Plano_Contas__c> lstGrupoPlanoContas = [SELECT Id, Name, Codigo__c 
                                                                    FROM Grupo_Plano_Contas__c
                                                                    WHERE Name LIKE :'%' + searchKey + '%'
                                                                    AND Id IN :lstAccountFromGroupIds
                                                                    ORDER BY Name
                                                                    LIMIT 10
                                                                    OFFSET :offSet];
    
                for(Grupo_Plano_Contas__c varGrupo : lstGrupoPlanoContas){
                    lstResultWrapper.add(new ResultWrapper( varGrupo.Id,
                                                            varGrupo.Name,
                                                            varGrupo.Codigo__c
                                                            )
                    );
                }
            }
            when 'cnpjBasico'{
                List<Account> lstAccount = [SELECT Id, Name, Numero_Do_Documento__c, Codigo_SAP__c, Grupo_Plano_Contas__r.Name
                                            FROM Account 
                                            WHERE Numero_Do_Documento__c LIKE : searchKey + '%'
                                            AND Tipo_De_Documento__c = 'CNPJ'
                                            AND Id NOT IN (SELECT AccountId 
                                                            FROM AccountContactRelation 
                                                            WHERE ContactId =: recordId)
                                            ORDER BY Name
                                            LIMIT 10
                                            OFFSET :offSet];
    
                for(Account varAccount : lstAccount){
                    lstResultWrapper.add(new ResultWrapper( varAccount.Id,
                                            varAccount.Name, 
                                            varAccount.Numero_Do_Documento__c, 
                                            varAccount.Codigo_SAP__c,
                                            varAccount.Grupo_Plano_Contas__r.Name
                                            )
                    );
                }
            }
        }
        return lstResultWrapper;
    }

    /**********************************************************************************************************************************
    * ================================================================================================================================
    * Purpose: US 15477 - Inserir os registros de AccountContactRelation (chama o batch RelateContactToAccountsBatch)
    * ================================================================================================================================
    * History
    * -------
    * VERSION     AUTHOR                  DATE            DETAIL      Description
    * 1.0         Daniela Segura          24/11/2021      Created     Versão Inicial
    **********************************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static void insertAccountContactRelations(String contactId, String selectedRecordsStr, String objectType, String acrString){
        List<AccountContactRelation> lstACRtoInsert = new List<AccountContactRelation>();
        List<ResultWrapper> lstResultWrapper = (List<ResultWrapper>) JSON.deserialize(selectedRecordsStr, List<ResultWrapper>.class);
        AccountContactRelation acr = (AccountContactRelation) JSON.deserialize(acrString, AccountContactRelation.class);

        if(objectType == 'account' || objectType == 'cnpjBasico'){
            for(ResultWrapper varResultWrapper : lstResultWrapper){
                lstACRtoInsert.add(new AccountContactRelation(  AccountId = varResultWrapper.Id,
                                                                ContactId = contactId,
                                                                Funcoes_Contato__c = acr.Funcoes_Contato__c,
                                                                Roles = acr.Roles,
                                                                Boleto_Por_Email__c = acr.Boleto_Por_Email__c,
                                                                Relationship_Strength__c = acr.Relationship_Strength__c,
                                                                StartDate = acr.StartDate,
                                                                EndDate = acr.EndDate,
                                                                IsActive = acr.IsActive
                ));
            }
        }else if(objectType == 'grupoPlanoContas'){
            Set<Id> setGruposPCIds = new Set<Id>();
            Set<Id> setAccountWithRelation = new Set<Id>();

            for(ResultWrapper varResultWrapper : lstResultWrapper){
                setGruposPCIds.add(varResultWrapper.Id);
            }

            List<Account> lstAccountWithRelation = [SELECT Id 
                                                    FROM Account 
                                                    WHERE Id IN (SELECT AccountId 
                                                                FROM AccountContactRelation 
                                                                WHERE ContactId =: contactId)];

            for(Account varAccount : lstAccountWithRelation){
                setAccountWithRelation.add(varAccount.Id);
            }

            List<Account> lstAccountNoRelation = [SELECT Id FROM Account WHERE Grupo_Plano_Contas__c IN :setGruposPCIds AND Id NOT IN :setAccountWithRelation];

            for(Account varAccount : lstAccountNoRelation){
                lstACRtoInsert.add(new AccountContactRelation(  AccountId = varAccount.Id,
                                                                ContactId = contactId,
                                                                Funcoes_Contato__c = acr.Funcoes_Contato__c,
                                                                Roles = acr.Roles,
                                                                Boleto_Por_Email__c = acr.Boleto_Por_Email__c,
                                                                Relationship_Strength__c = acr.Relationship_Strength__c,
                                                                StartDate = acr.StartDate,
                                                                EndDate = acr.EndDate,
                                                                IsActive = acr.IsActive
                ));
            }
        }

        if(!lstACRtoInsert.isEmpty()){
            Database.executeBatch(new RelateContactToAccountsBatch(lstACRtoInsert));
        }
    }

/**********************************************************************************************************************************
* ================================================================================================================================
* Purpose: US 15477 - Retorna os Ids dos registros selecionados (utilizado para forçar a atualização dos selected-rows da datatable)
* ================================================================================================================================
* History
* -------
* VERSION     AUTHOR                  DATE            DETAIL      Description
* 1.0         Daniela Segura          24/11/2021      Created     Versão Inicial
**********************************************************************************************************************************/
    @AuraEnabled
    public static List<Id> returnSelectedIds(String selectedRecordsString){
        List<ResultWrapper> lstResultWrapper = (List<ResultWrapper>) JSON.deserialize(selectedRecordsString, List<ResultWrapper>.class);
        List<Id> lstIds = new List<Id>();
        for(ResultWrapper varResultWrapper : lstResultWrapper){
            lstIds.add(varResultWrapper.Id);
        }
        return lstIds;
    }

/**********************************************************************************************************************************
* ================================================================================================================================
* Purpose: US 15477 - Buscar os valores da picklist Funções do Contato do objeto AccountContactRelation
* ================================================================================================================================
* History
* -------
* VERSION     AUTHOR                  DATE            DETAIL      Description
* 1.0         Daniela Segura          20/01/2022      Created     Versão Inicial
**********************************************************************************************************************************/
@AuraEnabled
public static Map<String, String> getPicklistFuncoesDoContato(){
    Map<String, String> mapValueToLabel = new Map<String, String>();
    List<Schema.PicklistEntry> lstPicklistEntries = Util.getPicklistValues('AccountContactRelation', 'Funcoes_Contato__c');

    for(Schema.PicklistEntry varPicklistEntry : lstPicklistEntries){
        mapValueToLabel.put(varPicklistEntry.getValue(), varPicklistEntry.getLabel());
    }

    return mapValueToLabel;
}

/**********************************************************************************************************************************
* ================================================================================================================================
* Purpose: US 15477 - Buscar os valores da picklist Papéis (Roles) do objeto AccountContactRelation
* ================================================================================================================================
* History
* -------
* VERSION     AUTHOR                  DATE            DETAIL      Description
* 1.0         Daniela Segura          20/01/2022      Created     Versão Inicial
**********************************************************************************************************************************/
@AuraEnabled
public static Map<String, String> getPicklistRoles(){
    Map<String, String> mapValueToLabel = new Map<String, String>();
    List<Schema.PicklistEntry> lstPicklistEntries = Util.getPicklistValues('AccountContactRelation', 'Roles');

    for(Schema.PicklistEntry varPicklistEntry : lstPicklistEntries){
        mapValueToLabel.put(varPicklistEntry.getValue(), varPicklistEntry.getLabel());
    }

    return mapValueToLabel;
}

/**********************************************************************************************************************************
* ================================================================================================================================
* Purpose: US 15477 - Buscar os valores da picklist Relationship Strength do objeto AccountContactRelation
* ================================================================================================================================
* History
* -------
* VERSION     AUTHOR                  DATE            DETAIL      Description
* 1.0         Daniela Segura          21/01/2022      Created     Versão Inicial
**********************************************************************************************************************************/
@AuraEnabled
public static Map<String, String> getPicklistRelationshipStrength(){
    Map<String, String> mapValueToLabel = new Map<String, String>();
    List<Schema.PicklistEntry> lstPicklistEntries = Util.getPicklistValues('AccountContactRelation', 'Relationship_Strength__c');

    for(Schema.PicklistEntry varPicklistEntry : lstPicklistEntries){
        mapValueToLabel.put(varPicklistEntry.getValue(), varPicklistEntry.getLabel());
    }

    return mapValueToLabel;
}

/**********************************************************************************************************************************
* ================================================================================================================================
* Purpose: US 15477 - Classe wrapper que une os atributos necessários para serem utilizados pelo componente
* ================================================================================================================================
* History
* -------
* VERSION     AUTHOR                  DATE            DETAIL      Description
* 1.0         Daniela Segura          24/11/2021      Created     Versão Inicial
**********************************************************************************************************************************/
    public class ResultWrapper{
        @AuraEnabled public String Id;
        @AuraEnabled public String name;
        @AuraEnabled public String numeroDocumento;
        @AuraEnabled public String nomeGrupo;
        @AuraEnabled public String codigoSAP;
        @AuraEnabled public String codigoGrupo;

        public ResultWrapper(String tempAccountId, String tempName, String tempNumDoc, String tempCodigoSAP, String tempNomeGrupo){
            this.Id = tempAccountId;
            this.name = tempName;
            this.numeroDocumento = tempNumDoc;
            this.nomeGrupo = tempNomeGrupo;
            this.codigoSAP = tempCodigoSAP;
        }

        public ResultWrapper(String tempGrupoId, String tempNomeGrupo, String tempCodigoGrupo){
            this.Id = tempGrupoId;
            this.nomeGrupo = tempNomeGrupo;
            this.codigoGrupo = tempCodigoGrupo;
        }
    }
}