/*******************************************************************************************************************************
 * Copyright © 2019 BR Distribuidores
 * =============================================================================================================================
 * @description  Handler da Trigger de Centro_De_Lucro__c
 * =============================================================================================================================
 * History
 * -------
 * VERSION 	AUTHOR 							DATE 		DETAIL 		Description
 * 1.0 		Rafael A. Barbaroto de Araújo 	26/06/2019 	Created 	Implementação de handler para contextos da trigger de
 * 																	Equipe_De_Vendas__c e suas respectivas regras de negócio.
 * 1.1      Daniel Lopes                    27/03/2020  Edited      Alteração na chamada da classe AreaDeVendasUpdateBatch
 * 1.2      Diogo Braga                     15/06/2020  Edited      Add compartilhamento de conta
 * 1.3      Daniela Segura                  05/11/2021  Edited      Implementação do método updateAccountCentroDeLucro
 * 1.4      Daniela Segura                  16/11/2021  Edited      Alteração no updateAccountCentroDeLucro (chama batch)
********************************************************************************************************************************/
public with sharing class CentroDeLucroTriggerHandler extends TriggerHandler {

	private Map<Id, Centro_De_Lucro__c> mapNewCentroDeLucro;
    private Map<Id, Centro_De_Lucro__c> mapOldCentroDeLucro;
    private List<Centro_De_Lucro__c> lstNewCentroDeLucro;
    private List<Centro_De_Lucro__c> lstOldCentroDeLucro;

    public CentroDeLucroTriggerHandler() {
        this.lstNewCentroDeLucro = (List<Centro_De_Lucro__c>) Trigger.new;
        this.lstOldCentroDeLucro = (List<Centro_De_Lucro__c>) Trigger.old;
        this.mapNewCentroDeLucro = (Map<Id, Centro_De_Lucro__c>) Trigger.newMap;
        this.mapOldCentroDeLucro = (Map<Id, Centro_De_Lucro__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        this.updateOwner();
    }

    public override void afterInsert() {
        this.addTerritoryUser();
        new SharerAccount().shareAccount(AccountSharerBatch.BY_LIST_CENTRO, new List<String>{'Equipe_De_Vendas__c'});
    }

    public override void beforeUpdate() {
        this.updateOwner();
    }

    public override void afterUpdate() {
        this.updateTerritoryUser();
        this.updateSAP();
        new SharerAccount().shareAccount(AccountSharerBatch.BY_LIST_CENTRO, new List<String>{'Equipe_De_Vendas__c'});
        this.updateAccountCentroDeLucro();
    }

    public override void afterDelete() {
        this.removeTerritoryUser();
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

        if (!Schema.sObjectType.Centro_De_Lucro__c.isAccessible()) {
            throw new CustomCrudException('Objecto Centro_De_Lucro__c não está acessível para esse usuário!');
        }

        for(Area_de_Vendas__c varObject : [SELECT Id FROM Area_de_Vendas__c WHERE Centro_De_Lucro__c IN :mapOldCentroDeLucro.keySet()]) {
            listIds.add(varObject.Id);
        }

        if(!listIds.isEmpty()) {
            Database.executeBatch(new AccountSharerBatch(listIds, AccountSharerBatch.BY_LIST_AREA), 100);
        }
    }

	/***************************************************************************************************************************************************
	 * Purpose: US1445 - Associação de vendedor a território - Método executado na remoção de Centro de Lucro
	 * Parameters: -
	 * Returns: void
	 * Throws -
	 *
	 * History
	 * --------
	 * VERSION 		AUTHOR 							DATE 			DETAIL 		Description
	 * 1.0 			Rafael A. Barbaroto de Araújo 	11/07/2019 		Created 	Remove associação do Vendedor (User) do Centro de Lucro ao Território
	 * 																			respectivo à sua equipe de vendas
	***************************************************************************************************************************************************/
    private void removeTerritoryUser() {

        Set<Id> lstIdEquipeDeVendas = new Set<Id>();
        Set<Id> lstVendedores = new Set<Id>();

        for(Centro_De_Lucro__c centro : lstOldCentroDeLucro) {
            lstIdEquipeDeVendas.add(centro.Equipe_De_Vendas__c);
            lstVendedores.add(centro.Vendedor__c);
        }

        if (!Schema.sObjectType.Equipe_De_Vendas__c.isAccessible()) {
            throw new CustomCrudException('Objecto Equipe_De_Vendas__c não está acessível para esse usuário!');
        }

        List<Equipe_De_Vendas__c> lstEquipeDeVendas =   [SELECT Id, 
                                                        Codigo_Equipe_De_Venda__c 
                                                        FROM Equipe_De_Vendas__c 
                                                        WHERE Id IN :lstIdEquipeDeVendas];

        List<String> territoryNames = new List<String>();

        for(Equipe_De_Vendas__c equipe : lstEquipeDeVendas) {
            territoryNames.add(equipe.Codigo_Equipe_De_Venda__c);
        }

        if (!Schema.sObjectType.Territory2.isAccessible()) {
            throw new CustomCrudException('Objecto Territory2 não está acessível para esse usuário!');
        }

        List<Territory2> territories = new List<Territory2>();

        territories =   [SELECT Id 
                        FROM Territory2 
                        WHERE Name IN :territoryNames];

        if (!Schema.sObjectType.UserTerritory2Association.isAccessible()) {
            throw new CustomCrudException('Objecto UserTerritory2Association não está acessível para esse usuário!');
        }

        List<UserTerritory2Association> associations =  [SELECT Id 
                                                        FROM UserTerritory2Association
                                                        WHERE Territory2Id IN :territories 
                                                        AND UserId IN :lstVendedores];

        for(UserTerritory2Association association : associations) {
            TerritoryService.disassociateUser(association.Id);
        }

    }

    /***************************************************************************************************************************************************
	 * Purpose: US1445 - Associação de vendedor a território - Método executado na criação de Centro de Lucro
	 * Parameters: -
	 * Returns: void
	 * Throws -
	 *
	 * History
	 * --------
	 * VERSION 		AUTHOR 							DATE 			DETAIL 		Description
	 * 1.0 			Rafael A. Barbaroto de Araújo 	11/07/2019 		Created 	Associa Vendedor (User) do Centro de Lucro ao Território
	 * 																			respectivo à sua equipe de vendas
	***************************************************************************************************************************************************/
    private void addTerritoryUser() {

        Set<Id> lstIdEquipeDeVendas = new Set<Id>();

        for(Centro_De_Lucro__c centroDeLucro : lstNewCentroDeLucro) {
            lstIdEquipeDeVendas.add(centroDeLucro.Equipe_De_Vendas__c);
        }

        if (!Schema.sObjectType.Equipe_De_Vendas__c.isAccessible()) {
            throw new CustomCrudException('Objecto Equipe_De_Vendas__c não está acessível para esse usuário!');
        }

        List<Equipe_De_Vendas__c> lstEquipeDeVendas =   [SELECT Id, 
                                                        Codigo_Equipe_De_Venda__c 
                                                        FROM Equipe_De_Vendas__c 
                                                        WHERE Id IN :lstIdEquipeDeVendas];

        List<String> territoryNames = new List<String>();

        for(Equipe_De_Vendas__c equipe : lstEquipeDeVendas) {
            territoryNames.add(equipe.Codigo_Equipe_De_Venda__c);
        }

        List<Territory2> territories = new List<Territory2>();

        if (!Schema.sObjectType.Territory2.isAccessible()) {
            throw new CustomCrudException('Objecto Territory2 não está acessível para esse usuário!');
        }

        territories =   [SELECT Id, 
                        Name
                        FROM Territory2 
                        WHERE Name IN :territoryNames];

        for(Centro_De_Lucro__c centroDeLucro : lstNewCentroDeLucro) {
            if(centroDeLucro.Vendedor__c != null) {
                for(Equipe_De_Vendas__c equipe : lstEquipeDeVendas) {
                    if(centroDeLucro.Equipe_De_Vendas__c == equipe.Id) {
                        for(Territory2 territory : territories) {
                            if(territory.Name == equipe.Codigo_Equipe_De_Venda__c) {
                                TerritoryService.associateUser(territory.Id, centroDeLucro.Vendedor__c);
                            }
                        }
                    }
                }
            }
        }

    }

    /***************************************************************************************************************************************************
	 * Purpose: US1445 - Associação de vendedor a território - Método executado na atualização de Vendedor em Centro de Lucro
	 * Parameters: -
	 * Returns: void
	 * Throws -
	 *
	 * History
	 * --------
	 * VERSION 		AUTHOR 							DATE 			DETAIL 		Description
	 * 1.0 			Rafael A. Barbaroto de Araújo 	11/07/2019 		Created 	Confirma se houve alteração do Vendedor; se sim:
	 * 																				- Altera associação de Território - Usuário (Vendedor)
	***************************************************************************************************************************************************/
    private void updateTerritoryUser() {

        Set<Id> lstIdEquipeDeVendas = new Set<Id>();
        Set<Id> removedVendedores = new Set<Id>();

        for(Id newCentroKey : mapNewCentroDeLucro.keySet()) {
            if(mapOldCentroDeLucro.get(newCentroKey).Vendedor__c != mapNewCentroDeLucro.get(newCentroKey).Vendedor__c) {
                lstIdEquipeDeVendas.add(mapNewCentroDeLucro.get(newCentroKey).Equipe_De_Vendas__c);
                removedVendedores.add(mapOldCentroDeLucro.get(newCentroKey).Vendedor__c);
            }
        }

        List<Equipe_De_Vendas__c> lstEquipeDeVendas = new List<Equipe_De_Vendas__c>();

        if (!Schema.sObjectType.Equipe_De_Vendas__c.isAccessible()) {
            throw new CustomCrudException('Objecto Equipe_De_Vendas__c não está acessível para esse usuário!');
        }

        lstEquipeDeVendas = [SELECT Id, 
                            Codigo_Equipe_De_Venda__c 
                            FROM Equipe_De_Vendas__c 
                            WHERE Id IN :lstIdEquipeDeVendas];

        List<String> territoriesToUpdateNames = new List<String>();

        for(Equipe_De_Vendas__c equipe : lstEquipeDeVendas) {
            territoriesToUpdateNames.add(equipe.Codigo_Equipe_De_Venda__c);
        }

        List<Territory2> territoriesToUpdate = new List<Territory2>();

        if (!Schema.sObjectType.Territory2.isAccessible()) {
            throw new CustomCrudException('Objecto Territory2 não está acessível para esse usuário!');
        }

        territoriesToUpdate =   [SELECT Id, 
                                Name 
                                FROM Territory2 
                                WHERE Name IN :territoriesToUpdateNames];

        // criação de novas associações
        for(Id newCentroKey : mapNewCentroDeLucro.keySet()) {
            for(Equipe_De_Vendas__c team : lstEquipeDeVendas) {
                if(team.Id == mapNewCentroDeLucro.get(newCentroKey).Equipe_De_Vendas__c) {
                    for(Territory2 territory : territoriesToUpdate) {
                        if(territory.Name == team.Codigo_Equipe_De_Venda__c
                        && mapNewCentroDeLucro.get(newCentroKey).Vendedor__c != null) {

                            TerritoryService.associateUser(territory.Id, mapNewCentroDeLucro.get(newCentroKey).Vendedor__c);
                        }
                    }
                }
            }
        }

        // Remoção de antigas associações
        Set<Id> territoriesIds = new Set<Id>();

        for(Territory2 territory : territoriesToUpdate) {
            territoriesIds.add(territory.Id);
        }

        if (!Schema.sObjectType.UserTerritory2Association.isAccessible()) {
            throw new CustomCrudException('Objecto UserTerritory2Association não está acessível para esse usuário!');
        }

        List<UserTerritory2Association> associationsToDelete =  [SELECT Id 
                                                                FROM UserTerritory2Association 
                                                                WHERE Territory2Id IN :territoriesIds
                                                                AND UserId IN: removedVendedores];

        for(UserTerritory2Association association : associationsToDelete) {
            TerritoryService.disassociateUser(association.Id);
        }
    }
    
    private void updateSAP()
    {
        Map<Id, Boolean> mapCentroLucroToBatch = new Map<Id, Boolean>();
        map<Id, Id> mapCentroDeLucroToManager = new Map<Id, Id>();

        if (!Schema.sObjectType.User.isAccessible()) {
            throw new CustomCrudException('Objecto User não está acessível para esse usuário!');
        }
        // se houve alteração em Vendedor__c ou Equipe_de_Vendas__c
        for(Centro_De_Lucro__c newCentroDeLucro : lstNewCentroDeLucro)
        {
            System.debug('newCentroDeLucro.Vendedor__c: ' + newCentroDeLucro.Vendedor__c);
            if((mapOldCentroDeLucro.get(newCentroDeLucro.Id).Equipe_De_Vendas__c != newCentroDeLucro.Equipe_De_Vendas__c) ||
               (mapOldCentroDeLucro.get(newCentroDeLucro.Id).Codigo_Centro_De_Lucro__c != newCentroDeLucro.Codigo_Centro_De_Lucro__c)	||
               (mapOldCentroDeLucro.get(newCentroDeLucro.Id).Name != newCentroDeLucro.Name)) {
                mapCentroLucroToBatch.put(newCentroDeLucro.Id, true);
            } else if(mapOldCentroDeLucro.get(newCentroDeLucro.Id).Vendedor__c != newCentroDeLucro.Vendedor__c) {
                mapCentroLucroToBatch.put(newCentroDeLucro.Id, false);
            }

            if(newCentroDeLucro.Vendedor__c == null && mapOldCentroDeLucro.get(newCentroDeLucro.Id).Vendedor__c != null) {
                
                User vendedor = [SELECT ManagerId 
                                FROM User 
                                WHERE Id = :mapOldCentroDeLucro.get(newCentroDeLucro.Id).Vendedor__c];

                System.debug('oldVendedor: ' + vendedor);
                mapCentroDeLucroToManager.put(newCentroDeLucro.Id, vendedor.ManagerId);
            }
        }

        if(!mapCentroLucroToBatch.isEmpty())
        {
            System.debug('Called batch');
            System.debug('mapCentroLucroToBatch: ' + mapCentroLucroToBatch.keySet());
            System.debug('mapCentroDeLucroToManager: ' + mapCentroDeLucroToManager);
            Database.executeBatch(new AreaDeVendasUpdateBatch(mapCentroLucroToBatch, mapCentroDeLucroToManager), 40);
        }
    }

    private void updateOwner()
    {
        List<Centro_De_Lucro__c> lstCentroDeLucro = new List<Centro_De_Lucro__c>();
        Set<Id> setUserId = new Set<Id>();

        for(Centro_De_Lucro__c newCentroDeLucro : lstNewCentroDeLucro)
        {
            if(Trigger.isInsert || (Trigger.isUpdate &&  newCentroDeLucro.Vendedor__c != mapOldCentroDeLucro.get(newCentroDeLucro.Id).Vendedor__c))
            {
                lstCentroDeLucro.add(newCentroDeLucro);
                setUserId.add(newCentroDeLucro.Vendedor__c);
            }
        }

        if (!Schema.sObjectType.User.isAccessible()) {
            throw new CustomCrudException('Objecto User não está acessível para esse usuário!');
        }

        Map<Id, User> mapUser = new Map<Id, User>([SELECT Id, IsActive, ManagerId, Manager.IsActive FROM User WHERE Id IN :setUserId]);

        for(Centro_De_Lucro__c centroDeLucro : lstCentroDeLucro)
        {
            if(mapUser.containsKey(centroDeLucro.Vendedor__c))
            {
                if(mapUser.get(centroDeLucro.Vendedor__c).Manager.IsActive)
                {
                    centroDeLucro.OwnerId = mapUser.get(centroDeLucro.Vendedor__c).ManagerId;
                } else
                {
                    centroDeLucro.addError(Label.ERROR_INACTIVE_USER_MANAGER);
                }
            }
        }
    }

    /**********************************************************************************************************************************
     * Copyright © 2021 BR Distribuidores
     * ================================================================================================================================
     * Purpose: US 15353 - Atualiza os campos Centro de Lucro Principal / Aviação nas Contas relacionadas
     * ================================================================================================================================
     * History
     * -------
     * VERSION  AUTHOR                  DATE            DETAIL      Description
     * 1.0      Daniela Segura          29/10/2021      Created     Atualização dos campos Centro de Lucro (Principal e Aviação)
     * 1.1      Daniela Segura          16/11/2021      Edited      Chamada para o batch AccountUpdateCentroDeLucroBatch
     **********************************************************************************************************************************/
    private void updateAccountCentroDeLucro(){
        List<Id> lstCentroLucroVendedorAlterado = new List<Id>();

        for(Id centroLucroId : mapNewCentroDeLucro.keySet()){
            if(mapNewCentroDeLucro.get(centroLucroId).Vendedor__c != mapOldCentroDeLucro.get(centroLucroId).Vendedor__c){
                lstCentroLucroVendedorAlterado.add(centroLucroId);
            }
        }
        
        sendAreasDeVendasToQueueable(lstCentroLucroVendedorAlterado);
    }
    
    /**********************************************************************************************************************************
     * Copyright © 2021 BR Distribuidores
     * ================================================================================================================================
     * Purpose: US 15353 - Método future para realizar a query de Área de Vendas e chamar batch sem contar tempo de execução da trigger
     * ================================================================================================================================
     * History
     * -------
     * VERSION  AUTHOR                  DATE            DETAIL      Description
     * 1.0      Daniela Segura          06/12/2021      Created     Versão inicial
     **********************************************************************************************************************************/
    
    @future
    private static void sendAreasDeVendasToQueueable(List<Id> lstCentroLucroVendedorAlterado){
        Set<Id> setAccountId = new Set<Id>();
        List<Area_De_Vendas__c> lstAreaVendas = [SELECT Emissor__c FROM Area_De_Vendas__c WHERE Centro_De_Lucro__c IN :lstCentroLucroVendedorAlterado];

        for(Area_De_Vendas__c varAreaVendas : lstAreaVendas){
            setAccountId.add(varAreaVendas.Emissor__c);
        }

        if(!setAccountId.isEmpty()){
            AccountUpdateCentroDeLucroQueueable queueable = new AccountUpdateCentroDeLucroQueueable(setAccountId);
            System.enqueueJob(queueable);
        }
    }
}