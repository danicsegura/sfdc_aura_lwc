/******************************************************************************************************************************************
 * Copyright © 2021 BR Distribuidores
 * ========================================================================================================================================
 * Purpose: US 15365 - Classe responsável por conter a estrutura do retorno da integração ConsultaPedidosService
 * ========================================================================================================================================
 * History
 * -------
 * VERSION		AUTHOR 				DATE 			DETAIL 		Description
 * 1.0 			Daniela Segura		26/11/2021 		Created 	Versão inicial
******************************************************************************************************************************************/
public class ConsultaPedidosWrapper {

	public class DetalhesOrdemVenda {
		@AuraEnabled public String OrdemVenda;
		@AuraEnabled public String Produto;
		@AuraEnabled public String Posicao;
		@AuraEnabled public String DescricaoProduto;
		@AuraEnabled public Double QuantidadePedida;
		@AuraEnabled public Double QuantidadeAtendida;
		@AuraEnabled public Double QuantidadePendente;
		@AuraEnabled public Double Valor;
		@AuraEnabled public String Centro;
		@AuraEnabled public String ModalidadeEntrega;
		@AuraEnabled public String Incoterms2;
		@AuraEnabled public String StatusProcessamentoItem;
		@AuraEnabled public String CondicaoPagamento;
		@AuraEnabled public String Contrato;
		@AuraEnabled public Double QuantidadeRemessa;
		@AuraEnabled public Double QuantidadeEntregue;
		@AuraEnabled public String ProdutoEntregue;
		@AuraEnabled public Double MontanteBoleto;
		@AuraEnabled public String DataGeracaoRemessa;
	}

	public class RetornoConsultaOrdemVendaDetalhada {
		@AuraEnabled public List<OrdensVenda> OrdensVenda;
		@AuraEnabled public List<DetalhesOrdemVenda> DetalhesOrdemVenda;
		@AuraEnabled public List<Restricoes> Restricoes;
		@AuraEnabled public List<Remessa> Remessa;
	}

	public class Mensagens {
		public Integer Numero;
		public String Texto;
	}

	public class StatusExecucao {
		@AuraEnabled public Boolean ExecutadaCorretamente;
		public List<Mensagens> Mensagens;
	}

	@AuraEnabled public RetornoConsultaOrdemVendaDetalhada RetornoConsultaOrdemVendaDetalhada;
	@AuraEnabled public StatusExecucao StatusExecucao;

	public class Restricoes {
		@AuraEnabled public String OrdemVenda;
		@AuraEnabled public String Texto;
		@AuraEnabled public String IdTexto;
	}

	public class OrdensVenda {
		@AuraEnabled public String Numero;
		@AuraEnabled public String Tipo;
		@AuraEnabled public String DataPedido;
		@AuraEnabled public String DataEntrega;
		@AuraEnabled public String Emissor;
		@AuraEnabled public String Recebedor;
		@AuraEnabled public Boolean Bloqueada;
		@AuraEnabled public String OrganizacaoVenda;
		@AuraEnabled public String CanalDistribuicao;
		@AuraEnabled public String SetorAtividade;
		@AuraEnabled public String DataDeterminacaoPreco;
		@AuraEnabled public String StatusOrdem;
		@AuraEnabled public String TipoPedido;
		@AuraEnabled public String StatusProcessamentoRemessa;
		@AuraEnabled public String Motivo;
		@AuraEnabled public String DescricaoMotivo;
		@AuraEnabled public Double QuantidadePedida;
		@AuraEnabled public String CssColorClass;
	}

	public class Remessa {
		@AuraEnabled public String DocumentoVenda;
		@AuraEnabled public String ItemDocumentoVenda;
		@AuraEnabled public String Fornecimento;
		@AuraEnabled public Double QuantidadeTransporte;
		@AuraEnabled public String DataFaturamentoIndice;
		@AuraEnabled public Double QuantidadeFaturadaEfetivamente;
		@AuraEnabled public Double ValorFaturado;
		@AuraEnabled public String StatusRemessa;
		@AuraEnabled public String NumeroNotaFiscal;
		@AuraEnabled public String PlacaVeiculo;
		@AuraEnabled public String StatusProgramacao;
		@AuraEnabled public String NumeroProgramacao;
		@AuraEnabled public String NomeTransportadora;
		@AuraEnabled public String DataEntradaBase;
		@AuraEnabled public String HoraEntradaBase;
		@AuraEnabled public String DataSaidaBase;
		@AuraEnabled public String HoraSaidaBase;
		@AuraEnabled public String DataHoraSaidaBase;
		@AuraEnabled public String DataCriacaoProgramacao;
		@AuraEnabled public String DataPlanejadaProgramacao;
		@AuraEnabled public String DataEfetivaCarregamento;
		@AuraEnabled public String DescricaoProduto;
		@AuraEnabled public String Key;
		@AuraEnabled public String InfoCarregamento;
	}

	
	public static ConsultaPedidosWrapper parse(String json) {
		return (ConsultaPedidosWrapper) System.JSON.deserialize(json, ConsultaPedidosWrapper.class);
	}
}