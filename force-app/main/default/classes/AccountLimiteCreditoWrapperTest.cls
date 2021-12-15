@IsTest
public class AccountLimiteCreditoWrapperTest {
	
	static testMethod void testParse() {
		String json = '{'+
		'    \"RetornoConsultaCreditoClienteCRM\": {'+
		'        \"AdministracoesCredito\": {'+
		'            \"ContaCliente\": \"0000000731\",'+
		'            \"CNPJ\": \"00171013000123\",'+
		'            \"LimiteCredito\": 772848930.33,'+
		'            \"GrauEsgotamento\": 100.01,'+
		'            \"DataHorizonte\": \"2021-09-29\",'+
		'            \"TotalDividas\": 772066596.07,'+
		'            \"CompromissoEspecial\": 0.00,'+
		'            \"TotalValores\": 879276.63,'+
		'            \"TotalCompromisso\": 772945872.70,'+
		'            \"AdministracaoCredito\": \"Z06\",'+
		'            \"GrupoCredito\": \"Z02S\",'+
		'            \"VerificacaoSeguinte\": \"2020-09-26\"'+
		'        }'+
		'    },'+
		'    \"StatusExecucao\": {'+
		'        \"ExecutadaCorretamente\": true'+
		'    }'+
		'}';
		AccountLimiteCreditoWrapper obj = AccountLimiteCreditoWrapper.parse(json);
		System.assert(obj != null);
	}
}