/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15365 - Controller para o componente lwc consultaPedidos e detalhesPedido
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		03/12/2021		Created		Versão inicial
**************************************************************************************************************************************************/
public class ConsultaPedidosController {

    @AuraEnabled(cacheable=true)
    public static String getCodigoSap(String recordId){
        Account account = [SELECT Codigo_SAP__c FROM Account WHERE Id =: recordId LIMIT 1];
        return account.Codigo_SAP__c;
    }

    @AuraEnabled
    public static String getEndereco(String codigoSapRecebedor){
        List<String> lstCamposEndereco = new List<String>();
        String endereco = '';

        List<Account> lstAccount = [SELECT Rua__c, Numero__c, Complemento__c, Bairro__c, Cidade__r.Name, Cidade__r.Codigo_Estado__c, Pais_Endereco_Cobranca__c, CEP__c 
                                    FROM Account 
                                    WHERE Codigo_SAP__c =: codigoSapRecebedor LIMIT 1];

        for(Account varAccount : lstAccount){
            if(varAccount.Rua__c != null)                       lstCamposEndereco.add(varAccount.Rua__c);
            if(varAccount.Numero__c != null)                    lstCamposEndereco.add(varAccount.Numero__c);
            if(varAccount.Complemento__c != null)               lstCamposEndereco.add(varAccount.Complemento__c);
            if(varAccount.Bairro__c != null)                    lstCamposEndereco.add(varAccount.Bairro__c);
            if(varAccount.Cidade__r.Name != null)               lstCamposEndereco.add(varAccount.Cidade__r.Name);
            if(varAccount.Cidade__r.Codigo_Estado__c != null)   lstCamposEndereco.add(varAccount.Cidade__r.Codigo_Estado__c);
            if(varAccount.Pais_Endereco_Cobranca__c != null)    lstCamposEndereco.add(varAccount.Pais_Endereco_Cobranca__c);
            if(varAccount.CEP__c != null)                       lstCamposEndereco.add(varAccount.CEP__c);
        }

        if(!lstCamposEndereco.isEmpty()){
            endereco = String.join(lstCamposEndereco, ', ').replace(', ,', ', ');
        }

        return endereco;
    }

    @AuraEnabled
    public static List<ConsultaPedidosWrapper.DetalhesOrdemVenda> getCodeToLabelReferences(String detalhesString){
        Map<String, String> mapPrazoValueToLabel = new Map<String, String>();
        Map<String, String> mapIncotermsValueToLabel = new Map<String, String>();
        List<ConsultaPedidosWrapper.DetalhesOrdemVenda> lstDetalhes = (List<ConsultaPedidosWrapper.DetalhesOrdemVenda>) JSON.deserialize(detalhesString, List<ConsultaPedidosWrapper.DetalhesOrdemVenda>.class);

        //access values from global picklist: Prazo_De_Pagamento
        Schema.DescribeFieldResult fieldDescribePrazo = QuoteLineItem.Prazo_De_Pagamento__c.getDescribe();
        Schema.sObjectField objectFieldPrazo = fieldDescribePrazo.getSObjectField();
        List<PicklistEntry> picklistEntriesPrazo = objectFieldPrazo.getDescribe().getPicklistValues();

        for(PicklistEntry varPicklist : picklistEntriesPrazo){
            mapPrazoValueToLabel.put(varPicklist.value, varPicklist.label);
        }

        //access values from global picklist: Incoterms
        Schema.DescribeFieldResult fieldDescribeIncoterms = Area_De_Vendas__c.Incoterms__c.getDescribe();
        Schema.sObjectField objectFieldIncoterms = fieldDescribeIncoterms.getSObjectField();
        List<PicklistEntry> picklistEntriesIncoterms = objectFieldIncoterms.getDescribe().getPicklistValues();

        for(PicklistEntry varPicklist : picklistEntriesIncoterms){
            mapIncotermsValueToLabel.put(varPicklist.value, varPicklist.label);
        }

        for(ConsultaPedidosWrapper.DetalhesOrdemVenda varDetalhe : lstDetalhes){
            if(mapPrazoValueToLabel.containsKey(varDetalhe.CondicaoPagamento)){
                varDetalhe.CondicaoPagamento = mapPrazoValueToLabel.get(varDetalhe.CondicaoPagamento);
            }

            if(mapIncotermsValueToLabel.containsKey(varDetalhe.ModalidadeEntrega)){
                varDetalhe.ModalidadeEntrega = mapIncotermsValueToLabel.get(varDetalhe.ModalidadeEntrega);
            }
        }

        return lstDetalhes;
    }
}