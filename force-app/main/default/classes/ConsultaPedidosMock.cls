/*************************************************************************************************************************************************
* Copyright © 2021 BR Distribuidores
* ================================================================================================================================================
* Purpose: US 15365 - Classe teste de mock utilizada pela classe de teste ConsultaPedidosServiceTest
* ================================================================================================================================================
* History
* -------
* VERSION		AUTHOR 				DATE 			DETAIL 		Description
* 1.0 			Daniela Segura		26/10/2021		Created		Versão inicial
**************************************************************************************************************************************************/
@isTest
public class ConsultaPedidosMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"RetornoConsultaOrdemVendaDetalhada":{"OrdensVenda":[{"Numero":"0070481504","Tipo":"Z746","DataPedido":"2019-11-25","DataEntrega":"2019-11-25",'                     +
                        '"Emissor":"0000019105","Recebedor":"0000019105","Bloqueada":false,"OrganizacaoVenda":"2001","CanalDistribuicao":"11","SetorAtividade":"13","DataDeterminacaoPreco":'   +
                        '"2019-11-25","StatusOrdem":"4"}],"DetalhesOrdemVenda":[{"OrdemVenda":"0070481504","Produto":"000000000001000001","Posicao":"000010","DescricaoProduto":'               +
                        '"GásNaturalVeicular(GNV)","QuantidadePedida":0.000,"QuantidadeAtendida":0.000,"QuantidadePendente":0.000,"Valor":203224.41,"Centro":"5095","ModalidadeEntrega":'       +
                        '"ZST","Incoterms2":"ZST","StatusProcessamentoItem":"B","CondicaoPagamento":"Z008","QuantidadeRemessa":0.000,"QuantidadeEntregue":0.000,"ProdutoEntregue":'             +
                        '"000000000001000001","MontanteBoleto":0.00}],"Restricoes":[{"OrdemVenda":"0070481504"}],"Remessa":[{"DocumentoVenda":'        +
                        '"0245655751","ItemDocumentoVenda":"000010","Fornecimento":"8112782650","QuantidadeTransporte":15000.000,"DataFaturamentoIndice":"2019-11-26",'                         +
                        '"QuantidadeFaturadaEfetivamente":15000.000,"ValorFaturado":56894.40,"StatusRemessa":"Concluído","NumeroNotaFiscal":"002515261","PlacaVeiculo":'                        +
                        '"LSD7630","StatusProgramacao":"6","NumeroProgramacao":"4030789470","NomeTransportadora":"WM.TRANSP.DECOMB.ECARGASLTDA","DataEntradaBase":'                             +
                        '"2019-11-26","HoraEntradaBase":"11:40:03","DataSaidaBase":"2019-11-26","HoraSaidaBase":"13:22:10","DataCriacaoProgramacao":"2019-11-26",'                              +
                        '"DataPlanejadaProgramacao":"2019-11-26","DataEfetivaCarregamento":"2019-11-26"}]},"StatusExecucao":{"ExecutadaCorretamente":true,"Mensagens":'                         +
                        '[{"Numero":0,"Texto":"ConsultarealizadacomSucesso."}]}}');
        response.setStatusCode(200);
        return response; 
    }
}