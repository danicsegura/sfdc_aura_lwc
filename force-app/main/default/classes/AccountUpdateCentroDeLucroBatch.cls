/******************************************************************************************************************************************
 * Copyright © 2021 BR Distribuidores
 * ========================================================================================================================================
 * Purpose: Classe batch para atualizar os campos Centro de Lucro (Principal e Aviação) de Contas
 * ========================================================================================================================================
 * History
 * -------
 * VERSION      AUTHOR              DATE           DETAIL      Description
 * 1.0          Daniela Segura      16/11/2021     Created     Versão Inicial
 ******************************************************************************************************************************************/
public class AccountUpdateCentroDeLucroBatch implements Database.Batchable<sObject>{
    private String query;
    private Set<Id> setAccountId;
    
    public AccountUpdateCentroDeLucroBatch(){
		this.query = 'SELECT Id FROM Account';        
    }
    
    public AccountUpdateCentroDeLucroBatch(Set<Id> setAccountId){
        this.setAccountId = setAccountId;
		this.query = 'SELECT Id FROM Account WHERE Id IN: setAccountId';
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope){
        Set<Id> setAccountId = new Set<Id>();
        Map<Id, String> mapCentroLucroToEmailVendedor = new Map<Id, String>();
        List<LogApexException__c> lstLogApexException = new List<LogApexException__c>();

        for(Account varAccount : scope){
            Id accountId = varAccount.Id;
            setAccountId.add(accountId);
        }

        CentroLucroWrapper wrapper = buscarCentroLucroPrincipalEAviacao(setAccountId);

        List<Centro_De_Lucro__c> lstCentroLucro = [SELECT Id, Vendedor__r.Email 
                                                FROM Centro_De_Lucro__c 
                                                WHERE Id IN : wrapper.mapAccountCentroLucroPrincipal.values() 
                                                OR Id IN : wrapper.mapAccountCentroLucroAviacao.values()];

        for(Centro_De_Lucro__c varCentroLucro : lstCentroLucro){
            mapCentroLucroToEmailVendedor.put(varCentroLucro.Id, varCentroLucro.Vendedor__r.Email);
        }

        for(Account varAccount : scope){
            if(wrapper.mapAccountCentroLucroPrincipal.containsKey(varAccount.Id)){
                String centroLucroId = wrapper.mapAccountCentroLucroPrincipal.get(varAccount.Id);
                varAccount.Centro_de_Lucro_Principal__c = centroLucroId;
                if(mapCentroLucroToEmailVendedor.containsKey(centroLucroId)){
                    varAccount.Email_do_Executivo_de_Venda__c = mapCentroLucroToEmailVendedor.get(centroLucroId);
                }

                if(!wrapper.mapAccountCentroLucroAviacao.containsKey(varAccount.Id)){
                    varAccount.Centro_de_Lucro_Avia_o__c = null;
                }
            }

            //caso tenha somente CL Aviação, ele é preenchido também no Principal
            if(wrapper.mapAccountCentroLucroAviacao.containsKey(varAccount.Id)){
                String centroLucroId = wrapper.mapAccountCentroLucroAviacao.get(varAccount.Id);
                varAccount.Centro_de_Lucro_Avia_o__c = centroLucroId;
                
                if(!wrapper.mapAccountCentroLucroPrincipal.containsKey(varAccount.Id)){
                    varAccount.Centro_de_Lucro_Principal__c = centroLucroId;
                    if(mapCentroLucroToEmailVendedor.containsKey(centroLucroId)){
                        varAccount.Email_do_Executivo_de_Venda__c = mapCentroLucroToEmailVendedor.get(centroLucroId);
                    }
                }
            }

            //caso não tenha Centro de Lucro Principal e nem Aviação, limpa o campo
            if(!wrapper.mapAccountCentroLucroPrincipal.containsKey(varAccount.Id) && !wrapper.mapAccountCentroLucroAviacao.containsKey(varAccount.Id)){
                varAccount.Centro_de_Lucro_Principal__c = null;
                varAccount.Centro_de_Lucro_Avia_o__c = null;
                varAccount.Email_do_Executivo_de_Venda__c = '';
            }
        }

        TriggerHandler.bypass('AccountTriggerHandler');

        Database.SaveResult[] srListAccount = Database.update(scope, false);
        for (Database.SaveResult srAccount : srListAccount) 
        {
            if (!srAccount.isSuccess()) 
            {
                // Operation failed, so get all errors                
                for(Database.Error errorAccount : srAccount.getErrors()) 
                {
                    LogApexException__c regLogApexException = new LogApexException__c();
                    regLogApexException.Class_Name__c = 'AccountUpdateCentroDeLucroBatch';
                    regLogApexException.Method_Name__c = 'execute / update scope';
                    regLogApexException.Exception_Message__c = errorAccount.getStatusCode() + ': ' + errorAccount.getMessage() + ' >>>> ' + errorAccount.getFields();
                    regLogApexException.Observacao__c = 'Id da Conta: ' + srAccount.getId();
                    regLogApexException.log_de_erro__c = true;                

                    lstLogApexException.add(regLogApexException);
                }
            }
        }

        if(!lstLogApexException.isEmpty())
            Util.insereLstLogApexException(lstLogApexException);

        TriggerHandler.clearbypass('AccountTriggerHandler');
    }

        /**********************************************************************************************************************************
    * ================================================================================================================================
    * @Description: US 15353 - Realiza a lógica para determinar os Centros de Lucro (Principal e Aviação) da Conta
    * ================================================================================================================================
    * History
    * -------
    * VERSION     AUTHOR                  DATE            DETAIL      Description
    * 1.0         Daniela Segura          16/11/2021      Created     Determina o Centro de Lucro Principal / Aviação da Conta
    **********************************************************************************************************************************/   

    public static CentroLucroWrapper buscarCentroLucroPrincipalEAviacao(Set<Id> setAccountId){
        Map<Area_De_Vendas__c, Id> mapAreaVendasAccountId = new Map<Area_De_Vendas__c, Id>();
        Map<Id, Id> mapAccountCentroLucroPrincipal = new Map<Id, Id>();
        Map<Id, Id> mapAccountCentroLucroAviacao = new Map<Id, Id>();
        Map<Id, Integer> mapAccountSetorDeAtividade = new Map<Id, Integer>();

        List<Area_De_Vendas__c> lstAreaVendas = [SELECT Id, Setor_De_Atividade__c, Centro_De_Lucro__c, Emissor__c 
                                                FROM Area_De_Vendas__c 
                                                WHERE Emissor__c IN :setAccountId];

        for(Area_De_Vendas__c varAreaVendas : lstAreaVendas){
            mapAreaVendasAccountId.put(varAreaVendas, varAreaVendas.Emissor__c);
        }

        for(Area_De_Vendas__c varAreaVendas : mapAreaVendasAccountId.keySet()){

            if(varAreaVendas.Setor_De_Atividade__c == '03'){
                mapAccountCentroLucroAviacao.put(varAreaVendas.Emissor__c,varAreaVendas.Centro_De_Lucro__c);
            }
            else if(varAreaVendas.Setor_De_Atividade__c != '03' && varAreaVendas.Setor_De_Atividade__c != null && !mapAccountCentroLucroPrincipal.containsKey(varAreaVendas.Emissor__c)){
                mapAccountCentroLucroPrincipal.put(varAreaVendas.Emissor__c,varAreaVendas.Centro_De_Lucro__c);
                mapAccountSetorDeAtividade.put(varAreaVendas.Emissor__c, Integer.valueOf(varAreaVendas.Setor_De_Atividade__c));
            }
            else if(varAreaVendas.Setor_De_Atividade__c != '03' && varAreaVendas.Setor_De_Atividade__c != null && mapAccountCentroLucroPrincipal.containsKey(varAreaVendas.Emissor__c)){
                if(Integer.valueOf(varAreaVendas.Setor_De_Atividade__c) < mapAccountSetorDeAtividade.get(varAreaVendas.Emissor__c)){
                    mapAccountCentroLucroPrincipal.put(varAreaVendas.Emissor__c,varAreaVendas.Centro_De_Lucro__c);
                    mapAccountSetorDeAtividade.put(varAreaVendas.Emissor__c, Integer.valueOf(varAreaVendas.Setor_De_Atividade__c));
                }
            }
        }

        CentroLucroWrapper wrapper = new CentroLucroWrapper(mapAccountCentroLucroPrincipal, mapAccountCentroLucroAviacao);
        return wrapper;
    }

        /**********************************************************************************************************************************
    * ================================================================================================================================
    * @Description: US 15353 - Classe wrapper dos Centros de Lucro (Principal e Aviação) da Conta
    * ================================================================================================================================
    * History
    * -------
    * VERSION     AUTHOR                  DATE            DETAIL      Description
    * 1.0         Daniela Segura          16/11/2021      Created     Classe wrapper dos Centros de Lucro (Principal e Aviação)
    **********************************************************************************************************************************/   

    public class CentroLucroWrapper{
        public Map<Id, Id> mapAccountCentroLucroPrincipal = new Map<Id, Id>();
        public Map<Id, Id> mapAccountCentroLucroAviacao = new Map<Id, Id>();

        public CentroLucroWrapper(Map<Id, Id> tempMapAccountCentroLucroPrincipal, Map<Id, Id> TempMapAccountCentroLucroAviacao){
            this.mapAccountCentroLucroPrincipal = tempMapAccountCentroLucroPrincipal;
            this.mapAccountCentroLucroAviacao = TempMapAccountCentroLucroAviacao;
        }
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('AccountUpdateCentroDeLucroBatch finalizado.');
    }
}