/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15365 - Service class para consultar os últimos pedidos cadastrados nos últimos 30 dias
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		26/11/2021		Created		Versão inicial
**************************************************************************************************************************************************/
public class ConsultaPedidosService {
    public static ConsultaPedidosWrapper wrapperClass;
    public ConsultaPedidosWrapper pedidosInfo;
    private Map<String, Double> mapOrdemVendaQtdePedida = new Map<String, Double>();
    private Map<String, String> mapDetalhesOrdemVendaPosicaoToDescricao = new Map<String, String>();
    private Map<String, String> mapDetalhesOrdemVendaCentroFornecedor = new Map<String, String>();
    private Map<String, String> mapStatusCodigoToLabel = new Map<String, String>();
    private Map<String, String> mapTipoPedidoCodigoToLabel = new Map<String, String>();

    @AuraEnabled(cacheable=true)
    public static ConsultaPedidosWrapper callService(String codigoSap, Integer searchPeriod){
        DateTime dataPedidoFinal = DateTime.Now();
        String dataPedidoFinalStr = dataPedidoFinal.format('yyyy-MM-dd');

        DateTime dataPedidoInicial = DateTime.Now().addDays(-searchPeriod);
        String dataPedidoInicialStr = dataPedidoInicial.format('yyyy-MM-dd');

        String endpoint, key, value, body = '{ '+
                                                '"Emissor":"' + codigoSap + '",'    +
                                                '"Recebedor":"' + codigoSap + '",'  +
                                                '"DataPedidoInicial":"' + dataPedidoInicialStr + '",' +
                                                '"DataPedidoFinal":"' + dataPedidoFinalStr + '",'   +
                                                '"IncluirItens":"1",'   +
                                                '"IncluirRemessas":"1"' +
                                            '}';

        Organization org = [SELECT IsSandbox FROM Organization];

        if(org.IsSandbox == true){
            Integration_Information__mdt integrationInfoSandbox = [SELECT Endpoint__c, Authentication__c 
                                                                    FROM Integration_Information__mdt 
                                                                    WHERE MasterLabel = 'AzureConsultaPedidosHOM' LIMIT 1];

            Authentication__mdt authInfo = [SELECT Username__c, Password__c 
                                            FROM Authentication__mdt 
                                            WHERE Id =:integrationInfoSandbox.Authentication__c LIMIT 1];

            endpoint 	= integrationInfoSandbox.Endpoint__c;
            key 		= authInfo.Username__c;
            value 		= authInfo.Password__c;
        }else{
            Integration_Information__mdt integrationInfoProd = [SELECT Endpoint__c, Authentication__c 
                                                                FROM Integration_Information__mdt 
                                                                WHERE MasterLabel = 'AzureConsultaPedidosPROD' LIMIT 1];
            
            Authentication__mdt authInfo = [SELECT Username__c, Password__c 
                                            FROM Authentication__mdt 
                                            WHERE Id =:integrationInfoProd.Authentication__c LIMIT 1];
            
            endpoint 	= integrationInfoProd.Endpoint__c;
            key 		= authInfo.Username__c;
            value 		= authInfo.Password__c;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader(key, value);
        req.setBody(body);
        req.setMethod('POST');

        Http http = new Http();
        HttpResponse response = http.send(req);

        wrapperClass = ConsultaPedidosWrapper.parse(response.getBody());

        ConsultaPedidosService service = new ConsultaPedidosService();
        service.getStatusOrdemMetadata();
        service.getTipoPedidoMetadata();
        service.complementDetalhesOrdemVenda();
        service.fillCentroFornecedorName();
        service.complementOrdensVenda();
        service.complementRemessas();

        return wrapperClass;
    }

    public void complementDetalhesOrdemVenda(){
        if(wrapperClass.RetornoConsultaOrdemVendaDetalhada.DetalhesOrdemVenda != null){
            for(ConsultaPedidosWrapper.DetalhesOrdemVenda detalhe : wrapperClass.RetornoConsultaOrdemVendaDetalhada.DetalhesOrdemVenda){
                String detalheKey = detalhe.OrdemVenda + ';' + detalhe.Posicao;

                if(detalhe.QuantidadePedida != null && detalhe.Valor != null && detalhe.Valor > 0){
                    if(this.mapOrdemVendaQtdePedida.containsKey(detalhe.OrdemVenda))
                        this.mapOrdemVendaQtdePedida.put(detalhe.OrdemVenda, this.mapOrdemVendaQtdePedida.get(detalhe.OrdemVenda) + detalhe.QuantidadePedida);
                    else
                        this.mapOrdemVendaQtdePedida.put(detalhe.OrdemVenda, detalhe.QuantidadePedida);
                }

                if(detalhe.Centro != null)
                    this.mapDetalhesOrdemVendaCentroFornecedor.put(detalheKey, detalhe.Centro);
    
                if(detalhe.DescricaoProduto != null)
                    this.mapDetalhesOrdemVendaPosicaoToDescricao.put(detalheKey, detalhe.DescricaoProduto);
            }
        }
    }

    private void complementOrdensVenda(){
        if(wrapperClass.RetornoConsultaOrdemVendaDetalhada.OrdensVenda != null){
            for(ConsultaPedidosWrapper.OrdensVenda ordemVenda : wrapperClass.RetornoConsultaOrdemVendaDetalhada.OrdensVenda){
                //limpar zeros iniciais
                ordemVenda.Emissor = ordemVenda.Emissor.replaceFirst('^0+', '');
                ordemVenda.Recebedor = ordemVenda.Recebedor.replaceFirst('^0+', '');
    
                if(this.mapOrdemVendaQtdePedida.containsKey(ordemVenda.Numero))
                    ordemVenda.QuantidadePedida = this.mapOrdemVendaQtdePedida.get(ordemVenda.Numero);
                
                //referências dos códigos StatusOrdem
                if(ordemVenda.StatusOrdem != null){
                    ordemVenda.StatusOrdem = this.mapStatusCodigoToLabel.get(ordemVenda.StatusOrdem);
                    
                    switch on ordemVenda.StatusOrdem{
                        when 'Bloqueio Financeiro'{
                            ordemVenda.CssColorClass = 'status_bloqueio_financeiro';
                        }when 'Não Programado'{
                            ordemVenda.CssColorClass = 'status_nao_programado';
                        }when 'Parcialmente Bloqueado'{
                            ordemVenda.CssColorClass = 'status_parcialmente_bloqueado';
                        }when 'Parcialmente Faturado'{
                            ordemVenda.CssColorClass = 'status_parcialmente_faturado';
                        }when 'Parcialmente Programado'{
                            ordemVenda.CssColorClass = 'status_pacialmente_programado';
                        }when 'Totalmente Cancelado'{
                            ordemVenda.CssColorClass = 'status_totalmente_cancelado';
                        }when 'Totalmente Faturado'{
                            ordemVenda.CssColorClass = 'status_totalmente_faturado';
                        }when 'Totalmente Programado'{
                            ordemVenda.CssColorClass = 'status_totalmente_programado';
                        }when else{
                            ordemVenda.CssColorClass = 'status_default';
                        }
                    }
                }

                if(ordemVenda.TipoPedido != null){
                    if(this.mapTipoPedidoCodigoToLabel.containsKey(ordemVenda.TipoPedido))
                        ordemVenda.TipoPedido = this.mapTipoPedidoCodigoToLabel.get(ordemVenda.TipoPedido);
                    else
                        ordemVenda.TipoPedido = 'Pedido BR';
                }else{
                    ordemVenda.TipoPedido = 'Pedido BR';
                }
            }
        }
    }

    private void complementRemessas(){
        if(wrapperClass.RetornoConsultaOrdemVendaDetalhada.Remessa != null){
            for(ConsultaPedidosWrapper.Remessa remessa : wrapperClass.RetornoConsultaOrdemVendaDetalhada.Remessa){
                //cria chave única para as remessas
                remessa.Key = remessa.DocumentoVenda + ';' + remessa.ItemDocumentoVenda;

                if(remessa.DataSaidaBase != null){
                    String diaSaidaBase = remessa.DataSaidaBase.substringAfterLast('-');
                    String mesSaidaBase = remessa.DataSaidaBase.substringAfter('-').substringBefore('-');
                    String anoSaidaBase = remessa.DataSaidaBase.substringBefore('-');
                    String dtSaidaBaseformatada = diaSaidaBase + '/' + mesSaidaBase + '/' + anoSaidaBase;
                    remessa.InfoCarregamento = remessa.PlacaVeiculo + ' ' + dtSaidaBaseformatada + ' ' + remessa.HoraSaidaBase;
                    remessa.DataHoraSaidaBase = dtSaidaBaseformatada + ' ' + remessa.HoraSaidaBase;
                }
    
                if(this.mapDetalhesOrdemVendaPosicaoToDescricao.containsKey(remessa.Key))
                    remessa.DescricaoProduto = this.mapDetalhesOrdemVendaPosicaoToDescricao.get(remessa.Key);
            }
        }
    }

    private void fillCentroFornecedorName(){
        Map<String, String> mapCentroFornecedorCodigoToName = new Map<String, String>();
        List<Centro_Fornecedor__c> lstCentroFornecedor = [SELECT Name, Codigo_Do_Centro__c FROM Centro_Fornecedor__c WHERE Codigo_Do_Centro__c IN : this.mapDetalhesOrdemVendaCentroFornecedor.values()];
        
        for(Centro_Fornecedor__c varCentroFornecedor : lstCentroFornecedor){
            mapCentroFornecedorCodigoToName.put(varCentroFornecedor.Codigo_Do_Centro__c, varCentroFornecedor.Name);
        }

        if(wrapperClass.RetornoConsultaOrdemVendaDetalhada.DetalhesOrdemVenda != null){
            for(ConsultaPedidosWrapper.DetalhesOrdemVenda detalhe : wrapperClass.RetornoConsultaOrdemVendaDetalhada.DetalhesOrdemVenda){
                String detalheKey = detalhe.OrdemVenda + ';' + detalhe.Posicao;
                if(this.mapDetalhesOrdemVendaCentroFornecedor.containsKey(detalheKey))
                    detalhe.Centro = mapCentroFornecedorCodigoToName.get(this.mapDetalhesOrdemVendaCentroFornecedor.get(detalheKey));
            }
        }
    }

    private void getStatusOrdemMetadata(){
        List<Status_Ordem_map__mdt> lstStatusOrdem = [SELECT Codigo__c, MasterLabel FROM Status_Ordem_map__mdt];
        for(Status_Ordem_map__mdt varStatusOrdem : lstStatusOrdem){
            this.mapStatusCodigoToLabel.put(varStatusOrdem.Codigo__c, varStatusOrdem.MasterLabel);
        }
    }

    private void getTipoPedidoMetadata(){
        List<Tipo_Pedido_map__mdt> lstTipoPedido = [SELECT Codigo__c, MasterLabel FROM Tipo_Pedido_map__mdt];
        for(Tipo_Pedido_map__mdt varTipoPedido : lstTipoPedido){
            this.mapTipoPedidoCodigoToLabel.put(varTipoPedido.Codigo__c, varTipoPedido.MasterLabel);
        }
    }
}