/******************************************************************************************************************************************
 * Copyright © 2021 BR Distribuidores
 * ========================================================================================================================================
 * Purpose: US 15366 - Classe utilizada como Wrapper da classe de integração AccountLimiteCreditoService
 * ========================================================================================================================================
 * History
 * -------
 * VERSION		AUTHOR 				DATE 			DETAIL 		Description
 * 1.0 			Daniela Segura		26/10/2021 		Created 	Classe responsável por conter a estrutura do retorno das integrações.
******************************************************************************************************************************************/
public class AccountLimiteCreditoWrapper {

	@AuraEnabled public RetornoConsultaCreditoClienteCRM RetornoConsultaCreditoClienteCRM;
	@AuraEnabled public StatusExecucao StatusExecucao;

	public class RetornoConsultaCreditoClienteCRM {
		@AuraEnabled public AdministracoesCredito AdministracoesCredito;
	}

	public class AdministracoesCredito {
		@AuraEnabled public String ContaCliente;
		@AuraEnabled public String CNPJ;
		@AuraEnabled public Double LimiteCredito;
		@AuraEnabled public Double GrauEsgotamento;
		@AuraEnabled public String DataHorizonte;
		@AuraEnabled public Double TotalDividas;
		@AuraEnabled public Double CompromissoEspecial;
		@AuraEnabled public Double TotalValores;
		@AuraEnabled public Double TotalCompromisso;
		@AuraEnabled public String AdministracaoCredito;
		@AuraEnabled public String GrupoCredito;
		@AuraEnabled public String VerificacaoSeguinte;
	}

	public class StatusExecucao {
		@AuraEnabled public Boolean ExecutadaCorretamente;
        @AuraEnabled public String Mensagem;
	}

	
	public static AccountLimiteCreditoWrapper parse(String json) {
		return (AccountLimiteCreditoWrapper) System.JSON.deserialize(json, AccountLimiteCreditoWrapper.class);
	}
}