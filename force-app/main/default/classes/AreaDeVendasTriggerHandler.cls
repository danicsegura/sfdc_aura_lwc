/**********************************************************************************************************************************
 * Copyright © 2019 BR Distribuidores
 * ================================================================================================================================
 * @description  Handler padrão para a trigger do Objeto Área de Vendas (Area_De_Vendas__c).
 * ================================================================================================================================
 * History
 * -------
 * VERSION  AUTHOR                  DATE            DETAIL      Description
 * 1.0      Daniel Fehnle           24/06/2019      Created     Implementação de handler da Trigger do objeto Área de Vendas (Area_De_Vendas__c)
 * 1.1      Daniel Lopes            03/04/2020      Edited      Implementação do método fillAreaDeVendasMigracao
 * 1.2      Diogo Braga             15/06/2020      Edited      Implementação de compartilhamento de conta customizado
 * 1.3      Daniela Segura          05/11/2021      Edited      Implementação do método updateAccountCentroDeLucro
 * 1.4      Daniela Segura          16/11/2021      Edited      Alteração no updateAccountCentroDeLucro (batch realiza o update)
 **********************************************************************************************************************************/
public without sharing class AreaDeVendasTriggerHandler extends TriggerHandler
{
    private List<Area_De_Vendas__c> lstNewAreaDeVendas;
    private List<Area_De_Vendas__c> lstOldAreaDeVendas;
    private Map<Id, Area_De_Vendas__c> mapNewAreaDeVendas;
    private Map<Id, Area_De_Vendas__c> mapOldAreaDeVendas;
    
    public AreaDeVendasTriggerHandler()
    {
        this.lstNewAreaDeVendas = (List<Area_De_Vendas__c>) Trigger.new;
        this.lstOldAreaDeVendas = (List<Area_De_Vendas__c>) Trigger.old;
        this.mapNewAreaDeVendas = (Map<Id, Area_De_vendas__c>) Trigger.newMap;
        this.mapOldAreaDeVendas = (Map<Id, Area_De_Vendas__c>) Trigger.oldMap;
    }

    public override void beforeInsert()
    {
        this.fillAreaDeVendasMigracao();
    }
    
    public override void afterInsert()
    {
        this.updateTerritories(true);
        new SharerAccount().shareAccount(AccountSharerBatch.BY_LIST_AREA, new List<String>{'Centro_De_Lucro__c','Emissor__c'});
        this.updateAccountCentroDeLucro();
    }
    
    public override void beforeUpdate()
    {
        this.fillAreaDeVendasMigracao();
        this.checkIfIntegrationIsRunning();
        this.updateAreaZone();
        this.updateSAP();
    }
    
    public override void afterUpdate()
    {
        this.updateTerritories(false);
        this.updateProducts();
        new SharerAccount().shareAccount(AccountSharerBatch.BY_LIST_AREA, new List<String>{'Centro_De_Lucro__c','Emissor__c'});
        RezoneamentoService.checkIfCentroLucroIsChanged(this.lstNewAreaDeVendas, this.mapOldAreaDeVendas);
        this.updateAccountCentroDeLucro();
    }
    
    public override void afterDelete()
    {
        this.removeTerritories();
        new SharerAccount().shareAccount(AccountSharerBatch.BY_LIST_AREA, new List<String>{'Centro_De_Lucro__c','Emissor__c'});
    }

     /******************************************************************
    * @description contexto de before delete
    * History
    * --------
    * VERSION      AUTHOR                  DATE            DETAIL      Description
    * 1.0          Diogo Braga             15/06/2020      Created     Created
    ******************************************************************/
    public override void beforeDelete() {
        sharerAccountOnDelete();
        this.updateAccountCentroDeLucro();
    }

    /******************************************************************
    * @description recalcula compartilhamento de conta no contexto de delete
    * History
    * --------
    * VERSION      AUTHOR                  DATE            DETAIL      Description
    * 1.0          Diogo Braga             15/06/2020      Created     Created
    ******************************************************************/
    private void sharerAccountOnDelete() {
        List<Id> listIds = new List<Id>();

        for(Area_De_Vendas__c areaVendas : lstOldAreaDeVendas) {
            if(String.isNotBlank(areaVendas.Emissor__c)) {
                listIds.add(areaVendas.Emissor__c);
            }
        }

        if(!listIds.isEmpty()) {
            Database.executeBatch(new AccountSharerBatch(listIds, AccountSharerBatch.BY_LIST_ACCOUNT), 100);
        }
    }


    /***************************************************************************************************************************
     * Purpose: SUP_6769 Preenchimento de campo Area_De_Vendas_Migracao__c
     * Parameters: void
     * Returns: void
     * Throws -
     *
     * History
     * --------
     * VERSION      AUTHOR                          DATE            DETAIL      Description
     * 1.0          Daniel Lopes                    03/04/2020      Created     Alimenta o campo Area_De_Vendas_Migracao__c
    ****************************************************************************************************************************/
    private void fillAreaDeVendasMigracao()
    {
        Set<Id> setAccount = new Set<Id>();

        for(Area_De_Vendas__c areaDeVendas : this.lstNewAreaDeVendas)
        {
            setAccount.add(areaDeVendas.Emissor__c);
        }

        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id, Codigo_SAP__c FROM Account WHERE Id IN :setAccount]);

        for(Area_De_Vendas__c areaDeVendas : this.lstNewAreaDeVendas)
        {
            if(mapAccount.get(areaDeVendas.Emissor__c).Codigo_SAP__c != null)
            {
                areaDeVendas.Area_De_Vendas_Migracao__c = mapAccount.get(areaDeVendas.Emissor__c).Codigo_SAP__c + '-' + areaDeVendas.Organizacao_De_Venda__c + '-' + areaDeVendas.Canal_De_Distribuicao__c + '-' + areaDeVendas.Setor_De_Atividade__c;
            }
            else
            {
                areaDeVendas.Area_De_Vendas_Migracao__c = areaDeVendas.Emissor__c + '-' + areaDeVendas.Organizacao_De_Venda__c + '-' + areaDeVendas.Canal_De_Distribuicao__c + '-' + areaDeVendas.Setor_De_Atividade__c;
            }
        }

        System.debug('lstNewAreaDeVendas: ' + lstNewAreaDeVendas);
    }
    
    /***************************************************************************************************************************
     * Purpose: US 1445 - Atualização do campo Territorios__c em Account
     * Parameters: void
     * Returns: void
     * Throws -
     *
     * History
     * --------
     * VERSION      AUTHOR                          DATE            DETAIL      Description
     * 1.0          Rafael A. Barbaroto de Araújo   15/07/2019      Created     Checa se houveram alterações em 
     *                                                                          Centro_De_Lucro__c e atualiza campo
     *                                                                          Account.Territorios__c se necessário.
    ****************************************************************************************************************************/
    private void updateTerritories(Boolean isInsert)
    {
        Set<Id> setEmissoresIds = new Set<Id>();
        
        for(Area_De_Vendas__c area : lstNewAreaDeVendas)
        {
            setEmissoresIds.add(area.Emissor__c);
        }
        
        
        Map<Id, Account> mapEmissores = new Map<Id, Account>([SELECT Id, Territorios__c FROM Account WHERE Id IN: setEmissoresIds]);
        
        for(Area_De_Vendas__c newArea : lstNewAreaDeVendas)
        {
            Account emissor = mapEmissores.get(newArea.Emissor__c);
            
            if(isInsert)
            {
                Util.addTerritoryToAccountField(newArea.Equipe_De_Vendas__c, emissor);
            }
            else
            {
                Area_De_Vendas__c oldArea = mapOldAreaDeVendas.get(newArea.Id);
                
                if(newArea.Centro_De_Lucro__c != oldArea.Centro_De_Lucro__c) // necessário atualizar Account.Territorios__c
                {
                    Util.addTerritoryToAccountField(newArea.Equipe_De_Vendas__c, emissor);
                    Util.removeTerritoryToAccountField(oldArea.Equipe_De_Vendas__c, emissor);
                }
            }
        }
        
        try
        {
            TriggerHandler.bypass('AccountTriggerHandler');
            Database.update(mapEmissores.values());
            TriggerHandler.clearBypass('AccountTriggerHandler');
        }catch(Exception e)
        {
            system.debug('################### ERROR HANDLER AREA DE VENDAS ############');
            system.debug('getCause: '+e.getCause());
            system.debug('getLineNumber: '+e.getLineNumber());
            system.debug('getMessage: '+e.getMessage());
            system.debug('################### FIM ERROR HANDLER AREA DE VENDAS ############');
            e.setMessage(Label.Erro_ao_atualizar_o_campo_territorio_da_Conta);
        }
    }
    
    /***************************************************************************************************************************
     * Purpose: US 1445 - Atualização do campo Territorios__c em Account
     * Parameters: void
     * Returns: void
     * Throws -
     *
     * History
     * --------
     * VERSION      AUTHOR                          DATE            DETAIL      Description
     * 1.0          Rafael A. Barbaroto de Araújo   15/07/2019      Created     Remove territórios do campo
     *                                                                          Account.Territorios__c
    ****************************************************************************************************************************/
    private void removeTerritories() {
        
        Set<Id> setEmissoresIds = new Set<Id>();
        
        for(Area_De_Vendas__c area : lstOldAreaDeVendas)
        {
            setEmissoresIds.add(area.Emissor__c);
        }
        
        Map<Id, Account> mapEmissores = new Map<Id, Account>([SELECT Id, Territorios__c FROM Account WHERE Id IN: setEmissoresIds]);
        
        for(Area_De_Vendas__c oldArea : lstOldAreaDeVendas)
        {
            Account emissor = mapEmissores.get(oldArea.Emissor__c);
            Util.removeTerritoryToAccountField(oldArea.Equipe_De_Vendas__c, emissor);
        }
        
        try
        {
            //TriggerHandler.bypass('AccountTriggerHandler');
            Database.update(mapEmissores.values());
            //TriggerHandler.clearBypass('AccountTriggerHandler');
        }catch(Exception e)
        {
            system.debug('################### ERROR HANDLER AREA DE VENDAS ############');
            system.debug('getCause: '+e.getCause());
            system.debug('getLineNumber: '+e.getLineNumber());
            system.debug('getMessage: '+e.getMessage());
            system.debug('################### FIM ERROR HANDLER AREA DE VENDAS ############');
            e.setMessage(Label.Erro_ao_atualizar_o_campo_territorio_da_Conta);
        }
        
    }
    
    /***************************************************************************************************************************
     * Purpose: US 1455 - Rezoneamento
     * Parameters: void
     * Returns: void
     * Throws -
     *
     * History
     * --------
     * VERSION      AUTHOR                          DATE            DETAIL      Description
     * 1.0          Rafael A. Barbaroto de Araújo   25/07/2019      Created     
    ****************************************************************************************************************************/
    private void updateAreaZone()
    {
        Set<Id> setIdCentroLucro = new Set<Id>();
        for(Area_De_Vendas__c newArea : lstNewAreaDeVendas)
        {
            if((newArea.Centro_De_Lucro__c != mapOldAreaDeVendas.get(newArea.Id).Centro_De_Lucro__c))
            {
                setIdCentroLucro.add(newArea.Centro_De_Lucro__c);
                newArea.Centro_De_Lucro_Alterado__c = true;
            }
        }
        
        if(!setIdCentroLucro.isEmpty())
        {
            Map<Id,Id> mapCentroLucro = new Map<Id,Id>();

            if (!Schema.sObjectType.Centro_De_Lucro__c.isAccessible()) {
                throw new CustomCrudException('Objecto Centro_De_Lucro__c não está acessível para esse usuário!');
            }
            
            List<Centro_De_Lucro__c> lstCentroLucro = [SELECT Id, Vendedor__c 
                                                       FROM Centro_De_Lucro__c
                                                       WHERE Id IN: setIdCentroLucro 
                                                       AND Vendedor__c != null
                                                       AND Vendedor__r.IsActive = true];
            
            for(Centro_De_Lucro__c centroLucro: lstCentroLucro)
            {
                mapCentroLucro.put(centroLucro.Id, centroLucro.Vendedor__c);
            }
            
            for(Area_De_Vendas__c areaVendas: lstNewAreaDeVendas)
            {
                system.debug(mapCentroLucro);
                system.debug(areaVendas.Centro_De_Lucro__c);
                if(mapCentroLucro.containsKey(areaVendas.Centro_De_Lucro__c))
                {
                    areaVendas.OwnerId = mapCentroLucro.get(areaVendas.Centro_De_Lucro__c);
                }
            }
        }
    }

    /***************************************************************************************************
     *      Purpose: Método update SAP (metodo novo utilizando batch)
     *      Parameters: -
     *      Returns: void
     *      Throws -
     * History
     * --------
     * VERSION      AUTHOR                  DATE        DETAIL      Description
     * 1.0          Daniel Meyer Dammous    30/08/2019  Created     Método update SAP (metodo novo utilizando batch)
     ***************************************************************************************************/
    /*private void updateSAPNew()
    {
        Database.executeBatch(
            new IntegrationAreaDeVendasBatch(lstNewAreaDeVendas, lstOldAreaDeVendas, mapNewAreaDeVendas, mapOldAreaDeVendas),
            2);
    }*/
    
    /***************************************************************************************************************************
     * Purpose: US 2635 - Sincronizar Áreas de Vendas com sistema SAP
     * Parameters: void
     * Returns: void
     * Throws -
     *
     * History
     * --------
     * VERSION      AUTHOR                          DATE            DETAIL      Description
     * 1.0          Rafael A. Barbaroto de Araújo   15/07/2019      Created     Chama integração SAP
    ****************************************************************************************************************************/
    private void updateSAP()
    {
        //new batch(Trigger.new, Trigger.old);
        //List<IntegrationElectedAreaDeVendas> lstElectedSObjects = new List<IntegrationElectedAreaDeVendas>();
        Set<Id> setIdAccountWithSAPCode = new Set<Id>();

        if (!Schema.sObjectType.Area_De_Vendas__c.isAccessible()) {
            throw new CustomCrudException('Objecto Area_De_Vendas__c não está acessível para esse usuário!');
        }

        List<Area_De_Vendas__c> lstAreaDeVendas =   [SELECT Emissor__r.Codigo_SAP__c, 
                                                    Emissor__c 
                                                    FROM Area_De_Vendas__c 
                                                    WHERE Id IN: lstNewAreaDeVendas];
        
        for(Area_De_Vendas__c newArea : lstAreaDeVendas) {
            if(String.isNotBlank(newArea.Emissor__r.Codigo_SAP__c)) {
                setIdAccountWithSAPCode.add(newArea.Emissor__c);
            }
        }
        
        Boolean integrateLongTexts = false;
        Boolean integrateBlock = false;
        for(Area_De_Vendas__c newArea : lstNewAreaDeVendas)
        {
            if(setIdAccountWithSAPCode.contains(newArea.Emissor__c) && newArea.Area_De_Vendas_Aprovada__c)
            {
                if(!newArea.Sync_SAP__c)
                {
                    AreaDeVendasIntegrationService.handleSendCreation(newArea.Id);
                    newArea.Integracao_Em_Processamento__c = true;
                } else
                {
                    Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.Area_De_Vendas__c.fields.getMap();
                    Area_De_Vendas__c oldArea = mapOldAreaDeVendas.get(newArea.Id);
                    Area_De_Vendas__c areaVendaToSerialize = oldArea.clone(true, true);
                    List<String> lstUpdatedField = new List<String>();
                    
                    for(String field : IntegrationSyncAreaDeVendas.FIELDS)
                    {
                        if(newArea.get(field) != oldArea.get(field))
                        {
                            lstUpdatedField.add(field);
                        }
                        
                        Schema.DisplayType fieldType = mapFields.get(field).getDescribe().getType();
                        if(fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.PICKLIST)
                        {
                            if(String.isBlank(String.valueOf(newArea.get(field))))
                            {
                                newArea.put(field, '');
                            }
                            if(String.isBlank(String.valueOf(areaVendaToSerialize.get(field))))
                            {
                                areaVendaToSerialize.put(field, '');
                            }
                        } else if(fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.PERCENT)
                        {
                            if(String.isBlank(String.valueOf(newArea.get(field))))
                            {
                                newArea.put(field, 0);
                            }
                            if(String.isBlank(String.valueOf(areaVendaToSerialize.get(field))))
                            {
                                areaVendaToSerialize.put(field, 0);
                            }
                        }else if(fieldType == Schema.DisplayType.REFERENCE)
                        {
                            if(String.isBlank(String.valueOf(areaVendaToSerialize.get(field))))
                            {
                                areaVendaToSerialize.put(field, null);
                            }
                        }
                    }
                    
                    if(newArea.Bloqueio_De_Faturamento__c != oldArea.Bloqueio_De_Faturamento__c || newArea.Motivo_Do_Bloqueio_De_Faturamento__c != oldArea.Motivo_Do_Bloqueio_De_Faturamento__c ||
                       newArea.Bloqueio_De_Ordem__c != oldArea.Bloqueio_De_Ordem__c || newArea.Motivo_Do_Bloqueio_De_Ordem__c != oldArea.Motivo_Do_Bloqueio_De_Ordem__c ||
                       newArea.Bloqueio_De_Remessa__c != oldArea.Bloqueio_De_Remessa__c || newArea.Motivo_Do_Bloqueio_De_Remessa__c != oldArea.Motivo_Do_Bloqueio_De_Remessa__c ||
                       newArea.Eliminacao__c != oldArea.Eliminacao__c)
                    {
                        integrateBlock = true;
                    }
                    
                    if(newArea.Texto_Nota_Fiscal__c != oldArea.Texto_Nota_Fiscal__c ||
                       newArea.Registro_ANP_Agente__c != oldArea.Registro_ANP_Agente__c ||
                       newArea.Registro_ANP_PA_Instalacao__c != oldArea.Registro_ANP_PA_Instalacao__c)
                    {
                        integrateLongTexts = true;
                    }
                    
                    if(!lstUpdatedField.isEmpty() || integrateLongTexts || integrateBlock)
                    {
                        if(String.isBlank(oldArea.Motivo_Do_Bloqueio_De_Faturamento__c)) { areaVendaToSerialize.Motivo_Do_Bloqueio_De_Faturamento__c = ''; }
                        if(String.isBlank(oldArea.Motivo_Do_Bloqueio_De_Ordem__c)) { areaVendaToSerialize.Motivo_Do_Bloqueio_De_Ordem__c = ''; }
                        if(String.isBlank(oldArea.Motivo_Do_Bloqueio_De_Remessa__c)) { areaVendaToSerialize.Motivo_Do_Bloqueio_De_Remessa__c = ''; }
                        
                        areaVendaToSerialize.Chamada_SAP__c = '';
                        newArea.Integracao_Em_Processamento__c = true;
                        newArea.Chamada_SAP__c = JSON.serialize(areaVendaToSerialize, false).replace('&amp', '&');
                        
                        AreaDeVendasIntegrationService.handleSendUpdate(newArea.Id, lstUpdatedField, integrateLongTexts, integrateBlock);
                    }
                }
            }
            //lstElectedSObjects.add(new IntegrationElectedAreaDeVendas(newArea, true, false));
        }
    }

    /******************************************************************************************************************************************
     *      Purpose: Copia o incoterm e base da área de vendas para os produtos com mesmos valores
     *      Parameters: -
     *      Returns: void
     *      Throws -
     * History
     * --------
     * VERSION      AUTHOR          DATE            DETAIL      Description
     * 1.0          André Bunya     11/09/2019      Created     Ao alterar o incoterm ou base da área de vendas, todos os produtos que tiverem
     *                                                          os mesmos valores antes da alteração devem ser atualizados com o novo valor
     * 1.1          Daniel Lopes    22/03/2021      Updated     INC0129211 | Alteração para remover For Loop encadeado e simplificar código como um todo. 
     ******************************************************************************************************************************************/
    private void updateProducts()
    {
        Set<Id> setAreaDeVendasId = new Set<Id>();
        List<Produtos_Elegiveis__c> lstProdutosElegiveis = new List<Produtos_Elegiveis__c>();

        for(Area_De_Vendas__c newAreaDeVendas : this.lstNewAreaDeVendas)
        {
            if(newAreaDeVendas.Incoterms__c != mapOldAreaDeVendas.get(newAreaDeVendas.Id).Incoterms__c || 
               newAreaDeVendas.Centro_Fornecedor__c != mapOldAreaDeVendas.get(newAreaDeVendas.Id).Centro_Fornecedor__c)
            {
                setAreaDeVendasId.add(newAreaDeVendas.Id);
            }
        }

        if(!setAreaDeVendasId.isEmpty())
        {
            Database.executeBatch(new UpdateProdElegivelBatch(setAreaDeVendasId, UpdateProdElegivelBatch.BY_AREA));
        }
    }
    /**********************************************************************************************************************************
    * ================================================================================================================================
    * Purpose: Bloquear atualização de registros quando estiver sendo realizada a integração com o SAP
    * ================================================================================================================================
    * History
    * -------
    * VERSION     AUTHOR                  DATE            DETAIL      Description
    * 1.0         Daniel Fehnle           14/10/2019      Created
    **********************************************************************************************************************************/
    private void checkIfIntegrationIsRunning()
    {
        for(Area_De_Vendas__c areaDeVendas: lstNewAreaDeVendas)
        {
            if(areaDeVendas.Integracao_Em_Processamento__c && areaDeVendas.Integracao_Em_Processamento__c == mapOldAreaDeVendas.get(areaDeVendas.Id).Integracao_Em_Processamento__c)
            {
                areaDeVendas.addError(LABEL.Check_If_Integration_Is_Running);
            }
        }
    }

    /**********************************************************************************************************************************
     * Copyright © 2019 BR Distribuidores
     * ================================================================================================================================
     * Purpose: Sub-classe para organizar sObjects para o batch
     * ================================================================================================================================
     * History
     * -------
     * VERSION  AUTHOR                  DATE            DETAIL      Description
     * 1.0      Daniel Meyer Dammous    30/08/2019      Created     Sub-classe para organizar sObjects para o batch
     **********************************************************************************************************************************/
    /*public class IntegrationElectedAreaDeVendas
    {
        private Area_De_Vendas__c varAreaVendas;
        private Boolean isUpdate;
        private Boolean isInsert;

        public IntegrationElectedAreaDeVendas(Area_De_Vendas__c varAreaVendas, Boolean isUpdate, Boolean isInsert)
        {
            this.isUpdate = isUpdate;
            this.isInsert = isInsert;
        }

    }*/

    /**********************************************************************************************************************************
     * Copyright © 2021 BR Distribuidores
     * ================================================================================================================================
     * Purpose: US 15353 - Atualiza os campos Centro de Lucro Principal / Aviação nas Contas relacionadas
     * ================================================================================================================================
     * History
     * -------
     * VERSION  AUTHOR                  DATE            DETAIL      Description
     * 1.0      Daniela Segura          27/10/2021      Created     Atualização dos campos Centro de Lucro (Principal e Aviação)
     * 1.1      Daniela Segura          16/11/2021      Edited      Chamada para AccountUpdateCentroDeLucroQueueable
     **********************************************************************************************************************************/
    private void updateAccountCentroDeLucro(){
        Set<Id> setAccountId = new Set<Id>();

        if(Trigger.isUpdate){
            for(Id areaVendaId : mapNewAreaDeVendas.keySet()){
                if(mapNewAreaDeVendas.get(areaVendaId).Centro_De_Lucro__c != mapOldAreaDeVendas.get(areaVendaId).Centro_De_Lucro__c){
                    setAccountId.add(mapNewAreaDeVendas.get(areaVendaId).Emissor__c);
                }
            }
        }else if(Trigger.isInsert){
            for(Id areaVendaId : mapNewAreaDeVendas.keySet()){
                setAccountId.add(mapNewAreaDeVendas.get(areaVendaId).Emissor__c);
            }
        }else{
            for(Id areaVendaId : mapOldAreaDeVendas.keySet()){
                setAccountId.add(mapOldAreaDeVendas.get(areaVendaId).Emissor__c);
            }
        }

        if(!setAccountId.isEmpty()){
            AccountUpdateCentroDeLucroQueueable queueable = new AccountUpdateCentroDeLucroQueueable(setAccountId);
            System.enqueueJob(queueable);
        }
    }
}