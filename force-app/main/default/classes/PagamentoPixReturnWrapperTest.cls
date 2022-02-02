/********************************************************************************************************************************
* 2021 - Previsul 
* ===============================================================================================================================
* Purpose: Classe de teste para a classe PagamentoPixReturnWrapper
* ===============================================================================================================================
* History
* -------
* VERSION   AUTHOR              DATE            DETAIL      Description
* 1.0       Daniela Segura      22/12/2021      Created     Versão inicial
*********************************************************************************************************************************/
@IsTest
public class PagamentoPixReturnWrapperTest {
	
    @isTest
	static void testParse() {
		String json = '{'+
		'    \"identificacao\": {'+
		'        \"codigoNegocio\": \"123123123\"'+
		'    },'+
		'    \"parcela\": {'+
		'        \"numeroParcela\": 1,'+
		'        \"codigoModalidade\": \"1\"'+
		'    },'+
		'    \"produto\": {'+
		'        \"codigoProdutoNegocio\": \"123\",'+
		'        \"cnpjEmpresa\": \"12121\"'+
		'    },'+
		'    \"valor\": 0.03,'+
		'    \"pix\": {'+
		'        \"txId\": \"EX29910000000000000000000000146\",'+
		'        \"location\": \"pix-h.santander.com.br/qr/v2/79bf31cb-81ab-4df7-9865-0ff8c18d9b36\",'+
		'        \"expiracao\": \"1331220\",'+
		'        \"chave\": \"20201210000155\"'+
		'    },'+
		'    \"informacoesAdicionais\": ['+
		'        {'+
		'            \"nome\": \"AAA\",'+
		'            \"valor\": \"Valor9\"'+
		'        }'+
		'    ],'+
		'    \"dataCobranca\": \"2022-01-01T20:00:00Z\",'+
		'    \"pagador\": {'+
		'        \"nome\": \"DIEGO PEREIRA AIRES\",'+
		'        \"cpfCnpj\": \"01709467118\"'+
		'    },'+
		'    \"descricaoCobranca\": \"Cobrança dos serviços prestados.\",'+
		'    \"dataCriacao\": \"2021-12-17T10:13:00Z\"'+
		'}';
		PagamentoPixReturnWrapper obj = PagamentoPixReturnWrapper.parse(json);
		System.assert(obj != null);
	}
}