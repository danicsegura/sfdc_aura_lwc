@isTest
public class PagamentoPixLwcControllerTest {
    @TestSetup
    static void testSetup(){
        LogIntegracao__c logIntegracao = new LogIntegracao__c();
        logIntegracao.Identificador_sequencial__c = 1;
        logIntegracao.Status__c = 'Vencido';
        logIntegracao.NumeroContrato__c = '71476390';
        logIntegracao.RecordTypeId = Schema.SObjectType.LogIntegracao__c.getRecordTypeInfosByDeveloperName().get('PIX').getRecordTypeId();
        logIntegracao.Name = 'Test Log';
        insert logIntegracao;

        Profile profileId = [SELECT Id FROM Profile WHERE Name IN ('Gerente Sucursal') LIMIT 1];
        User user = new User();
        user.LastName = 'Test';
        user.Alias = 'Test';
        user.Email = 'user@previsul.com';
        user.Username = 'user@previsul.com';
        user.ProfileId = profileId.Id;
        user.LocaleSidKey = 'pt_BR';
        user.LanguageLocaleKey = 'pt_BR';
        user.EmailEncodingKey = 'UTF-8';
        user.TimeZoneSidKey = 'America/Sao_Paulo';
        user.IsActive = true;
        user.CPF__c = '62506622195';
        insert user;

        List<Account> lstAccount = TestDataFactory.createAccount(1, 'PF', 'Segurado');

        Contact contact = new Contact();
        contact.LastName = 'Test';
        contact.Email = 'user@previsul.com';
        contact.AccountId = lstAccount.get(0).Id;
        contact.Tipo__c = '	Segurado';
        contact.CPF__c = '62506622195';
        insert contact;

    }

    @isTest
    static void validateNewPixRequestTest(){
        String cobrancaString = '{"apolice":"10101140000124","apoliceDisplay":"10101140000124","chaveParcelaLegado":"12294329","ColetivoSn":"N","competencia":"202007","diasVencido":"0","dtVencimento":"31/12/2020","fatura":"71476390","formaPagamento":"Débito em Conta","sistema":"I4PRO","valor":"0.01"}';
        
        Test.startTest();
        Boolean validRequest = PagamentoPixLwcController.validateNewPixRequest(cobrancaString);
        Test.stopTest();

        System.assertEquals(true, validRequest, 'A validação para gerar pix não foi bem sucedida.');
    }

    @isTest
    static void generateCRC16stringTest(){
        String expectedCrc16String = '00020101021226420014br.gov.bcb.pix2520fake.url.test.com.br52040000530398654040.035802BR5908PREVISUL6009SAO PAULO62070503***6304';

        Test.startTest();
        String crc16string = PagamentoPixLwcController.getFieldsValuesString('fake.url.test.com.br', '0.03');
        Test.stopTest();

        System.assertEquals(crc16string, expectedCrc16String, 'A geração da string CRC16-CCIT não foi bem sucedida.');
    }

    @isTest
    static void createLogIntegracaoTest(){
        String testCobranca = '{"apolice":"10101140000124","apoliceDisplay":"10101140000124","chaveParcelaLegado":"12294329","ColetivoSn":"N","competencia":"202007","diasVencido":"0","dtVencimento":"31/12/2020","fatura":"71476390","formaPagamento":"Débito em Conta","sistema":"I4PRO","valor":"0.01"}';
        String testResultWrapper = '{"identificacao": {"codigoNegocio": "123123123"},' +
                                        '"parcela": {"numeroParcela": 1,"codigoModalidade": "1"},' +
                                        '"produto": {"codigoProdutoNegocio": "123","cnpjEmpresa": "12121"},' +
                                        '"valor": 0.03,' +
                                        '"pix": {"txId": "EX23210000000000000000000000146","location": "pix-h.santander.com.br/qr/v2/ba38bfa8-dc7f-4ced-b7cc-bef4c8282c45",' +
                                            '"expiracao": "891798","chave": "20201210000155"},' +
                                        '"informacoesAdicionais": [{"nome": "AAA","valor": "Valor9"}],' +
                                        '"dataCobranca": "2022-01-01T20:00:00Z",' +
                                        '"pagador": {"nome": "DIEGO PEREIRA AIRES","cpfCnpj": "01709467118"},' +
                                        '"descricaoCobranca": "Cobrança dos serviços prestados.",' +
                                        '"dataCriacao": "2021-12-22T12:16:42Z"' +
                                        '}';
        String qrcode = 'fakeQrCode';
        String txId = 'EX23210000000000000000000000146';
        Boolean integrationSuccessful = true;

        Test.startTest();
        String logIntegracaoId = PagamentoPixLwcController.createLogIntegracao(testCobranca, testResultWrapper, qrcode, txId, integrationSuccessful);
        Test.stopTest();

        LogIntegracao__c logIntegracao = [SELECT Id FROM LogIntegracao__c WHERE Name != 'Test Log' LIMIT 1];

        System.assertEquals(logIntegracao.Id, logIntegracaoId, 'O Log de Integração não foi criado.');
    }

     @isTest
    static void sendEmailTest(){
        LogIntegracao__c logIntegracao = [SELECT Id FROM LogIntegracao__c LIMIT 1];
        User user = [SELECT Id FROM User WHERE Alias = 'Test' LIMIT 1];
        String result;

        Test.startTest();
        System.runAs(user){
            result = PagamentoPixLwcController.sendEmail('test@email.com', logIntegracao.Id, true, '71489864');
        }
        Test.stopTest();

        System.assertEquals('', result, 'Sucesso no envio do email de teste.');
    }
}