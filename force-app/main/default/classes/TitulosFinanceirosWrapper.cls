/******************************************************************************************************************************************
 * Copyright © 2022 BR Distribuidores
 * ========================================================================================================================================
 * Purpose: US 17299 - Classe responsável por conter a estrutura de retorno da integração ConsultaTitulosFinanceirosService
 * ========================================================================================================================================
 * History
 * -------
 * VERSION		AUTHOR 				DATE 			DETAIL 		Description
 * 1.0 			Daniela Segura		11/04/2022 		Created 	Versão inicial
******************************************************************************************************************************************/
public with sharing class TitulosFinanceirosWrapper {

	public class RetornoConsultaDebitosCentroLucro {
		@AuraEnabled public List<Debitos> Debitos;
	}

	public class Debitos {
		@AuraEnabled public String CodigoCliente;
		@AuraEnabled public String CnpjCpf;
		@AuraEnabled public String RazaoSocial;
		@AuraEnabled public String CentroLucro;
		@AuraEnabled public String NumeroDocumento;
		@AuraEnabled public Integer NumeroDocExercicio;
		@AuraEnabled public Integer NumeroDocItem;
		@AuraEnabled public String TipoDocItem;
		@AuraEnabled public String TipoDocDescricao;
		@AuraEnabled public String NotaFiscal;
		@AuraEnabled public String LocalNegocio;
		@AuraEnabled public String LocalNegocioDescricao;
		@AuraEnabled public String DataEmissao;
		@AuraEnabled public String DataVencimento;
		@AuraEnabled public Double Valor;
		@AuraEnabled public Double Juros;
		@AuraEnabled public Double Multa;
		@AuraEnabled public Double ValorTotal;
		@AuraEnabled public Double OutrasDeducoes;
		@AuraEnabled public String FlagMora;
	}

	public class StatusExecucao {
		@AuraEnabled public Boolean ExecutadaCorretamente;
		@AuraEnabled public List<Mensagens> Mensagens;
	}

	public class Mensagens {
		@AuraEnabled public String Codigo;
		@AuraEnabled public String Descricao;
	}

	@AuraEnabled public RetornoConsultaDebitosCentroLucro RetornoConsultaDebitosCentroLucro;
	@AuraEnabled public StatusExecucao StatusExecucao;
	@AuraEnabled public Integer statusCode;
	@AuraEnabled public String message;

	/***************************************************************************************************************************************************
    * 		Purpose: US 17299 - Realizar a deserialização do retorno da integração na estrutura da classe
    * 		Parameters: -
    * 		Returns: void
    * 		Throws -
    * History
    * --------
    * VERSION 		AUTHOR 				DATE 		DETAIL 		Description
    * 1.0 			Daniela Segura     	11/04/2022 	Created 	Versão inicial
    ***************************************************************************************************************************************************/
	
	public static TitulosFinanceirosWrapper parse(String json) {
		return (TitulosFinanceirosWrapper) System.JSON.deserialize(json, TitulosFinanceirosWrapper.class);
	}
}