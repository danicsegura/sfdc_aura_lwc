/********************************************************************************************************************************
* 2021 - Previsul 
* ===============================================================================================================================
* Purpose: Classe que contém a estrutura de retorno da integração feita pela classe IntegrationServicePagamentoPix
* ===============================================================================================================================
* History
* -------
* VERSION   AUTHOR              DATE            DETAIL      Description
* 1.0       Daniela Segura      22/12/2021      Created     Versão inicial
*********************************************************************************************************************************/
public class PagamentoPixReturnWrapper {

	@AuraEnabled public Identificacao identificacao;
	@AuraEnabled public Parcela parcela;
	@AuraEnabled public Produto produto;
	@AuraEnabled public Double valor;
	@AuraEnabled public Pix pix;
	@AuraEnabled public Status status;
	@AuraEnabled public List<InformacoesAdicionais> informacoesAdicionais;
	@AuraEnabled public String dataCobranca;
	@AuraEnabled public Pagador pagador;
	@AuraEnabled public String descricaoCobranca;
	@AuraEnabled public String dataCriacao;
	@AuraEnabled public String message;
	@AuraEnabled public String moreInformation;
	@AuraEnabled public String httpMessage;
	@AuraEnabled public String httpCode;
	@AuraEnabled public String httpStatus;
	@AuraEnabled public String code;
	@AuraEnabled public String timestamp;
	@AuraEnabled public String detail;
	@AuraEnabled public String element1;

	public class Parcela {
		@AuraEnabled public Integer numeroParcela;
		@AuraEnabled public String codigoModalidade;
	}

	public class Identificacao {
		@AuraEnabled public String codigoNegocio;
	}

	public class InformacoesAdicionais {
		@AuraEnabled public String nome;
		@AuraEnabled public String valor;
	}

	public class Pagador {
		@AuraEnabled public String nome;
		@AuraEnabled public String cpfCnpj;
	}

	public class Pix {
		@AuraEnabled public String txId;
		@AuraEnabled public String location;
		@AuraEnabled public String expiracao;
		@AuraEnabled public String chave;
		@AuraEnabled public String qrCode;
	}

	public class Status {
		@AuraEnabled public String codigo;
	}

	public class Produto {
		@AuraEnabled public String codigoProdutoNegocio;
		@AuraEnabled public String cnpjEmpresa;
	}

	
	public static PagamentoPixReturnWrapper parse(String json) {
		return (PagamentoPixReturnWrapper) System.JSON.deserialize(json, PagamentoPixReturnWrapper.class);
	}
}