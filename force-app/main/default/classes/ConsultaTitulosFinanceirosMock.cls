/*************************************************************************************************************************************************
* Copyright © 2022 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 17299 - Classe teste de mock utilizada pela classe de teste ConsultaTitulosFinanceirosService
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		11/04/2022		Created		Versão inicial
**************************************************************************************************************************************************/
@isTest
public class ConsultaTitulosFinanceirosMock implements HttpCalloutMock{
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{'                                                                        +
                            '"RetornoConsultaDebitosCentroLucro": {'                                +
                                '"Debitos": ['                                                      +
                                    '{'                                                             +
                                        '"CodigoCliente": "0000005617",'                            +
                                        '"CnpjCpf": "03447202000174",'                              +
                                        '"RazaoSocial": "P.ABAST.IMPERIAL 2000 LTDA",'              +
                                        '"CentroLucro": "DAC5M00000",'                              +
                                        '"NumeroDocumento": "0700027301",'                          +
                                        '"NumeroDocExercicio": 2022,'                               +
                                        '"NumeroDocItem": 1,'                                       +
                                        '"TipoDocItem": "ND",'                                      +
                                        '"TipoDocDescricao": "Nota de débito",'                     +
                                        ' "LocalNegocio": "5001",'                                  +
                                        '"LocalNegocioDescricao": "Administração Central VIBRA",'   +
                                        '"DataEmissao": "2022-03-09",'                              +
                                        '"DataVencimento": "2022-04-17",'                           +
                                        '"Valor": 1335.0,'                                          +
                                        '"Juros": 0.0,'                                             +
                                        '"Multa": 0.0,'                                             +
                                        '"ValorTotal": 1335.0,'                                     +
                                        '"OutrasDeducoes": 0.0,'                                    +
                                        '"FlagMora": "0"'                                           +
                                    '}'                                                             +
                                ']'                                                                 +
                            '},'                                                                    +
                            '"StatusExecucao": {'                                                   +
                                '"ExecutadaCorretamente": true'                                     +
                            '}'                                                                     +
                        '}');
        response.setStatusCode(200);
        return response; 
    }
}